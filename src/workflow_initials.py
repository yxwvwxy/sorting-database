"""Fetch ops-day initial city volumes from UniMap Workflow Management.

Flow (after new batch is known):
  Menu → WORKFLOW MANAGEMENT → Step 1 Select Batch → Enter
  → Step 2 Select Warehouse dropdown → read warehouse quantities.

Warehouse labels → dashboard city:
  RIC / ALB / SWF / SYR Warehouse → same code
  BOS Warehouse → PVD2
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import datetime, timezone

from playwright.sync_api import Page

from .config import Settings, SubbatchJob
from .scraper import _is_login_page, _login_form_visible, _portal_logged_in
from .slot_assignment import MAIN_URL, _dismiss_blocking_dialogs, _ensure_logged_in_main

# Dropdown label → city code stored in city_initial_volume
WAREHOUSE_TO_CITY = {
    "RIC": "RIC",
    "ALB": "ALB",
    "SWF": "SWF",
    "SYR": "SYR",
    "BOS": "PVD2",
}
REQUIRED_CITIES = ("RIC", "ALB", "SWF", "SYR", "PVD2")

# e.g. "RIC Warehouse", "BOS Warehouse - 1234", "ALB Warehouse(56)"
_WAREHOUSE_LINE = re.compile(
    r"\b(RIC|ALB|SWF|SYR|BOS)\s*Warehouse\b[^\d]*(\d[\d,]*)",
    re.I,
)


@dataclass(frozen=True)
class CityInitial:
    city: str
    initial_volume: int


@dataclass(frozen=True)
class CityInitialsResult:
    subbatch: str
    operation_date: str
    scraped_at: datetime
    rows: list[CityInitial]


def _open_workflow_management(page: Page) -> Page:
    """Menu → WORKFLOW MANAGEMENT tile; return the page hosting the form."""
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
        # Already on Menu grid sometimes has no role=tab match — try text tab
        tab = page.get_by_text(re.compile(r"^\s*Menu\s*$", re.I)).first
        if tab.count() == 0:
            raise RuntimeError("Menu tab not found on UniMap main page.")
        tab.click(force=True)

    page.wait_for_function(
        """() => /WORKFLOW\\s*MANAGEMENT/i.test(document.body.innerText || '')""",
        timeout=20_000,
    )

    tile = page.get_by_text(re.compile(r"WORKFLOW\s*MANAGEMENT", re.I)).first
    tile.click(force=True)
    page.wait_for_timeout(2_000)

    target = page.context.pages[-1]
    target.wait_for_load_state("domcontentloaded")
    target.get_by_text(re.compile(r"Workflow\s*Management", re.I)).first.wait_for(
        state="visible", timeout=60_000
    )
    return target


def _select_workflow_mode(page: Page) -> None:
    """Ensure the 'workflow' radio is selected (not port transit / heavy / view)."""
    radio = page.get_by_role("radio", name=re.compile(r"^\s*workflow\s*$", re.I))
    if radio.count() and not radio.first.is_checked():
        radio.first.check(force=True)
        page.wait_for_timeout(400)
    else:
        # Fallback: click label text
        label = page.get_by_text(re.compile(r"^\s*workflow\s*$", re.I)).first
        if label.count():
            label.click(force=True)
            page.wait_for_timeout(400)


def _fill_step1_batch(page: Page, subbatch: str) -> None:
    """Step 1: Select Batch → type subbatch → Enter."""
    candidates = [
        page.get_by_label(re.compile(r"Select\s*Batch", re.I)),
        page.get_by_placeholder(re.compile(r"Select\s*Batch|batch", re.I)),
        page.locator("input").filter(has=page.locator("xpath=..")).first,
    ]
    inp = None
    # Prefer input near "Select Batch" / Step 1
    labeled = page.locator(
        "input:not([type='hidden']):not([type='radio']):not([type='checkbox'])"
    )
    # Try MUI / ant floating label containers
    box = page.get_by_text(re.compile(r"Select\s*Batch", re.I)).first
    if box.count():
        container = box.locator(
            "xpath=ancestor::*[contains(@class,'MuiFormControl') or "
            "contains(@class,'ant-form-item') or self::div][1]"
        )
        field = container.locator("input").first
        if field.count():
            inp = field

    if inp is None:
        for c in candidates:
            try:
                if c.count() and c.first.is_visible():
                    inp = c.first
                    break
            except Exception:
                continue

    if inp is None:
        # First visible text input on the page (Step 1)
        fields = page.locator(
            "input:not([type='hidden']):not([type='radio']):not([type='checkbox']):not([type='password'])"
        )
        for i in range(min(fields.count(), 8)):
            el = fields.nth(i)
            if el.is_visible():
                inp = el
                break

    if inp is None:
        raise RuntimeError("Workflow Management Step 1 batch input not found.")

    print(f"  Step 1: entering batch {subbatch}")
    inp.click(force=True)
    inp.fill("")
    inp.fill(subbatch)
    page.keyboard.press("Enter")
    page.wait_for_timeout(1_500)


def _open_step2_warehouse_dropdown(page: Page) -> None:
    """Click Step 2 Select Warehouse dropdown."""
    label = page.get_by_text(re.compile(r"Select\s*Warehouse", re.I)).first
    if label.count() == 0:
        raise RuntimeError("Workflow Management Step 2 'Select Warehouse' not found.")

    container = label.locator(
        "xpath=ancestor::*[contains(@class,'MuiFormControl') or "
        "contains(@class,'ant-form-item') or contains(@class,'MuiSelect') or "
        "self::div][1]"
    )
    trigger = container.locator(
        "[role='combobox'], .MuiSelect-select, .ant-select-selector, "
        ".MuiOutlinedInput-root, input"
    ).first
    if trigger.count() == 0:
        trigger = label
    print("  Step 2: opening Select Warehouse dropdown")
    trigger.click(force=True)
    page.wait_for_timeout(800)


def _parse_warehouse_quantities(raw_lines: list[str]) -> dict[str, int]:
    """Map dashboard city → initial volume; ignore any warehouse not in the five."""
    found: dict[str, int] = {}
    ignored: list[str] = []
    for line in raw_lines:
        text = re.sub(r"\s+", " ", (line or "")).strip()
        if not text:
            continue
        match = _WAREHOUSE_LINE.search(text)
        if not match:
            # Other labels / NONEs / unrelated option text — ignore
            if re.search(r"Warehouse", text, re.I):
                ignored.append(text)
            continue
        wh = match.group(1).upper()
        city = WAREHOUSE_TO_CITY.get(wh)
        if not city:
            ignored.append(text)
            continue
        volume = int(match.group(2).replace(",", ""))
        # Keep first / max if duplicates
        found[city] = max(found.get(city, 0), volume)
    if ignored:
        print(f"  Ignored non-target warehouse lines ({len(ignored)}):")
        for line in ignored[:20]:
            print(f"    {line}")
    return found


def _read_dropdown_option_texts(page: Page) -> list[str]:
    texts = page.evaluate(
        """() => {
          const nodes = [
            ...document.querySelectorAll(
              '[role="listbox"] [role="option"], [role="option"], '
              + '.ant-select-item, .MuiMenuItem-root, li'
            )
          ];
          const out = [];
          for (const el of nodes) {
            const style = window.getComputedStyle(el);
            if (style && (style.display === 'none' || style.visibility === 'hidden')) continue;
            const t = (el.innerText || el.textContent || '').trim();
            if (t) out.push(t);
          }
          // Also scan any visible popover/menu panel text lines
          const panels = document.querySelectorAll(
            '.MuiPopover-root, .MuiMenu-paper, .ant-select-dropdown, [role="presentation"]'
          );
          for (const panel of panels) {
            const style = window.getComputedStyle(panel);
            if (style && style.display === 'none') continue;
            const block = (panel.innerText || '').trim();
            if (!block) continue;
            for (const line of block.split('\\n')) {
              const t = line.trim();
              if (t) out.push(t);
            }
          }
          return [...new Set(out)];
        }"""
    )
    return list(texts or [])


def _reuse_main_session(page: Page, settings: Settings) -> Page:
    """Stay in the current UniMap browser session after Slot Assignment.

    Do not re-login when already authenticated. Only goto /main if the active
    tab is not already on main (e.g. after closing the Slot Assignment tab).
    """
    target = page
    try:
        if page.is_closed():
            target = next(p for p in page.context.pages if not p.is_closed())
    except Exception:
        pass

    # Prefer an existing /main tab in this browser context.
    try:
        for p in target.context.pages:
            if p.is_closed():
                continue
            url = p.url or ""
            if "dispatch.uniuni.com" in url and "/main" in url:
                target = p
                break
    except Exception:
        pass

    url = ""
    try:
        url = target.url or ""
    except Exception:
        url = ""

    logged_in = False
    try:
        logged_in = (
            "dispatch.uniuni.com" in url
            and not _is_login_page(target)
            and not _login_form_visible(target)
            and _portal_logged_in(target)
        )
    except Exception:
        logged_in = False

    if logged_in and "/main" in url:
        print("Reusing open UniMap main tab (no reload / re-login).")
        _dismiss_blocking_dialogs(target)
        try:
            target.bring_to_front()
        except Exception:
            pass
        return target

    if logged_in:
        print("Same UniMap session → /main (no re-login).")
        target.goto(MAIN_URL, wait_until="domcontentloaded", timeout=60_000)
        _dismiss_blocking_dialogs(target)
        return target

    _ensure_logged_in_main(target, settings)
    return target


def fetch_city_initials_on_page(
    page: Page,
    settings: Settings,
    job: SubbatchJob,
) -> CityInitialsResult:
    """Navigate Workflow Management and read Step 2 warehouse initial quantities."""
    page = _reuse_main_session(page, settings)
    wf = _open_workflow_management(page)
    _select_workflow_mode(wf)
    _fill_step1_batch(wf, job.subbatch)
    _open_step2_warehouse_dropdown(wf)

    lines = _read_dropdown_option_texts(wf)
    print(f"  Warehouse dropdown lines ({len(lines)}):")
    for line in lines[:30]:
        print(f"    {line}")

    parsed = _parse_warehouse_quantities(lines)
    missing = [c for c in REQUIRED_CITIES if c not in parsed]
    if missing:
        # Close dropdown and fail with context
        try:
            wf.keyboard.press("Escape")
        except Exception:
            pass
        raise RuntimeError(
            "Workflow Management Step 2 missing initial volumes for: "
            + ", ".join(missing)
            + f". Parsed={parsed!r}. Check dropdown labels (BOS Warehouse → PVD2)."
        )

    try:
        wf.keyboard.press("Escape")
    except Exception:
        pass

    rows = [
        CityInitial(city=city, initial_volume=parsed[city]) for city in REQUIRED_CITIES
    ]
    scraped_at = datetime.now(timezone.utc)
    print(
        "  Initial volumes: "
        + ", ".join(f"{r.city}={r.initial_volume}" for r in rows)
    )
    return CityInitialsResult(
        subbatch=job.subbatch,
        operation_date=job.operation_date.isoformat(),
        scraped_at=scraped_at,
        rows=rows,
    )


def fetch_city_initials(
    page: Page,
    settings: Settings,
    job: SubbatchJob,
) -> CityInitialsResult:
    """Public entry: reuse the open session, then Workflow Management."""
    return fetch_city_initials_on_page(page, settings, job)
