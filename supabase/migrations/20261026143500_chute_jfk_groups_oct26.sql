-- Active 1021-Gofo on 2026-10-26. These six chutes take effect that ops day.
-- 368 JFK-DL, 367 JFK-ANT, 517 adds FRG01-66, 568 JFK-AR, 567 JFK-SD, 1070 JFK-ZW.
-- 367 and 567 already had a 10/26 row set; replace it with the live routes.
-- JFK01-31-G and JFK01-36-G left 367 and are not on another chute.

UPDATE public.chute_destination_gofo
SET end_date = DATE '2026-10-25'
WHERE chute_id IN (368, 568, 1070)
  AND end_date IS NULL
  AND (effective_date IS NULL OR effective_date <= DATE '2026-10-25');

DELETE FROM public.chute_destination_gofo
WHERE chute_id IN (367, 567)
  AND effective_date = DATE '2026-10-26';

INSERT INTO public.chute_destination_gofo (
    chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type
)
SELECT v.chute_id, v.bundle_type, v.destination_warehouse, v.effective_date, v.route, v.sort_type
FROM (
    VALUES
        (367, 'transit', 'JFK175', DATE '2026-10-26', '175002.21-JFK.H-JFK01-12-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-10-26', '185176.22-EWR.H-FRG01-51-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-10-26', '185179.22-EWR.H-FRG01-54-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-10-26', '185182.22-EWR.H-FRG01-57-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-10-26', '185184.22-EWR.H-FRG01-59-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-10-26', '185185.22-EWR.H-FRG01-60-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-10-26', '185034.21-JFK.H-LGA01-45-U', 'by_city'),
        (368, 'transit', 'JFK175', DATE '2026-10-26', '185023.21-JFK.H-LGA01-24-U', 'by_city'),
        (368, 'transit', 'JFK175', DATE '2026-10-26', '185036.21-JFK.H-LGA01-47-U', 'by_city'),
        (368, 'transit', 'JFK175', DATE '2026-10-26', '185044.21-JFK.H-LGA01-55-U', 'by_city'),
        (368, 'transit', 'JFK175', DATE '2026-10-26', '185562.21-JFK.H-LGA01-58-U', 'by_city'),
        (368, 'transit', 'JFK175', DATE '2026-10-26', '185193.22-EWR.H-FRG01-68-U', 'by_city'),
        (517, 'transit', 'EWR.H', DATE '2026-10-26', '185191.22-EWR.H-FRG01-66-U', 'by_route'),
        (567, 'transit', 'JFK175', DATE '2026-10-26', '185186.22-EWR.H-FRG01-61-U', 'by_city'),
        (567, 'transit', 'JFK175', DATE '2026-10-26', '185190.22-EWR.H-FRG01-65-U', 'by_city'),
        (567, 'transit', 'JFK175', DATE '2026-10-26', '185001.21-JFK.H-JFK01-01-U', 'by_city'),
        (567, 'transit', 'JFK175', DATE '2026-10-26', '185002.21-JFK.H-JFK01-02-U', 'by_city'),
        (567, 'transit', 'JFK175', DATE '2026-10-26', '185004.21-JFK.H-JFK01-04-U', 'by_city'),
        (567, 'transit', 'JFK175', DATE '2026-10-26', '185006.21-JFK.H-JFK01-06-U', 'by_city'),
        (567, 'transit', 'JFK175', DATE '2026-10-26', '185178.22-EWR.H-FRG01-53-U', 'by_city'),
        (568, 'transit', 'JFK175', DATE '2026-10-26', '185021.21-JFK.H-LGA01-22-U', 'by_city'),
        (568, 'transit', 'JFK175', DATE '2026-10-26', '185024.21-JFK.H-LGA01-25-U', 'by_city'),
        (568, 'transit', 'JFK175', DATE '2026-10-26', '185037.21-JFK.H-LGA01-48-U', 'by_city'),
        (568, 'transit', 'JFK175', DATE '2026-10-26', '185041.21-JFK.H-LGA01-52-U', 'by_city'),
        (568, 'transit', 'JFK175', DATE '2026-10-26', '185007.21-JFK.H-JFK01-07-U', 'by_city'),
        (568, 'transit', 'JFK175', DATE '2026-10-26', '185008.21-JFK.H-JFK01-08-U', 'by_city'),
        (568, 'transit', 'JFK175', DATE '2026-10-26', '185011.21-JFK.H-JFK01-32-U', 'by_city'),
        (568, 'transit', 'JFK175', DATE '2026-10-26', '185018.21-JFK.H-JFK01-39-U', 'by_city'),
        (1070, 'transit', 'JFK175', DATE '2026-10-26', '185188.22-EWR.H-FRG01-63-U', 'by_city'),
        (1070, 'transit', 'JFK175', DATE '2026-10-26', '185189.22-EWR.H-FRG01-64-U', 'by_city'),
        (1070, 'transit', 'JFK175', DATE '2026-10-26', '185177.22-EWR.H-FRG01-52-U', 'by_city'),
        (1070, 'transit', 'JFK175', DATE '2026-10-26', '185009.21-JFK.H-JFK01-09-U', 'by_city'),
        (1070, 'transit', 'JFK175', DATE '2026-10-26', '175005.21-JFK.H-JFK01-15-U', 'by_city'),
        (1070, 'transit', 'JFK175', DATE '2026-10-26', '175006.21-JFK.H-JFK01-16-U', 'by_city'),
        (1070, 'transit', 'JFK175', DATE '2026-10-26', '185013.21-JFK.H-JFK01-34-U', 'by_city'),
        (1070, 'transit', 'JFK175', DATE '2026-10-26', '185003.21-JFK.H-JFK01-03-U', 'by_city')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type)
WHERE NOT EXISTS (
    SELECT 1
    FROM public.chute_destination_gofo existing
    WHERE existing.chute_id = v.chute_id
      AND existing.effective_date IS NOT DISTINCT FROM v.effective_date
      AND existing.route IS NOT DISTINCT FROM v.route
      AND existing.sort_type IS NOT DISTINCT FROM v.sort_type
);
