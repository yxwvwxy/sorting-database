-- Keep ended-in-1103 chutes 269/320 on current Active mapping until the
-- exact 11/5 switch clock time is confirmed (then set end_date).
UPDATE public.chute_destination_gofo
SET end_date = NULL
WHERE chute_id IN (269, 320)
  AND end_date = DATE '2026-11-04'
  AND effective_date = DATE '2026-10-29';
