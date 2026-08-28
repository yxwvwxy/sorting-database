"""CLI entrypoint for the UniUni sorting data scraper."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone

from dotenv import load_dotenv

from .batch_resolve import resolve_job
from .config import ET, Settings, validate_supabase_settings, validate_uniuni_login_settings
from .db import (
    create_supabase_client,
    fetch_finalized_hourly_buckets,
    has_city_initials,
    has_subbatch_scrape,
    save_city_initials,
    save_scrape_result,
)
from .scraper import ScrapeResult, hour_bucket_key
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
    parser.add_argument(
        "--initials-only",
        action="store_true",
        help="Only fetch Workflow Management city initials (skip chute scrape).",
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

        already_scraped = False
        already_initials = False
        if client is not None:
            already_scraped = has_subbatch_scrape(client, job.subbatch)
            already_initials = has_city_initials(client, job.subbatch)
            print(
                f"Existing scrape for batch: {already_scraped}; "
                f"city initials saved: {already_initials}"
            )

        # First snapshot of a new ops-day batch: capture Workflow Management
        # carryover initials and skip chute/隔口 scrape (little sorter data yet).
        # --initials-only always re-fetches (demo / manual refresh) even if rows exist.
        first_ops_day_run = (not already_scraped) or args.initials_only
        need_initials = args.initials_only or (
            first_ops_day_run and not already_initials
        )
        initials_summary: dict | None = None

        if need_initials:
            print(
                "Fetching city initials from Workflow Management "
                "(skipping chute/隔口 scrape this run)."
            )
            initials = session.fetch_city_initials(job)
            initials_summary = {
                "subbatch": initials.subbatch,
                "operation_date": initials.operation_date,
                "scraped_at": initials.scraped_at.isoformat(),
                "cities": {row.city: row.initial_volume for row in initials.rows},
            }
            if not args.dry_run:
                assert client is not None
                save_city_initials(
                    client,
                    job,
                    [
                        {"city": row.city, "initial_volume": row.initial_volume}
                        for row in initials.rows
                    ],
                    scraped_at=initials.scraped_at,
                )
                print(
                    "Saved city_initial_volume for "
                    + ", ".join(
                        f"{row.city}={row.initial_volume}" for row in initials.rows
                    )
                )
            else:
                print("Dry run — city initials not written.")

            # Marker so later :10/:30/:50 runs do chute scrape (skip if batch
            # already has scrapes — e.g. --initials-only catch-up).
            if not args.dry_run and not already_scraped:
                assert client is not None
                marker = ScrapeResult(
                    scraped_at=datetime.now(timezone.utc),
                    hourly=[],
                    chutes=[],
                    feed_stations=[],
                )
                save_scrape_result(client, job, marker)
                print(
                    "Saved empty scrape marker (no chute rows) so later runs "
                    "will scrape Sorting Production Analysis."
                )

            summary = {
                "operation_date": job.operation_date.isoformat(),
                "subbatch": job.subbatch,
                "machine_id": job.machine_id,
                "mode": "city_initials_first_run",
                "hourly_rows": 0,
                "chute_rows": 0,
                "feed_station_rows": 0,
                "city_initials": initials_summary,
                "note": (
                    "Skipped chute/隔口 scrape on first ops-day run. "
                    "City totals = initial + later chute volumes "
                    "(RIC/ALB/SWF/SYR/PVD2; BOS Warehouse → PVD2)."
                ),
            }
            print(json.dumps(summary, indent=2))
            return 0

        if (not already_initials) and already_scraped:
            # Mid-day catch-up: batch already has chute scrapes but initials missing
            print(
                "City initials missing for an already-scraped batch — "
                "fetching Workflow Management initials before chute scrape."
            )
            try:
                initials = session.fetch_city_initials(job)
                initials_summary = {
                    "subbatch": initials.subbatch,
                    "operation_date": initials.operation_date,
                    "scraped_at": initials.scraped_at.isoformat(),
                    "cities": {
                        row.city: row.initial_volume for row in initials.rows
                    },
                }
                if not args.dry_run:
                    assert client is not None
                    save_city_initials(
                        client,
                        job,
                        [
                            {
                                "city": row.city,
                                "initial_volume": row.initial_volume,
                            }
                            for row in initials.rows
                        ],
                        scraped_at=initials.scraped_at,
                    )
                    print("Saved catch-up city_initial_volume rows.")
            except Exception as err:
                print(
                    f"WARNING: could not fetch city initials ({err}); "
                    "continuing scrape."
                )

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
        "mode": "chute_scrape",
        "hourly_rows": len(result.hourly),
        "chute_rows": len(result.chutes),
        "feed_station_rows": len(result.feed_stations),
        "scraped_at": result.scraped_at.isoformat(),
        "city_initials": initials_summary,
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
        print("Dry run complete - no Supabase writes.")
        return 0

    assert client is not None
    save_scrape_result(client, job, result)
    print(f"Saved scrape snapshot to Supabase (scraped_at={result.scraped_at.isoformat()}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
