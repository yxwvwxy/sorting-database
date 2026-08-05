"""Read the active Batch No from UniMap Slot Assignment (Mgmt tab)."""

from __future__ import annotations

import os
import re

from playwright.sync_api import Locator, Page, sync_playwright

from .config import Settings, SubbatchJob, SUBBATCH_PATTERN, operation_date_from_subbatch
from .scraper import (
    _dismiss_portal_dialogs,
    _is_login_page,
    _launch_browser,
    _login_with_credentials,
    _portal_logged_in,
)

MAIN_URL = "https://dispatch.uniuni.com/main"
BATCH_NO_PATTERN = re.compile(r"Batch\s*No\s*:?\s*(NJSUB-\d{8}2100)", re.I)


def _dismiss_blocking_dialogs(page: Page) -> None:
    """Close Version Update / Got it / Retry overlays that block the rail tabs."""
    _dismiss_portal_dialogs(page)
    page.evaluate(
        """() => {
          for (const button of document.querySelectorAll('button')) {
            const text = (button.innerText || '').trim();
            if (/^got it$/i.test(text) || /^retry$/i.test(text)) {
              button.click();
            }
          }
        }"""
    )
    page.wait_for_timeout(500)


def _ensure_logged_in_main(page: Page, settings: Settings) -> None:
    page.goto(MAIN_URL, wait_until="domcontentloaded", timeout=60_000)
    _dismiss_blocking_dialogs(page)

    for _ in range(20):
        if not _is_login_page(page):
            break
        page.wait_for_timeout(500)

    if _is_login_page(page):
        _login_with_credentials(page, settings)
        page.goto(MAIN_URL, wait_until="domcontentloaded", timeout=60_000)
        _dismiss_blocking_dialogs(page)

    if _is_login_page(page) or not _portal_logged_in(page):
        raise RuntimeError(
            "UniMap login did not complete before Slot Assignment. "
            f"Current url={page.url!r}."
        )

    _dismiss_blocking_dialogs(page)


def _open_slot_assignment(page: Page) -> Page:
    """Open Mgmt → SLOT ASSIGNMENT; return the page that hosts the form."""
    _dismiss_blocking_dialogs(page)

    # Vertical rail tab (MUI). JS click is more reliable than force-click here.
    switched = page.evaluate(
        """() => {
          const el = [...document.querySelectorAll('[role=tab]')]
            .find(e => /^\\s*Mgmt\\.?\\s*$/i.test((e.innerText || '').trim()));
          if (!el) return false;
          el.click();
          return true;
        }"""
    )
    if not switched:
        raise RuntimeError("Mgmt. tab not found on UniMap main page.")

    page.wait_for_function(
        """() => /SLOT\\s*ASSIGNMENT/i.test(document.body.innerText || '')""",
        timeout=20_000,
    )

    tile = page.get_by_text(re.compile(r"SLOT\s*ASSIGNMENT", re.I)).first
    tile.click(force=True)

    # Slot Assignment may open in the same tab or a new one.
    page.wait_for_timeout(2_000)
    target = page.context.pages[-1]
    target.wait_for_load_state("domcontentloaded")

    target.get_by_text(re.compile(r"Slot\s*Assignment", re.I)).first.wait_for(
        state="visible", timeout=60_000
    )
    target.get_by_text(re.compile(r"Sort\s*Machine\s*Configuration", re.I)).first.wait_for(
        state="visible", timeout=60_000
    )
    return target


def _mui_select_value(page: Page, trigger: Locator, value: str) -> None:
    trigger.click(force=True)
    page.wait_for_timeout(400)

    listbox = page.get_by_role("listbox")
    if listbox.count():
        option = listbox.get_by_role("option", name=value, exact=True)
        if option.count() == 0:
            option = listbox.get_by_text(value, exact=True)
        if option.count():
            option.first.click(force=True)
            page.wait_for_timeout(500)
            return

    option = page.get_by_role("option", name=value, exact=True)
    if option.count() == 0:
        option = page.locator("li, [role='option']").filter(
            has_text=re.compile(rf"^{re.escape(value)}$")
        )
    if option.count() == 0:
        raise RuntimeError(f"Dropdown option {value!r} not found.")
    option.first.click(force=True)
    page.wait_for_timeout(500)


