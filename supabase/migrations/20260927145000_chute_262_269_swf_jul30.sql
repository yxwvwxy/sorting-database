-- SWF chutes 262-269: warehouse ALB→SWF, new routes effective 2026-07-30.
-- Keep prior 2026-06-01 rows for historical as-of mapping.

INSERT INTO public.chute_destination (
  chute_id, warehouse, city, route, region, sort_type, effective_date, note
)
SELECT v.chute_id, v.warehouse, v.city, v.route, v.region, v.sort_type, v.effective_date, v.note
FROM (VALUES
  (262, 'SWF', 'SWF', '920008', 'JFK', 'last_mile', DATE '2026-07-30', NULL::text),
  (263, 'SWF', 'SWF', '920007', 'JFK', 'last_mile', DATE '2026-07-30', NULL),
  (264, 'SWF', 'SWF', '920006', 'JFK', 'last_mile', DATE '2026-07-30', NULL),
  (265, 'SWF', 'SWF', '920005', 'JFK', 'last_mile', DATE '2026-07-30', NULL),
  (266, 'SWF', 'SWF', '920015', 'JFK', 'last_mile', DATE '2026-07-30', NULL),
  (268, 'SWF', 'SWF', '920017', 'JFK', 'last_mile', DATE '2026-07-30', NULL),
  (269, 'SWF', 'SWF', '920016', 'JFK', 'last_mile', DATE '2026-07-30', NULL)
) AS v(chute_id, warehouse, city, route, region, sort_type, effective_date, note)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date = v.effective_date
);
