-- New sorter map from the 2026-10-18 screenshots, chutes 651-670.
-- ORD184 is a hub warehouse. ATL441 has no individual routes on the screenshot,
-- so it is stored the same way, with route uni_hub.

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
    (651::integer, 'transit'::text, 'EWR.H'::text, DATE '2026-10-18', '185143.22-EWR.H-BOS01-031-G'::text),
    (652, 'transit', 'EWR.H', DATE '2026-10-18', '185142.22-EWR.H-BOS01-030-G'),
    (653, 'transit', 'EWR.H', DATE '2026-10-18', '185141.22-EWR.H-BOS01-029-G'),
    (654, 'transit', 'EWR.H', DATE '2026-10-18', '185140.22-EWR.H-BOS01-028-G'),
    (655, 'transit', 'EWR.H', DATE '2026-10-18', '185139.22-EWR.H-BOS01-027-G'),
    (656, 'transit', 'EWR.H', DATE '2026-10-18', '185138.22-EWR.H-BOS01-026-G'),
    (657, 'transit', 'EWR.H', DATE '2026-10-18', '185137.22-EWR.H-BOS01-025-G'),
    (658, 'transit', 'EWR.H', DATE '2026-10-18', '185136.22-EWR.H-BOS01-024-G'),
    (659, 'transit', 'EWR.H', DATE '2026-10-18', '185135.22-EWR.H-BOS01-023-G'),
    (660, 'transit', 'EWR.H', DATE '2026-10-18', '185134.22-EWR.H-BOS01-022-G'),
    (661, 'transit', 'EWR.H', DATE '2026-10-18', '185133.22-EWR.H-BOS01-021-G'),
    (662, 'transit', 'EWR.H', DATE '2026-10-18', '185132.22-EWR.H-BOS01-020-G'),
    (663, 'transit', 'EWR.H', DATE '2026-10-18', '185131.22-EWR.H-BOS01-018-G'),
    (664, 'transit', 'EWR.H', DATE '2026-10-18', '185130.22-EWR.H-BOS01-017-G'),
    (665, 'transit', 'EWR.H', DATE '2026-10-18', '185589.22-EWR.H-BOS01-033-G'),
    (666, 'transit', 'EWR.H', DATE '2026-10-18', '185205.22-EWR.H-HYA01-001-H'),
    (666, 'transit', 'EWR.H', DATE '2026-10-18', '185206.22-EWR.H-HYA01-002-H'),
    (666, 'transit', 'EWR.H', DATE '2026-10-18', '185207.22-EWR.H-HYA01-005-H'),
    (666, 'transit', 'EWR.H', DATE '2026-10-18', '185208.22-EWR.H-HYA01-006-H'),
    (666, 'transit', 'EWR.H', DATE '2026-10-18', '185209.22-EWR.H-HYA01-007-H'),
    (666, 'transit', 'EWR.H', DATE '2026-10-18', '185210.22-EWR.H-HYA01-008-H'),
    (666, 'transit', 'EWR.H', DATE '2026-10-18', '185211.22-EWR.H-HYA01-010-H'),
    (666, 'transit', 'EWR.H', DATE '2026-10-18', '185569.22-EWR.H-HYA01-009-H'),
    (666, 'transit', 'EWR.H', DATE '2026-10-18', '185681.22-EWR.H-HYA01-003-H'),
    (667, 'transit', 'EWR.H', DATE '2026-10-18', '185374.22-EWR.H-ROC01-008-H'),
    (667, 'transit', 'EWR.H', DATE '2026-10-18', '185375.22-EWR.H-ROC01-01-H'),
    (667, 'transit', 'EWR.H', DATE '2026-10-18', '185376.22-EWR.H-ROC01-010-H'),
    (667, 'transit', 'EWR.H', DATE '2026-10-18', '185377.22-EWR.H-ROC01-011-H'),
    (667, 'transit', 'EWR.H', DATE '2026-10-18', '185378.22-EWR.H-ROC01-012-H'),
    (667, 'transit', 'EWR.H', DATE '2026-10-18', '185379.22-EWR.H-ROC01-02-H'),
    (667, 'transit', 'EWR.H', DATE '2026-10-18', '185380.22-EWR.H-ROC01-020-H'),
    (667, 'transit', 'EWR.H', DATE '2026-10-18', '185381.22-EWR.H-ROC01-03-H'),
    (667, 'transit', 'EWR.H', DATE '2026-10-18', '185382.22-EWR.H-ROC01-05-H'),
    (667, 'transit', 'EWR.H', DATE '2026-10-18', '185383.22-EWR.H-ROC01-06-H'),
    (667, 'transit', 'EWR.H', DATE '2026-10-18', '185384.22-EWR.H-ROC01-13-H'),
    (667, 'transit', 'EWR.H', DATE '2026-10-18', '185385.22-EWR.H-ROC01-14-H'),
    (667, 'transit', 'EWR.H', DATE '2026-10-18', '185386.22-EWR.H-ROC01-15-H'),
    (667, 'transit', 'EWR.H', DATE '2026-10-18', '185387.22-EWR.H-ROC01-16-H'),
    (667, 'transit', 'EWR.H', DATE '2026-10-18', '185388.22-EWR.H-ROC01-17-H'),
    (667, 'transit', 'EWR.H', DATE '2026-10-18', '185389.22-EWR.H-ROC01-18-H'),
    (667, 'transit', 'EWR.H', DATE '2026-10-18', '185641.22-EWR.H-ROC01-007-H'),
    (667, 'transit', 'EWR.H', DATE '2026-10-18', '185670.22-EWR.H-ROC01-021-H'),
    (668, 'transit', 'ATL441', DATE '2026-10-18', 'uni_hub'),
    (669, 'transit', 'EWR.H', DATE '2026-10-18', '185246.22-EWR.H-LDJ01-64-G'),
    (670, 'transit', 'ORD184', DATE '2026-10-18', 'uni_hub')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route IS NOT DISTINCT FROM v.route
    AND d.effective_date IS NOT DISTINCT FROM v.effective_date
);
