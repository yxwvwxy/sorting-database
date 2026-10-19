-- New sorter map from the 2026-10-18 screenshot, chutes 152-163.
-- All transit to EWR.H. City LDJ01 is generated from the route.

INSERT INTO public.chute_destination_gofo (
  chute_id,
  bundle_type,
  destination_warehouse,
  effective_date,
  route
)
SELECT
  v.chute_id,
  v.bundle_type,
  v.destination_warehouse,
  v.effective_date,
  v.route
FROM (
  VALUES
    (152::integer, 'transit'::text, 'EWR.H'::text, DATE '2026-10-18', '185244.22-EWR.H-LDJ01-61-G'::text),
    (153, 'transit', 'EWR.H', DATE '2026-10-18', '185243.22-EWR.H-LDJ01-60-G'),
    (154, 'transit', 'EWR.H', DATE '2026-10-18', '185242.22-EWR.H-LDJ01-56-G'),
    (155, 'transit', 'EWR.H', DATE '2026-10-18', '185241.22-EWR.H-LDJ01-55-G'),
    (156, 'transit', 'EWR.H', DATE '2026-10-18', '185240.22-EWR.H-LDJ01-53-G'),
    (157, 'transit', 'EWR.H', DATE '2026-10-18', '185239.22-EWR.H-LDJ01-52-G'),
    (158, 'transit', 'EWR.H', DATE '2026-10-18', '185238.22-EWR.H-LDJ01-51-G'),
    (159, 'transit', 'EWR.H', DATE '2026-10-18', '185237.22-EWR.H-LDJ01-50-G'),
    (160, 'transit', 'EWR.H', DATE '2026-10-18', '185236.22-EWR.H-LDJ01-49-G'),
    (161, 'transit', 'EWR.H', DATE '2026-10-18', '185235.22-EWR.H-LDJ01-48-G'),
    (162, 'transit', 'EWR.H', DATE '2026-10-18', '185234.22-EWR.H-LDJ01-47-G'),
    (163, 'transit', 'EWR.H', DATE '2026-10-18', '185233.22-EWR.H-LDJ01-46-G')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date IS NOT DISTINCT FROM v.effective_date
);
