-- New sorter map from the 2026-10-18 screenshot, chutes 164-170 and 201-205.
-- Chute 170 is transit to BWI.H with seven ORF01 routes.

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
    (164::integer, 'transit'::text, 'EWR.H'::text, DATE '2026-10-18', '185232.22-EWR.H-LDJ01-45-G'::text),
    (165, 'transit', 'EWR.H', DATE '2026-10-18', '185231.22-EWR.H-LDJ01-44-G'),
    (166, 'transit', 'EWR.H', DATE '2026-10-18', '185230.22-EWR.H-LDJ01-43-G'),
    (167, 'transit', 'EWR.H', DATE '2026-10-18', '185229.22-EWR.H-LDJ01-42-G'),
    (168, 'transit', 'EWR.H', DATE '2026-10-18', '185228.22-EWR.H-LDJ01-18-G'),
    (169, 'transit', 'EWR.H', DATE '2026-10-18', '185227.22-EWR.H-LDJ01-067-G'),
    (170, 'transit', 'BWI.H', DATE '2026-10-18', '185531.25-BWI.H-ORF01-041-H'),
    (170, 'transit', 'BWI.H', DATE '2026-10-18', '185532.25-BWI.H-ORF01-042-H'),
    (170, 'transit', 'BWI.H', DATE '2026-10-18', '185533.25-BWI.H-ORF01-043-H'),
    (170, 'transit', 'BWI.H', DATE '2026-10-18', '185534.25-BWI.H-ORF01-044-H'),
    (170, 'transit', 'BWI.H', DATE '2026-10-18', '185535.25-BWI.H-ORF01-045-H'),
    (170, 'transit', 'BWI.H', DATE '2026-10-18', '185536.25-BWI.H-ORF01-046-H'),
    (170, 'transit', 'BWI.H', DATE '2026-10-18', '185537.25-BWI.H-ORF01-047-H'),
    (201, 'transit', 'EWR.H', DATE '2026-10-18', '185373.22-EWR.H-PVD01-022-G'),
    (202, 'transit', 'EWR.H', DATE '2026-10-18', '185372.22-EWR.H-PVD01-021-G'),
    (203, 'transit', 'EWR.H', DATE '2026-10-18', '185371.22-EWR.H-PVD01-020-G'),
    (204, 'transit', 'EWR.H', DATE '2026-10-18', '185370.22-EWR.H-PVD01-019-G'),
    (205, 'transit', 'EWR.H', DATE '2026-10-18', '185369.22-EWR.H-PVD01-018-G')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date IS NOT DISTINCT FROM v.effective_date
);
