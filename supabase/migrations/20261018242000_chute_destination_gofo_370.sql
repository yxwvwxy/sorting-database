-- Chute 370 is transit to DEN423. DEN, DFW, IAH, LAX, MIA, ORD, SEA, SJC,
-- and SLC warehouses are stored without routes.

INSERT INTO public.chute_destination_gofo (
  chute_id,
  bundle_type,
  destination_warehouse,
  effective_date,
  route
)
SELECT
  370,
  'transit',
  'DEN423',
  DATE '2026-10-18',
  NULL
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = 370
    AND d.destination_warehouse = 'DEN423'
    AND d.effective_date = DATE '2026-10-18'
    AND d.route IS NULL
);
