-- New sorter map from the 2026-10-18 configuration screenshot, chutes 101-111.
-- effective_date 2026-10-18 so ops day NJSUB-202610171930 maps these slots.

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
    (101::integer, 'transit'::text, 'EWR.H'::text, DATE '2026-10-18', '185226.22-EWR.H-LDJ01-062-G'::text),
    (102, 'transit', 'EWR.H', DATE '2026-10-18', '185225.22-EWR.H-LDJ01-057-G'),
    (103, 'transit', 'EWR.H', DATE '2026-10-18', '185224.22-EWR.H-LDJ01-03-G'),
    (104, 'transit', 'EWR.H', DATE '2026-10-18', '185223.22-EWR.H-LDJ01-025-G'),
    (105, 'transit', 'EWR.H', DATE '2026-10-18', '185222.22-EWR.H-LDJ01-024-G'),
    (106, 'transit', 'EWR.H', DATE '2026-10-18', '185221.22-EWR.H-LDJ01-023-G'),
    (107, 'transit', 'EWR.H', DATE '2026-10-18', '185220.22-EWR.H-LDJ01-022-G'),
    (108, 'transit', 'EWR.H', DATE '2026-10-18', '185219.22-EWR.H-LDJ01-021-G'),
    (109, 'transit', 'EWR.H', DATE '2026-10-18', '185218.22-EWR.H-LDJ01-020-G'),
    (110, 'transit', 'EWR.H', DATE '2026-10-18', '185217.22-EWR.H-LDJ01-019-G'),
    (111, 'transit', 'EWR.H', DATE '2026-10-18', '185216.22-EWR.H-LDJ01-017-G')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date IS NOT DISTINCT FROM v.effective_date
);
