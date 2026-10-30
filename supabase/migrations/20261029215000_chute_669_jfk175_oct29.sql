-- Chute 669 in plan 458 (effective 2026-10-29 after 12:10 ET) is JFK175.
-- Ingest had used EWR.H from the route hub token; UniMap warehouse is JFK.

UPDATE public.chute_destination_gofo
SET destination_warehouse = 'JFK175'
WHERE chute_id = 669
  AND effective_date = DATE '2026-10-29'
  AND end_date IS NULL
  AND route = '185191.22-EWR.H-FRG01-66-U'
  AND destination_warehouse = 'EWR.H';
