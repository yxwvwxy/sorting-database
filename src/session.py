"""One UniMap browser session per scrape run.

Login only when the saved nj600 session is missing/expired. When Slot Assignment
is needed, stay in the same browser and navigate to Sorting Production Analysis
instead of closing and logging in again.
"""

from __future__ import annotations

import os
from contextlib import contextmanager
from dataclasses import dataclass
from typing import Iterator

from playwright.sync_api import Browser, BrowserContext, Page, sync_playwright

from .config import Settings, SubbatchJob
from .scraper import ScrapeResult, _launch_browser, scrape_on_page


@dataclass
class UniUniSession:
    settings: Settings
    page: Page
    context: BrowserContext
    browser: Browser

    def fetch_batch(self, machine_id: int = 9) -> SubbatchJob:
        from .slot_assignment import fetch_batch_on_page

        job, self.page = fetch_batch_on_page(
            self.page,
            self.settings,
            machine_id=machine_id,
        )
        return job

    def scrape(self, job: SubbatchJob) -> ScrapeResult:
        return scrape_on_page(self.page, self.settings, job)


@contextmanager
def open_uniuni_session(
    settings: Settings,
    *,
    headless: bool = True,
) -> Iterator[UniUniSession]:
    state_path = settings.uniuni_auth_state_path
    with sync_playwright() as playwright:
        browser = _launch_browser(playwright, headless=headless)
        context_kwargs: dict[str, object] = {"accept_downloads": True}
        if state_path and os.path.exists(state_path):
            context_kwargs["storage_state"] = state_path
            print(f"Reusing saved UniMap session from {state_path}")
        else:
            print("No saved UniMap session - will login if the portal asks.")

        context = browser.new_context(**context_kwargs)
        page = context.new_page()
        session = UniUniSession(
            settings=settings,
            page=page,
            context=context,
            browser=browser,
        )
        try:
            yield session
        finally:
            # Only persist a usable session — failed logins used to overwrite
            # good cookies with a half-logged-in /main state.
            if state_path:
                try:
                    from .scraper import _portal_logged_in

                    if not page.is_closed() and _portal_logged_in(page):
                        os.makedirs(os.path.dirname(state_path) or ".", exist_ok=True)
                        context.storage_state(path=state_path)
                        print(f"Saved UniMap session to {state_path}")
                    else:
                        print("Skipped saving UniMap session (not fully logged in).")
                except Exception as exc:
                    print(f"Skipped saving UniMap session ({exc}).")
            context.close()
            browser.close()
