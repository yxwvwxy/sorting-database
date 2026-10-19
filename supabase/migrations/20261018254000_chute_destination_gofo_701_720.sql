-- New sorter map from the 2026-10-18 screenshots, chutes 701-720.
-- ATL441 and SJC449 have no individual routes, so their route is uni_hub.

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
    (701::integer, 'transit'::text, 'EWR.H'::text, DATE '2026-10-18', '185152.22-EWR.H-BOS01-045-G'::text),
    (702, 'transit', 'EWR.H', DATE '2026-10-18', '185151.22-EWR.H-BOS01-044-G'),
    (703, 'transit', 'EWR.H', DATE '2026-10-18', '185150.22-EWR.H-BOS01-043-G'),
    (704, 'transit', 'EWR.H', DATE '2026-10-18', '185149.22-EWR.H-BOS01-041-G'),
    (705, 'transit', 'EWR.H', DATE '2026-10-18', '185148.22-EWR.H-BOS01-040-G'),
    (706, 'transit', 'EWR.H', DATE '2026-10-18', '185147.22-EWR.H-BOS01-039-G'),
    (707, 'transit', 'EWR.H', DATE '2026-10-18', '185146.22-EWR.H-BOS01-035-G'),
    (708, 'transit', 'EWR.H', DATE '2026-10-18', '185145.22-EWR.H-BOS01-034-G'),
    (709, 'transit', 'EWR.H', DATE '2026-10-18', '185144.22-EWR.H-BOS01-032-G'),
    (710, 'transit', 'EWR.H', DATE '2026-10-18', '185065.22-EWR.H-ALB01-012-G'),
    (711, 'transit', 'EWR.H', DATE '2026-10-18', '185064.22-EWR.H-ALB01-011-G'),
    (712, 'transit', 'EWR.H', DATE '2026-10-18', '185063.22-EWR.H-ALB01-010-G'),
    (713, 'transit', 'EWR.H', DATE '2026-10-18', '185062.22-EWR.H-ALB01-009-G'),
    (714, 'transit', 'EWR.H', DATE '2026-10-18', '185061.22-EWR.H-ALB01-008-G'),
    (715, 'transit', 'EWR.H', DATE '2026-10-18', '185060.22-EWR.H-ALB01-007-G'),
    (716, 'transit', 'EWR.H', DATE '2026-10-18', '185565.22-EWR.H-ALB01-006-G'),
    (717, 'transit', 'ATL441', DATE '2026-10-18', 'uni_hub'),
    (718, 'transit', 'EWR.H', DATE '2026-10-18', '185248.22-EWR.H-LDJ01-66-G'),
    (719, 'transit', 'EWR.H', DATE '2026-10-18', '185247.22-EWR.H-LDJ01-65-G'),
    (720, 'transit', 'SJC449', DATE '2026-10-18', 'uni_hub')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route IS NOT DISTINCT FROM v.route
    AND d.effective_date IS NOT DISTINCT FROM v.effective_date
);
