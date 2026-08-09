"""Resolve which subbatch to scrape.

Agreed ops rules (America/New_York):

- 21:10 (21:00-21:29): never open Slot Assignment; use the saved batch.
- From 21:30 until Slot Batch No changes from the pre-switch value:
  every run opens Slot Assignment.
  - still old -> scrape with the old batch; check again next run
  - changed -> page value becomes this ops-day batch; no more Slot checks
    until the next evening's 21:30
- If a Slot check fails, the next run must try again (do not mark confirmed).
- --refresh-batch adopts the live page Batch No outside the evening wait loop.
"""

from __future__ import annotations

from datetime import date, datetime, timedelta
from typing import TYPE_CHECKING

from .batch_state import BatchState, load_batch_state, save_batch_state
from .config import (
    Settings,
    SubbatchJob,
    _as_eastern,
    current_subbatch_job,
    operation_date_from_subbatch,
)
from .sheets import fetch_subbatch_for_date
from .slot_assignment import fetch_batch_from_slot_assignment

if TYPE_CHECKING:
    from .session import UniUniSession

CONFIRMED_SOURCES = frozenset(
    {
        "slot_assignment",
        "slot_assignment_switch",
        "slot_assignment_refresh",
    }
)


def switch_window_operation_date(now: datetime | None = None) -> date:
    """Ops date for the active post-21:30 switch window.

    Aug 5 21:30 -> Aug 6
    Aug 6 01:10 (still waiting) -> Aug 6
    Aug 6 21:30 -> Aug 7
    """
    current = _as_eastern(now)
    if current.hour > 21 or (current.hour == 21 and current.minute >= 30):
        window_start = current.date()
    else:
        window_start = current.date() - timedelta(days=1)
    return window_start + timedelta(days=1)


def window_batch_confirmed(state: BatchState | None, window_ops: date) -> bool:
    """True after Slot Batch No has switched for this ops-day window."""
    if state is None or state.awaiting_from:
        return False
    if state.job.operation_date != window_ops:
        return False
    return (state.source or "") in CONFIRMED_SOURCES


def should_poll_slot_assignment(
    now: datetime | None = None,
    *,
    state: BatchState | None,
) -> bool:
    """Whether this run must open Slot Assignment."""
    current = _as_eastern(now)
    window_ops = switch_window_operation_date(now)

    # 21:10 uses saved batch only.
    if current.hour == 21 and current.minute < 30:
        return False

    # Still waiting for the page Batch No to change (may continue overnight).
    if state and state.awaiting_from:
        return True

    if window_batch_confirmed(state, window_ops):
        return False

    # Evening open: every run from 21:30 until confirmed.
    if current.hour > 21 or (current.hour == 21 and current.minute >= 30):
        return True

    # Daytime catch-up: 21:30 was missed/skipped and this window is not confirmed.
    return True


def resolve_job(
    settings: Settings,
    *,
    subbatch_override: str | None = None,
    machine_id_override: int | None = None,
    use_sheet: bool = False,
    refresh_batch: bool = False,
    headless: bool = True,
    now: datetime | None = None,
    session: "UniUniSession | None" = None,
) -> SubbatchJob:
    machine_id = (
        machine_id_override
        if machine_id_override is not None
        else settings.machine_id_override or 9
    )

    subbatch = subbatch_override or settings.subbatch_override
    if subbatch:
        return SubbatchJob(
            operation_date=operation_date_from_subbatch(subbatch),
            subbatch=subbatch,
            machine_id=machine_id,
        )

    if use_sheet:
        clock_job = current_subbatch_job(now=now, machine_id=machine_id)
        return fetch_subbatch_for_date(settings, clock_job.operation_date)

    state = load_batch_state(machine_id=machine_id)
    should_refresh = refresh_batch or should_poll_slot_assignment(now, state=state)

    if should_refresh:
        return _resolve_from_slot_assignment(
            settings,
            machine_id=machine_id,
            state=state,
            headless=headless,
            now=now,
            session=session,
            adopt_page_batch=refresh_batch
            and not should_poll_slot_assignment(now, state=None),
        )

    if state:
        print(
            f"Using saved batch: {state.job.subbatch} "
            f"(operation date {state.job.operation_date})"
        )
        return state.job

    fallback = current_subbatch_job(now=now, machine_id=machine_id)
    save_batch_state(fallback, source="clock_bootstrap")
    print(
        f"No saved batch yet; bootstrapped from clock: {fallback.subbatch} "
        f"(operation date {fallback.operation_date}). "
        "Will poll Slot Assignment from next 21:30 ET until Batch No changes."
    )
    return fallback


