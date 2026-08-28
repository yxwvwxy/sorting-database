#!/usr/bin/env python3
"""Mac-only: poll for the new ops-day batch and write city initials.

Intended for evenings when the Windows runner does not yet have this code.
Runs from ~21:30 ET until initials for tonight's switch-window ops day exist,
or until 22:30 ET.
"""

from __future__ import annotations

import subprocess
import sys
import time
from datetime import datetime, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from dotenv import load_dotenv

from src.batch_resolve import switch_window_operation_date
from src.config import ET, Settings, validate_supabase_settings
from src.db import create_supabase_client


def _now_et() -> datetime:
    return datetime.now(ET)


def _initials_ready(client, operation_date) -> bool:
    response = (
        client.table("city_initial_volume")
        .select("city")
        .eq("operation_date", operation_date.isoformat())
        .execute()
    )
    cities = {row["city"] for row in (response.data or [])}
    needed = {"RIC", "ALB", "SWF", "SYR", "PVD2"}
    return needed.issubset(cities)


def main() -> int:
    load_dotenv(ROOT / "local.env")
    load_dotenv(ROOT / ".env")
    settings = Settings.from_env()
    validate_supabase_settings(settings)
    client = create_supabase_client(settings)

    now = _now_et()
    expected = switch_window_operation_date(now)
    deadline = now.replace(hour=22, minute=30, second=0, microsecond=0)
    if now >= deadline:
        deadline = now + timedelta(minutes=45)

    print(
        f"[{now.isoformat()}] Mac evening initials: "
        f"expect ops day {expected}, poll until {deadline.strftime('%H:%M %Z')}"
    )

    if _initials_ready(client, expected):
        print(f"Already have city_initial_volume for {expected} — nothing to do.")
        return 0

    python = ROOT / ".venv" / "bin" / "python"
    attempt = 0
    while _now_et() < deadline:
        attempt += 1
        print(f"\n--- attempt {attempt} @ {_now_et().strftime('%H:%M:%S %Z')} ---")
        # Refresh reads live Slot Batch No. If still yesterday's batch, we may
        # re-upsert old initials; loop continues until expected ops day is ready.
        result = subprocess.run(
            [str(python), "-m", "src.main", "--initials-only", "--refresh-batch"],
            cwd=str(ROOT),
        )
        print(f"src.main exit={result.returncode}")

        if _initials_ready(client, expected):
            print(f"Saved initials for ops day {expected}. Done.")
            return 0

        print(
            f"Ops day {expected} initials not ready yet "
            "(batch may not have switched). Sleeping 120s..."
        )
        time.sleep(120)

    print(
        f"ERROR: timed out waiting for city initials for ops day {expected}.",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
