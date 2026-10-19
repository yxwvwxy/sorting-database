-- New sorter map from the 2026-10-18 screenshots, chutes 869, 870, and 901-920.
-- LAX489 and ATL441 have no individual routes, so their route is uni_hub.
-- 910 suffix is 01, not 001.

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
    (869::integer, 'transit'::text, 'LAX489'::text, DATE '2026-10-18', 'uni_hub'::text),
    (870, 'transit', 'ATL441', DATE '2026-10-18', 'uni_hub'),
    (901, 'transit', 'EWR.H', DATE '2026-10-18', '185647.22-EWR.H-SWF01-023-G'),
    (902, 'transit', 'EWR.H', DATE '2026-10-18', '185646.22-EWR.H-SWF01-022-G'),
    (903, 'transit', 'EWR.H', DATE '2026-10-18', '185396.22-EWR.H-SWF01-020-G'),
    (904, 'transit', 'EWR.H', DATE '2026-10-18', '185645.22-EWR.H-SWF01-019-G'),
    (905, 'transit', 'EWR.H', DATE '2026-10-18', '185395.22-EWR.H-SWF01-018-G'),
    (906, 'transit', 'EWR.H', DATE '2026-10-18', '185394.22-EWR.H-SWF01-016-G'),
    (907, 'transit', 'EWR.H', DATE '2026-10-18', '185644.22-EWR.H-SWF01-014-G'),
    (908, 'transit', 'EWR.H', DATE '2026-10-18', '185393.22-EWR.H-SWF01-011-G'),
    (909, 'transit', 'EWR.H', DATE '2026-10-18', '185392.22-EWR.H-SWF01-010-G'),
    (910, 'transit', 'EWR.H', DATE '2026-10-18', '185643.22-EWR.H-SWF01-01-G'),
    (911, 'transit', 'EWR.H', DATE '2026-10-18', '185642.22-EWR.H-SWF01-009-G'),
    (912, 'transit', 'EWR.H', DATE '2026-10-18', '185391.22-EWR.H-SWF01-007-G'),
    (913, 'transit', 'EWR.H', DATE '2026-10-18', '185390.22-EWR.H-SWF01-002-G'),
    (914, 'transit', 'EWR.H', DATE '2026-10-18', '185072.22-EWR.H-ALB01-099-G'),
    (915, 'transit', 'EWR.H', DATE '2026-10-18', '185071.22-EWR.H-ALB01-098-G'),
    (916, 'transit', 'EWR.H', DATE '2026-10-18', '185059.22-EWR.H-ALB01-002-G'),
    (917, 'transit', 'EWR.H', DATE '2026-10-18', '185404.22-EWR.H-SYR01-001-H'),
    (917, 'transit', 'EWR.H', DATE '2026-10-18', '185405.22-EWR.H-SYR01-002-H'),
    (917, 'transit', 'EWR.H', DATE '2026-10-18', '185406.22-EWR.H-SYR01-003-H'),
    (917, 'transit', 'EWR.H', DATE '2026-10-18', '185407.22-EWR.H-SYR01-004-H'),
    (917, 'transit', 'EWR.H', DATE '2026-10-18', '185408.22-EWR.H-SYR01-005-H'),
    (917, 'transit', 'EWR.H', DATE '2026-10-18', '185409.22-EWR.H-SYR01-006-H'),
    (917, 'transit', 'EWR.H', DATE '2026-10-18', '185410.22-EWR.H-SYR01-007-H'),
    (917, 'transit', 'EWR.H', DATE '2026-10-18', '185411.22-EWR.H-SYR01-010-H'),
    (917, 'transit', 'EWR.H', DATE '2026-10-18', '185412.22-EWR.H-SYR01-011-H'),
    (917, 'transit', 'EWR.H', DATE '2026-10-18', '185413.22-EWR.H-SYR01-014-H'),
    (917, 'transit', 'EWR.H', DATE '2026-10-18', '185414.22-EWR.H-SYR01-015-H'),
    (917, 'transit', 'EWR.H', DATE '2026-10-18', '185650.22-EWR.H-SYR01-008-H'),
    (917, 'transit', 'EWR.H', DATE '2026-10-18', '185651.22-EWR.H-SYR01-009-H'),
    (917, 'transit', 'EWR.H', DATE '2026-10-18', '185652.22-EWR.H-SYR01-012-H'),
    (917, 'transit', 'EWR.H', DATE '2026-10-18', '185653.22-EWR.H-SYR01-013-H'),
    (917, 'transit', 'EWR.H', DATE '2026-10-18', '185654.22-EWR.H-SYR01-020-H'),
    (918, 'transit', 'ATL441', DATE '2026-10-18', 'uni_hub'),
    (919, 'transit', 'ATL441', DATE '2026-10-18', 'uni_hub'),
    (920, 'transit', 'ATL441', DATE '2026-10-18', 'uni_hub')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route IS NOT DISTINCT FROM v.route
    AND d.effective_date IS NOT DISTINCT FROM v.effective_date
);
