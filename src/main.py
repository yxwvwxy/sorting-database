"""CLI entrypoint for the UniUni sorting data scraper."""

from __future__ import annotations

import argparse
import json
import sys

from dotenv import load_dotenv

from .config import Settings, operation_date_et, validate_supabase_settings
from .db import create_supabase_client, save_scrape_result, upsert_subbatch
from .scraper import scrape_job
from .sheets import resolve_job


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
        help="Override subbatch (skips Google Sheet lookup).",
    )
    parser.add_argument(
        "--machine-id",
        type=int,
        help="Override machine id (default 9).",
    )
    args = parser.parse_args(argv)

    load_dotenv("local.env")
    load_dotenv(".env")
    settings = Settings.from_env()
    operation_date = operation_date_et()
    job = resolve_job(
        settings,
        operation_date,
        subbatch_override=args.subbatch,
        machine_id_override=args.machine_id,
    )

    print(f"Operation date: {job.operation_date}")
    print(f"Subbatch: {job.subbatch} | Machine: {job.machine_id}")

    client = None
    if not args.dry_run:
        validate_supabase_settings(settings)
        client = create_supabase_client(settings)
        upsert_subbatch(client, job)
        print(
            f"Saved subbatch to Supabase: {job.subbatch} "
            f"(operation date {job.operation_date}, machine {job.machine_id})."
        )

    result = scrape_job(settings, job, headless=not args.headed)

    summary = {
        "operation_date": job.operation_date.isoformat(),
        "subbatch": job.subbatch,
        "machine_id": job.machine_id,
        "hourly_rows": len(result.hourly),
        "chute_rows": len(result.chutes),
        "feed_station_rows": len(result.feed_stations),
        "scraped_at": result.scraped_at.isoformat(),
        "hourly_sample": [
            {
                "bucket_time": row.bucket_time.isoformat(sep=" "),
                "hourly_volume": row.hourly_volume,
                "cumulative_volume": row.cumulative_volume,
            }
            for row in result.hourly[:3]
        ],
        "chute_sample": [
            {"chute_id": row.chute_id, "volume": row.volume} for row in result.chutes[:5]
        ],
    }
    print(json.dumps(summary, indent=2))

    if args.dry_run:
        print("Dry run complete — no Supabase writes.")
        return 0

    save_scrape_result(client, job, result)
    print(f"Saved scrape result to Supabase (scraped_at={result.scraped_at.isoformat()}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
