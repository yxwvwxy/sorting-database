"""Write scraped data to Supabase."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from supabase import Client, create_client

from .config import Settings, SubbatchJob
from .scraper import ScrapeResult


def create_supabase_client(settings: Settings) -> Client:
    return create_client(settings.supabase_url, settings.supabase_service_role_key)


def upsert_subbatch(client: Client, job: SubbatchJob) -> None:
    """Record the operation-day batch from Google Sheets in Supabase."""
    client.table("subbatch").upsert(
        {
            "subbatch": job.subbatch,
            "machine_id": job.machine_id,
            "subbatch_date": job.operation_date.isoformat(),
        }
    ).execute()


def _as_utc_iso(value: datetime) -> str:
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    else:
        value = value.astimezone(timezone.utc)
    return value.isoformat()


def mark_subbatch_scraped(client: Client, job: SubbatchJob, scraped_at: datetime) -> None:
    """Set scraped_at after 8203 data is fully persisted."""
    client.table("subbatch").update({"scraped_at": _as_utc_iso(scraped_at)}).eq(
        "subbatch", job.subbatch
    ).execute()


def save_scrape_result(
    client: Client,
    job: SubbatchJob,
    result: ScrapeResult,
) -> None:
    hourly_rows: list[dict[str, Any]] = []
    for row in result.hourly:
        hourly_rows.append(
            {
                "subbatch_id": job.subbatch,
                "bucket_time": row.bucket_time.isoformat(sep=" "),
                "hourly_volume": row.hourly_volume,
                "cumulative_volume": row.cumulative_volume,
            }
        )
    if hourly_rows:
        client.table("hourly_throughput").upsert(hourly_rows).execute()

    chute_rows = [
        {
            "subbatch_id": job.subbatch,
            "chute_id": row.chute_id,
            "volume": row.volume,
        }
        for row in result.chutes
    ]
    if chute_rows:
        client.table("chute_volume").upsert(chute_rows).execute()

    feed_rows = [
        {
            "subbatch_id": job.subbatch,
            "station_id": row.station_id,
            "volume": row.volume,
        }
        for row in result.feed_stations
    ]
    if feed_rows:
        client.table("feed_station").upsert(feed_rows).execute()

    mark_subbatch_scraped(client, job, result.scraped_at)
