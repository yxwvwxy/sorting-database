"""Resolve which subbatch(es) to scrape.

Agreed ops rules (America/New_York):

- Each ops day uses three batches.
  - Batch 1 opens at the evening switch (normally 19:30).
  - From 23:10, every scrape opens Slot Assignment until Batch No leaves
    batch 1. If unchanged, keep scraping batch 1. When it changes (e.g. 01:30),
    that run scrapes batch 1 one last time and batch 2 for the first time;
    then stop Slot checks until the morning watch.
  - From 06:10, every scrape opens Slot until Batch No leaves batch 2. If
    unchanged, keep scraping batch 2. When it changes (e.g. 06:50), that run
    scrapes batch 2 one last time and batch 3 for the first time; then stop
    Slot checks until the next evening open.
- Batches 1 and 3 use the regular chute plan. Batch 2 uses the secondary-
  split (secondary-split) plan (EWR.H destinations only; re-sorts EWR.H multi-route
  volume from this ops day's batch 1 plus the prior ops day's batch 3).
  Dashboard still follows the regular plan for now; batch 2 volumes are
  scraped under their Batch No. From batch 3 of ops day 2026-11-05 onward
  the regular plan is `458-multisplit-1103`; until that morning batch 3 opens,
  regular remains `458-config`.
- 19:10 (19:00-19:29): never open Slot Assignment; use the saved batch.
  On an early-switch date that closing slot is one hour earlier.
- From 19:30 until Slot Batch No leaves the pre-switch value, every run
  opens Slot Assignment (early-switch evenings start at 18:30 / 17:30).
- If a Slot check fails, the next run must try again (do not mark confirmed).
- --refresh-batch adopts the live page Batch No outside the wait loop.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime, timedelta
from typing import TYPE_CHECKING

from .batch_state import BatchState, load_batch_state, save_batch_state
from .config import (
    Settings,
    SubbatchJob,
    _as_eastern,
    current_subbatch_job,
    is_closing_scrape_slot,
    job_with_phase,
    new_ops_window_started,
    operation_date_from_subbatch,
)
from .sheets import fetch_subbatch_for_date
from .slot_assignment import fetch_batch_from_slot_assignment

if TYPE_CHECKING:
    from .session import UniUniSession

BATCH2_WATCH_HOUR = 23
BATCH2_WATCH_MINUTE = 10
BATCH3_WATCH_HOUR = 6
BATCH3_WATCH_MINUTE = 10

EVENING_CONFIRMED_SOURCES = frozenset(
    {
        "slot_assignment",
        "slot_assignment_switch",
        "slot_assignment_refresh",
        "slot_assignment_batch2",
        "slot_assignment_batch3",
    }
)


@dataclass(frozen=True)
class ResolveResult:
    """One scrape run may cover two batches when a mid-ops switch is first seen."""

    jobs: tuple[SubbatchJob, ...]
    # After scraping jobs[0] (closing batch) and before jobs[1], record the
    # regular-plan cutover clock (11/5 batch 3: 458-config → 458-multisplit-1103).
    regular_plan_switch: bool = False

    @property
    def job(self) -> SubbatchJob:
        return self.jobs[-1]


def switch_window_operation_date(now: datetime | None = None) -> date:
    """Ops date for the active post-19:30 switch window.

    Aug 5 19:30 -> Aug 6
    Aug 6 01:10 (still waiting) -> Aug 6
    Aug 6 19:30 -> Aug 7
    """
    current = _as_eastern(now)
    if new_ops_window_started(current):
        window_start = current.date()
    else:
        window_start = current.date() - timedelta(days=1)
    return window_start + timedelta(days=1)


def window_batch1_confirmed(state: BatchState | None, window_ops: date) -> bool:
    """True after the evening Slot Batch No has switched for this ops-day window."""
    if state is None or state.awaiting_from:
        return False
    if state.job.operation_date != window_ops:
        return False
    return (state.source or "") in EVENING_CONFIRMED_SOURCES


def in_batch2_watch_window(now: datetime | None = None) -> bool:
    """From 23:10 ET through the rest of the ops day (past midnight) until 19:10."""
    current = _as_eastern(now)
    if new_ops_window_started(current):
        return current.hour > BATCH2_WATCH_HOUR or (
            current.hour == BATCH2_WATCH_HOUR and current.minute >= BATCH2_WATCH_MINUTE
        )
    # After midnight until the evening close: still the same ops day.
    return True


def in_batch3_watch_window(now: datetime | None = None) -> bool:
    """From 06:10 ET until the evening close (same ops-day calendar morning/day)."""
    current = _as_eastern(now)
    if new_ops_window_started(current):
        return False
    return current.hour > BATCH3_WATCH_HOUR or (
        current.hour == BATCH3_WATCH_HOUR and current.minute >= BATCH3_WATCH_MINUTE
    )


def should_poll_slot_assignment(
    now: datetime | None = None,
    *,
    state: BatchState | None,
) -> bool:
    """Whether this run must open Slot Assignment."""
    current = _as_eastern(now)
    window_ops = switch_window_operation_date(now)

    # 19:10 uses saved batch only.
    if is_closing_scrape_slot(current):
        return False

    # Evening open: still waiting for Batch No to leave the pre-switch value.
    if state and state.awaiting_from:
        return True

    phase = state.phase if state else 1

    # 23:10 onward while still on batch 1: watch for batch 2.
    if (
        state
        and window_batch1_confirmed(state, window_ops)
        and phase == 1
        and in_batch2_watch_window(current)
    ):
        return True

    # 06:10 onward while still on batch 2: watch for batch 3.
    if (
        state
        and window_batch1_confirmed(state, window_ops)
        and phase == 2
        and in_batch3_watch_window(current)
    ):
        return True

    # Already confirmed for this window and not in a watch window.
    if window_batch1_confirmed(state, window_ops):
        return False

    # Evening open: every run from 19:30 until the first switch is confirmed.
    if new_ops_window_started(current):
        return True

    # Daytime catch-up: 19:30 was missed/skipped and this window is not confirmed.
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
) -> ResolveResult:
    machine_id = (
        machine_id_override
        if machine_id_override is not None
        else settings.machine_id_override or 9
    )

    subbatch = subbatch_override or settings.subbatch_override
    if subbatch:
        return ResolveResult(
            jobs=(
                SubbatchJob(
                    operation_date=operation_date_from_subbatch(subbatch),
                    subbatch=subbatch,
                    machine_id=machine_id,
                ),
            )
        )

    if use_sheet:
        clock_job = current_subbatch_job(now=now, machine_id=machine_id)
        return ResolveResult(
            jobs=(fetch_subbatch_for_date(settings, clock_job.operation_date),)
        )

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
            f"(operation date {state.job.operation_date}, phase {state.phase})"
        )
        return ResolveResult(jobs=(job_with_phase(state.job, state.phase),))

    fallback = job_with_phase(
        current_subbatch_job(now=now, machine_id=machine_id),
        1,
    )
    save_batch_state(fallback, source="clock_bootstrap", phase=1)
    print(
        f"No saved batch yet; bootstrapped from clock: {fallback.subbatch} "
        f"(operation date {fallback.operation_date}). "
        "Will poll Slot Assignment from next 19:30 ET until Batch No changes."
    )
    return ResolveResult(jobs=(fallback,))


def _resolve_from_slot_assignment(
    settings: Settings,
    *,
    machine_id: int,
    state: BatchState | None,
    headless: bool,
    now: datetime | None,
    adopt_page_batch: bool = False,
    session: "UniUniSession | None" = None,
) -> ResolveResult:
    previous = state.job.subbatch if state else None
    previous_ops = state.job.operation_date if state else None
    awaiting_from = state.awaiting_from if state else None
    phase = state.phase if state else 1
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
    window_ops_now = switch_window_operation_date(now)

    # Forced mid-day refresh: page Batch No is the batch in use right now.
    if adopt_page_batch:
        keep_phase = phase if previous_ops == window_ops_now else 1
        job = job_with_phase(
            SubbatchJob(
                operation_date=previous_ops
                if previous_ops == window_ops_now
                else operation_date_from_subbatch(page_batch),
                subbatch=page_batch,
                machine_id=machine_id,
            ),
            keep_phase,
        )
        save_batch_state(
            job,
            source="slot_assignment_refresh",
            awaiting_from=None,
            window_operation_date=None,
            phase=keep_phase,
        )
        print(
            f"Refreshed current batch from Slot Assignment: {job.subbatch} "
            f"(operation date {job.operation_date}, phase {keep_phase})"
        )
        return ResolveResult(jobs=(job,))

    # Mid-ops watches: phase 1 from 23:10 (→ batch 2), phase 2 from 06:10 (→ batch 3).
    if (
        state
        and previous
        and not awaiting_from
        and window_batch1_confirmed(state, window_ops_now)
        and phase in (1, 2)
    ):
        watching_batch2 = phase == 1 and in_batch2_watch_window(now)
        watching_batch3 = phase == 2 and in_batch3_watch_window(now)
        if watching_batch2 or watching_batch3:
            ops = previous_ops or window_ops_now
            if page_batch == previous:
                label = "batch 2" if watching_batch2 else "batch 3"
                print(
                    f"Slot Assignment still shows {page_batch}; "
                    f"keep scraping phase {phase} while watching for {label} "
                    f"(operation date {ops})."
                )
                return ResolveResult(jobs=(job_with_phase(state.job, phase),))

            new_phase = 2 if watching_batch2 else 3
            source = (
                "slot_assignment_batch2"
                if watching_batch2
                else "slot_assignment_batch3"
            )
            old_job = job_with_phase(
                SubbatchJob(
                    operation_date=ops,
                    subbatch=previous,
                    machine_id=machine_id,
                ),
                phase,
            )
            new_job = job_with_phase(
                SubbatchJob(
                    operation_date=ops,
                    subbatch=page_batch,
                    machine_id=machine_id,
                ),
                new_phase,
            )
            save_batch_state(
                new_job,
                source=source,
                awaiting_from=None,
                window_operation_date=None,
                phase=new_phase,
            )
            plan_switch = new_phase == 3 and ops >= date(2026, 11, 5)
            print(
                f"Phase {phase} → {new_phase} batch switch: {previous} -> {page_batch} "
                f"(operation date {ops}). "
                f"This run scrapes phase {phase} once more, then phase {new_phase} first. "
                "No more Slot checks until the next watch window."
            )
            if plan_switch:
                print(
                    "Will record regular-plan cutover clock after the closing-batch "
                    "scrape (458-config end / 458-multisplit-1103 start)."
                )
            return ResolveResult(
                jobs=(old_job, new_job),
                regular_plan_switch=plan_switch,
            )

    # First poll of the evening window: remember the pre-switch Batch No.
    if previous and not awaiting_from:
        awaiting_from = previous
        window_ops = window_ops_now
        print(
            f"Slot poll start for ops {window_ops}: "
            f"waiting for Batch No to change from {awaiting_from}."
        )

    # Evening open switched: page value is batch 1 for the new ops day.
    if awaiting_from and page_batch != awaiting_from:
        job = job_with_phase(
            SubbatchJob(
                operation_date=window_ops_now,
                subbatch=page_batch,
                machine_id=machine_id,
            ),
            1,
        )
        save_batch_state(
            job,
            source="slot_assignment_switch",
            awaiting_from=None,
            window_operation_date=None,
            phase=1,
        )
        print(
            f"Batch switched: {awaiting_from} -> {page_batch} "
            f"(operation date {job.operation_date}, phase 1). "
            "Next Slot watch for batch 2 starts at 23:10 ET."
        )
        return ResolveResult(jobs=(job,))

    # Still old on the page: scrape old batch; check again next run.
    if awaiting_from and page_batch == awaiting_from:
        # Keep the prior ops-day phase on the closing batch (do not force #1).
        keep_phase = phase if phase in (1, 2, 3) else 3
        job = job_with_phase(
            SubbatchJob(
                operation_date=previous_ops or page_job.operation_date,
                subbatch=page_batch,
                machine_id=machine_id,
            ),
            keep_phase,
        )
        save_batch_state(
            job,
            source="slot_assignment_waiting",
            awaiting_from=awaiting_from,
            window_operation_date=window_ops,
            phase=keep_phase,
        )
        print(
            f"Slot Assignment still shows {page_batch}; "
            f"keep using old batch (target ops {window_ops}). "
            "Will check again next run."
        )
        return ResolveResult(jobs=(job,))

    # No prior saved batch: adopt page value for this window as phase 1.
    job = job_with_phase(
        SubbatchJob(
            operation_date=window_ops_now,
            subbatch=page_batch,
            machine_id=machine_id,
        ),
        1,
    )
    save_batch_state(job, source="slot_assignment", phase=1)
    print(
        f"Loaded batch from Slot Assignment: {job.subbatch} "
        f"(operation date {job.operation_date}, phase 1). "
        "Next Slot watch for batch 2 starts at 23:10 ET."
    )
    return ResolveResult(jobs=(job,))
