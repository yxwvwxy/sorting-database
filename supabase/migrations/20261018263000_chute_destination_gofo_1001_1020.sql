-- New sorter map from the 2026-10-18 screenshots, chutes 1001-1020.
-- City segment is BDR, not BDR01. PHL suffixes and MDT 80/81 have no leading zero.
-- LAX489 and MIA307 route is uni_hub.

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
    (1001::integer, 'transit'::text, 'EWR.H'::text, DATE '2026-10-18', '185103.22-EWR.H-BDR-020-G'::text),
    (1002, 'transit', 'EWR.H', DATE '2026-10-18', '185102.22-EWR.H-BDR-019-G'),
    (1003, 'transit', 'EWR.H', DATE '2026-10-18', '185101.22-EWR.H-BDR-018-G'),
    (1004, 'transit', 'EWR.H', DATE '2026-10-18', '185100.22-EWR.H-BDR-017-G'),
    (1005, 'transit', 'EWR.H', DATE '2026-10-18', '185099.22-EWR.H-BDR-016-G'),
    (1006, 'transit', 'EWR.H', DATE '2026-10-18', '185098.22-EWR.H-BDR-015-G'),
    (1007, 'transit', 'EWR.H', DATE '2026-10-18', '185097.22-EWR.H-BDR-014-G'),
    (1008, 'transit', 'EWR.H', DATE '2026-10-18', '185096.22-EWR.H-BDR-013-G'),
    (1009, 'transit', 'EWR.H', DATE '2026-10-18', '185095.22-EWR.H-BDR-011-G'),
    (1010, 'transit', 'EWR.H', DATE '2026-10-18', '185295.22-EWR.H-PHL01-99-G'),
    (1011, 'transit', 'EWR.H', DATE '2026-10-18', '185294.22-EWR.H-PHL01-96-G'),
    (1012, 'transit', 'EWR.H', DATE '2026-10-18', '185636.22-EWR.H-PHL01-63-G'),
    (1013, 'transit', 'EWR.H', DATE '2026-10-18', '185635.22-EWR.H-PHL01-61-G'),
    (1014, 'transit', 'EWR.H', DATE '2026-10-18', '185634.22-EWR.H-PHL01-60-G'),
    (1015, 'transit', 'EWR.H', DATE '2026-10-18', '185249.22-EWR.H-MDT01-102-H'),
    (1015, 'transit', 'EWR.H', DATE '2026-10-18', '185250.22-EWR.H-MDT01-103-H'),
    (1015, 'transit', 'EWR.H', DATE '2026-10-18', '185251.22-EWR.H-MDT01-105-H'),
    (1015, 'transit', 'EWR.H', DATE '2026-10-18', '185252.22-EWR.H-MDT01-106-H'),
    (1015, 'transit', 'EWR.H', DATE '2026-10-18', '185253.22-EWR.H-MDT01-107-H'),
    (1015, 'transit', 'EWR.H', DATE '2026-10-18', '185254.22-EWR.H-MDT01-111-H'),
    (1015, 'transit', 'EWR.H', DATE '2026-10-18', '185255.22-EWR.H-MDT01-112-H'),
    (1015, 'transit', 'EWR.H', DATE '2026-10-18', '185256.22-EWR.H-MDT01-113-H'),
    (1015, 'transit', 'EWR.H', DATE '2026-10-18', '185672.22-EWR.H-MDT01-083-H'),
    (1016, 'transit', 'EWR.H', DATE '2026-10-18', '185257.22-EWR.H-MDT01-114-H'),
    (1016, 'transit', 'EWR.H', DATE '2026-10-18', '185258.22-EWR.H-MDT01-115-H'),
    (1016, 'transit', 'EWR.H', DATE '2026-10-18', '185259.22-EWR.H-MDT01-116-H'),
    (1016, 'transit', 'EWR.H', DATE '2026-10-18', '185260.22-EWR.H-MDT01-117-H'),
    (1016, 'transit', 'EWR.H', DATE '2026-10-18', '185261.22-EWR.H-MDT01-118-H'),
    (1016, 'transit', 'EWR.H', DATE '2026-10-18', '185262.22-EWR.H-MDT01-119-H'),
    (1016, 'transit', 'EWR.H', DATE '2026-10-18', '185263.22-EWR.H-MDT01-120-H'),
    (1016, 'transit', 'EWR.H', DATE '2026-10-18', '185264.22-EWR.H-MDT01-80-H'),
    (1016, 'transit', 'EWR.H', DATE '2026-10-18', '185265.22-EWR.H-MDT01-81-H'),
    (1017, 'transit', 'LAX489', DATE '2026-10-18', 'uni_hub'),
    (1018, 'transit', 'JFK175', DATE '2026-10-18', '185041.21-JFK.H-LGA01-52-U'),
    (1018, 'transit', 'JFK175', DATE '2026-10-18', '185043.21-JFK.H-LGA01-54-U'),
    (1018, 'transit', 'JFK175', DATE '2026-10-18', '185044.21-JFK.H-LGA01-55-U'),
    (1018, 'transit', 'JFK175', DATE '2026-10-18', '185560.21-JFK.H-LGA01-56-U'),
    (1018, 'transit', 'JFK175', DATE '2026-10-18', '185561.21-JFK.H-LGA01-57-U'),
    (1018, 'transit', 'JFK175', DATE '2026-10-18', '185562.21-JFK.H-LGA01-58-U'),
    (1019, 'transit', 'JFK175', DATE '2026-10-18', '185032.21-JFK.H-LGA01-43-U'),
    (1019, 'transit', 'JFK175', DATE '2026-10-18', '185034.21-JFK.H-LGA01-45-U'),
    (1019, 'transit', 'JFK175', DATE '2026-10-18', '185036.21-JFK.H-LGA01-47-U'),
    (1019, 'transit', 'JFK175', DATE '2026-10-18', '185037.21-JFK.H-LGA01-48-U'),
    (1019, 'transit', 'JFK175', DATE '2026-10-18', '185038.21-JFK.H-LGA01-49-U'),
    (1020, 'transit', 'MIA307', DATE '2026-10-18', 'uni_hub')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route IS NOT DISTINCT FROM v.route
    AND d.effective_date IS NOT DISTINCT FROM v.effective_date
);
