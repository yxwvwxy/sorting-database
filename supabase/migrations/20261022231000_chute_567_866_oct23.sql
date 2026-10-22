-- Live 10/23 plan: chute 567 holds the FRG routes previously split onto 866.
-- 60-U is 185186.22. 64-U and 68-U move onto 567. Chute 866 has no setting.

UPDATE public.chute_destination_gofo
SET route = '185186.22-EWR.H-FRG01-60-U'
WHERE chute_id = 567
  AND effective_date = DATE '2026-10-23'
  AND route = '185185.22-EWR.H-FRG01-60-U';

INSERT INTO public.chute_destination_gofo (
    chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type
)
SELECT v.chute_id, v.bundle_type, v.destination_warehouse, v.effective_date, v.route, v.sort_type
FROM (
    VALUES
        (567, 'transit', 'JFK175', DATE '2026-10-23', '185189.22-EWR.H-FRG01-64-U', 'by_city'),
        (567, 'transit', 'JFK175', DATE '2026-10-23', '185193.22-EWR.H-FRG01-68-U', 'by_city')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type)
WHERE NOT EXISTS (
    SELECT 1
    FROM public.chute_destination_gofo existing
    WHERE existing.chute_id = v.chute_id
      AND existing.effective_date IS NOT DISTINCT FROM v.effective_date
      AND existing.route IS NOT DISTINCT FROM v.route
      AND existing.sort_type IS NOT DISTINCT FROM v.sort_type
);

DELETE FROM public.chute_destination_gofo
WHERE chute_id = 866
  AND effective_date = DATE '2026-10-23';
