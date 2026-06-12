"""Read subbatch rows from Google Sheets (gspread + service account)."""

from __future__ import annotations

from datetime import date, datetime

import gspread
from google.oauth2.service_account import Credentials

from .config import Settings, SubbatchJob, google_credentials_dict

SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets.readonly",
    "https://www.googleapis.com/auth/drive.readonly",
]


def _client(settings: Settings) -> gspread.Client:
    creds = Credentials.from_service_account_info(google_credentials_dict(settings), scopes=SCOPES)
    return gspread.authorize(creds)


def _parse_row_date(value: str) -> date | None:
    value = value.strip()
    for fmt in ("%Y-%m-%d", "%m/%d/%Y"):
        try:
            return datetime.strptime(value, fmt).date()
        except ValueError:
            continue
    return None


def fetch_subbatch_for_date(settings: Settings, operation_date: date) -> SubbatchJob:
    client = _client(settings)
    if settings.google_sheet_id:
        sheet = client.open_by_key(settings.google_sheet_id).worksheet(settings.google_worksheet_name)
    else:
        sheet = client.open(settings.google_sheet_name).worksheet(settings.google_worksheet_name)
    rows = sheet.get_all_values()
    if not rows:
        raise RuntimeError("Google Sheet is empty.")

    target = operation_date.isoformat()
    for row in rows:
        if len(row) < 2:
            continue
        row_date = _parse_row_date(row[0])
        if row_date is None or row_date.isoformat() != target:
            continue
        machine_raw = row[2].strip() if len(row) > 2 and row[2].strip() else "9"
        return SubbatchJob(
            operation_date=operation_date,
            subbatch=row[1].strip(),
            machine_id=int(machine_raw),
        )

    raise RuntimeError(f"No subbatch row found for operation date {target}.")


def resolve_job(
    settings: Settings,
    operation_date: date,
    *,
    subbatch_override: str | None = None,
    machine_id_override: int | None = None,
) -> SubbatchJob:
    subbatch = subbatch_override or settings.subbatch_override
    machine_id = machine_id_override if machine_id_override is not None else settings.machine_id_override
    if subbatch:
        return SubbatchJob(
            operation_date=operation_date,
            subbatch=subbatch,
            machine_id=machine_id or 9,
        )
    return fetch_subbatch_for_date(settings, operation_date)
