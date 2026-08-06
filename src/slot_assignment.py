"""Read the active Batch No from UniMap Slot Assignment (Mgmt tab).

On the Slot Assignment page itself, ONLY the two Machine Code dropdowns are
clicked. Warehouse / Blind Batch / SET / VIEW / EDIT / MODIFY / table rows are
never touched.
"""

from __future__ import annotations

import re

from playwright.sync_api import Locator, Page

from .config import Settings, SubbatchJob, SUBBATCH_PATTERN, operation_date_from_subbatch
from .scraper import (
    _dismiss_portal_dialogs,
    _is_login_page,
    _login_form_visible,
    _login_with_credentials,
    _portal_logged_in,
)

MAIN_URL = "https://dispatch.uniuni.com/main"
BATCH_NO_PATTERN = re.compile(r"Batch\s*No\s*:?\s*(NJSUB-\d{8}2100)", re.I)


def _dismiss_blocking_dialogs(page: Page) -> None:
    """Close Version Update overlays on the main portal only."""
    _dismiss_portal_dialogs(page)
    page.evaluate(
        """() => {
          for (const button of document.querySelectorAll('button')) {
            const text = (button.innerText || '').trim();
            if (/^got it$/i.test(text)) {
              button.click();
            }
          }
        }"""
    )
    page.wait_for_timeout(500)


def _ensure_logged_in_main(page: Page, settings: Settings) -> None:
    """Go to UniMap main; login only when the saved nj600 session is gone."""
    page.goto(MAIN_URL, wait_until="domcontentloaded", timeout=60_000)
    _dismiss_blocking_dialogs(page)
    page.wait_for_timeout(1_000)

    needs_login = (
        _is_login_page(page)
        or _login_form_visible(page)
        or not _portal_logged_in(page)
    )
    if needs_login:
        print("UniMap session missing/expired — logging in with .env credentials...")
        _login_with_credentials(page, settings)
        page.goto(MAIN_URL, wait_until="domcontentloaded", timeout=60_000)
        _dismiss_blocking_dialogs(page)
        page.wait_for_timeout(1_000)
    else:
        print("Already logged in as nj600 session — skipping login.")

    if _login_form_visible(page):
        print("UniMap re-auth modal still open — filling password again...")
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


def _select_machine_code_trigger(page: Page, trigger: Locator, value: str, *, which: str) -> None:
    """Click only this Machine Code dropdown, then only option `value`."""
    box = trigger.bounding_box()
    print(
        f"Selecting {which} Machine Code dropdown = {value!r} "
        f"at ({box['x']:.0f},{box['y']:.0f})..."
        if box
        else f"Selecting {which} Machine Code dropdown = {value!r}..."
    )
    trigger.scroll_into_view_if_needed()
    trigger.click()
    page.wait_for_timeout(400)

    listbox = page.locator('[role="listbox"]:visible').last
    listbox.wait_for(state="visible", timeout=10_000)

    option = listbox.locator('[role="option"], li').filter(
        has_text=re.compile(rf"^{re.escape(value)}$")
    )
    if option.count() == 0:
        option = listbox.get_by_role("option", name=value, exact=True)
    if option.count() == 0:
        page.keyboard.press("Escape")
        raise RuntimeError(
            f"{which} Machine Code option {value!r} not found in open listbox. "
            "No other controls were clicked."
        )

    option.first.click()
    page.wait_for_timeout(600)
    if page.locator('[role="listbox"]:visible').count():
        page.keyboard.press("Escape")
        page.wait_for_timeout(200)


