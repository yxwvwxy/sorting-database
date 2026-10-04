-- 2026-09-15: chute 654 leaves 580005 (that route stays on 662)
-- and takes 580013 plus 58function. Earlier 580005 row stays for prior ops days.

INSERT INTO public.chute_destination (
  chute_id, warehouse, city, route, region, sort_type, effective_date, note
)
SELECT v.chute_id, v.warehouse, v.city, v.route, v.region, v.sort_type, v.effective_date, v.note
FROM (VALUES
  (654, 'MDT', 'MDT', '580013', 'JFK', 'last_mile', DATE '2026-09-15', NULL::text),
  (654, 'MDT', 'MDT', '58function', 'JFK', 'last_mile', DATE '2026-09-15', NULL)
) AS v(chute_id, warehouse, city, route, region, sort_type, effective_date, note)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date = v.effective_date
);
