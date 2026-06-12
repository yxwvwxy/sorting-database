"""Configuration loaded from environment variables."""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo

ET = ZoneInfo("America/New_York")


@dataclass(frozen=True)
class Settings:
    uniuni_username: str
    uniuni_password: str
    uniuni_url: str
    google_credentials_json: str
    google_sheet_name: str
    google_worksheet_name: str
    supabase_url: str
    supabase_service_role_key: str
    subbatch_override: str | None
    machine_id_override: int | None

    @classmethod
    def from_env(cls) -> Settings:
        machine = os.getenv("MACHINE_ID", "9").strip()
        return cls(
            uniuni_username=os.environ["UNIUNI_USERNAME"],
            uniuni_password=os.environ["UNIUNI_PASSWORD"],
            uniuni_url=os.getenv("UNIUNI_URL", "https://tools.uniuni.com:8203/").rstrip("/") + "/",
            google_credentials_json=os.getenv("GOOGLE_CREDENTIALS", ""),
            google_sheet_name=os.getenv("GOOGLE_SHEET_NAME", "subbatch sheet"),
            google_worksheet_name=os.getenv("GOOGLE_WORKSHEET_NAME", "subbatch sheet"),
            supabase_url=os.environ["SUPABASE_URL"],
            supabase_service_role_key=os.environ["SUPABASE_SERVICE_ROLE_KEY"],
            subbatch_override=(os.getenv("SUBBATCH") or "").strip() or None,
            machine_id_override=int(machine) if machine else None,
        )


@dataclass(frozen=True)
class SubbatchJob:
    operation_date: date
    subbatch: str
    machine_id: int


def operation_date_et(now: datetime | None = None) -> date:
    """Return the operation date in US/Eastern.

    Runs between midnight and 8:59am ET are attributed to the previous calendar day
    so a delayed GitHub Action still targets the correct operation day.
    """
    current = now or datetime.now(ET)
    if current.hour < 9:
        return (current - timedelta(days=1)).date()
    return current.date()


def google_credentials_dict(settings: Settings) -> dict:
    raw = settings.google_credentials_json.strip()
    if not raw:
        creds_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "").strip()
        if creds_path:
            with open(creds_path, encoding="utf-8") as handle:
                return json.load(handle)
        raise RuntimeError(
            "Google credentials not configured. Set GOOGLE_CREDENTIALS (JSON string) "
            "or GOOGLE_APPLICATION_CREDENTIALS (path to JSON file)."
        )
    if raw.startswith("{"):
        return json.loads(raw)
    with open(raw, encoding="utf-8") as handle:
        return json.load(handle)


def enforce_schedule_window() -> None:
    """Only scheduled GitHub Actions must run during the 9:05–9:50pm ET window."""
    event_name = os.environ.get("GITHUB_EVENT_NAME")
    if event_name != "schedule":
        return

    now = datetime.now(ET)
    if not (now.hour == 21 and 5 <= now.minute <= 50):
        raise SystemExit(
            f"Scheduled run outside 21:05–21:50 ET window (now {now.strftime('%H:%M %Z')})."
        )
