-- Activate chute 569 as MDT last_mile (was note=idle).
-- last_mile requires a non-null route; placeholder route 'MDT' until a real route is known.

DELETE FROM public.chute_destination
WHERE chute_id = 569
  AND effective_date = DATE '2026-06-01'
  AND note = 'idle';

INSERT INTO public.chute_destination (
  chute_id, warehouse, city, route, region, sort_type, effective_date, note
)
SELECT 569, 'MDT', 'MDT', 'MDT', 'JFK', 'last_mile', DATE '2026-06-01', NULL
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination
  WHERE chute_id = 569
    AND effective_date = DATE '2026-06-01'
    AND COALESCE(note, '') NOT IN ('idle', 'block')
);
