"""Playwright scraper for the UniUni production analytics Streamlit app."""

from __future__ import annotations

import base64
import csv
import io
import re
from dataclasses import dataclass, field
from datetime import datetime

from playwright.sync_api import Page, sync_playwright

from .config import Settings, SubbatchJob

DOWNLOAD_LINK_TEXT = "下载图表数据"
FEED_STATION_ORDER = [
    "上层供包台1",
    "上层供包台2",
    "上层供包台3",
    "上层供包台4",
    "上层供包台5",
    "下层供包台1",
    "下层供包台2",
    "下层供包台3",
    "下层供包台4",
    "下层供包台5",
]


@dataclass(frozen=True)
class HourlyRow:
    timestamp: datetime
    hour: int
    hourly_volume: int
    cumulative_volume: int


@dataclass(frozen=True)
class ChuteRow:
    chute_id: int
    volume: int
    lane_id: str | None = None


@dataclass(frozen=True)
class FeedStationRow:
    station_id: int
    volume: int
    growth_rate: float | None = None


@dataclass
class ScrapeResult:
    hourly: list[HourlyRow] = field(default_factory=list)
    chutes: list[ChuteRow] = field(default_factory=list)
    feed_stations: list[FeedStationRow] = field(default_factory=list)
    captured_at: datetime = field(default_factory=datetime.utcnow)


def _login(page: Page, settings: Settings) -> None:
    page.goto(settings.uniuni_url, wait_until="networkidle", timeout=120_000)
    page.get_by_role("textbox", name="Username").fill(settings.uniuni_username)
    page.get_by_role("textbox", name="Password").fill(settings.uniuni_password)
    page.get_by_role("button", name="Login").click()
    page.get_by_role("button", name="Logout").wait_for(timeout=60_000)


def _submit_query(page: Page, job: SubbatchJob) -> None:
    page.get_by_role("textbox", name=re.compile("批次号")).fill(job.subbatch)
    page.get_by_role("textbox", name=re.compile("机器编号")).fill(str(job.machine_id))
    page.get_by_role("button", name="查询日志", exact=True).click()
    page.get_by_role("link", name=DOWNLOAD_LINK_TEXT).wait_for(timeout=120_000)


def _parse_hourly_csv(href: str) -> list[HourlyRow]:
    if not href.startswith("data:file/csv;base64,"):
        raise RuntimeError("Unexpected hourly download link format.")

    raw = base64.b64decode(href.split(",", 1)[1]).decode("utf-8-sig")
    reader = csv.reader(io.StringIO(raw))
    rows = list(reader)
    if len(rows) < 2:
        raise RuntimeError("Hourly CSV download was empty.")

    hourly: list[HourlyRow] = []
    for line in rows[1:]:
        if len(line) < 3:
            continue
        timestamp = datetime.strptime(line[0].strip(), "%Y-%m-%d %H:%M:%S")
        hourly.append(
            HourlyRow(
                timestamp=timestamp,
                hour=timestamp.hour,
                hourly_volume=int(line[1]),
                cumulative_volume=int(line[2]),
            )
        )
    if not hourly:
        raise RuntimeError("No hourly rows parsed from CSV.")
    return hourly


def _parse_chutes(page: Page) -> list[ChuteRow]:
    raw = page.evaluate(
        """() => [...document.querySelectorAll('.slot-container')].map(slot => ({
            chute_id: Number(slot.querySelector('.slot-number')?.textContent?.trim() || 0),
            volume: Number(slot.querySelector('.tooltiptext')?.textContent?.trim() || 0),
        }))"""
    )
    chutes = [ChuteRow(chute_id=int(row["chute_id"]), volume=int(row["volume"])) for row in raw if row["chute_id"]]
    if not chutes:
        raise RuntimeError("No chute data found on page.")
    return chutes


def _parse_feed_stations(page: Page) -> list[FeedStationRow]:
    metrics = page.locator('[data-testid="stMetric"]')
    label_to_volume: dict[str, int] = {}
    for metric in metrics.all():
        label = metric.locator('[data-testid="stMetricLabel"]').inner_text(timeout=5_000).strip()
        value = metric.locator('[data-testid="stMetricValue"]').inner_text(timeout=5_000).strip()
        if label not in FEED_STATION_ORDER:
            continue
        digits = re.sub(r"[^\d]", "", value)
        label_to_volume[label] = int(digits) if digits else 0

    rows: list[FeedStationRow] = []
    for idx, label in enumerate(FEED_STATION_ORDER, start=1):
        if label in label_to_volume:
            rows.append(FeedStationRow(station_id=idx, volume=label_to_volume[label]))
    return rows


def scrape_job(settings: Settings, job: SubbatchJob, *, headless: bool = True) -> ScrapeResult:
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=headless)
        page = browser.new_page()
        try:
            _login(page, settings)
            _submit_query(page, job)

            download_href = page.get_by_role("link", name=DOWNLOAD_LINK_TEXT).get_attribute("href")
            if not download_href:
                raise RuntimeError("Hourly download link missing href.")

            result = ScrapeResult(
                hourly=_parse_hourly_csv(download_href),
                chutes=_parse_chutes(page),
                feed_stations=_parse_feed_stations(page),
                captured_at=datetime.utcnow(),
            )
            return result
        finally:
            browser.close()
