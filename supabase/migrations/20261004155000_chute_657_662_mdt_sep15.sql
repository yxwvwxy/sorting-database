-- 2026-09-15: chute 657 → MDT 580003, chute 662 → MDT 580005.
-- Earlier EWR/AT rows stay for ops days before this date.

INSERT INTO public.chute_destination (
  chute_id, warehouse, city, route, region, sort_type, effective_date, note
)
SELECT v.chute_id, v.warehouse, v.city, v.route, v.region, v.sort_type, v.effective_date, v.note
FROM (VALUES
  (657, 'MDT', 'MDT', '580003', 'JFK', 'last_mile', DATE '2026-09-15', NULL::text),
  (662, 'MDT', 'MDT', '580005', 'JFK', 'last_mile', DATE '2026-09-15', NULL)
) AS v(chute_id, warehouse, city, route, region, sort_type, effective_date, note)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date = v.effective_date
);
