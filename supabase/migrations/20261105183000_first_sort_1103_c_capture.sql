-- Regular plan was renamed to 第一次分拣模版1103 (UniMap id 559).
-- A/C segments use it. Cutover clock is the first stored C-segment scrape
-- on ops day 2026-11-05 (NJSUB-202611050633 at 09:10:16 ET), not the
-- 06:50 discovery stamp taken while closing B.

UPDATE public.gofo_plan_switch
SET
  switch_at = TIMESTAMPTZ '2026-11-05 09:10:16.114554-05',
  note = '458-config → 第一次分拣模版1103 (C segment first capture, ops 2026-11-05)'
WHERE ops_date = DATE '2026-11-05';

-- Live re-read of id 559 differs from the provisional 11/5 rows on these chutes.
DELETE FROM public.chute_destination_gofo
WHERE effective_date = DATE '2026-11-05'
  AND chute_id IN (367, 568, 967, 969);

INSERT INTO public.chute_destination_gofo (
    chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type
)
SELECT v.chute_id, v.bundle_type, v.destination_warehouse, v.effective_date, v.route, v.sort_type
FROM (
    VALUES
        (320, 'transit', 'JFK175', DATE '2026-11-05', '185011.21-JFK.H-JFK01-32-G', 'by_city'),
        (320, 'transit', 'JFK175', DATE '2026-11-05', '185015.21-JFK.H-JFK01-36-G', 'by_city'),
        (320, 'transit', 'JFK175', DATE '2026-11-05', '185018.21-JFK.H-JFK01-39-G', 'by_city'),
        (320, 'transit', 'JFK175', DATE '2026-11-05', '185028.21-JFK.H-LGA01-29-G', 'by_city'),
        (320, 'transit', 'JFK175', DATE '2026-11-05', '185560.21-JFK.H-LGA01-56-G', 'by_city'),
        (320, 'transit', 'JFK175', DATE '2026-11-05', '185576.21-JFK.H-JFK01-31-G', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-05', '175002.21-JFK.H-JFK01-12-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-05', '185034.21-JFK.H-LGA01-45-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-05', '185176.22-EWR.H-FRG01-51-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-05', '185182.22-EWR.H-FRG01-57-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-05', '185184.22-EWR.H-FRG01-59-U', 'by_city'),
        (568, 'transit', 'JFK175', DATE '2026-11-05', '185007.21-JFK.H-JFK01-07-U', 'by_city'),
        (568, 'transit', 'JFK175', DATE '2026-11-05', '185008.21-JFK.H-JFK01-08-U', 'by_city'),
        (568, 'transit', 'JFK175', DATE '2026-11-05', '185021.21-JFK.H-LGA01-22-U', 'by_city'),
        (568, 'transit', 'JFK175', DATE '2026-11-05', '185024.21-JFK.H-LGA01-25-U', 'by_city'),
        (568, 'transit', 'JFK175', DATE '2026-11-05', '185037.21-JFK.H-LGA01-48-U', 'by_city'),
        (568, 'transit', 'JFK175', DATE '2026-11-05', '185041.21-JFK.H-LGA01-52-U', 'by_city'),
        (967, 'transit', 'JFK175', DATE '2026-11-05', '175005.21-JFK.H-JFK01-15-U', 'by_city'),
        (967, 'transit', 'JFK175', DATE '2026-11-05', '175006.21-JFK.H-JFK01-16-U', 'by_city'),
        (967, 'transit', 'JFK175', DATE '2026-11-05', '185003.21-JFK.H-JFK01-03-U', 'by_city'),
        (967, 'transit', 'JFK175', DATE '2026-11-05', '185009.21-JFK.H-JFK01-09-U', 'by_city'),
        (967, 'transit', 'JFK175', DATE '2026-11-05', '185013.21-JFK.H-JFK01-34-U', 'by_city'),
        (967, 'transit', 'JFK175', DATE '2026-11-05', '185177.22-EWR.H-FRG01-52-U', 'by_city'),
        (967, 'transit', 'JFK175', DATE '2026-11-05', '185179.22-EWR.H-FRG01-54-U', 'by_city'),
        (967, 'transit', 'JFK175', DATE '2026-11-05', '185188.22-EWR.H-FRG01-63-U', 'by_city'),
        (967, 'transit', 'JFK175', DATE '2026-11-05', '185189.22-EWR.H-FRG01-64-U', 'by_city'),
        (969, 'transit', 'JFK175', DATE '2026-11-05', '185032.21-JFK.H-LGA01-43-U', 'by_route')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type)
WHERE NOT EXISTS (
    SELECT 1
    FROM public.chute_destination_gofo existing
    WHERE existing.chute_id = v.chute_id
      AND existing.effective_date IS NOT DISTINCT FROM v.effective_date
      AND existing.route IS NOT DISTINCT FROM v.route
      AND existing.sort_type IS NOT DISTINCT FROM v.sort_type
      AND existing.destination_warehouse IS NOT DISTINCT FROM v.destination_warehouse
);
