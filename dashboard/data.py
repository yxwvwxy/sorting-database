"""Fetch city-level scrape series from Supabase RPCs."""

from __future__ import annotations

import os
from functools import lru_cache
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from supabase import Client, create_client

ROOT = Path(__file__).resolve().parents[1]


def _load_env() -> None:
    load_dotenv(ROOT / "local.env")
    load_dotenv(ROOT / ".env")


@lru_cache(maxsize=1)
def get_client() -> Client:
    _load_env()
    url = (os.getenv("SUPABASE_URL") or "").strip()
    key = (os.getenv("SUPABASE_SERVICE_ROLE_KEY") or "").strip()
    if not url or not key:
        raise RuntimeError("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in local.env / .env")
    return create_client(url, key)


def list_batches(limit: int = 30) -> pd.DataFrame:
    rows = get_client().rpc("list_scrape_batches", {"p_limit": limit}).execute().data or []
    df = pd.DataFrame(rows)
    if df.empty:
        return df
    for col in ("first_scraped_at", "last_scraped_at"):
        df[col] = pd.to_datetime(df[col], utc=True)
    df["subbatch_date"] = pd.to_datetime(df["subbatch_date"]).dt.date
    df["scrape_count"] = df["scrape_count"].astype(int)
    df["latest_total"] = df["latest_total"].astype(int)
    return df


def city_volume_series(subbatch: str | None = None) -> pd.DataFrame:
    payload = {"p_subbatch": subbatch} if subbatch else {}
    rows = get_client().rpc("city_volume_series", payload).execute().data or []
    df = pd.DataFrame(rows)
    if df.empty:
        return df
    df["scraped_at"] = pd.to_datetime(df["scraped_at"], utc=True)
    df["subbatch_date"] = pd.to_datetime(df["subbatch_date"]).dt.date
    df["total_volume"] = df["total_volume"].astype(int)
    df["delta_volume"] = df["delta_volume"].astype(int)
    return df


def latest_city_totals(series: pd.DataFrame) -> pd.DataFrame:
    if series.empty:
        return series
    latest_ts = series["scraped_at"].max()
    latest = series.loc[series["scraped_at"] == latest_ts].copy()
    latest = latest.sort_values("total_volume", ascending=False).reset_index(drop=True)
    return latest
