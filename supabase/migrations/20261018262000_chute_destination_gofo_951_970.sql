-- New sorter map from the 2026-10-18 screenshots, chutes 951 and 953-970.
-- Chute 952 was not on the screenshot. LAX489 and MIA307 route is uni_hub.
-- Chute 969 skips prefix 185022 and suffix 23.

INSERT INTO public.chute_destination_gofo (
  chute_id,
  bundle_type,
  destination_warehouse,
  effective_date,
  route
)
SELECT
  v.chute_id,
  v.bundle_type,
  v.destination_warehouse,
  v.effective_date,
  v.route
FROM (
  VALUES
    (951::integer, 'transit'::text, 'EWR.H'::text, DATE '2026-10-18', '185439.22-EWR.H-TEB01-25-G'::text),
    (953, 'transit', 'EWR.H', DATE '2026-10-18', '185438.22-EWR.H-TEB01-24-G'),
    (954, 'transit', 'EWR.H', DATE '2026-10-18', '185437.22-EWR.H-TEB01-23-G'),
    (955, 'transit', 'EWR.H', DATE '2026-10-18', '185436.22-EWR.H-TEB01-22-G'),
    (956, 'transit', 'EWR.H', DATE '2026-10-18', '185435.22-EWR.H-TEB01-21-G'),
    (957, 'transit', 'EWR.H', DATE '2026-10-18', '185434.22-EWR.H-TEB01-20-G'),
    (958, 'transit', 'EWR.H', DATE '2026-10-18', '185433.22-EWR.H-TEB01-19-G'),
    (959, 'transit', 'EWR.H', DATE '2026-10-18', '185432.22-EWR.H-TEB01-18-G'),
    (960, 'transit', 'EWR.H', DATE '2026-10-18', '185431.22-EWR.H-TEB01-17-G'),
    (961, 'transit', 'EWR.H', DATE '2026-10-18', '185430.22-EWR.H-TEB01-16-G'),
    (962, 'transit', 'EWR.H', DATE '2026-10-18', '185429.22-EWR.H-TEB01-15-G'),
    (963, 'transit', 'EWR.H', DATE '2026-10-18', '185428.22-EWR.H-TEB01-14-G'),
    (964, 'transit', 'EWR.H', DATE '2026-10-18', '185427.22-EWR.H-TEB01-13-G'),
    (965, 'transit', 'EWR.H', DATE '2026-10-18', '185426.22-EWR.H-TEB01-12-G'),
    (966, 'transit', 'EWR.H', DATE '2026-10-18', '185425.22-EWR.H-TEB01-11-G'),
    (967, 'transit', 'EWR.H', DATE '2026-10-18', '185424.22-EWR.H-TEB01-10-G'),
    (968, 'transit', 'LAX489', DATE '2026-10-18', 'uni_hub'),
    (969, 'transit', 'JFK175', DATE '2026-10-18', '185021.21-JFK.H-LGA01-22-U'),
    (969, 'transit', 'JFK175', DATE '2026-10-18', '185023.21-JFK.H-LGA01-24-U'),
    (969, 'transit', 'JFK175', DATE '2026-10-18', '185024.21-JFK.H-LGA01-25-U'),
    (969, 'transit', 'JFK175', DATE '2026-10-18', '185025.21-JFK.H-LGA01-26-U'),
    (969, 'transit', 'JFK175', DATE '2026-10-18', '185026.21-JFK.H-LGA01-27-U'),
    (970, 'transit', 'MIA307', DATE '2026-10-18', 'uni_hub')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route IS NOT DISTINCT FROM v.route
    AND d.effective_date IS NOT DISTINCT FROM v.effective_date
);
