-- Correct chute 660 on 2026-09-15: 580012 → 580004.
-- 580012 remains the latest route on chute 658.

UPDATE public.chute_destination
SET route = '580004'
WHERE chute_id = 660
  AND effective_date = DATE '2026-09-15'
  AND route = '580012';
