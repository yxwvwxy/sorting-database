"""Hourly Bundle Management export, run after the :10 chute scrape.

UniMap's generated-date box is a 24-hour window, not a calendar day.
During EDT, date D is the instant after (D-1) 20:00 through D 20:00.
After the clocks fall back, that boundary is 19:00 and the last download
is 19:10. Shipment outliers are summarized only on that closing wave.

Status changes need the previous 24 hours. The 20:10 close is exactly one
date, so From and To are the same. Every other hour crosses that boundary,
so From is the date that contains 24 hours ago and To is the date open now.
"""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo

import pandas as pd
from dotenv import load_dotenv
from playwright.sync_api import Page

from .batch_state import load_batch_state
from .config import (
    ET,
    OPS_SWITCH_HOUR,
    OPS_SWITCH_MINUTE,
    Settings,
    validate_supabase_settings,
    validate_uniuni_login_settings,
)
from .db import create_supabase_client, fetch_subbatch_id, save_bundle_rows
from .session import open_uniuni_session
from .slot_assignment import MAIN_URL, _dismiss_blocking_dialogs, _ensure_logged_in_main

WAREHOUSE = "EWR600"
LOW_SHIPMENTS = 100
HIGH_SHIPMENTS = 300
LOG_DIR = Path("logs")


@dataclass(frozen=True)
class BundleRecord:
    bundle_id: str
    bundle_type: str
    carrier_id: str | None
    dest_transit_whs: str | None
    seal_id: str | None
    area: str | None
    shpt: str | None
    shipment_count: int | None
    current_whs: str
    generated_time: datetime | None
    status: str | None
    notes: str | None
    operator: str | None
    operator_id: str | None
    operation_date: date
    subbatch_id: str

    def as_row(self) -> dict[str, Any]:
        return {
            "subbatch_id": self.subbatch_id,
            "operation_date": self.operation_date.isoformat(),
            "bundle_id": self.bundle_id,
            "bundle_type": self.bundle_type,
            "carrier_id": self.carrier_id,
            "dest_transit_whs": self.dest_transit_whs,
            "seal_id": self.seal_id,
            "area": self.area,
            "shpt": self.shpt,
            "current_whs": self.current_whs,
            "generated_time": (
                self.generated_time.isoformat() if self.generated_time else None
            ),
            "status": self.status,
            "notes": self.notes,
            "operator": self.operator,
            "operator_id": self.operator_id,
        }


def parse_slot(value: str | None) -> datetime:
    if not value:
        return datetime.now(ET)
    text = value.strip()
    parsed = datetime.fromisoformat(text)
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=ET)
    return parsed.astimezone(ET)


def is_ten_past_slot(slot: datetime) -> bool:
    """True for the scheduled :10 run, including a start a few minutes late."""
    current = slot.astimezone(ET)
    return 10 <= current.minute < 30


def _on_daylight_time(slot: datetime) -> bool:
    current = slot.astimezone(ET)
    return (current.utcoffset() or timedelta(0)) == timedelta(hours=-4)


def is_unimap_day_closing_slot(slot: datetime) -> bool:
    """Last :10 download of the UniMap date.

    EDT: 20:10, the date box covers the previous 20:00 through 20:00.
    EST after the fall-back: 19:10, because that boundary moves to 19:00.
    """
    current = slot.astimezone(ET)
    if not is_ten_past_slot(current):
        return False
    if _on_daylight_time(current):
        return current.hour == 20
    return current.hour == OPS_SWITCH_HOUR and current.minute < OPS_SWITCH_MINUTE


def _boundary_hour(moment: datetime) -> int:
    """Hour when the UniMap generated-date closes, in Eastern time."""
    return 20 if _on_daylight_time(moment) else 19


def unimap_date_of(moment: datetime) -> date:
    """UniMap generated-date that contains this instant.

    EDT: after 20:00 belongs to the next calendar date, and 20:00 itself
    still belongs to the date that is closing. EST uses 19:00.
    """
    current = moment.astimezone(ET)
    boundary = _boundary_hour(current)
    if (current.hour, current.minute, current.second, current.microsecond) > (boundary, 0, 0, 0):
        return current.date() + timedelta(days=1)
    return current.date()


