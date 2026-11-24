-- From ops day 2026-11-23: one Batch No per ops day again (no A/B/C).
-- Clear segment tags on already-stored rows so the dashboard does not show #A.

UPDATE public.subbatch
SET batch_phase = NULL
WHERE subbatch_date >= DATE '2026-11-23'
  AND batch_phase IS NOT NULL;
