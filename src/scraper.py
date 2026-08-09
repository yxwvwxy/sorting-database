"""Playwright scraper for UniMap sorting production analysis."""

from __future__ import annotations

import csv
import io
import re
from dataclasses import dataclass, field
from datetime import date, datetime, timezone

from playwright.sync_api import Download, Frame, Page

from .config import Settings, SubbatchJob

ANALYSIS_URL = "https://dispatch.uniuni.com/sorting-production-analysis"
QUERY_LOG_PATTERN = re.compile(r"^query log$", re.I)
DOWNLOAD_CHART_PATTERN = re.compile(r"download chart data", re.I)
FEED_STATION_ORDER = [
    "Upper station 1",
    "Upper station 2",
    "Upper station 3",
    "Upper station 4",
    "Upper station 5",
    "Lower station 1",
    "Lower station 2",
    "Lower station 3",
    "Lower station 4",
    "Lower station 5",
]


@dataclass(frozen=True)
class HourlyRow:
    bucket_time: datetime
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


@dataclass
class ScrapeResult:
    hourly: list[HourlyRow] = field(default_factory=list)
    chutes: list[ChuteRow] = field(default_factory=list)
    feed_stations: list[FeedStationRow] = field(default_factory=list)
    scraped_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))


def _has_query_log_button(target: Page | Frame) -> bool:
    query_button = target.locator("button").filter(has_text=QUERY_LOG_PATTERN)
    if query_button.count() > 0:
        return True
    return target.get_by_role("button", name=re.compile(r"查询日志|query log", re.I)).count() > 0


def _analysis_target(page: Page) -> Page | Frame:
    """Return the Sorting Production Analysis Streamlit frame when present."""
    candidates = [
        frame
        for frame in page.frames
        if re.search(r"8203|streamlit", frame.url, re.I)
    ]
    for frame in candidates:
        if _has_query_log_button(frame):
            return frame
    if candidates:
        return candidates[0]
    return page


def _is_login_page(page: Page) -> bool:
    if "/login" in page.url:
        return True
    if page.locator('[data-testid="login-microsoft-sso-button"]').count() > 0:
        return True
    username = page.get_by_role("textbox", name=re.compile(r"username", re.I))
    return username.count() > 0 and username.first.is_visible()


def _dismiss_portal_dialogs(page: Page) -> None:
    """Close UniMap release-note dialogs that block clicks."""
    page.evaluate(
        """() => {
          for (const button of document.querySelectorAll('button')) {
            if (/got it/i.test(button.innerText)) {
              button.click();
              return;
            }
          }
        }"""
    )
    page.wait_for_timeout(500)


def _mgmt_tab_present(page: Page) -> bool:
    """True when the UniMap shell shows the Mgmt tab (real logged-in main UI)."""
    try:
        return bool(
            page.evaluate(
                """() => [...document.querySelectorAll('[role=tab]')]
                  .some(e => /^\\s*Mgmt\\.?\\s*$/i.test((e.innerText || '').trim()))"""
            )
        )
    except Exception:
        return False


def _portal_logged_in(page: Page) -> bool:
    if _is_login_page(page) or _login_form_visible(page):
        return False
    # Prefer concrete UI signals over URL alone — stale cookies can land on /main
    # without a usable session.
    if _mgmt_tab_present(page):
        return True
    if _analysis_ready(page):
        return True
    return False


def _login_error_message(page: Page) -> str | None:
    body = page.locator("body").inner_text(timeout=5_000)
    if re.search(r"login failed", body, re.I):
        return "UniUni rejected the username/password (Login failed!)."
    return None


def _login_inputs(page: Page):
    username = page.locator('[data-testid="login-username-input"]').first
    if username.count() == 0 or not username.is_visible():
        username = page.locator(
            'input[name="username"], input[autocomplete="username"], input[type="text"]'
        ).first
    if username.count() == 0 or not username.is_visible():
        username = page.get_by_role("textbox", name=re.compile(r"username", re.I)).first

    password = page.locator('[data-testid="login-password-input"]').first
    if password.count() == 0 or not password.is_visible():
        password = page.locator('input[name="password"], input[type="password"]').first
    if password.count() == 0 or not password.is_visible():
        password = page.get_by_role("textbox", name=re.compile(r"password", re.I)).first

    submit = page.locator('[data-testid="login-submit-button"]').first
    if submit.count() == 0 or not submit.is_visible():
        submit = page.get_by_role(
            "button", name=re.compile(r"^(login|log\s*in|sign\s*in)$", re.I)
        ).first
    if submit.count() == 0 or not submit.is_visible():
        submit = page.locator('button[type="submit"]').first

    return username, password, submit