def unimap_filter_date(slot: datetime) -> date:
    """UniMap date open at this slot.

    The closing :10 still names the Eastern calendar date that just ended.
    Every other slot names the date whose window contains the slot.
    """
    if is_unimap_day_closing_slot(slot):
        return slot.astimezone(ET).date()
    return unimap_date_of(slot)


def bundle_filter_range(slot: datetime) -> tuple[date, date]:
    """Generated Date From/To for the previous 24 hours.

    20:10 EDT (19:10 EST) is one date: that box is the 24 hours just closed.
    Any other hour reaches back across the boundary, so From is one date
    earlier than To.
    """
    if is_unimap_day_closing_slot(slot):
        closed = slot.astimezone(ET).date()
        return closed, closed
    current = slot.astimezone(ET)
    return unimap_date_of(current - timedelta(hours=24)), unimap_date_of(current)


def subbatch_for(operation_date: date, saved_subbatch: str | None, saved_ops: date | None) -> str:
    if saved_subbatch and saved_ops == operation_date:
        return saved_subbatch
    stamp = operation_date - timedelta(days=1)
    return f"NJSUB-{stamp.strftime('%Y%m%d')}2100"


def shipment_count(value: Any) -> int | None:
    if value is None:
        return None
    text = str(value).strip()
    if not text or text in {"-", "nan", "None"}:
        return None
    if re.fullmatch(r"\d+(?:\.0+)?", text):
        return int(float(text))
    return None


def _clean_text(value: Any) -> str | None:
    if value is None or (isinstance(value, float) and pd.isna(value)):
        return None
    text = str(value).strip()
    if not text or text.lower() == "nan":
        return None
    if re.fullmatch(r"\d+\.0+", text):
        return str(int(float(text)))
    return text


def _clean_time(value: Any) -> datetime | None:
    if value is None or (isinstance(value, float) and pd.isna(value)):
        return None
    if isinstance(value, datetime):
        parsed = value
    else:
        parsed = pd.to_datetime(value, utc=True).to_pydatetime()
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=ZoneInfo("UTC"))
    return parsed.astimezone(timezone.utc)


def records_from_frame(
    frame: pd.DataFrame,
    *,
    subbatch_by_ops: dict[date, str],
) -> list[BundleRecord]:
    records: list[BundleRecord] = []
    seen: set[str] = set()
    for raw in frame.to_dict(orient="records"):
        bundle_id = _clean_text(raw.get("Bundle ID"))
        bundle_type = _clean_text(raw.get("Bundle Type"))
        current_whs = _clean_text(raw.get("Current WHS"))
        status = _clean_text(raw.get("Status"))
        if not bundle_id or not bundle_type or not current_whs or not status:
            continue
        seen_key = f"{bundle_id}\0{status}"
        if seen_key in seen:
            continue
        seen.add(seen_key)
        generated = _clean_time(raw.get("Generated Time"))
        if generated is None:
            continue
        ops = unimap_date_of(generated)
        shpt = _clean_text(raw.get("SHPT"))
        records.append(
            BundleRecord(
                bundle_id=bundle_id,
                bundle_type=bundle_type,
                carrier_id=_clean_text(raw.get("Carrier ID")),
                dest_transit_whs=_clean_text(raw.get("Dest. Transit WHS")),
                seal_id=_clean_text(raw.get("Seal ID")),
                area=_clean_text(raw.get("Area")),
                shpt=shpt,
                shipment_count=shipment_count(shpt),
                current_whs=current_whs,
                generated_time=generated,
                status=status,
                notes=_clean_text(raw.get("Notes")),
                operator=_clean_text(raw.get("Operator")),
                operator_id=_clean_text(raw.get("Operator ID")),
                operation_date=ops,
                subbatch_id=subbatch_by_ops.get(ops) or subbatch_for(ops, None, None),
            )
        )
    return records


