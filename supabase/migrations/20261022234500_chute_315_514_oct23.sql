-- Live 10/23 plan: FRG01-67 moves from chute 315 to chute 514.
-- Chute 315 has no setting. The old 315 row ends on 2026-10-22.

UPDATE public.chute_destination_gofo
SET end_date = DATE '2026-10-22'
WHERE chute_id = 315
  AND end_date IS NULL
  AND effective_date <= DATE '2026-10-22';

INSERT INTO public.chute_destination_gofo (
    chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type
)
SELECT v.chute_id, v.bundle_type, v.destination_warehouse, v.effective_date, v.route, v.sort_type
FROM (
    VALUES
        (514, 'transit', 'EWR.H', DATE '2026-10-23', '185192.22-EWR.H-FRG01-67-G', 'by_route')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type)
WHERE NOT EXISTS (
    SELECT 1
    FROM public.chute_destination_gofo existing
    WHERE existing.chute_id = v.chute_id
      AND existing.effective_date IS NOT DISTINCT FROM v.effective_date
      AND existing.route IS NOT DISTINCT FROM v.route
      AND existing.sort_type IS NOT DISTINCT FROM v.sort_type
);