def _fill_and_submit_login(page: Page, settings: Settings) -> bool:
    """Fill username/password on the full-page login or any re-auth modal. Returns True if submitted."""
    _dismiss_portal_dialogs(page)
    username_input, password_input, login_button = _login_inputs(page)
    if username_input.count() == 0 or password_input.count() == 0 or login_button.count() == 0:
        return False
    if not password_input.is_visible():
        return False

    print(f"Filling UniMap login for user {settings.uniuni_username!r}...")
    username_input.click(force=True)
    username_input.fill("")
    username_input.fill(settings.uniuni_username)
    password_input.click(force=True)
    password_input.fill("")
    password_input.fill(settings.uniuni_password)
    # Ensure React/MUI controlled inputs see the values.
    page.evaluate(
        """([user, pass]) => {
          const u = document.querySelector('[data-testid="login-username-input"]');
          const p = document.querySelector('[data-testid="login-password-input"]');
          if (u) {
            const proto = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value');
            proto.set.call(u, user);
            u.dispatchEvent(new Event('input', { bubbles: true }));
            u.dispatchEvent(new Event('change', { bubbles: true }));
          }
          if (p) {
            const proto = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value');
            proto.set.call(p, pass);
            p.dispatchEvent(new Event('input', { bubbles: true }));
            p.dispatchEvent(new Event('change', { bubbles: true }));
          }
        }""",
        [settings.uniuni_username, settings.uniuni_password],
    )
    login_button.click(force=True)
    return True


def _login_form_visible(page: Page) -> bool:
    password = page.locator('[data-testid="login-password-input"], input[type="password"]')
    return password.count() > 0 and password.first.is_visible()


def _login_with_credentials(page: Page, settings: Settings) -> None:
    """Username/password login for full-page /login or re-auth modal on /main."""
    _dismiss_portal_dialogs(page)

    if _portal_logged_in(page) and not _login_form_visible(page):
        return

    last_error = "UniMap login did not complete."
    for attempt in range(1, 4):
        if not _login_form_visible(page):
            # Stale cookies often bounce /login -> /main without a usable session.
            if attempt > 1 or "dispatch.uniuni.com" in (page.url or ""):
                try:
                    page.context.clear_cookies()
                except Exception:
                    pass
                page.goto("about:blank", wait_until="domcontentloaded", timeout=15_000)
            page.goto(settings.uniuni_portal_url, wait_until="domcontentloaded", timeout=60_000)
            _dismiss_portal_dialogs(page)
            try:
                page.wait_for_selector(
                    '[data-testid="login-password-input"], input[type="password"]',
                    timeout=30_000,
                )
            except Exception:
                last_error = (
                    "UniMap username/password login form not found. "
                    f"Current url={page.url!r}."
                )
                page.wait_for_timeout(2_000)
                continue

        print(f"UniMap password login attempt {attempt}/3...")
        if not _fill_and_submit_login(page, settings):
            last_error = (
                "UniMap username/password login form not found. "
                f"Current url={page.url!r}."
            )
            page.wait_for_timeout(2_000)
            continue

        try:
            page.wait_for_url(
                re.compile(r"dispatch\.uniuni\.com/(main|sorting-production-analysis)"),
                timeout=30_000,
            )
        except Exception:
            pass

        page.wait_for_timeout(2_000)
        _dismiss_portal_dialogs(page)
        # Wait briefly for the shell tabs to render after login.
        for _ in range(20):
            if _portal_logged_in(page) and not _login_form_visible(page):
                print("UniMap login succeeded.")
                return
            page.wait_for_timeout(500)

        login_error = _login_error_message(page)
        last_error = login_error or (
            "UniMap login finished without a usable session "
            f"(url={page.url!r})."
        )
        if login_error:
            break
        if attempt < 3:
            page.wait_for_timeout(3_000)

    raise RuntimeError(
        f"{last_error} Check UNIUNI_USERNAME and UNIUNI_PASSWORD "
        "(GitHub Actions secrets or local .env)."
    )


def _analysis_ready(page: Page) -> bool:
    # Require Sorting Production Analysis URL so Slot Assignment Streamlit
    # (also often on :8203) is not mistaken for the analysis page.
    if "sorting-production-analysis" not in page.url:
        return False
    target = _analysis_target(page)
    if not _has_query_log_button(target):
        return False
    if target.locator("input").count() >= 2:
        return True
    return target.get_by_role("textbox", name=re.compile(r"批次号|batch numbers", re.I)).count() > 0


