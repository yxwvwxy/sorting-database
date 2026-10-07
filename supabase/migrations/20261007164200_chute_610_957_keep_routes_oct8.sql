-- Keep the routes still in use on 2026-10-07 when the 10/8 rows start.
-- Chute 610 keeps 740003 beside 74function.
-- Chute 957 keeps 960007 beside 96function.

INSERT INTO public.chute_destination (
  chute_id, warehouse, city, route, region, sort_type, effective_date, note
)
SELECT v.chute_id, v.warehouse, v.city, v.route, v.region, v.sort_type, v.effective_date, v.note
FROM (VALUES
  (610, 'PWM', 'PWM', '740003', 'JFK', 'last_mile', DATE '2026-10-08', NULL::text),
  (957, 'ORF', 'ORF', '960007', 'JFK', 'last_mile', DATE '2026-10-08', NULL)
) AS v(chute_id, warehouse, city, route, region, sort_type, effective_date, note)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date = v.effective_date
);
