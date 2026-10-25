"""Configuration loaded from environment variables."""

from __future__ import annotations

import json
import os
import re
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo

ET = ZoneInfo("America/New_York")
# Stamp is YYYYMMDD + time digits (usually 2100; sometimes 2101 etc.).
SUBBATCH_PATTERN = re.compile(r"^NJSUB-(\d{8})\d+$", re.I)


@dataclass(frozen=True)
class Settings:
    uniuni_username: str
    uniuni_password: str
    uniuni_portal_url: str
    uniuni_auth_state_path: str | None
    google_credentials_json: str
    google_sheet_id: str
    google_sheet_name: str
    google_worksheet_name: str
    supabase_url: str
    supabase_service_role_key: str
    subbatch_override: str | None
    machine_id_override: int | None

    @classmethod
    def from_env(cls) -> Settings:
        machine = os.getenv("MACHINE_ID", "9").strip()
        auth_state = (os.getenv("UNIUNI_AUTH_STATE_PATH") or ".uniuni-auth-state.json").strip()

        return cls(
            uniuni_username=os.environ["UNIUNI_USERNAME"].strip(),
            uniuni_password=os.environ["UNIUNI_PASSWORD"].strip(),
            uniuni_portal_url=os.getenv(
                "UNIUNI_PORTAL_URL", "https://dispatch.uniuni.com/login"
            ).rstrip("/")
            + "/",
            uniuni_auth_state_path=auth_state or None,
            google_credentials_json=os.getenv("GOOGLE_CREDENTIALS", "")
            or os.getenv("GOOGLE_SHEETS_CREDENTIALS", ""),
            google_sheet_id=os.getenv("GOOGLE_SHEETS_ID", ""),
            google_sheet_name=os.getenv("GOOGLE_SHEET_NAME", "subbatch scrape"),
            google_worksheet_name=os.getenv("GOOGLE_WORKSHEET_NAME", "subbatch scrape"),
            supabase_url=os.getenv("SUPABASE_URL", "").strip(),
            supabase_service_role_key=os.getenv("SUPABASE_SERVICE_ROLE_KEY", "").strip(),
            subbatch_override=(os.getenv("SUBBATCH") or "").strip() or None,
            machine_id_override=int(machine) if machine else None,
        )


def validate_uniuni_login_settings(settings: Settings) -> None:
    """Fail fast when UniMap username/password are missing."""
    missing = [
        name
        for name, value in (
            ("UNIUNI_USERNAME", settings.uniuni_username),
            ("UNIUNI_PASSWORD", settings.uniuni_password),
        )
        if not value
    ]
    if missing:
        raise RuntimeError(
            "Missing UniMap login configuration: "
            + ", ".join(missing)
            + ". Check GitHub Actions secrets or your local .env file."
        )


def validate_supabase_settings(settings: Settings) -> None:
    """Fail fast with a clear message when Supabase env vars are missing."""
    missing = [
        name
        for name, value in (
            ("SUPABASE_URL", settings.supabase_url),
            ("SUPABASE_SERVICE_ROLE_KEY", settings.supabase_service_role_key),
        )
        if not value
    ]
    if missing:
        raise RuntimeError(
            "Missing Supabase configuration: "
            + ", ".join(missing)
            + ". Check GitHub Actions secrets or your local .env file."
        )


# 19:10 ET is the last scrape of the current ops day.
# 19:30 ET is the first scrape of the new ops day and must read the new Batch No.
# On an early-switch date the last scrape is 18:10, and 18:30 opens the next batch.
OPS_SWITCH_HOUR = 19
OPS_SWITCH_MINUTE = 30
EARLY_OPS_SWITCH_ON = frozenset({
    date(2026, 10, 22),
    date(2026, 10, 25),
})
EARLY_OPS_SWITCH_HOUR = 18
EARLY_OPS_SWITCH_MINUTE = 30


@dataclass(frozen=True)
class SubbatchJob:
    """One sorting operation day (7pm–7pm ET).

    ``operation_date`` is the business day (stamp date + 1).
    The live batch number comes from Slot Assignment at 19:30 ET.
    """

    operation_date: date
    subbatch: str
    machine_id: int