def _machine_code_triggers(page: Page) -> tuple[Locator, Locator]:
    """Return (left/top Machine Code, right/config Machine Code) triggers."""
    config = page.get_by_text(re.compile(r"Sort\s*Machine\s*Configuration", re.I)).locator(
        "xpath=ancestor::div[.//text()[contains(., 'Batch No')]][1]"
    )
    if config.count() == 0:
        config = page.locator("div").filter(
            has_text=re.compile(r"Sort\s*Machine\s*Configuration", re.I)
        ).filter(has_text=re.compile(r"Batch\s*No", re.I)).first
    else:
        config = config.first

    # Prefer MUI select / combobox controls.
    config_triggers = config.locator(
        '[role="button"][aria-haspopup="listbox"], '
        '[class*="MuiSelect-select"], '
        '[aria-haspopup="listbox"]'
    )
    if config_triggers.count() == 0:
        # Fallback: clickable control near the Machine Code label inside the box.
        config_triggers = config.get_by_text(re.compile(r"^Machine Code$", re.I)).locator(
            "xpath=following::div[@role='button' or contains(@class,'MuiSelect')][1]"
        )

    if config_triggers.count() == 0:
        raise RuntimeError("Machine Code dropdown not found inside Sort Machine Configuration.")

    right = config_triggers.first

    # Top-left Machine Code sits outside the configuration box, next to Warehouse.
    all_triggers = page.locator(
        '[role="button"][aria-haspopup="listbox"], '
        '[class*="MuiSelect-select"], '
        '[aria-haspopup="listbox"]'
    )
    left = None
    right_box = right.bounding_box()
    for i in range(all_triggers.count()):
        candidate = all_triggers.nth(i)
        box = candidate.bounding_box()
        if not box or not right_box:
            continue
        # Same control as the config dropdown.
        if abs(box["x"] - right_box["x"]) < 2 and abs(box["y"] - right_box["y"]) < 2:
            continue
        # Prefer a control above the configuration box.
        if box["y"] + box["height"] <= right_box["y"] + 5:
            left = candidate
            break

    if left is None:
        # Fallback: first page-level "Not selected" / Machine Code control.
        not_selected = page.get_by_text(re.compile(r"^Not selected$", re.I))
        if not_selected.count():
            left = not_selected.first
        else:
            raise RuntimeError("Left/top Machine Code dropdown not found on Slot Assignment.")

    return left, right


def _read_batch_no(page: Page) -> str:
    # Prefer the value inside Sort Machine Configuration.
    config_text = page.get_by_text(re.compile(r"Sort\s*Machine\s*Configuration", re.I)).locator(
        "xpath=ancestor::div[.//text()[contains(., 'Batch No')]][1]"
    )
    raw = ""
    if config_text.count():
        raw = config_text.first.inner_text(timeout=10_000)
    if not raw:
        raw = page.locator("body").inner_text(timeout=15_000)

    match = BATCH_NO_PATTERN.search(raw)
    if not match:
        raise RuntimeError(
            "Batch No not found on Slot Assignment after selecting machine code 9. "
            "Re-run with --headed to inspect the page."
        )
    subbatch = re.sub(r"^njsub-", "NJSUB-", match.group(1), flags=re.I)
    if not SUBBATCH_PATTERN.match(subbatch):
        raise RuntimeError(f"Unexpected Batch No format: {subbatch!r}")
    return subbatch


def fetch_batch_from_slot_assignment(
    settings: Settings,
    *,
    machine_id: int = 9,
    headless: bool = True,
) -> SubbatchJob:
    """Login → dismiss dialogs → Mgmt → Slot Assignment → both Machine Codes → Batch No."""
    machine_value = str(machine_id)

    with sync_playwright() as playwright:
        browser = _launch_browser(playwright, headless=headless)
        context_kwargs: dict[str, object] = {}
        state_path = settings.uniuni_auth_state_path
        if state_path and os.path.exists(state_path):
            context_kwargs["storage_state"] = state_path

        context = browser.new_context(**context_kwargs)
        page = context.new_page()
        try:
            _ensure_logged_in_main(page, settings)
            page = _open_slot_assignment(page)

            left, right = _machine_code_triggers(page)
            _mui_select_value(page, left, machine_value)
            _mui_select_value(page, right, machine_value)

            page.wait_for_timeout(1_500)
            page.get_by_text(re.compile(r"Batch\s*No\s*:?\s*NJSUB-", re.I)).first.wait_for(
                state="visible", timeout=30_000
            )
            subbatch = _read_batch_no(page)
            return SubbatchJob(
                operation_date=operation_date_from_subbatch(subbatch),
                subbatch=subbatch,
                machine_id=machine_id,
            )
        finally:
            if state_path:
                os.makedirs(os.path.dirname(state_path) or ".", exist_ok=True)
                context.storage_state(path=state_path)
            context.close()
            browser.close()
