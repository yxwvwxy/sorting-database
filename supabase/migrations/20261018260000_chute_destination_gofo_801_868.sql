-- New sorter map from the 2026-10-18 screenshots, chutes 801-820 and 851-868.
-- 810 is BDL02. 820 MIA307 has no individual routes, so its route is uni_hub.
-- PIT suffixes 26, 28, 27, 25, and 24 are stored without a leading zero.

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
    (801::integer, 'transit'::text, 'EWR.H'::text, DATE '2026-10-18', '185423.22-EWR.H-TEB01-09-G'::text),
    (802, 'transit', 'EWR.H', DATE '2026-10-18', '185422.22-EWR.H-TEB01-08-G'),
    (803, 'transit', 'EWR.H', DATE '2026-10-18', '185421.22-EWR.H-TEB01-07-G'),
    (804, 'transit', 'EWR.H', DATE '2026-10-18', '185420.22-EWR.H-TEB01-06-G'),
    (805, 'transit', 'EWR.H', DATE '2026-10-18', '185419.22-EWR.H-TEB01-05-G'),
    (806, 'transit', 'EWR.H', DATE '2026-10-18', '185418.22-EWR.H-TEB01-04-G'),
    (807, 'transit', 'EWR.H', DATE '2026-10-18', '185417.22-EWR.H-TEB01-03-G'),
    (808, 'transit', 'EWR.H', DATE '2026-10-18', '185416.22-EWR.H-TEB01-02-G'),
    (809, 'transit', 'EWR.H', DATE '2026-10-18', '185415.22-EWR.H-TEB01-01-G'),
    (810, 'transit', 'EWR.H', DATE '2026-10-18', '185094.22-EWR.H-BDL02-08-G'),
    (811, 'transit', 'EWR.H', DATE '2026-10-18', '185093.22-EWR.H-BDL01-42-G'),
    (812, 'transit', 'EWR.H', DATE '2026-10-18', '185092.22-EWR.H-BDL01-41-G'),
    (813, 'transit', 'EWR.H', DATE '2026-10-18', '185091.22-EWR.H-BDL01-40-G'),
    (814, 'transit', 'EWR.H', DATE '2026-10-18', '185090.22-EWR.H-BDL01-36-G'),
    (815, 'transit', 'EWR.H', DATE '2026-10-18', '185089.22-EWR.H-BDL01-32-G'),
    (816, 'transit', 'EWR.H', DATE '2026-10-18', '185088.22-EWR.H-BDL01-31-G'),
    (817, 'last_mile', 'PWM417', DATE '2026-10-18', '740001.PWM Route01'),
    (818, 'last_mile', 'PWM417', DATE '2026-10-18', '740002.PWM Route02'),
    (819, 'last_mile', 'PWM417', DATE '2026-10-18', '740003.PWM Route03'),
    (820, 'transit', 'MIA307', DATE '2026-10-18', 'uni_hub'),
    (851, 'transit', 'EWR.H', DATE '2026-10-18', '185403.22-EWR.H-SWF01-17-G'),
    (852, 'transit', 'EWR.H', DATE '2026-10-18', '185402.22-EWR.H-SWF01-15-G'),
    (853, 'transit', 'EWR.H', DATE '2026-10-18', '185649.22-EWR.H-SWF01-13-G'),
    (854, 'transit', 'EWR.H', DATE '2026-10-18', '185401.22-EWR.H-SWF01-12-G'),
    (855, 'transit', 'EWR.H', DATE '2026-10-18', '185400.22-EWR.H-SWF01-08-G'),
    (856, 'transit', 'EWR.H', DATE '2026-10-18', '185399.22-EWR.H-SWF01-06-G'),
    (857, 'transit', 'EWR.H', DATE '2026-10-18', '185398.22-EWR.H-SWF01-05-G'),
    (858, 'transit', 'EWR.H', DATE '2026-10-18', '185648.22-EWR.H-SWF01-04-G'),
    (859, 'transit', 'EWR.H', DATE '2026-10-18', '185397.22-EWR.H-SWF01-03-G'),
    (860, 'transit', 'EWR.H', DATE '2026-10-18', '185586.22-EWR.H-ALB01-018-G'),
    (861, 'transit', 'EWR.H', DATE '2026-10-18', '185566.22-EWR.H-ALB01-017-G'),
    (862, 'transit', 'EWR.H', DATE '2026-10-18', '185070.22-EWR.H-ALB01-097-G'),
    (863, 'transit', 'EWR.H', DATE '2026-10-18', '185069.22-EWR.H-ALB01-016-G'),
    (864, 'transit', 'EWR.H', DATE '2026-10-18', '185068.22-EWR.H-ALB01-015-G'),
    (865, 'transit', 'EWR.H', DATE '2026-10-18', '185067.22-EWR.H-ALB01-014-G'),
    (866, 'transit', 'EWR.H', DATE '2026-10-18', '185066.22-EWR.H-ALB01-013-G'),
    (867, 'transit', 'EWR.H', DATE '2026-10-18', '185296.22-EWR.H-PIT01-001-H'),
    (867, 'transit', 'EWR.H', DATE '2026-10-18', '185297.22-EWR.H-PIT01-002-H'),
    (867, 'transit', 'EWR.H', DATE '2026-10-18', '185298.22-EWR.H-PIT01-003-H'),
    (867, 'transit', 'EWR.H', DATE '2026-10-18', '185299.22-EWR.H-PIT01-004-H'),
    (867, 'transit', 'EWR.H', DATE '2026-10-18', '185300.22-EWR.H-PIT01-006-H'),
    (867, 'transit', 'EWR.H', DATE '2026-10-18', '185313.22-EWR.H-PIT01-26-H'),
    (867, 'transit', 'EWR.H', DATE '2026-10-18', '185314.22-EWR.H-PIT01-28-H'),
    (867, 'transit', 'EWR.H', DATE '2026-10-18', '185570.22-EWR.H-PIT01-007-H'),
    (867, 'transit', 'EWR.H', DATE '2026-10-18', '185571.22-EWR.H-PIT01-008-H'),
    (867, 'transit', 'EWR.H', DATE '2026-10-18', '185637.22-EWR.H-PIT01-27-H'),
    (867, 'transit', 'EWR.H', DATE '2026-10-18', '185312.22-EWR.H-PIT01-25-H'),
    (868, 'transit', 'EWR.H', DATE '2026-10-18', '185301.22-EWR.H-PIT01-009-H'),
    (868, 'transit', 'EWR.H', DATE '2026-10-18', '185302.22-EWR.H-PIT01-010-H'),
    (868, 'transit', 'EWR.H', DATE '2026-10-18', '185303.22-EWR.H-PIT01-011-H'),
    (868, 'transit', 'EWR.H', DATE '2026-10-18', '185304.22-EWR.H-PIT01-012-H'),
    (868, 'transit', 'EWR.H', DATE '2026-10-18', '185305.22-EWR.H-PIT01-014-H'),
    (868, 'transit', 'EWR.H', DATE '2026-10-18', '185306.22-EWR.H-PIT01-015-H'),
    (868, 'transit', 'EWR.H', DATE '2026-10-18', '185307.22-EWR.H-PIT01-020-H'),
    (868, 'transit', 'EWR.H', DATE '2026-10-18', '185308.22-EWR.H-PIT01-021-H'),
    (868, 'transit', 'EWR.H', DATE '2026-10-18', '185309.22-EWR.H-PIT01-022-H'),
    (868, 'transit', 'EWR.H', DATE '2026-10-18', '185310.22-EWR.H-PIT01-023-H'),
    (868, 'transit', 'EWR.H', DATE '2026-10-18', '185311.22-EWR.H-PIT01-24-H')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route IS NOT DISTINCT FROM v.route
    AND d.effective_date IS NOT DISTINCT FROM v.effective_date
);
