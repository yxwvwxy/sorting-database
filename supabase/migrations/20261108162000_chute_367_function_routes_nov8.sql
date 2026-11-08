-- 第一次分拣模版1103: chute 367 gains 18 JFK Function / system routes.
-- Ops day 2026-11-08 start. Destination stays JFK175 by_city; 5 city routes unchanged.

UPDATE public.chute_destination_gofo
SET end_date = DATE '2026-11-07'
WHERE chute_id = 367
  AND end_date IS NULL
  AND (effective_date IS NULL OR effective_date <= DATE '2026-11-07');

INSERT INTO public.chute_destination_gofo (
    chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type
)
SELECT v.chute_id, v.bundle_type, v.destination_warehouse, v.effective_date, v.route, v.sort_type
FROM (
    VALUES
        -- city routes (unchanged)
        (367, 'transit', 'JFK175', DATE '2026-11-08', '175002.21-JFK.H-JFK01-12-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '185034.21-JFK.H-LGA01-45-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '185176.22-EWR.H-FRG01-51-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '185182.22-EWR.H-FRG01-57-U', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '185184.22-EWR.H-FRG01-59-U', 'by_city'),
        -- Function / system routes from UniMap district "Function"
        (367, 'transit', 'JFK175', DATE '2026-11-08', '170989.AE Blind scanned', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '170990.USPS', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '170991.Out of Range', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '170992.Driver Parcel Unscanned', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '170993.Orders need to be addressed', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '170994.Second Delivery', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '170995.Shortage', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '170996.Customer reject', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '170997.Wrong City', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '170998.Reserved 01', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '170999.Reserved 02', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', 'BR_JFK_01', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '171777.TikTok USPS dangerous goods', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '171888.TikTok CBT Carrier SwiftX', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '171889.TikTok CBT Carrier SpeedX', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '171890.RTS Collector', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '171891.TT UPS Collector', 'by_city'),
        (367, 'transit', 'JFK175', DATE '2026-11-08', '171893.Uni Air', 'by_city')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type)
WHERE NOT EXISTS (
    SELECT 1
    FROM public.chute_destination_gofo existing
    WHERE existing.chute_id = v.chute_id
      AND existing.effective_date IS NOT DISTINCT FROM v.effective_date
      AND existing.route IS NOT DISTINCT FROM v.route
      AND existing.sort_type IS NOT DISTINCT FROM v.sort_type
      AND existing.destination_warehouse IS NOT DISTINCT FROM v.destination_warehouse
);