def _two_machine_code_triggers(page: Page):
    """Return two distinct Machine Code selects: top-left, then config-box.

    Layout on Slot Assignment (from live DOM):
    - LEFT: labeled MUI control beside Warehouse (~x=284, y=97)
    - RIGHT: select inside Sort Machine Configuration (~x=547, y=158)
    """
    left = page.locator("div.MuiFormControl-root").filter(
        has=page.locator("label", has_text=re.compile(r"^Machine Code$"))
    ).locator("[class*='MuiSelect-select']").first
    if left.count() == 0:
        raise RuntimeError("LEFT Machine Code dropdown (top bar) not found.")

    # RIGHT is NOT the top-bar control. Prefer geometric match inside the config card.
    right_handle = page.evaluate_handle(
        """() => {
          const selects = [...document.querySelectorAll('[class*="MuiSelect-select"]')]
            .filter(el => el.offsetParent !== null);
          // Config-box Machine Code sits below the top bar and to the right of Blind Batch.
          return selects.find(el => {
            const t = (el.textContent || '').trim();
            if (!/^(Not selected|\\d+)$/.test(t)) return false;
            const r = el.getBoundingClientRect();
            return r.y > 130 && r.y < 190 && r.x > 450 && r.x < 700;
          }) || null;
        }"""
    )
    right = right_handle.as_element()
    if right is None:
        raise RuntimeError(
            "RIGHT Machine Code dropdown (Sort Machine Configuration) not found."
        )

    left_box = left.bounding_box()
    right_box = right.bounding_box()
    if not left_box or not right_box:
        raise RuntimeError("Could not measure Machine Code dropdown positions.")
    if abs(left_box["x"] - right_box["x"]) < 2 and abs(left_box["y"] - right_box["y"]) < 2:
        raise RuntimeError(
            "Resolved the same Machine Code dropdown twice; refusing to continue."
        )
    print(
        f"Found 2 Machine Code dropdowns: "
        f"LEFT=({left_box['x']:.0f},{left_box['y']:.0f}) "
        f"RIGHT=({right_box['x']:.0f},{right_box['y']:.0f})"
    )
    return left, right


def _select_both_machine_codes(page: Page, machine_value: str) -> None:
    """Two different dropdowns, both set to machine_value: left first, then right."""
    left, right = _two_machine_code_triggers(page)
    _select_machine_code_trigger(page, left, machine_value, which="LEFT")
    _select_machine_code_trigger(page, right, machine_value, which="RIGHT")


def _read_batch_no(page: Page) -> str:
    """Read Batch No text only — never click it or MODIFY."""
    raw = page.locator("body").inner_text(timeout=15_000)
    match = BATCH_NO_PATTERN.search(raw)
    if not match:
        raise RuntimeError(
            "Batch No not found on Slot Assignment after selecting machine code. "
            "Re-run with --headed to inspect the page."
        )
    subbatch = re.sub(r"^njsub-", "NJSUB-", match.group(1), flags=re.I)
    if not SUBBATCH_PATTERN.match(subbatch):
        raise RuntimeError(f"Unexpected Batch No format: {subbatch!r}")
    return subbatch


def fetch_batch_on_page(
    page: Page,
    settings: Settings,
    *,
    machine_id: int = 9,
) -> tuple[SubbatchJob, Page]:
    """On an open UniMap page: Slot Assignment → Machine Codes → Batch No.

    Returns (job, active_page). Caller should keep using active_page (often the
    Slot Assignment tab) and navigate it to Sorting Production Analysis next.
    """
    machine_value = str(machine_id)
    _ensure_logged_in_main(page, settings)
    slot_page = _open_slot_assignment(page)

    # From here on: Machine Code dropdowns only.
    _select_both_machine_codes(slot_page, machine_value)

    slot_page.wait_for_timeout(1_500)
    slot_page.wait_for_function(
        """() => /Batch\\s*No\\s*:?\\s*NJSUB-\\d{8}2100/i.test(document.body.innerText || '')""",
        timeout=30_000,
    )
    subbatch = _read_batch_no(slot_page)
    print(f"Read Batch No from page (no other clicks): {subbatch}")
    print("Leaving Slot Assignment in this browser — next step is Sorting Production Analysis.")
    return (
        SubbatchJob(
            operation_date=operation_date_from_subbatch(subbatch),
            subbatch=subbatch,
            machine_id=machine_id,
        ),
        slot_page,
    )


def fetch_batch_from_slot_assignment(
    settings: Settings,
    *,
    machine_id: int = 9,
    headless: bool = True,
) -> SubbatchJob:
    """Standalone batch fetch (own browser). Prefer UniUniSession.fetch_batch."""
    from .session import open_uniuni_session

    with open_uniuni_session(settings, headless=headless) as session:
        return session.fetch_batch(machine_id=machine_id)
