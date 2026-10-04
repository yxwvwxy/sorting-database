-- Chute 720: city BK → JFK starting ops day 2026-10-03.
-- Keep the 2026-06-01 row so earlier ops days still map to BK.

INSERT INTO public.chute_destination (
  chute_id, warehouse, city, route, region, sort_type, effective_date, note
)
SELECT 720, 'JFK', 'JFK', '170004', 'JFK', 'last_mile', DATE '2026-10-03', NULL
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination d
  WHERE d.chute_id = 720
    AND d.effective_date = DATE '2026-10-03'
    AND d.city = 'JFK'
    AND d.route = '170004'
);
