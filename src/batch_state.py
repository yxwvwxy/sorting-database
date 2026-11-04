"""Persist the active batch and ops-day phase / Slot poll state."""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path

from .config import ET, SubbatchJob, operation_date_from_subbatch

DEFAULT_BATCH_STATE_PATH = ".current-batch.json"


@dataclass
class BatchState:
    job: SubbatchJob
    awaiting_from: str | None = None
    window_operation_date: date | None = None
    resolved_at: str | None = None
    source: str | None = None
    # 1 = evening batch, 2 = mid-night batch, 3 = morning batch (same ops day).
    phase: int = 1


def batch_state_path() -> Path:
    raw = (os.getenv("CURRENT_BATCH_PATH") or DEFAULT_BATCH_STATE_PATH).strip()
    return Path(raw)


def load_batch_state(*, machine_id: int = 9) -> BatchState | None:
    path = batch_state_path()
    if not path.exists():
        return None
    data = json.loads(path.read_text(encoding="utf-8"))
    subbatch = str(data.get("subbatch") or "").strip()
    if not subbatch:
        return None
    stored_machine = int(data.get("machine_id") or machine_id)
    if stored_machine != machine_id:
        return None

    raw_ops = data.get("operation_date")
    if raw_ops:
        # Prefer the stored ops date. Mid-ops batch 2/3 stamps can parse to the
        # next calendar day; the scraper locks the evening window's ops date.
        operation_date = date.fromisoformat(str(raw_ops))
    else:
        operation_date = operation_date_from_subbatch(subbatch)

    window_raw = data.get("window_operation_date")
    window_operation_date = date.fromisoformat(str(window_raw)) if window_raw else None
    awaiting_from = (data.get("awaiting_from") or "").strip() or None
    source = (data.get("source") or "").strip() or None

    phase_raw = data.get("phase")
    if phase_raw is not None:
        phase = int(phase_raw)
    elif source == "slot_assignment_batch3":
        phase = 3
    elif source == "slot_assignment_batch2":
        phase = 2
    else:
        phase = 1
    if phase not in (1, 2, 3):
        phase = 1

    return BatchState(
        job=SubbatchJob(
            operation_date=operation_date,
            subbatch=subbatch,
            machine_id=machine_id,
        ),
        awaiting_from=awaiting_from,
        window_operation_date=window_operation_date,
        resolved_at=data.get("resolved_at"),
        source=source,
        phase=phase,
    )


def save_batch_state(
    job: SubbatchJob,
    *,
    source: str = "slot_assignment",
    awaiting_from: str | None = None,
    window_operation_date: date | None = None,
    phase: int = 1,
) -> Path:
    path = batch_state_path()
    if phase not in (1, 2, 3):
        phase = 1
    payload = {
        "subbatch": job.subbatch,
        "operation_date": job.operation_date.isoformat(),
        "machine_id": job.machine_id,
        "resolved_at": datetime.now(ET).isoformat(),
        "source": source,
        "awaiting_from": awaiting_from,
        "window_operation_date": (
            window_operation_date.isoformat() if window_operation_date else None
        ),
        "phase": phase,
    }
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return path
