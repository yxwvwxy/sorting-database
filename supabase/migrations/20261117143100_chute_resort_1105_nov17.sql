-- Secondary-split plan 二次分拣模版1105 (UniMap id 560) update for ops day 2026-11-17.
-- Adds chutes 1068 / 106801 (LDJ01-033-G / 030-G). Prior open rows unchanged.

INSERT INTO public.chute_destination_resort (
    chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type
)
SELECT v.chute_id, v.bundle_type, v.destination_warehouse, v.effective_date, v.route, v.sort_type
FROM (
    VALUES
        (1068, 'transit', 'EWR.H', DATE '2026-11-17', '185686.22-EWR.H-LDJ01-033-G', 'by_route'),
        (106801, 'transit', 'EWR.H', DATE '2026-11-17', '185685.22-EWR.H-LDJ01-030-G', 'by_route')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type)
WHERE NOT EXISTS (
    SELECT 1 FROM public.chute_destination_resort existing
    WHERE existing.chute_id = v.chute_id
      AND existing.destination_warehouse IS NOT DISTINCT FROM v.destination_warehouse
      AND existing.effective_date IS NOT DISTINCT FROM v.effective_date
      AND existing.route IS NOT DISTINCT FROM v.route
      AND existing.sort_type IS NOT DISTINCT FROM v.sort_type
      AND existing.end_date IS NULL
);

-- added=[1068, 106801] ended=[] dest_sort=[] route_only=[]
-- plan id=560 name=二次分拣模版1105 api_rows=254 live_chutes=254
