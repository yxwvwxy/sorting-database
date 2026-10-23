-- 1021-gofo additions on chutes 420 and 620, same ops-day batch as the 2026-10-23 plan.
-- The 6:10pm scrape on 2026-10-22 is still ops day 2026-10-22. These rows start 2026-10-23.
-- 420 keeps ORD184 uni_hub and adds the ORD02 routes. 620 keeps ORD184 uni_hub and adds LEX01-010.

UPDATE public.chute_destination_gofo
SET end_date = DATE '2026-10-22'
WHERE chute_id IN (420, 620)
  AND end_date IS NULL
  AND effective_date <= DATE '2026-10-22';

INSERT INTO public.chute_destination_gofo (
    chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type
)
SELECT v.chute_id, v.bundle_type, v.destination_warehouse, v.effective_date, v.route, v.sort_type
FROM (
    VALUES
        (420, 'transit', 'ORD184', DATE '2026-10-23', NULL::text, 'uni_hub'),
        (620, 'transit', 'ORD184', DATE '2026-10-23', NULL::text, 'uni_hub'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125386.31-ORD.H-ORD02-053-G', 'by_city'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125387.31-ORD.H-ORD02-011-G', 'by_city'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125388.31-ORD.H-ORD02-003-G', 'by_city'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125389.31-ORD.H-ORD02-055-G', 'by_city'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125390.31-ORD.H-ORD02-012-G', 'by_city'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125391.31-ORD.H-ORD02-002-G', 'by_city'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125392.31-ORD.H-ORD02-004-G', 'by_city'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125393.31-ORD.H-ORD02-001-G', 'by_city'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125394.31-ORD.H-ORD02-086-G', 'by_city'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125395.31-ORD.H-ORD02-089-G', 'by_city'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125396.31-ORD.H-ORD02-006-G', 'by_city'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125397.31-ORD.H-ORD02-095-G', 'by_city'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125398.31-ORD.H-ORD02-087-G', 'by_city'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125399.31-ORD.H-ORD02-075-G', 'by_city'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125400.31-ORD.H-ORD02-088-G', 'by_city'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125401.31-ORD.H-ORD02-085-G', 'by_city'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125402.31-ORD.H-ORD02-080-G', 'by_city'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125403.31-ORD.H-ORD02-090-G', 'by_city'),
        (420, 'transit', 'ORD.H', DATE '2026-10-23', '125404.31-ORD.H-ORD02-078-G', 'by_city'),
        (620, 'transit', 'IND.H', DATE '2026-10-23', '125385.33-IND.H-LEX01-010-H', 'by_city')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type)
WHERE NOT EXISTS (
    SELECT 1
    FROM public.chute_destination_gofo existing
    WHERE existing.chute_id = v.chute_id
      AND existing.effective_date IS NOT DISTINCT FROM v.effective_date
      AND existing.route IS NOT DISTINCT FROM v.route
      AND existing.sort_type IS NOT DISTINCT FROM v.sort_type
);