def _as_eastern(now: datetime | None = None) -> datetime:
    current = now or datetime.now(ET)
    if current.tzinfo is None:
        return current.replace(tzinfo=ET)
    return current.astimezone(ET)


def _ops_switch_clock(current: datetime) -> tuple[int, int]:
    """Hour and minute when this evening's new ops day opens."""
    if current.date() in EARLY_OPS_SWITCH_ON:
        return EARLY_OPS_SWITCH_HOUR, EARLY_OPS_SWITCH_MINUTE
    return OPS_SWITCH_HOUR, OPS_SWITCH_MINUTE


def new_ops_window_started(now: datetime | None = None) -> bool:
    """True from the evening switch until the next day's switch.

    Normally 19:30 ET. On an early-switch date the window opens at 18:30.
    """
    current = _as_eastern(now)
    hour, minute = _ops_switch_clock(current)
    return current.hour > hour or (current.hour == hour and current.minute >= minute)


def is_closing_scrape_slot(now: datetime | None = None) -> bool:
    """True for the :10 before the switch. That scrape stays on the current batch.

    Normally 19:00–19:29 ET. On an early-switch date it is 18:00–18:29, so
    18:10 stays on the current batch and 18:30 may open the new batch.
    """
    current = _as_eastern(now)
    hour, minute = _ops_switch_clock(current)
    return current.hour == hour and current.minute < minute


def operation_date_et(now: datetime | None = None) -> date:
    """Return the operation date for the active 7pm–7pm ET window.

    Switch to the new batch at 19:30 ET. The 19:10 scrape still belongs
    to the previous batch.
    """
    return current_subbatch_job(now=now).operation_date


def is_opening_initials_slot(now: datetime | None = None) -> bool:
    """Five-city Workflow initials are no longer captured on the opening scrape."""
    del now
    return False


def operation_date_from_subbatch(subbatch: str) -> date:
    """Derive operation date from NJSUB-YYYYMMDD#### (stamp day + 1)."""
    match = SUBBATCH_PATTERN.match(subbatch.strip())
    if not match:
        raise RuntimeError(
            f"Cannot parse operation date from subbatch {subbatch!r}. "
            "Expected NJSUB-YYYYMMDD followed by time digits (e.g. 2100 or 2101)."
        )
    stamp = datetime.strptime(match.group(1), "%Y%m%d").date()
    return stamp + timedelta(days=1)


def current_subbatch_job(
    now: datetime | None = None,
    *,
    machine_id: int = 9,
) -> SubbatchJob:
    """Resolve a clock fallback batch (no Google Sheet, no Slot Assignment).

    Schedule alignment:
    - 19:10 ET → last scrape of the previous ops day
    - 19:30 ET → first scrape of the new ops day; the real Batch No comes
      from Slot Assignment, not this fallback id
    """
    current = _as_eastern(now)
    if new_ops_window_started(current):
        stamp_date = current.date()
    else:
        stamp_date = current.date() - timedelta(days=1)

    operation_date = stamp_date + timedelta(days=1)
    subbatch = f"NJSUB-{stamp_date.strftime('%Y%m%d')}2100"
    return SubbatchJob(
        operation_date=operation_date,
        subbatch=subbatch,
        machine_id=machine_id,
    )


def google_credentials_dict(settings: Settings) -> dict:
    raw = (
        settings.google_credentials_json.strip()
        or os.getenv("GOOGLE_SHEETS_CREDENTIALS", "").strip()
    )
    if not raw:
        creds_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "").strip()
        if creds_path:
            with open(creds_path, encoding="utf-8") as handle:
                return json.load(handle)
        raise RuntimeError(
            "Google credentials not configured. Set GOOGLE_CREDENTIALS (JSON string or file path) "
            "or GOOGLE_APPLICATION_CREDENTIALS (path to JSON file)."
        )
    if raw.startswith("{"):
        return json.loads(raw)
    with open(raw, encoding="utf-8") as handle:
        return json.load(handle)
