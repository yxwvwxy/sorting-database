-- New sorter map from the 2026-10-18 screenshots, chutes 751-770.
-- 751-753 use BDR01; 754-764 use BDR. MIA307 has no individual routes, so its route is uni_hub.

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
    (751::integer, 'transit'::text, 'EWR.H'::text, DATE '2026-10-18', '185115.22-EWR.H-BDR01-044-G'::text),
    (752, 'transit', 'EWR.H', DATE '2026-10-18', '185588.22-EWR.H-BDR01-040-G'),
    (753, 'transit', 'EWR.H', DATE '2026-10-18', '185587.22-EWR.H-BDR01-024-G'),
    (754, 'transit', 'EWR.H', DATE '2026-10-18', '185114.22-EWR.H-BDR-039-G'),
    (755, 'transit', 'EWR.H', DATE '2026-10-18', '185113.22-EWR.H-BDR-038-G'),
    (756, 'transit', 'EWR.H', DATE '2026-10-18', '185112.22-EWR.H-BDR-037-G'),
    (757, 'transit', 'EWR.H', DATE '2026-10-18', '185111.22-EWR.H-BDR-036-G'),
    (758, 'transit', 'EWR.H', DATE '2026-10-18', '185110.22-EWR.H-BDR-035-G'),
    (759, 'transit', 'EWR.H', DATE '2026-10-18', '185109.22-EWR.H-BDR-034-G'),
    (760, 'transit', 'EWR.H', DATE '2026-10-18', '185108.22-EWR.H-BDR-033-G'),
    (761, 'transit', 'EWR.H', DATE '2026-10-18', '185107.22-EWR.H-BDR-028-G'),
    (762, 'transit', 'EWR.H', DATE '2026-10-18', '185106.22-EWR.H-BDR-023-G'),
    (763, 'transit', 'EWR.H', DATE '2026-10-18', '185105.22-EWR.H-BDR-022-G'),
    (764, 'transit', 'EWR.H', DATE '2026-10-18', '185104.22-EWR.H-BDR-021-G'),
    (765, 'transit', 'EWR.H', DATE '2026-10-18', '185195.22-EWR.H-GED01-001-H'),
    (765, 'transit', 'EWR.H', DATE '2026-10-18', '185196.22-EWR.H-GED01-004-H'),
    (765, 'transit', 'EWR.H', DATE '2026-10-18', '185197.22-EWR.H-GED01-006-H'),
    (765, 'transit', 'EWR.H', DATE '2026-10-18', '185198.22-EWR.H-GED01-007-H'),
    (765, 'transit', 'EWR.H', DATE '2026-10-18', '185199.22-EWR.H-GED01-008-H'),
    (765, 'transit', 'EWR.H', DATE '2026-10-18', '185200.22-EWR.H-GED01-071-H'),
    (765, 'transit', 'EWR.H', DATE '2026-10-18', '185201.22-EWR.H-GED01-072-H'),
    (765, 'transit', 'EWR.H', DATE '2026-10-18', '185202.22-EWR.H-GED01-073-H'),
    (765, 'transit', 'EWR.H', DATE '2026-10-18', '185203.22-EWR.H-GED01-074-H'),
    (765, 'transit', 'EWR.H', DATE '2026-10-18', '185204.22-EWR.H-GED01-075-H'),
    (765, 'transit', 'EWR.H', DATE '2026-10-18', '185591.22-EWR.H-GED01-002-H'),
    (765, 'transit', 'EWR.H', DATE '2026-10-18', '185592.22-EWR.H-GED01-003-H'),
    (765, 'transit', 'EWR.H', DATE '2026-10-18', '185593.22-EWR.H-GED01-005-H'),
    (765, 'transit', 'EWR.H', DATE '2026-10-18', '185594.22-EWR.H-GED01-009-H'),
    (765, 'transit', 'EWR.H', DATE '2026-10-18', '185595.22-EWR.H-GED01-010-H'),
    (765, 'transit', 'EWR.H', DATE '2026-10-18', '185596.22-EWR.H-GED01-076-H'),
    (766, 'transit', 'EWR.H', DATE '2026-10-18', '185266.22-EWR.H-MHT01-001-H'),
    (766, 'transit', 'EWR.H', DATE '2026-10-18', '185267.22-EWR.H-MHT01-002-H'),
    (766, 'transit', 'EWR.H', DATE '2026-10-18', '185268.22-EWR.H-MHT01-003-H'),
    (766, 'transit', 'EWR.H', DATE '2026-10-18', '185269.22-EWR.H-MHT01-004-H'),
    (766, 'transit', 'EWR.H', DATE '2026-10-18', '185270.22-EWR.H-MHT01-005-H'),
    (766, 'transit', 'EWR.H', DATE '2026-10-18', '185271.22-EWR.H-MHT01-006-H'),
    (766, 'transit', 'EWR.H', DATE '2026-10-18', '185272.22-EWR.H-MHT01-007-H'),
    (766, 'transit', 'EWR.H', DATE '2026-10-18', '185273.22-EWR.H-MHT01-008-H'),
    (766, 'transit', 'EWR.H', DATE '2026-10-18', '185274.22-EWR.H-MHT01-009-H'),
    (766, 'transit', 'EWR.H', DATE '2026-10-18', '185275.22-EWR.H-MHT01-010-H'),
    (766, 'transit', 'EWR.H', DATE '2026-10-18', '185632.22-EWR.H-MHT01-012-H'),
    (766, 'transit', 'EWR.H', DATE '2026-10-18', '185633.22-EWR.H-MHT01-013-H'),
    (767, 'last_mile', 'PWM417', DATE '2026-10-18', '740004.PWM Route04'),
    (768, 'last_mile', 'PWM417', DATE '2026-10-18', '740005.PWM Route05'),
    (769, 'last_mile', 'PWM417', DATE '2026-10-18', '741890.RTS Collector'),
    (769, 'last_mile', 'PWM417', DATE '2026-10-18', '740999.Reserved 02'),
    (769, 'last_mile', 'PWM417', DATE '2026-10-18', '740998.Reserved 01'),
    (769, 'last_mile', 'PWM417', DATE '2026-10-18', '740997.Wrong City'),
    (769, 'last_mile', 'PWM417', DATE '2026-10-18', '740996.Customer Reject'),
    (769, 'last_mile', 'PWM417', DATE '2026-10-18', '740995.Shortage'),
    (769, 'last_mile', 'PWM417', DATE '2026-10-18', '740994.Second Delivery'),
    (769, 'last_mile', 'PWM417', DATE '2026-10-18', '740993.Orders Need to be Addressed'),
    (769, 'last_mile', 'PWM417', DATE '2026-10-18', '740992.Driver Parcel Unscanned'),
    (769, 'last_mile', 'PWM417', DATE '2026-10-18', '740991.Out of Range'),
    (769, 'last_mile', 'PWM417', DATE '2026-10-18', '740006.PWM Route06'),
    (770, 'transit', 'MIA307', DATE '2026-10-18', 'uni_hub')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route IS NOT DISTINCT FROM v.route
    AND d.effective_date IS NOT DISTINCT FROM v.effective_date
);
