-- GSO chutes 757-762: warehouse RDU→GSO, new routes effective 2026-09-16.
-- Keep prior 2026-06-01 rows for historical as-of mapping.
-- Chute 762 has two active routes (950001 + 950004).

INSERT INTO public.chute_destination (
  chute_id, warehouse, city, route, region, sort_type, effective_date, note
)
SELECT v.chute_id, v.warehouse, v.city, v.route, v.region, v.sort_type, v.effective_date, v.note
FROM (VALUES
  (757, 'GSO', 'GSO', '95function', 'JFK', 'last_mile', DATE '2026-09-16', NULL::text),
  (758, 'GSO', 'GSO', '950006', 'JFK', 'last_mile', DATE '2026-09-16', NULL),
  (759, 'GSO', 'GSO', '950005', 'JFK', 'last_mile', DATE '2026-09-16', NULL),
  (760, 'GSO', 'GSO', '950003', 'JFK', 'last_mile', DATE '2026-09-16', NULL),
  (761, 'GSO', 'GSO', '950002', 'JFK', 'last_mile', DATE '2026-09-16', NULL),
  (762, 'GSO', 'GSO', '950001', 'JFK', 'last_mile', DATE '2026-09-16', NULL),
  (762, 'GSO', 'GSO', '950004', 'JFK', 'last_mile', DATE '2026-09-16', NULL)
) AS v(chute_id, warehouse, city, route, region, sort_type, effective_date, note)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date = v.effective_date
);
