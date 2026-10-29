-- Evening chute swaps for ops day 2026-10-30.
-- 170 gets ERI01 (from 467), 220 gets BUF01 (from 516),
-- 467 gets LDJ01 (from 170), 516 gets LDJ01 (from 220).

UPDATE public.chute_destination_gofo
SET end_date = DATE '2026-10-29'
WHERE chute_id IN (170, 220, 467, 516)
  AND end_date IS NULL
  AND (effective_date IS NULL OR effective_date <= DATE '2026-10-29');

INSERT INTO public.chute_destination_gofo (
    chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type
)
SELECT v.chute_id, v.bundle_type, v.destination_warehouse, v.effective_date, v.route, v.sort_type
FROM (
    VALUES
        -- 170 ERI01
        (170, 'transit', 'EWR.H', DATE '2026-10-30', '185172.22-EWR.H-ERI01-001-H', 'by_city'),
        (170, 'transit', 'EWR.H', DATE '2026-10-30', '185173.22-EWR.H-ERI01-002-H', 'by_city'),
        (170, 'transit', 'EWR.H', DATE '2026-10-30', '185174.22-EWR.H-ERI01-004-H', 'by_city'),
        (170, 'transit', 'EWR.H', DATE '2026-10-30', '185175.22-EWR.H-ERI01-005-H', 'by_city'),
        (170, 'transit', 'EWR.H', DATE '2026-10-30', '185590.22-EWR.H-ERI01-006-H', 'by_city'),
        (170, 'transit', 'EWR.H', DATE '2026-10-30', '185676.22-EWR.H-ERI01-003-H', 'by_city'),
        -- 220 BUF01
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185153.22-EWR.H-BUF01-001-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185154.22-EWR.H-BUF01-002-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185155.22-EWR.H-BUF01-003-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185156.22-EWR.H-BUF01-004-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185157.22-EWR.H-BUF01-005-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185158.22-EWR.H-BUF01-006-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185159.22-EWR.H-BUF01-007-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185160.22-EWR.H-BUF01-008-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185161.22-EWR.H-BUF01-009-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185162.22-EWR.H-BUF01-010-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185163.22-EWR.H-BUF01-011-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185164.22-EWR.H-BUF01-012-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185165.22-EWR.H-BUF01-013-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185166.22-EWR.H-BUF01-014-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185167.22-EWR.H-BUF01-015-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185168.22-EWR.H-BUF01-016-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185169.22-EWR.H-BUF01-018-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185170.22-EWR.H-BUF01-019-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185171.22-EWR.H-BUF01-020-H', 'by_city'),
        (220, 'transit', 'EWR.H', DATE '2026-10-30', '185568.22-EWR.H-BUF01-017-H', 'by_city'),
        -- 467 LDJ01 (from 170)
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185212.22-EWR.H-LDJ01-013-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185213.22-EWR.H-LDJ01-014-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185214.22-EWR.H-LDJ01-015-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185215.22-EWR.H-LDJ01-016-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185216.22-EWR.H-LDJ01-017-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185217.22-EWR.H-LDJ01-019-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185218.22-EWR.H-LDJ01-020-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185219.22-EWR.H-LDJ01-021-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185220.22-EWR.H-LDJ01-022-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185221.22-EWR.H-LDJ01-023-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185222.22-EWR.H-LDJ01-024-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185223.22-EWR.H-LDJ01-025-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185224.22-EWR.H-LDJ01-03-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185225.22-EWR.H-LDJ01-057-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185226.22-EWR.H-LDJ01-062-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185227.22-EWR.H-LDJ01-067-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185228.22-EWR.H-LDJ01-18-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185229.22-EWR.H-LDJ01-42-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185230.22-EWR.H-LDJ01-43-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-10-30', '185231.22-EWR.H-LDJ01-44-G', 'by_city'),
        -- 516 LDJ01 (from 220)
        (516, 'transit', 'EWR.H', DATE '2026-10-30', '185232.22-EWR.H-LDJ01-45-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-10-30', '185233.22-EWR.H-LDJ01-46-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-10-30', '185234.22-EWR.H-LDJ01-47-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-10-30', '185235.22-EWR.H-LDJ01-48-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-10-30', '185236.22-EWR.H-LDJ01-49-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-10-30', '185237.22-EWR.H-LDJ01-50-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-10-30', '185238.22-EWR.H-LDJ01-51-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-10-30', '185239.22-EWR.H-LDJ01-52-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-10-30', '185240.22-EWR.H-LDJ01-53-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-10-30', '185241.22-EWR.H-LDJ01-55-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-10-30', '185242.22-EWR.H-LDJ01-56-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-10-30', '185243.22-EWR.H-LDJ01-60-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-10-30', '185244.22-EWR.H-LDJ01-61-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-10-30', '185245.22-EWR.H-LDJ01-63-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-10-30', '185246.22-EWR.H-LDJ01-64-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-10-30', '185247.22-EWR.H-LDJ01-65-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-10-30', '185248.22-EWR.H-LDJ01-66-G', 'by_city')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type)
WHERE NOT EXISTS (
    SELECT 1
    FROM public.chute_destination_gofo existing
    WHERE existing.chute_id = v.chute_id
      AND existing.effective_date IS NOT DISTINCT FROM v.effective_date
      AND existing.route IS NOT DISTINCT FROM v.route
      AND existing.sort_type IS NOT DISTINCT FROM v.sort_type
);