def format_shpt_summary(records: list[BundleRecord], *, batch: str, operation_date: date) -> str:
    """Bundles on this batch whose shipment count is under 100 or over 300."""
    owned = [row for row in records if row.operation_date == operation_date]
    low = [row for row in owned if row.shipment_count is not None and row.shipment_count < LOW_SHIPMENTS]
    high = [row for row in owned if row.shipment_count is not None and row.shipment_count > HIGH_SHIPMENTS]
    unknown = [row for row in owned if row.shipment_count is None]
    low.sort(key=lambda row: (row.shipment_count or 0, row.bundle_id))
    high.sort(key=lambda row: (-(row.shipment_count or 0), row.bundle_id))

    lines = [
        f"集包件数汇总  批次 {batch}  运营日 {operation_date.isoformat()}",
        f"本批次集包 {len(owned)} 行",
        f"shipment < {LOW_SHIPMENTS}：{len(low)} 行",
        f"shipment > {HIGH_SHIPMENTS}：{len(high)} 行",
    ]
    if unknown:
        lines.append(f"shipment 不是整数：{len(unknown)} 行")
    lines.append("")

    def add_block(title: str, rows: list[BundleRecord]) -> None:
        lines.append(title)
        if not rows:
            lines.append("（无）")
            lines.append("")
            return
        for row in rows:
            when = ""
            if row.generated_time is not None:
                when = row.generated_time.astimezone(ET).strftime("%m/%d %H:%M")
            count = row.shpt if row.shipment_count is None else str(row.shipment_count)
            lines.append(
                f"{count:>5}  {row.dest_transit_whs or '-':<8}  {row.area or '-':<8}  "
                f"{row.status or '-':<8}  {when}  {row.bundle_id}"
            )
        lines.append("")

    add_block(f"低于 {LOW_SHIPMENTS}", low)
    add_block(f"高于 {HIGH_SHIPMENTS}", high)
    return "\n".join(lines).rstrip() + "\n"


def _control(page: Page, label: str):
    return page.locator(".MuiFormControl-root, .ant-form-item").filter(
        has=page.locator("label", has_text=re.compile(rf"^{re.escape(label)}$", re.I))
    ).first


def _open_bundle_management(page: Page) -> Page:
    _dismiss_blocking_dialogs(page)
    switched = page.evaluate(
        """() => {
          const el = [...document.querySelectorAll('[role=tab]')]
            .find(e => /^\\s*Menu\\s*$/i.test((e.innerText || '').trim()));
          if (!el) return false;
          el.click();
          return true;
        }"""
    )
    if not switched:
        tab = page.get_by_text(re.compile(r"^\s*Menu\s*$", re.I)).first
        if tab.count() == 0:
            raise RuntimeError("Menu tab not found on UniMap main page.")
        tab.click(force=True)
    page.wait_for_function(
        """() => /BUNDLE\\s*MANAGEMENT/i.test(document.body.innerText || '')""",
        timeout=20_000,
    )
    page.get_by_text(re.compile(r"BUNDLE\s*MANAGEMENT", re.I)).first.click(force=True)
    page.wait_for_timeout(2_000)
    target = page.context.pages[-1]
    target.wait_for_load_state("domcontentloaded")
    target.get_by_text(re.compile(r"Bundle\s*Management", re.I)).first.wait_for(
        state="visible", timeout=60_000
    )
    return target


def _set_date(page: Page, label: str, iso_date: str) -> None:
    field = _control(page, label).locator("input").first
    field.click(force=True)
    field.fill(iso_date)
    page.keyboard.press("Escape")
    page.wait_for_timeout(200)


def _set_warehouse(page: Page, value: str) -> None:
    field = _control(page, "Current Warehouse").locator("input").first
    field.click(force=True)
    field.fill("")
    field.fill(value)
    page.wait_for_timeout(600)
    option = page.locator('[role="option"]').filter(
        has_text=re.compile(rf"^{re.escape(value)}$")
    )
    if option.count() == 0:
        page.keyboard.press("Escape")
        raise RuntimeError(f"Warehouse option {value!r} not found.")
    option.first.click(force=True)
    page.wait_for_timeout(300)


