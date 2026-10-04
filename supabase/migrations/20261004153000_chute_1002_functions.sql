-- Chute 1002 on 2026-06-01: drop route 180061.
-- Same effective date becomes 17function and 18function.
-- 180061 stays on chute 1010.

DELETE FROM public.chute_destination
WHERE chute_id = 1002
  AND effective_date = DATE '2026-06-01'
  AND route = '180061';

INSERT INTO public.chute_destination (
  chute_id, warehouse, city, route, region, sort_type, effective_date, note
)
SELECT v.chute_id, v.warehouse, v.city, v.route, v.region, v.sort_type, v.effective_date, v.note
FROM (VALUES
  (1002, 'EWR', 'EWR', '17function', 'JFK', 'last_mile', DATE '2026-06-01', NULL::text),
  (1002, 'EWR', 'EWR', '18function', 'JFK', 'last_mile', DATE '2026-06-01', NULL)
) AS v(chute_id, warehouse, city, route, region, sort_type, effective_date, note)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date = v.effective_date
);