def _open_sorting_production_analysis(page: Page) -> None:
    if _analysis_ready(page):
        _dismiss_portal_dialogs(page)
        return

    page.goto(ANALYSIS_URL, wait_until="domcontentloaded", timeout=60_000)
    _dismiss_portal_dialogs(page)
    page.locator("input").first.wait_for(state="visible", timeout=60_000)


def _ensure_logged_in_and_open_analysis(page: Page, settings: Settings) -> None:
    """Open Sorting Production Analysis; login only if the nj600 session expired."""
    if _analysis_ready(page) and not _login_form_visible(page) and not _is_login_page(page):
        _dismiss_portal_dialogs(page)
        return

    page.goto(ANALYSIS_URL, wait_until="domcontentloaded", timeout=60_000)
    _dismiss_portal_dialogs(page)

    for _ in range(20):
        if not _is_login_page(page) and not _login_form_visible(page):
            break
        page.wait_for_timeout(500)

    if _is_login_page(page) or _login_form_visible(page):
        print("UniMap session missing/expired - logging in with .env credentials...")
        _login_with_credentials(page, settings)
        page.goto(ANALYSIS_URL, wait_until="domcontentloaded", timeout=60_000)
        _dismiss_portal_dialogs(page)
    else:
        print("Already logged in as nj600 session - opening Sorting Production Analysis.")

    if _is_login_page(page) or _login_form_visible(page):
        raise RuntimeError(
            "UniMap login did not complete. "
            f"Current url={page.url!r}. "
            "Re-run with --headed to verify UNIUNI_USERNAME and UNIUNI_PASSWORD."
        )

    # Wait for the Streamlit analysis UI (not just any stray input).
    page.locator("input").first.wait_for(state="visible", timeout=60_000)
    target = _analysis_target(page)
    deadline = 60_000
    elapsed = 0
    while elapsed < deadline:
        if _has_query_log_button(target):
            return
        page.wait_for_timeout(500)
        elapsed += 500
        target = _analysis_target(page)

    raise RuntimeError(
        "Query log button not found after opening Sorting Production Analysis. "
        f"url={page.url!r} frames={[f.url for f in page.frames]!r}"
    )


def _fill_analysis_inputs(target: Page | Frame, job: SubbatchJob) -> None:
    batch_input = target.get_by_role("textbox", name=re.compile(r"批次号|batch numbers", re.I))
    machine_input = target.get_by_role("textbox", name=re.compile(r"机器编号|machine numbers", re.I))
    if batch_input.count() and machine_input.count():
        batch_input.first.fill(job.subbatch)
        machine_input.first.fill(str(job.machine_id))
        return

    inputs = target.locator("input")
    if inputs.count() < 2:
        raise RuntimeError("Batch and machine inputs not found on Sorting Production Analysis page.")
    inputs.nth(0).fill(job.subbatch)
    inputs.nth(1).fill(str(job.machine_id))


def _click_query_log(target: Page | Frame, page: Page) -> None:
    if not _has_query_log_button(target):
        raise RuntimeError("Query log button not found on Sorting Production Analysis page.")

    query_button = target.locator("button").filter(has_text=QUERY_LOG_PATTERN)
    if query_button.count() == 0:
        query_button = target.get_by_role("button", name=re.compile(r"查询日志|query log", re.I))

    _dismiss_portal_dialogs(page)
    query_button.first.click(force=True)


def _submit_query(page: Page, job: SubbatchJob) -> Page | Frame:
    target = _analysis_target(page)
    _fill_analysis_inputs(target, job)
    _click_query_log(target, page)
    page.get_by_text(re.compile(r"download chart data|下载图表数据", re.I)).wait_for(timeout=120_000)
    return target


def _parse_hourly_timestamp(raw: str, reference_year: int) -> datetime:
    value = raw.strip()
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M"):
        try:
            return datetime.strptime(value, fmt)
        except ValueError:
            continue
    return datetime.strptime(f"{reference_year}-{value}", "%Y-%m-%d %H:%M")


def _parse_hourly_csv_text(raw: str, operation_date: date) -> list[HourlyRow]:
    reader = csv.reader(io.StringIO(raw))
    rows = list(reader)
    if len(rows) < 2:
        raise RuntimeError("Hourly CSV download was empty.")

    hourly: list[HourlyRow] = []
    for line in rows[1:]:
        if len(line) < 3:
            continue
        timestamp = _parse_hourly_timestamp(line[0], operation_date.year)
        hourly.append(
            HourlyRow(
                bucket_time=timestamp,
                hourly_volume=int(line[1]),
                cumulative_volume=int(line[2]),
            )
        )
    if not hourly:
        raise RuntimeError("No hourly rows parsed from CSV.")
    return hourly


