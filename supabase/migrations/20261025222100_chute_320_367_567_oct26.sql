-- Live 1021-Gofo plan, saved 2026-10-25 18:21 ET. The 19:30 switch
-- opens ops day 2026-10-26, so these route moves start that day.
-- 470 ORD184, 518 DFW445, and 1020 MIA307 stay uni_hub. Only their
-- routes changed, and uni_hub rows do not store routes.

UPDATE public.chute_destination_gofo
SET end_date = DATE '2026-10-25'
WHERE chute_id IN (320, 367, 567)
  AND end_date IS NULL
  AND (effective_date IS NULL OR effective_date <= DATE '2026-10-25');

INSERT INTO public.chute_destination_gofo (
    chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type
)
SELECT v.chute_id, v.bundle_type, v.destination_warehouse, v.effective_date, v.route, v.sort_type
FROM (
    VALUES
        (320, 'transit', 'JFK175', DATE '2026-10-26', '185187.22-EWR.H-FRG01-62-U', 'by_city'),
        (320, 'transit', 'JFK175', DATE '2026-10-26', '185194.22-EWR.H-FRG01-69-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-10-26', '175002.21-JFK.H-JFK01-12-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-10-26', '175005.21-JFK.H-JFK01-15-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-10-26', '175006.21-JFK.H-JFK01-16-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-10-26', '185011.21-JFK.H-JFK01-32-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-10-26', '185013.21-JFK.H-JFK01-34-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-10-26', '185015.21-JFK.H-JFK01-36-G', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-10-26', '185018.21-JFK.H-JFK01-39-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-10-26', '185576.21-JFK.H-JFK01-31-G', 'by_city'),
        (567, 'transit', 'JFK175', DATE '2026-10-26', '185185.22-EWR.H-FRG01-60-U', 'by_city'),
        (567, 'transit', 'JFK175', DATE '2026-10-26', '185186.22-EWR.H-FRG01-61-U', 'by_city'),
        (567, 'transit', 'JFK175', DATE '2026-10-26', '185188.22-EWR.H-FRG01-63-U', 'by_city'),
        (567, 'transit', 'JFK175', DATE '2026-10-26', '185189.22-EWR.H-FRG01-64-U', 'by_city'),
        (567, 'transit', 'JFK175', DATE '2026-10-26', '185190.22-EWR.H-FRG01-65-U', 'by_city'),
        (567, 'transit', 'JFK175', DATE '2026-10-26', '185191.22-EWR.H-FRG01-66-U', 'by_city'),
        (567, 'transit', 'JFK175', DATE '2026-10-26', '185193.22-EWR.H-FRG01-68-U', 'by_city')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type)
WHERE NOT EXISTS (
    SELECT 1
    FROM public.chute_destination_gofo existing
    WHERE existing.chute_id = v.chute_id
      AND existing.effective_date IS NOT DISTINCT FROM v.effective_date
      AND existing.route IS NOT DISTINCT FROM v.route
      AND existing.sort_type IS NOT DISTINCT FROM v.sort_type
);
