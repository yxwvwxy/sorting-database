"""Headed Chrome probe: why UniMap is marked 'not fully logged in'.

Keeps the browser open so you can inspect the page.
Run: .venv\\Scripts\\python.exe scripts\\debug_unimap_login.py
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
os.chdir(ROOT)

from dotenv import load_dotenv
from playwright.sync_api import sync_playwright

load_dotenv(ROOT / ".env")

from src.config import Settings
from src.scraper import (
    _analysis_ready,
    _is_login_page,
    _launch_browser,
    _login_form_visible,
    _login_with_credentials,
    _mgmt_tab_present,
    _portal_logged_in,
    _purge_browser_auth,
)
from src.slot_assignment import (
    _ensure_logged_in_main,
    _open_slot_assignment,
    _read_batch_no,
    _select_both_machine_codes,
)


def snap(label: str, page) -> None:
    try:
        url = page.url
    except Exception as exc:
        print(f"\n=== {label} === page unusable ({exc})")
        return
    tabs = []
    try:
        tabs = page.evaluate(
            """() => [...document.querySelectorAll('[role=tab]')]
              .map(e => (e.innerText || '').trim()).filter(Boolean).slice(0, 20)"""
        )
    except Exception:
        tabs = ["<evaluate failed>"]
    body_head = ""
    try:
        body_head = (page.locator("body").inner_text(timeout=5_000) or "")[:400].replace("\n", " | ")
    except Exception as exc:
        body_head = f"<body read failed: {exc}>"
    print(f"\n=== {label} ===")
    print(f"  url: {url}")
    print(f"  is_login_page: {_is_login_page(page)}")
    print(f"  login_form_visible: {_login_form_visible(page)}")
    print(f"  mgmt_tab_present: {_mgmt_tab_present(page)}")
    print(f"  analysis_ready: {_analysis_ready(page)}")
    print(f"  portal_logged_in: {_portal_logged_in(page)}")
    print(f"  tabs: {tabs}")
    print(f"  body[:400]: {body_head}")


def main() -> int:
    settings = Settings.from_env()
    machine_id = settings.machine_id_override or 9
    state_path = settings.uniuni_auth_state_path
    print(f"Auth state path: {state_path} exists={os.path.exists(state_path) if state_path else None}")
    print(f"Machine: {machine_id}")
    print("Launching headed Chrome (slow_mo=500). Close the pause prompt when done looking.\n")

    with sync_playwright() as p:
        browser = _launch_browser(p, headless=False)
        context = browser.new_context(accept_downloads=True)
        page = context.new_page()

        try:
            snap("blank start", page)

            print("\n--- ensure logged in on /main ---")
            try:
                _ensure_logged_in_main(page, settings)
            except Exception as exc:
                print(f"ensure_logged_in_main FAILED: {exc}")
                snap("after failed ensure", page)
                input("\nBrowser left open. Press Enter to quit...")
                return 1
            snap("after ensure_logged_in_main (this is what login-succeeded looks like)", page)

            print("\n--- open Slot Assignment ---")
            try:
                slot = _open_slot_assignment(page)
            except Exception as exc:
                print(f"open Slot FAILED: {exc}")
                snap("main page after Slot open fail", page)
                print(f"  open pages: {len(page.context.pages)}")
                for i, pg in enumerate(page.context.pages):
                    snap(f"context page[{i}]", pg)
                input("\nBrowser left open. Press Enter to quit...")
                return 1

            print(f"Slot page is same object as main? {slot is page}")
            print(f"Open pages count: {len(page.context.pages)}")
            snap("MAIN page after Slot opened", page)
            snap("SLOT page after open", slot)

            print("\n--- select machine codes ---")
            try:
                _select_both_machine_codes(slot, str(machine_id))
            except Exception as exc:
                print(f"machine select FAILED: {exc}")
                snap("SLOT after machine fail", slot)
                input("\nBrowser left open. Press Enter to quit...")
                return 1
            snap("SLOT after machine select", slot)

            print("\n--- wait briefly then look for Batch No ---")
            slot.wait_for_timeout(2_000)
            try:
                batch = _read_batch_no(slot)
                print(f"Batch No found: {batch}")
            except Exception as exc:
                print(f"Batch No NOT found: {exc}")
            snap("SLOT while waiting/looking for Batch No", slot)

            print("\n--- finally-block simulation (checks ORIGINAL main page var) ---")
            snap("ORIGINAL page var (what session finally checks)", page)
            for i, pg in enumerate(page.context.pages):
                snap(f"all pages[{i}] for save decision", pg)

            print(
                "\nIf ORIGINAL page has portal_logged_in=False here, that is why "
                "logs say 'Skipped saving UniMap session (not fully logged in)' "
                "even though login succeeded earlier."
            )
            input("\nInspect Chrome, then press Enter here to close...")
            return 0
        finally:
            context.close()
            browser.close()


if __name__ == "__main__":
    raise SystemExit(main())
