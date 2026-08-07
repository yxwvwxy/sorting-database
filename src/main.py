"""CLI entrypoint for the UniUni sorting data scraper."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime

from dotenv import load_dotenv

from .batch_resolve import resolve_job
from .config import ET, Settings, validate_supabase_settings, validate_uniuni_login_settings
from .db import create_supabase_client, fetch_finalized_hourly_buckets, save_scrape_result
from .scraper import hour_bucket_key
from .session import open_uniuni_session


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Scrape UniUni sorting data into Supabase.")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Scrape only; print JSON summary without writing to Supabase.",
    )
    parser.add_argument(
        "--headed",
        action="store_true",
        help="Run browser with UI (useful for debugging).",
    )
    parser.add_argument(
        "--subbatch",
        help="Override subbatch (skips Slot Assignment / saved batch).",
    )
    parser.add_argument(
        "--machine-id",
        type=int,
        help="Override machine id (default 9).",
    )
    parser.add_argument(
        "--refresh-batch",
        action="store_true",
        help="Force Slot Assignment Batch No refresh (normally only at 21:30 ET).",
    )
    parser.add_argument(
        "--use-sheet",
        action="store_true",
        help="Resolve batch from Google Sheet instead of Slot Assignment / saved batch.",
    )
    args = parser.parse_args(argv)

    load_dotenv("local.env")
    load_dotenv(".env")
    settings = Settings.from_env()
    validate_uniuni_login_settings(settings)

    client = None
    if not args.dry_run:
        validate_supabase_settings(settings)
        client = create_supabase_client(settings)

    # One browser for the whole run: reuse nj600 session; if Slot Assignment is
    # needed first, navigate that same session to Sorting Production Analysis.
    with open_uniuni_session(settings, headless=not args.headed) as session:
        job = resolve_job(
            settings,
            subbatch_override=args.subbatch,
            machine_id_override=args.machine_id,
            use_sheet=args.use_sheet,
            refresh_batch=args.refresh_batch,
            headless=not args.headed,
            session=session,
        )

        print(f"Operation date: {job.operation_date}")
        print(f"Subbatch: {job.subbatch} | Machine: {job.machine_id}")

        finalized_hours = None
        if client is not None:
            finalized_hours = fetch_finalized_hourly_buckets(client, job.subbatch)
            print(f"Finalized hourly buckets already in DB: {len(finalized_hours)}")

        result = session.scrape(job, finalized_hours=finalized_hours)

    now_et = datetime.now(ET)
    current_key = hour_bucket_key(now_et.replace(minute=0, second=0, microsecond=0))
    backfilled = [
        row.bucket_time.isoformat(sep=" ")
        for row in result.hourly
        if hour_bucket_key(row.bucket_time) != current_key
    ]
    summary = {
        "operation_date": job.operation_date.isoformat(),
        "subbatch": job.subbatch,
        "machine_id": job.machine_id,
        "hourly_rows": len(result.hourly),
        "chute_rows": len(result.chutes),
        "feed_station_rows": len(result.feed_stations),
        "scraped_at": result.scraped_at.isoformat(),
        "hourly_note": (
            "current hour updates every scrape; completed hours written once when finalized "
            "(or backfilled after an outage)"
            if result.hourly
            else "no matching hourly buckets in chart CSV"
        ),
        "hourly_backfill": backfilled,
        "hourly_sample": [
            {
                "bucket_time": row.bucket_time.isoformat(sep=" "),
                "hourly_volume": row.hourly_volume,
                "cumulative_volume": row.cumulative_volume,
            }
            for row in result.hourly[:5]
        ],
        "chute_sample": [
            {"chute_id": row.chute_id, "volume": row.volume} for row in result.chutes[:5]
        ],
    }
    print(json.dumps(summary, indent=2))

    if args.dry_run:
        print("Dry run complete — no Supabase writes.")
        return 0

    assert client is not None
    save_scrape_result(client, job, result)
    print(f"Saved scrape snapshot to Supabase (scraped_at={result.scraped_at.isoformat()}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
