-- New sorter map from the 2026-10-18 screenshots, chutes 501-516 and 518-520.
-- DFW445, SLC260, and ORD184 are hub warehouses, so their route is uni_hub.

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
    (501::integer, 'transit'::text, 'EWR.H'::text, DATE '2026-10-18', '185462.22-EWR.H-TEB01-51-G'::text),
    (502, 'transit', 'EWR.H', DATE '2026-10-18', '185461.22-EWR.H-TEB01-50-G'),
    (503, 'transit', 'EWR.H', DATE '2026-10-18', '185460.22-EWR.H-TEB01-49-G'),
    (504, 'transit', 'EWR.H', DATE '2026-10-18', '185459.22-EWR.H-TEB01-48-G'),
    (505, 'transit', 'EWR.H', DATE '2026-10-18', '185458.22-EWR.H-TEB01-47-G'),
    (506, 'transit', 'EWR.H', DATE '2026-10-18', '185457.22-EWR.H-TEB01-46-G'),
    (507, 'transit', 'EWR.H', DATE '2026-10-18', '185456.22-EWR.H-TEB01-45-G'),
    (508, 'transit', 'EWR.H', DATE '2026-10-18', '185455.22-EWR.H-TEB01-44-G'),
    (509, 'transit', 'EWR.H', DATE '2026-10-18', '185454.22-EWR.H-TEB01-43-G'),
    (510, 'transit', 'EWR.H', DATE '2026-10-18', '185453.22-EWR.H-TEB01-42-G'),
    (511, 'transit', 'EWR.H', DATE '2026-10-18', '185452.22-EWR.H-TEB01-41-G'),
    (512, 'transit', 'EWR.H', DATE '2026-10-18', '185655.22-EWR.H-TEB01-40-G'),
    (513, 'transit', 'EWR.H', DATE '2026-10-18', '185451.22-EWR.H-TEB01-39-G'),
    (514, 'transit', 'EWR.H', DATE '2026-10-18', '185585.22-EWR.H-ALB01-005-G'),
    (515, 'transit', 'EWR.H', DATE '2026-10-18', '185584.22-EWR.H-ALB01-004-G'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185153.22-EWR.H-BUF01-001-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185154.22-EWR.H-BUF01-002-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185155.22-EWR.H-BUF01-003-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185156.22-EWR.H-BUF01-004-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185157.22-EWR.H-BUF01-005-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185158.22-EWR.H-BUF01-006-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185159.22-EWR.H-BUF01-007-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185160.22-EWR.H-BUF01-008-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185161.22-EWR.H-BUF01-009-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185162.22-EWR.H-BUF01-010-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185163.22-EWR.H-BUF01-011-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185164.22-EWR.H-BUF01-012-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185165.22-EWR.H-BUF01-013-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185166.22-EWR.H-BUF01-014-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185167.22-EWR.H-BUF01-015-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185168.22-EWR.H-BUF01-016-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185169.22-EWR.H-BUF01-018-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185170.22-EWR.H-BUF01-019-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185171.22-EWR.H-BUF01-020-H'),
    (516, 'transit', 'EWR.H', DATE '2026-10-18', '185568.22-EWR.H-BUF01-017-H'),
    (518, 'transit', 'DFW445', DATE '2026-10-18', 'uni_hub'),
    (519, 'transit', 'SLC260', DATE '2026-10-18', 'uni_hub'),
    (520, 'transit', 'ORD184', DATE '2026-10-18', 'uni_hub')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route IS NOT DISTINCT FROM v.route
    AND d.effective_date IS NOT DISTINCT FROM v.effective_date
);
