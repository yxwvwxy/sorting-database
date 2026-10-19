-- New sorter map from the 2026-10-18 screenshots, chutes 601-618 and 620.
-- IAH320 and ORD184 are hub warehouses, so their route is uni_hub.

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
    (601::integer, 'transit'::text, 'EWR.H'::text, DATE '2026-10-18', '185129.22-EWR.H-BOS01-016-G'::text),
    (602, 'transit', 'EWR.H', DATE '2026-10-18', '185128.22-EWR.H-BOS01-015-G'),
    (603, 'transit', 'EWR.H', DATE '2026-10-18', '185127.22-EWR.H-BOS01-014-G'),
    (604, 'transit', 'EWR.H', DATE '2026-10-18', '185126.22-EWR.H-BOS01-013-G'),
    (605, 'transit', 'EWR.H', DATE '2026-10-18', '185125.22-EWR.H-BOS01-012-G'),
    (606, 'transit', 'EWR.H', DATE '2026-10-18', '185124.22-EWR.H-BOS01-011-G'),
    (607, 'transit', 'EWR.H', DATE '2026-10-18', '185123.22-EWR.H-BOS01-010-G'),
    (608, 'transit', 'EWR.H', DATE '2026-10-18', '185047.22-EWR.H-ABE01-008-G'),
    (609, 'transit', 'EWR.H', DATE '2026-10-18', '185046.22-EWR.H-ABE01-007-G'),
    (610, 'transit', 'EWR.H', DATE '2026-10-18', '185045.22-EWR.H-ABE01-006-G'),
    (611, 'transit', 'EWR.H', DATE '2026-10-18', '185581.22-EWR.H-ABE01-005-G'),
    (612, 'transit', 'EWR.H', DATE '2026-10-18', '185580.22-EWR.H-ABE01-004-G'),
    (613, 'transit', 'EWR.H', DATE '2026-10-18', '185579.22-EWR.H-ABE01-003-G'),
    (614, 'transit', 'EWR.H', DATE '2026-10-18', '185578.22-EWR.H-ABE01-002-G'),
    (615, 'transit', 'EWR.H', DATE '2026-10-18', '185058.22-EWR.H-ABE01-092-G'),
    (616, 'transit', 'EWR.H', DATE '2026-10-18', '185057.22-EWR.H-ABE01-091-G'),
    (617, 'transit', 'EWR.H', DATE '2026-10-18', '185577.22-EWR.H-ABE01-001-G'),
    (618, 'transit', 'IAH320', DATE '2026-10-18', 'uni_hub'),
    (620, 'transit', 'ORD184', DATE '2026-10-18', 'uni_hub')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route IS NOT DISTINCT FROM v.route
    AND d.effective_date IS NOT DISTINCT FROM v.effective_date
);
