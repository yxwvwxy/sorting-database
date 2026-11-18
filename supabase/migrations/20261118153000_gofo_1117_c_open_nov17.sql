-- 11/17 regular-plan 1117 starts at C open (A of that ops day stays on 1111).
-- Same-day mid-switch: prior touched rows end_date = 2026-11-17 (was 11/16);
-- new/changed rows keep effective_date = 2026-11-17.
-- gofo_plan_switch clock = C Batch No NJSUB-202611170615 at 06:15 ET.

UPDATE public.chute_destination_gofo
SET end_date = DATE '2026-11-17'
WHERE chute_id = 467
  AND end_date = DATE '2026-11-16';

INSERT INTO public.gofo_plan_switch (ops_date, switch_at, note)
VALUES (
  DATE '2026-11-17',
  (DATE '2026-11-17' + TIME '06:15') AT TIME ZONE 'America/New_York',
  '第一次分拣模版1111 → 1117 (C segment open NJSUB-202611170615)'
)
ON CONFLICT (ops_date) DO UPDATE
SET
  switch_at = EXCLUDED.switch_at,
  note = EXCLUDED.note,
  recorded_at = now();
