-- Correct chute 263 on the 2026-07-30 SWF map: route 920008 → 920007.

UPDATE public.chute_destination
SET route = '920007'
WHERE chute_id = 263
  AND effective_date = DATE '2026-07-30'
  AND warehouse = 'SWF'
  AND route = '920008';
