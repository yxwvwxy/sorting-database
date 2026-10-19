-- New sorter map from the 2026-10-18 screenshots.
-- ORD184 and DFW445 are hub warehouses, so their route is uni_hub.

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
    (420::integer, 'transit'::text, 'ORD184'::text, DATE '2026-10-18', 'uni_hub'::text),
    (451, 'transit', 'EWR.H', DATE '2026-10-18', '185087.22-EWR.H-BDL01-30-G'),
    (452, 'transit', 'EWR.H', DATE '2026-10-18', '185086.22-EWR.H-BDL01-12-G'),
    (453, 'transit', 'EWR.H', DATE '2026-10-18', '185085.22-EWR.H-BDL01-10-G'),
    (454, 'transit', 'EWR.H', DATE '2026-10-18', '185084.22-EWR.H-BDL01-09-G'),
    (455, 'transit', 'EWR.H', DATE '2026-10-18', '185083.22-EWR.H-BDL01-07-G'),
    (456, 'transit', 'EWR.H', DATE '2026-10-18', '185082.22-EWR.H-BDL01-06-G'),
    (457, 'transit', 'EWR.H', DATE '2026-10-18', '185081.22-EWR.H-BDL01-05-G'),
    (458, 'transit', 'EWR.H', DATE '2026-10-18', '185080.22-EWR.H-BDL01-04-G'),
    (459, 'transit', 'EWR.H', DATE '2026-10-18', '185079.22-EWR.H-BDL01-03-G'),
    (460, 'transit', 'EWR.H', DATE '2026-10-18', '185078.22-EWR.H-BDL01-029-G'),
    (461, 'transit', 'EWR.H', DATE '2026-10-18', '185077.22-EWR.H-BDL01-026-G'),
    (462, 'transit', 'EWR.H', DATE '2026-10-18', '185076.22-EWR.H-BDL01-025-G'),
    (463, 'transit', 'EWR.H', DATE '2026-10-18', '185075.22-EWR.H-BDL01-024-G'),
    (464, 'transit', 'EWR.H', DATE '2026-10-18', '185074.22-EWR.H-BDL01-01-G'),
    (465, 'transit', 'EWR.H', DATE '2026-10-18', '185073.22-EWR.H-BDL01-002-G'),
    (466, 'transit', 'EWR.H', DATE '2026-10-18', '185172.22-EWR.H-ERI01-001-H'),
    (466, 'transit', 'EWR.H', DATE '2026-10-18', '185173.22-EWR.H-ERI01-002-H'),
    (466, 'transit', 'EWR.H', DATE '2026-10-18', '185174.22-EWR.H-ERI01-004-H'),
    (466, 'transit', 'EWR.H', DATE '2026-10-18', '185175.22-EWR.H-ERI01-005-H'),
    (466, 'transit', 'EWR.H', DATE '2026-10-18', '185590.22-EWR.H-ERI01-006-H'),
    (466, 'transit', 'EWR.H', DATE '2026-10-18', '185676.22-EWR.H-ERI01-003-H'),
    (468, 'transit', 'DFW445', DATE '2026-10-18', 'uni_hub'),
    (470, 'transit', 'ORD184', DATE '2026-10-18', 'uni_hub')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route IS NOT DISTINCT FROM v.route
    AND d.effective_date IS NOT DISTINCT FROM v.effective_date
);