def _download_hourly_csv(page: Page, operation_date: date) -> list[HourlyRow]:
    download_button = page.locator("button").filter(has_text=DOWNLOAD_CHART_PATTERN)
    if download_button.count() == 0:
        download_link = page.get_by_role("link", name=re.compile(r"下载图表数据|download chart data", re.I))
        href = download_link.get_attribute("href") if download_link.count() else None
        if href and href.startswith("data:"):
            import base64

            csv_text = base64.b64decode(href.split(",", 1)[1]).decode("utf-8-sig")
            return _parse_hourly_csv_text(csv_text, operation_date)
        raise RuntimeError("Download chart data control not found.")

    _dismiss_portal_dialogs(page)
    with page.expect_download(timeout=60_000) as download_info:
        download_button.first.click(force=True)
    download: Download = download_info.value
    csv_text = open(download.path(), encoding="utf-8-sig").read()
    return _parse_hourly_csv_text(csv_text, operation_date)


def _parse_chutes(target: Page | Frame) -> list[ChuteRow]:
    raw = target.evaluate(
        """() => {
          const modern = [];
          for (const el of document.querySelectorAll('div[title]')) {
            const chuteText = el.textContent.trim();
            const volText = el.getAttribute('title');
            if (!/^\\d+$/.test(chuteText) || !/^\\d+$/.test(volText)) continue;
            const chute_id = Number(chuteText);
            const volume = Number(volText);
            if (chute_id >= 100 && chute_id <= 1100) modern.push({ chute_id, volume });
          }
          if (modern.length) return modern;

          return [...document.querySelectorAll('.slot-container')].map(slot => ({
            chute_id: Number(slot.querySelector('.slot-number')?.textContent?.trim() || 0),
            volume: Number(slot.querySelector('.tooltiptext')?.textContent?.trim() || 0),
          }));
        }"""
    )
    chutes = [ChuteRow(chute_id=int(row["chute_id"]), volume=int(row["volume"])) for row in raw if row["chute_id"]]
    if not chutes:
        raise RuntimeError("No chute data found on page.")
    return chutes


def _parse_feed_stations(target: Page | Frame) -> list[FeedStationRow]:
    metrics = target.locator('[data-testid="stMetric"]')
    label_to_volume: dict[str, int] = {}
    if metrics.count():
        for metric in metrics.all():
            label = metric.locator('[data-testid="stMetricLabel"]').inner_text(timeout=5_000).strip()
            value = metric.locator('[data-testid="stMetricValue"]').inner_text(timeout=5_000).strip()
            if label not in FEED_STATION_ORDER:
                continue
            digits = re.sub(r"[^\d]", "", value)
            label_to_volume[label] = int(digits) if digits else 0
    else:
        parts = [line.strip() for line in target.locator("body").inner_text(timeout=10_000).splitlines()]
        for idx, label in enumerate(FEED_STATION_ORDER):
            key = label.lower()
            for pos, part in enumerate(parts):
                if part.lower() != key:
                    continue
                volume_line = parts[pos + 1] if pos + 1 < len(parts) else ""
                digits = re.sub(r"[^\d]", "", volume_line)
                if digits:
                    label_to_volume[label] = int(digits)
                break

    rows: list[FeedStationRow] = []
    for idx, label in enumerate(FEED_STATION_ORDER, start=1):
        if label in label_to_volume:
            rows.append(FeedStationRow(station_id=idx, volume=label_to_volume[label]))
    return rows


def _launch_browser(playwright, *, headless: bool):
    launch_kwargs: dict[str, object] = {"headless": headless}
    if not headless:
        launch_kwargs["slow_mo"] = 800
        try:
            return playwright.chromium.launch(channel="chrome", **launch_kwargs)
        except Exception:
            return playwright.chromium.launch(**launch_kwargs)
    return playwright.chromium.launch(**launch_kwargs)


def scrape_on_page(page: Page, settings: Settings, job: SubbatchJob) -> ScrapeResult:
    """Query Sorting Production Analysis on an already-open UniMap page."""
    _ensure_logged_in_and_open_analysis(page, settings)
    target = _submit_query(page, job)
    return ScrapeResult(
        hourly=_download_hourly_csv(page, job.operation_date),
        chutes=_parse_chutes(target),
        feed_stations=_parse_feed_stations(target),
        scraped_at=datetime.now(timezone.utc),
    )


def scrape_job(settings: Settings, job: SubbatchJob, *, headless: bool = True) -> ScrapeResult:
    """Standalone scrape (own browser). Prefer open_uniuni_session in normal runs."""
    from .session import open_uniuni_session

    with open_uniuni_session(settings, headless=headless) as session:
        return session.scrape(job)
