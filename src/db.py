"""Write scraped data to Supabase."""

from __future__ import annotations

import re
from datetime import datetime, timedelta, timezone
from typing import Any

from supabase import Client, create_client

from .config import ET, Settings, SubbatchJob
from .scraper import ScrapeResult, hour_bucket_key


def create_supabase_client(settings: Settings) -> Client:
    return create_client(settings.supabase_url, settings.supabase_service_role_key)


def _as_utc_iso(value: datetime) -> str:
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    else:
        value = value.astimezone(timezone.utc)
    return value.isoformat()


def _parse_db_timestamp(value: str | datetime) -> datetime:
    if isinstance(value, datetime):
        return value
    text = str(value).strip().replace("Z", "+00:00")
    # Postgres may emit 1–6 fractional digits; Python 3.9 fromisoformat is picky.
    try:
        return datetime.fromisoformat(text)
    except ValueError:
        pass
    match = re.fullmatch(
        r"(\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2})(\.\d+)?([+-]\d{2}:\d{2})?",
        text,
    )
    if not match:
        raise ValueError(f"Unrecognized timestamp: {value!r}")
    base, frac, offset = match.group(1), match.group(2) or "", match.group(3) or ""
    if frac:
        digits = frac[1:][:6].ljust(6, "0")
        frac = f".{digits}"
    normalized = f"{base.replace(' ', 'T')}{frac}{offset}"
    return datetime.fromisoformat(normalized)


def fetch_finalized_hourly_buckets(client: Client, subbatch: str) -> set[tuple[int, int, int, int]]:
    """Hours that already have a capture taken after that clock hour closed (ET).

    Used so a resumed scrape only backfills completed hours that were missed
    during an outage, instead of rewriting every frozen hour every run.
    """
    response = (
        client.table("hourly_throughput")
        .select("bucket_time, scraped_at")
        .eq("subbatch_id", subbatch)
        .limit(10000)
        .execute()
    )
    finalized: set[tuple[int, int, int, int]] = set()
    for row in response.data or []:
        bucket = _parse_db_timestamp(row["bucket_time"])
        if bucket.tzinfo is not None:
            bucket = bucket.astimezone(ET).replace(tzinfo=None)
        scraped_at = _parse_db_timestamp(row["scraped_at"])
        if scraped_at.tzinfo is None:
            scraped_at = scraped_at.replace(tzinfo=timezone.utc)
        else:
            scraped_at = scraped_at.astimezone(timezone.utc)
        hour_end_utc = (bucket.replace(tzinfo=ET) + timedelta(hours=1)).astimezone(timezone.utc)
        if scraped_at >= hour_end_utc:
            finalized.add(hour_bucket_key(bucket))
    return finalized


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


def has_subbatch_scrape(client: Client, subbatch: str) -> bool:
    """True when at least one scrape snapshot exists for this subbatch."""
    response = (
        client.table("subbatch")
        .select("subbatch")
        .eq("subbatch", subbatch)
        .limit(1)
        .execute()
    )
    return bool(response.data)


def has_city_initials(client: Client, subbatch: str) -> bool:
    """True when Workflow Management initials were already saved for this batch."""
    response = (
        client.table("city_initial_volume")
        .select("city")
        .eq("subbatch_id", subbatch)
        .limit(1)
        .execute()
    )
    return bool(response.data)


def save_city_initials(
    client: Client,
    job: SubbatchJob,
    rows: list[dict[str, Any]],
    *,
    scraped_at: datetime | None = None,
    source: str = "workflow_management",
) -> None:
    """Upsert RIC/ALB/SWF/SYR/PVD2 initial volumes for an ops-day batch."""
    stamp = _as_utc_iso(scraped_at or datetime.now(timezone.utc))
    payload = [
        {
            "subbatch_id": job.subbatch,
            "operation_date": job.operation_date.isoformat(),
            "city": row["city"],
            "initial_volume": int(row["initial_volume"]),
            "scraped_at": stamp,
            "source": source,
        }
        for row in rows
    ]
    (
        client.table("city_initial_volume")
        .upsert(payload, on_conflict="subbatch_id,city")
        .execute()
    )
