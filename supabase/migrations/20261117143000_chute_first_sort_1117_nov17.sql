-- Regular plan cutover for ops day 2026-11-17 (opens 2026-11-16 16:30 ET).
-- A/C: 第一次分拣模版-1117 (UniMap id 624).
-- Prior touched open rows end_date = 2026-11-16; new/changed rows effective_date = 2026-11-17.
-- Unchanged keep end_date null. B stays 二次分拣模版1105 (see companion migration).

UPDATE public.chute_destination_gofo
SET end_date = DATE '2026-11-16'
WHERE end_date IS NULL
  AND chute_id IN (467);

INSERT INTO public.chute_destination_gofo (
    chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type
)
SELECT v.chute_id, v.bundle_type, v.destination_warehouse, v.effective_date, v.route, v.sort_type
FROM (
    VALUES
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185212.22-EWR.H-LDJ01-013-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185213.22-EWR.H-LDJ01-014-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185214.22-EWR.H-LDJ01-015-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185215.22-EWR.H-LDJ01-016-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185216.22-EWR.H-LDJ01-017-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185217.22-EWR.H-LDJ01-019-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185218.22-EWR.H-LDJ01-020-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185219.22-EWR.H-LDJ01-021-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185220.22-EWR.H-LDJ01-022-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185221.22-EWR.H-LDJ01-023-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185222.22-EWR.H-LDJ01-024-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185223.22-EWR.H-LDJ01-025-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185224.22-EWR.H-LDJ01-03-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185228.22-EWR.H-LDJ01-18-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185229.22-EWR.H-LDJ01-42-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185230.22-EWR.H-LDJ01-43-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185231.22-EWR.H-LDJ01-44-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185685.22-EWR.H-LDJ01-030-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-17', '185686.22-EWR.H-LDJ01-033-G', 'by_city')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type)
WHERE NOT EXISTS (
    SELECT 1 FROM public.chute_destination_gofo existing
    WHERE existing.chute_id = v.chute_id
      AND existing.destination_warehouse IS NOT DISTINCT FROM v.destination_warehouse
      AND existing.effective_date IS NOT DISTINCT FROM v.effective_date
      AND existing.route IS NOT DISTINCT FROM v.route
      AND existing.sort_type IS NOT DISTINCT FROM v.sort_type
      AND existing.end_date IS NULL
);

-- touched=[467] added=[] ended=[] dest_sort=[] route_only=[467]
-- plan id=624 name=第一次分拣模版-1117
