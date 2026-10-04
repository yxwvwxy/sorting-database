-- 2026-09-15 MDT route moves:
-- 653 → 580016, 655 → 580009, 660 → 580012.
-- Earlier rows stay for ops days before this date.

INSERT INTO public.chute_destination (
  chute_id, warehouse, city, route, region, sort_type, effective_date, note
)
SELECT v.chute_id, v.warehouse, v.city, v.route, v.region, v.sort_type, v.effective_date, v.note
FROM (VALUES
  (653, 'MDT', 'MDT', '580016', 'JFK', 'last_mile', DATE '2026-09-15', NULL::text),
  (655, 'MDT', 'MDT', '580009', 'JFK', 'last_mile', DATE '2026-09-15', NULL),
  (660, 'MDT', 'MDT', '580012', 'JFK', 'last_mile', DATE '2026-09-15', NULL)
) AS v(chute_id, warehouse, city, route, region, sort_type, effective_date, note)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date = v.effective_date
);