def _resolve_from_slot_assignment(
    settings: Settings,
    *,
    machine_id: int,
    state: BatchState | None,
    headless: bool,
    now: datetime | None,
    adopt_page_batch: bool = False,
    session: "UniUniSession | None" = None,
) -> SubbatchJob:
    previous = state.job.subbatch if state else None
    previous_ops = state.job.operation_date if state else None
    awaiting_from = state.awaiting_from if state else None
    window_ops = (
        state.window_operation_date
        if state and state.window_operation_date
        else switch_window_operation_date(now)
    )

    if session is not None:
        page_job = session.fetch_batch(machine_id=machine_id)
    else:
        page_job = fetch_batch_from_slot_assignment(
            settings,
            machine_id=machine_id,
            headless=headless,
        )
    page_batch = page_job.subbatch

    # Forced mid-day refresh: page Batch No is the batch in use right now.
    if adopt_page_batch:
        job = SubbatchJob(
            operation_date=operation_date_from_subbatch(page_batch),
            subbatch=page_batch,
            machine_id=machine_id,
        )
        save_batch_state(
            job,
            source="slot_assignment_refresh",
            awaiting_from=None,
            window_operation_date=None,
        )
        print(
            f"Refreshed current batch from Slot Assignment: {job.subbatch} "
            f"(operation date {job.operation_date})"
        )
        return job

    # First poll of this window: remember the pre-switch Batch No.
    if previous and not awaiting_from:
        awaiting_from = previous
        window_ops = switch_window_operation_date(now)
        print(
            f"Slot poll start for ops {window_ops}: "
            f"waiting for Batch No to change from {awaiting_from}."
        )

    # Switched: page value is the new ops-day batch.
    if awaiting_from and page_batch != awaiting_from:
        job = SubbatchJob(
            operation_date=window_ops,
            subbatch=page_batch,
            machine_id=machine_id,
        )
        save_batch_state(
            job,
            source="slot_assignment_switch",
            awaiting_from=None,
            window_operation_date=None,
        )
        print(
            f"Batch switched: {awaiting_from} -> {page_batch} "
            f"(operation date {window_ops}). "
            "No more Slot checks until next 21:30 ET."
        )
        return job

    # Still old on the page: scrape old batch; check again next run.
    if awaiting_from and page_batch == awaiting_from:
        job = SubbatchJob(
            operation_date=previous_ops or page_job.operation_date,
            subbatch=page_batch,
            machine_id=machine_id,
        )
        save_batch_state(
            job,
            source="slot_assignment_waiting",
            awaiting_from=awaiting_from,
            window_operation_date=window_ops,
        )
        print(
            f"Slot Assignment still shows {page_batch}; "
            f"keep using old batch (target ops {window_ops}). "
            "Will check again next run."
        )
        return job

    # No prior saved batch: adopt page value for this window.
    job = SubbatchJob(
        operation_date=switch_window_operation_date(now),
        subbatch=page_batch,
        machine_id=machine_id,
    )
    save_batch_state(job, source="slot_assignment")
    print(
        f"Loaded batch from Slot Assignment: {job.subbatch} "
        f"(operation date {job.operation_date}). "
        "No more Slot checks until next 21:30 ET."
    )
    return job
