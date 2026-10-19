-- New sorter map from the 2026-10-18 screenshots, chutes 551-570.
-- IAH320 and SEA662 are hub warehouses, so their route is uni_hub.

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
    (551::integer, 'transit'::text, 'EWR.H'::text, DATE '2026-10-18', '185122.22-EWR.H-BOS01-008-G'::text),
    (552, 'transit', 'EWR.H', DATE '2026-10-18', '185121.22-EWR.H-BOS01-007-G'),
    (553, 'transit', 'EWR.H', DATE '2026-10-18', '185120.22-EWR.H-BOS01-005-G'),
    (554, 'transit', 'EWR.H', DATE '2026-10-18', '185119.22-EWR.H-BOS01-004-G'),
    (555, 'transit', 'EWR.H', DATE '2026-10-18', '185118.22-EWR.H-BOS01-003-G'),
    (556, 'transit', 'EWR.H', DATE '2026-10-18', '185117.22-EWR.H-BOS01-002-G'),
    (557, 'transit', 'EWR.H', DATE '2026-10-18', '185116.22-EWR.H-BOS01-001-G'),
    (558, 'transit', 'EWR.H', DATE '2026-10-18', '185055.22-EWR.H-ABE01-075-G'),
    (559, 'transit', 'EWR.H', DATE '2026-10-18', '185054.22-EWR.H-ABE01-074-G'),
    (560, 'transit', 'EWR.H', DATE '2026-10-18', '185053.22-EWR.H-ABE01-073-G'),
    (561, 'transit', 'EWR.H', DATE '2026-10-18', '185583.22-EWR.H-ABE01-015-G'),
    (562, 'transit', 'EWR.H', DATE '2026-10-18', '185582.22-EWR.H-ABE01-014-G'),
    (563, 'transit', 'EWR.H', DATE '2026-10-18', '185052.22-EWR.H-ABE01-013-G'),
    (564, 'transit', 'EWR.H', DATE '2026-10-18', '185051.22-EWR.H-ABE01-012-G'),
    (565, 'transit', 'EWR.H', DATE '2026-10-18', '185050.22-EWR.H-ABE01-011-G'),
    (566, 'transit', 'EWR.H', DATE '2026-10-18', '185049.22-EWR.H-ABE01-010-G'),
    (567, 'transit', 'EWR.H', DATE '2026-10-18', '185048.22-EWR.H-ABE01-009-G'),
    (568, 'transit', 'EWR.H', DATE '2026-10-18', '185056.22-EWR.H-ABE01-090-G'),
    (569, 'transit', 'IAH320', DATE '2026-10-18', 'uni_hub'),
    (570, 'transit', 'SEA662', DATE '2026-10-18', 'uni_hub')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route IS NOT DISTINCT FROM v.route
    AND d.effective_date IS NOT DISTINCT FROM v.effective_date
);
