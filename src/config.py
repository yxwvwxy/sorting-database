"""Configuration loaded from environment variables."""

from __future__ import annotations

import json
import os
import re
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo

ET = ZoneInfo("America/New_York")
SUBBATCH_PATTERN = re.compile(r"^NJSUB-(\d{8})2100$", re.I)


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


@dataclass(frozen=True)
class SubbatchJob:
    """One sorting operation day (9pm–9pm ET).

    ``operation_date`` is the business day (stamp date + 1).
    ``subbatch`` encodes the creation stamp at 9pm ET
    (e.g. NJSUB-202606152100 for a batch created Jun 15 at 9pm).
    """

    operation_date: date
    subbatch: str
    machine_id: int


def _as_eastern(now: datetime | None = None) -> datetime:
    current = now or datetime.now(ET)
    if current.tzinfo is None:
        return current.replace(tzinfo=ET)
    return current.astimezone(ET)


def operation_date_et(now: datetime | None = None) -> date:
    """Return the operation date for the active 9pm–9pm ET window.

    Switch to the new batch at 21:30 ET (first :30 scrape of the new window).
    The 21:10 scrape still belongs to the previous batch.
    """
    return current_subbatch_job(now=now).operation_date


def operation_date_from_subbatch(subbatch: str) -> date:
    """Derive operation date from NJSUB-YYYYMMDD2100 (stamp day + 1)."""
    match = SUBBATCH_PATTERN.match(subbatch.strip())
    if not match:
        raise RuntimeError(
            f"Cannot parse operation date from subbatch {subbatch!r}. "
            "Expected NJSUB-YYYYMMDD2100."
        )
    stamp = datetime.strptime(match.group(1), "%Y%m%d").date()
    return stamp + timedelta(days=1)


def current_subbatch_job(
    now: datetime | None = None,
    *,
    machine_id: int = 9,
) -> SubbatchJob:
    """Resolve the active batch from Eastern clock (no Google Sheet).

    Schedule alignment:
    - 21:10 ET → last scrape of the batch created the previous calendar day at 21:00
    - 21:30 ET → first scrape of the batch created today at 21:00
    """
    current = _as_eastern(now)
    if current.hour > 21 or (current.hour == 21 and current.minute >= 30):
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
