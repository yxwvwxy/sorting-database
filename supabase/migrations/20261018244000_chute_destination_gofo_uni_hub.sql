-- Hub warehouses DEN, DFW, IAH, LAX, MIA, ORD, SEA, SJC, and SLC
-- keep one row and store the route as uni_hub.

UPDATE public.chute_destination_gofo
SET route = 'uni_hub'
WHERE chute_id = 370
  AND destination_warehouse = 'DEN423'
  AND effective_date = DATE '2026-10-18'
  AND route IS NULL;
