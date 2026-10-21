-- Chute 418 drops FRG01-58-U on ops day 2026-10-21.
-- That route is already on chute 515. The other six FRG01 routes stay on JFK175.

UPDATE public.chute_destination_gofo
SET end_date = DATE '2026-10-20'
WHERE chute_id = 418
  AND effective_date = DATE '2026-10-18'
  AND end_date IS NULL;

INSERT INTO public.chute_destination_gofo (
  chute_id,
  bundle_type,
  destination_warehouse,
  effective_date,
  route,
  sort_type
)
SELECT
  v.chute_id,
  v.bundle_type,
  v.destination_warehouse,
  v.effective_date,
  v.route,
  v.sort_type
FROM (
  VALUES
    (418::integer, 'transit'::text, 'JFK175'::text, DATE '2026-10-21', '185176.22-EWR.H-FRG01-51-U'::text, 'by_city'::text),
    (418, 'transit', 'JFK175', DATE '2026-10-21', '185177.22-EWR.H-FRG01-52-U', 'by_city'),
    (418, 'transit', 'JFK175', DATE '2026-10-21', '185178.22-EWR.H-FRG01-53-U', 'by_city'),
    (418, 'transit', 'JFK175', DATE '2026-10-21', '185179.22-EWR.H-FRG01-54-U', 'by_city'),
    (418, 'transit', 'JFK175', DATE '2026-10-21', '185182.22-EWR.H-FRG01-57-U', 'by_city'),
    (418, 'transit', 'JFK175', DATE '2026-10-21', '185184.22-EWR.H-FRG01-59-U', 'by_city')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date = v.effective_date
);
