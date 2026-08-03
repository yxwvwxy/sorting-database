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

    ``operation_date`` is the sheet date / business day (e.g. Jun 16 batch).
    ``subbatch`` encodes the prior calendar day creation stamp (e.g.
    NJSUB-202606152100 for a batch created Jun 15 at 9pm).
    """

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