def download_bundle_excel(page: Page, date_from: date, date_to: date, dest: Path) -> None:
    _set_date(page, "Generated Date From", date_from.isoformat())
    _set_date(page, "Generated Date To", date_to.isoformat())
    _set_warehouse(page, WAREHOUSE)
    search = page.locator("button").filter(has_text=re.compile(r"^\s*SEARCH\s*$", re.I))
    search.first.click(force=True)
    page.wait_for_timeout(3_000)
    export = page.locator("button").filter(has_text=re.compile(r"^\s*EXPORT\s*$", re.I))
    export.first.wait_for(state="visible", timeout=20_000)
    dest.parent.mkdir(parents=True, exist_ok=True)
    with page.expect_download(timeout=90_000) as download_info:
        export.first.click(force=True)
    download_info.value.save_as(dest)


def _subbatches_for_range(
    client,
    date_from: date,
    date_to: date,
    *,
    saved_subbatch: str | None,
    saved_ops: date | None,
) -> dict[date, str]:
    found: dict[date, str] = {}
    day = date_from
    while day <= date_to:
        if saved_subbatch and saved_ops == day:
            found[day] = saved_subbatch
        else:
            found[day] = fetch_subbatch_id(client, day) or subbatch_for(day, None, None)
        day += timedelta(days=1)
    return found


def run(slot: datetime) -> int:
    load_dotenv("local.env")
    load_dotenv(".env")
    closing = is_unimap_day_closing_slot(slot)
    date_from, date_to = bundle_filter_range(slot)
    state = load_batch_state()
    saved_subbatch = state.job.subbatch if state else None
    saved_ops = state.job.operation_date if state else None
    settings = Settings.from_env()
    validate_uniuni_login_settings(settings)
    validate_supabase_settings(settings)
    client = create_supabase_client(settings)
    subbatches = _subbatches_for_range(
        client,
        date_from,
        date_to,
        saved_subbatch=saved_subbatch,
        saved_ops=saved_ops,
    )
    print(
        f"Bundle export slot {slot.astimezone(ET).strftime('%Y-%m-%d %H:%M')} ET "
        f"from {date_from.isoformat()} to {date_to.isoformat()} "
        f"closing={closing}"
    )

    span = date_from.isoformat() if date_from == date_to else f"{date_from.isoformat()}_{date_to.isoformat()}"
    dest = LOG_DIR / "bundles" / f"bundle-{span}-{slot.astimezone(ET).strftime('%H%M')}.xlsx"
    home = None
    with open_uniuni_session(settings, headless=True) as session:
        home = session.page
        try:
            _ensure_logged_in_main(home, settings)
            target = _open_bundle_management(home)
            download_bundle_excel(target, date_from, date_to, dest)
            print(f"Saved {dest} ({dest.stat().st_size} bytes)")
        finally:
            try:
                home.goto(MAIN_URL, wait_until="domcontentloaded", timeout=60_000)
                _dismiss_blocking_dialogs(home)
            except Exception as exc:
                print(f"Could not return to UniMap main before closing ({exc}).")

    frame = pd.read_excel(dest)
    records = records_from_frame(frame, subbatch_by_ops=subbatches)
    print(f"Parsed {len(records)} bundles from {len(frame)} rows")
    written = save_bundle_rows(
        client,
        [row.as_row() for row in records],
        scraped_at=datetime.now(timezone.utc),
    )
    print(
        f"Database inserted={written['inserted']} "
        f"updated={written['updated']} unchanged={written['unchanged']}"
    )

    if closing:
        batch_ops = date_to
        text = format_shpt_summary(
            records,
            batch=subbatches[batch_ops],
            operation_date=batch_ops,
        )
        summary_path = LOG_DIR / f"bundle-shpt-summary-{batch_ops.isoformat()}.txt"
        summary_path.parent.mkdir(parents=True, exist_ok=True)
        summary_path.write_text(text, encoding="utf-8")
        print(text)
        print(f"Summary written to {summary_path}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Export UniMap bundles for the current batch.")
    parser.add_argument(
        "--slot",
        help="When the :10 chute task started, as YYYY-MM-DDTHH:MM in Eastern time.",
    )
    args = parser.parse_args(argv)
    slot = parse_slot(args.slot)
    if args.slot and not is_ten_past_slot(slot):
        print(f"Skip bundle export: slot {args.slot} is not a :10 run.")
        return 0
    return run(slot)


if __name__ == "__main__":
    raise SystemExit(main())
