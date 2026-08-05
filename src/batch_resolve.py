"""Resolve which subbatch to scrape.

Whatever Batch No Slot Assignment shows is the batch in use — do not assume the
embedded YYYYMMDD must be operation_date-1.

From 21:30 ET, poll Slot Assignment every run until the Batch No changes from
the pre-switch value. The new batch is stored under that evening window's
operation date (window start day + 1), even if the ID digits are unusual
(e.g. late switch at 1:10am showing ...062100 for an Aug 6 ops day).
"""

from __future__ import annotations

from datetime import date, datetime, timedelta

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


def switch_window_operation_date(now: datetime | None = None) -> date:
    """Operation date for the active post-21:30 switch window.

    Aug 5 21:30 → Aug 6
    Aug 6 01:10 (still waiting) → Aug 6
    Aug 6 21:30 → Aug 7
    """
    current = _as_eastern(now)
    if current.hour > 21 or (current.hour == 21 and current.minute >= 30):
        window_start = current.date()
    else:
        window_start = current.date() - timedelta(days=1)
    return window_start + timedelta(days=1)


def should_poll_slot_assignment(
    now: datetime | None = None,
    *,
    state: BatchState | None,
) -> bool:
    """Poll from 21:30 until the page Batch No changes; never at 21:10."""
    current = _as_eastern(now)

    # 21:10 uses the saved batch only.
    if current.hour == 21 and current.minute < 30:
        return False

    # Already waiting for UniMap to flip — keep checking overnight if needed.
    if state and state.awaiting_from:
        return True

    # Open a new evening switch window at/after 21:30.
    if current.hour > 21 or (current.hour == 21 and current.minute >= 30):
        return True

    return False


def resolve_job(
    settings: Settings,
    *,
    subbatch_override: str | None = None,
    machine_id_override: int | None = None,
    use_sheet: bool = False,
    refresh_batch: bool = False,
    headless: bool = True,
    now: datetime | None = None,
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
        "Will poll Slot Assignment from next 21:30 ET until the batch switches."
    )
    return fallback


def _resolve_from_slot_assignment(
    settings: Settings,
    *,
    machine_id: int,
    state: BatchState | None,
    headless: bool,
    now: datetime | None,
) -> SubbatchJob:
    previous = state.job.subbatch if state else None
    previous_ops = state.job.operation_date if state else None
    awaiting_from = state.awaiting_from if state else None
    window_ops = (
        state.window_operation_date
        if state and state.window_operation_date
        else switch_window_operation_date(now)
    )

    # First poll of this evening window: lock the pre-switch batch + ops day.
    if previous and not awaiting_from:
        awaiting_from = previous
        window_ops = switch_window_operation_date(now)

    page_job = fetch_batch_from_slot_assignment(
        settings,
        machine_id=machine_id,
        headless=headless,
    )
    page_batch = page_job.subbatch

    # Page shows a different Batch No than before the window → switch complete.
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
            f"Batch switched: {awaiting_from} → {page_batch} "
            f"(operation date {window_ops}; using page Batch No as-is)"
        )
        return job

    # Still the old Batch No → keep waiting; do not invent a new ID.
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
            f"waiting for switch (target operation date {window_ops}). "
            "Will check again next run."
        )
        return job

    # No prior saved batch: trust the page value.
    job = SubbatchJob(
        operation_date=switch_window_operation_date(now),
        subbatch=page_batch,
        machine_id=machine_id,
    )
    save_batch_state(job, source="slot_assignment")
    print(
        f"Loaded batch from Slot Assignment: {job.subbatch} "
        f"(operation date {job.operation_date})"
    )
    return job
