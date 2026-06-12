"""Write scraped data to Supabase."""

from __future__ import annotations

from datetime import datetime
from typing import Any

from supabase import Client, create_client

from .config import Settings, SubbatchJob
from .scraper import FeedStationRow, HourlyRow, ScrapeResult


def create_supabase_client(settings: Settings) -> Client:
    return create_client(settings.supabase_url, settings.supabase_service_role_key)


def save_scrape_result(
    client: Client,
    job: SubbatchJob,
    result: ScrapeResult,
    *,
    capture_time: datetime | None = None,
) -> None:
    captured = capture_time or result.captured_at

    client.table("subbatch").upsert(
        {
            "subbatch": job.subbatch,
            "machine_id": job.machine_id,
            "subbatch_date": job.operation_date.isoformat(),
        }
    ).execute()

    hourly_rows: list[dict[str, Any]] = []
    for row in result.hourly:
        hourly_rows.append(
            {
                "subbatch_id": job.subbatch,
                "hour": row.hour,
                "hourly_volume": row.hourly_volume,
                "cumulative_volume": row.cumulative_volume,
                "capture_time": captured.isoformat(sep=" "),
            }
        )
    if hourly_rows:
        client.table("hourly_throughput").upsert(hourly_rows).execute()

    chute_rows = [
        {
            "subbatch_id": job.subbatch,
            "capture_time": captured.isoformat(sep=" "),
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
            "growth_rate": row.growth_rate,
            "capture_time": captured.isoformat(sep=" "),
        }
        for row in result.feed_stations
    ]
    if feed_rows:
        client.table("feed_station").upsert(feed_rows).execute()
