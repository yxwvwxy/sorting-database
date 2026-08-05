"""Write scraped data to Supabase."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from supabase import Client, create_client

from .config import Settings, SubbatchJob
from .scraper import ScrapeResult


def create_supabase_client(settings: Settings) -> Client:
    return create_client(settings.supabase_url, settings.supabase_service_role_key)


def _as_utc_iso(value: datetime) -> str:
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    else:
        value = value.astimezone(timezone.utc)
    return value.isoformat()


def save_scrape_result(
    client: Client,
    job: SubbatchJob,
    result: ScrapeResult,
) -> None:
    """Insert one full scrape snapshot (subbatch + detail tables) atomically."""
    scraped_at = _as_utc_iso(result.scraped_at)

    hourly_rows: list[dict[str, Any]] = [
        {
            "bucket_time": row.bucket_time.isoformat(sep=" "),
            "hourly_volume": row.hourly_volume,
            "cumulative_volume": row.cumulative_volume,
        }
        for row in result.hourly
    ]
    chute_rows: list[dict[str, Any]] = [
        {"chute_id": row.chute_id, "volume": row.volume} for row in result.chutes
    ]
    feed_rows: list[dict[str, Any]] = [
        {"station_id": row.station_id, "volume": row.volume} for row in result.feed_stations
    ]

    client.rpc(
        "save_scrape_snapshot",
        {
            "p_subbatch": job.subbatch,
            "p_machine_id": job.machine_id,
            "p_subbatch_date": job.operation_date.isoformat(),
            "p_scraped_at": scraped_at,
            "p_hourly": hourly_rows,
            "p_chutes": chute_rows,
            "p_feeds": feed_rows,
        },
    ).execute()
