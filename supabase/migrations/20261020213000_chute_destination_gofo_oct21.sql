-- Evening of 2026-10-20 starts ops day 2026-10-21
-- (NJSUB-202610201900 → subbatch_date 2026-10-21).
-- Old settings remain current through ops day 2026-10-20.
-- Chutes with a new plan get rows effective 2026-10-21.
-- Chutes 267, 514, 860, 914, 915, 916 have no successor.

UPDATE public.chute_destination_gofo
SET end_date = DATE '2026-10-20'
WHERE effective_date = DATE '2026-10-18'
  AND chute_id IN (
    267, 514, 515, 665,
    710, 711, 712, 713, 714, 715, 716,
    860, 861, 862, 863, 864, 865, 866,
    914, 915, 916
  );

INSERT INTO public.chute_destination_gofo (
  chute_id,
  bundle_type,
  destination_warehouse,
  effective_date,
  route,
  sort_type
)
SELECT
  v.chute_id,
  v.bundle_type,
  v.destination_warehouse,
  v.effective_date,
  v.route,
  v.sort_type
FROM (
  VALUES
    (515::integer, 'transit'::text, 'EWR.H'::text, DATE '2026-10-21', '185183.22-EWR.H-FRG01-58-U'::text, 'by_route'::text),
    (665, 'transit', 'EWR.H', DATE '2026-10-21', '185059.22-EWR.H-ALB01-002-G', 'by_city'),
    (665, 'transit', 'EWR.H', DATE '2026-10-21', '185060.22-EWR.H-ALB01-007-G', 'by_city'),
    (665, 'transit', 'EWR.H', DATE '2026-10-21', '185061.22-EWR.H-ALB01-008-G', 'by_city'),
    (665, 'transit', 'EWR.H', DATE '2026-10-21', '185062.22-EWR.H-ALB01-009-G', 'by_city'),
    (665, 'transit', 'EWR.H', DATE '2026-10-21', '185063.22-EWR.H-ALB01-010-G', 'by_city'),
    (665, 'transit', 'EWR.H', DATE '2026-10-21', '185064.22-EWR.H-ALB01-011-G', 'by_city'),
    (665, 'transit', 'EWR.H', DATE '2026-10-21', '185065.22-EWR.H-ALB01-012-G', 'by_city'),
    (665, 'transit', 'EWR.H', DATE '2026-10-21', '185066.22-EWR.H-ALB01-013-G', 'by_city'),
    (665, 'transit', 'EWR.H', DATE '2026-10-21', '185067.22-EWR.H-ALB01-014-G', 'by_city'),
    (665, 'transit', 'EWR.H', DATE '2026-10-21', '185068.22-EWR.H-ALB01-015-G', 'by_city'),
    (710, 'transit', 'EWR.H', DATE '2026-10-21', '185589.22-EWR.H-BOS01-033-G', 'by_route'),
    (711, 'transit', 'EWR.H', DATE '2026-10-21', '185669.22-EWR.H-AVP01-005-H', 'by_route'),
    (712, 'transit', 'EWR.H', DATE '2026-10-21', '185666.22-EWR.H-AVP01-004-H', 'by_route'),
    (713, 'transit', 'EWR.H', DATE '2026-10-21', '185673.22-EWR.H-AVP01-003-H', 'by_route'),
    (714, 'transit', 'EWR.H', DATE '2026-10-21', '185671.22-EWR.H-AVP01-002-H', 'by_route'),
    (715, 'transit', 'EWR.H', DATE '2026-10-21', '185674.22-EWR.H-AVP01-001-H', 'by_route'),
    (716, 'transit', 'EWR.H', DATE '2026-10-21', '185069.22-EWR.H-ALB01-016-G', 'by_city'),
    (716, 'transit', 'EWR.H', DATE '2026-10-21', '185070.22-EWR.H-ALB01-097-G', 'by_city'),
    (716, 'transit', 'EWR.H', DATE '2026-10-21', '185071.22-EWR.H-ALB01-098-G', 'by_city'),
    (716, 'transit', 'EWR.H', DATE '2026-10-21', '185072.22-EWR.H-ALB01-099-G', 'by_city'),
    (716, 'transit', 'EWR.H', DATE '2026-10-21', '185565.22-EWR.H-ALB01-006-G', 'by_city'),
    (716, 'transit', 'EWR.H', DATE '2026-10-21', '185566.22-EWR.H-ALB01-017-G', 'by_city'),
    (716, 'transit', 'EWR.H', DATE '2026-10-21', '185584.22-EWR.H-ALB01-004-G', 'by_city'),
    (716, 'transit', 'EWR.H', DATE '2026-10-21', '185585.22-EWR.H-ALB01-005-G', 'by_city'),
    (716, 'transit', 'EWR.H', DATE '2026-10-21', '185586.22-EWR.H-ALB01-018-G', 'by_city'),
    (861, 'transit', 'EWR.H', DATE '2026-10-21', '185667.22-EWR.H-AVP01-012-H', 'by_route'),
    (862, 'transit', 'EWR.H', DATE '2026-10-21', '185678.22-EWR.H-AVP01-010-H', 'by_route'),
    (863, 'transit', 'EWR.H', DATE '2026-10-21', '185675.22-EWR.H-AVP01-020-H', 'by_route'),
    (864, 'transit', 'EWR.H', DATE '2026-10-21', '185679.22-EWR.H-AVP01-008-H', 'by_route'),
    (865, 'transit', 'EWR.H', DATE '2026-10-21', '185677.22-EWR.H-AVP01-007-H', 'by_route'),
    (866, 'transit', 'EWR.H', DATE '2026-10-21', '185668.22-EWR.H-AVP01-006-H', 'by_route')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date = v.effective_date
);
