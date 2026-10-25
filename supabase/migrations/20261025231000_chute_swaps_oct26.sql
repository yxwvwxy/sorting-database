-- Active 1021-Gofo. These four pairs were swapped in the
-- evening of 2026-10-25 and take effect on ops day 2026-10-26.
-- 116<->667, 117<->666, 119<->766, 120<->765.

UPDATE public.chute_destination_gofo
SET end_date = DATE '2026-10-25'
WHERE chute_id IN (116, 117, 119, 120, 666, 667, 765, 766)
  AND end_date IS NULL
  AND (effective_date IS NULL OR effective_date <= DATE '2026-10-25');

INSERT INTO public.chute_destination_gofo (
    chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type
)
SELECT v.chute_id, v.bundle_type, v.destination_warehouse, v.effective_date, v.route, v.sort_type
FROM (
    VALUES
        (116, 'transit', 'EWR.H', DATE '2026-10-26', '185374.22-EWR.H-ROC01-008-H', 'by_city'),
        (116, 'transit', 'EWR.H', DATE '2026-10-26', '185375.22-EWR.H-ROC01-01-H', 'by_city'),
        (116, 'transit', 'EWR.H', DATE '2026-10-26', '185376.22-EWR.H-ROC01-010-H', 'by_city'),
        (116, 'transit', 'EWR.H', DATE '2026-10-26', '185377.22-EWR.H-ROC01-011-H', 'by_city'),
        (116, 'transit', 'EWR.H', DATE '2026-10-26', '185378.22-EWR.H-ROC01-012-H', 'by_city'),
        (116, 'transit', 'EWR.H', DATE '2026-10-26', '185379.22-EWR.H-ROC01-02-H', 'by_city'),
        (116, 'transit', 'EWR.H', DATE '2026-10-26', '185380.22-EWR.H-ROC01-020-H', 'by_city'),
        (116, 'transit', 'EWR.H', DATE '2026-10-26', '185381.22-EWR.H-ROC01-03-H', 'by_city'),
        (116, 'transit', 'EWR.H', DATE '2026-10-26', '185382.22-EWR.H-ROC01-05-H', 'by_city'),
        (116, 'transit', 'EWR.H', DATE '2026-10-26', '185383.22-EWR.H-ROC01-06-H', 'by_city'),
        (116, 'transit', 'EWR.H', DATE '2026-10-26', '185384.22-EWR.H-ROC01-13-H', 'by_city'),
        (116, 'transit', 'EWR.H', DATE '2026-10-26', '185385.22-EWR.H-ROC01-14-H', 'by_city'),
        (116, 'transit', 'EWR.H', DATE '2026-10-26', '185386.22-EWR.H-ROC01-15-H', 'by_city'),
        (116, 'transit', 'EWR.H', DATE '2026-10-26', '185387.22-EWR.H-ROC01-16-H', 'by_city'),
        (116, 'transit', 'EWR.H', DATE '2026-10-26', '185388.22-EWR.H-ROC01-17-H', 'by_city'),
        (116, 'transit', 'EWR.H', DATE '2026-10-26', '185389.22-EWR.H-ROC01-18-H', 'by_city'),
        (116, 'transit', 'EWR.H', DATE '2026-10-26', '185641.22-EWR.H-ROC01-007-H', 'by_city'),
        (116, 'transit', 'EWR.H', DATE '2026-10-26', '185670.22-EWR.H-ROC01-021-H', 'by_city'),
        (117, 'transit', 'EWR.H', DATE '2026-10-26', '185205.22-EWR.H-HYA01-001-H', 'by_city'),
        (117, 'transit', 'EWR.H', DATE '2026-10-26', '185206.22-EWR.H-HYA01-002-H', 'by_city'),
        (117, 'transit', 'EWR.H', DATE '2026-10-26', '185207.22-EWR.H-HYA01-005-H', 'by_city'),
        (117, 'transit', 'EWR.H', DATE '2026-10-26', '185208.22-EWR.H-HYA01-006-H', 'by_city'),
        (117, 'transit', 'EWR.H', DATE '2026-10-26', '185209.22-EWR.H-HYA01-007-H', 'by_city'),
        (117, 'transit', 'EWR.H', DATE '2026-10-26', '185210.22-EWR.H-HYA01-008-H', 'by_city'),
        (117, 'transit', 'EWR.H', DATE '2026-10-26', '185211.22-EWR.H-HYA01-010-H', 'by_city'),
        (117, 'transit', 'EWR.H', DATE '2026-10-26', '185569.22-EWR.H-HYA01-009-H', 'by_city'),
        (117, 'transit', 'EWR.H', DATE '2026-10-26', '185681.22-EWR.H-HYA01-003-H', 'by_city'),
        (119, 'transit', 'EWR.H', DATE '2026-10-26', '185266.22-EWR.H-MHT01-001-H', 'by_city'),
        (119, 'transit', 'EWR.H', DATE '2026-10-26', '185267.22-EWR.H-MHT01-002-H', 'by_city'),
        (119, 'transit', 'EWR.H', DATE '2026-10-26', '185268.22-EWR.H-MHT01-003-H', 'by_city'),
        (119, 'transit', 'EWR.H', DATE '2026-10-26', '185269.22-EWR.H-MHT01-004-H', 'by_city'),
        (119, 'transit', 'EWR.H', DATE '2026-10-26', '185270.22-EWR.H-MHT01-005-H', 'by_city'),
        (119, 'transit', 'EWR.H', DATE '2026-10-26', '185271.22-EWR.H-MHT01-006-H', 'by_city'),
        (119, 'transit', 'EWR.H', DATE '2026-10-26', '185272.22-EWR.H-MHT01-007-H', 'by_city'),
        (119, 'transit', 'EWR.H', DATE '2026-10-26', '185273.22-EWR.H-MHT01-008-H', 'by_city'),
        (119, 'transit', 'EWR.H', DATE '2026-10-26', '185274.22-EWR.H-MHT01-009-H', 'by_city'),
        (119, 'transit', 'EWR.H', DATE '2026-10-26', '185275.22-EWR.H-MHT01-010-H', 'by_city'),
        (119, 'transit', 'EWR.H', DATE '2026-10-26', '185632.22-EWR.H-MHT01-012-H', 'by_city'),
        (119, 'transit', 'EWR.H', DATE '2026-10-26', '185633.22-EWR.H-MHT01-013-H', 'by_city'),
        (120, 'transit', 'EWR.H', DATE '2026-10-26', '185195.22-EWR.H-GED01-001-H', 'by_city'),
        (120, 'transit', 'EWR.H', DATE '2026-10-26', '185196.22-EWR.H-GED01-004-H', 'by_city'),
        (120, 'transit', 'EWR.H', DATE '2026-10-26', '185197.22-EWR.H-GED01-006-H', 'by_city'),
        (120, 'transit', 'EWR.H', DATE '2026-10-26', '185198.22-EWR.H-GED01-007-H', 'by_city'),
        (120, 'transit', 'EWR.H', DATE '2026-10-26', '185199.22-EWR.H-GED01-008-H', 'by_city'),
        (120, 'transit', 'EWR.H', DATE '2026-10-26', '185200.22-EWR.H-GED01-071-H', 'by_city'),
        (120, 'transit', 'EWR.H', DATE '2026-10-26', '185201.22-EWR.H-GED01-072-H', 'by_city'),
        (120, 'transit', 'EWR.H', DATE '2026-10-26', '185202.22-EWR.H-GED01-073-H', 'by_city'),
        (120, 'transit', 'EWR.H', DATE '2026-10-26', '185203.22-EWR.H-GED01-074-H', 'by_city'),
        (120, 'transit', 'EWR.H', DATE '2026-10-26', '185204.22-EWR.H-GED01-075-H', 'by_city'),
        (120, 'transit', 'EWR.H', DATE '2026-10-26', '185591.22-EWR.H-GED01-002-H', 'by_city'),
        (120, 'transit', 'EWR.H', DATE '2026-10-26', '185592.22-EWR.H-GED01-003-H', 'by_city'),
        (120, 'transit', 'EWR.H', DATE '2026-10-26', '185593.22-EWR.H-GED01-005-H', 'by_city'),
        (120, 'transit', 'EWR.H', DATE '2026-10-26', '185594.22-EWR.H-GED01-009-H', 'by_city'),
        (120, 'transit', 'EWR.H', DATE '2026-10-26', '185595.22-EWR.H-GED01-010-H', 'by_city'),
        (120, 'transit', 'EWR.H', DATE '2026-10-26', '185596.22-EWR.H-GED01-076-H', 'by_city'),
        (666, 'transit', 'BWI.H', DATE '2026-10-26', '185554.25-BWI.H-RIC01-006-H', 'by_city'),
        (666, 'transit', 'BWI.H', DATE '2026-10-26', '185555.25-BWI.H-RIC01-007-H', 'by_city'),
        (666, 'transit', 'BWI.H', DATE '2026-10-26', '185556.25-BWI.H-RIC01-008-H', 'by_city'),
        (666, 'transit', 'BWI.H', DATE '2026-10-26', '185557.25-BWI.H-RIC01-009-H', 'by_city'),
        (666, 'transit', 'BWI.H', DATE '2026-10-26', '185558.25-BWI.H-RIC01-010-H', 'by_city'),
        (666, 'transit', 'BWI.H', DATE '2026-10-26', '185559.25-BWI.H-RIC01-011-H', 'by_city'),
        (667, 'transit', 'BWI.H', DATE '2026-10-26', '185549.25-BWI.H-RIC01-001-H', 'by_city'),
        (667, 'transit', 'BWI.H', DATE '2026-10-26', '185550.25-BWI.H-RIC01-002-H', 'by_city'),
        (667, 'transit', 'BWI.H', DATE '2026-10-26', '185551.25-BWI.H-RIC01-003-H', 'by_city'),
        (667, 'transit', 'BWI.H', DATE '2026-10-26', '185552.25-BWI.H-RIC01-004-H', 'by_city'),
        (667, 'transit', 'BWI.H', DATE '2026-10-26', '185553.25-BWI.H-RIC01-005-H', 'by_city'),
        (765, 'transit', 'BWI.H', DATE '2026-10-26', '185463.25-BWI.H-BWI01-001-H', 'by_city'),
        (765, 'transit', 'BWI.H', DATE '2026-10-26', '185464.25-BWI.H-BWI01-02-H', 'by_city'),
        (765, 'transit', 'BWI.H', DATE '2026-10-26', '185465.25-BWI.H-BWI01-025-H', 'by_city'),
        (765, 'transit', 'BWI.H', DATE '2026-10-26', '185466.25-BWI.H-BWI01-028-H', 'by_city'),
        (765, 'transit', 'BWI.H', DATE '2026-10-26', '185467.25-BWI.H-BWI01-03-H', 'by_city'),
        (765, 'transit', 'BWI.H', DATE '2026-10-26', '185468.25-BWI.H-BWI01-039-H', 'by_city'),
        (765, 'transit', 'BWI.H', DATE '2026-10-26', '185469.25-BWI.H-BWI01-04-H', 'by_city'),
        (766, 'transit', 'BWI.H', DATE '2026-10-26', '185471.25-BWI.H-BWI01-041-H', 'by_city'),
        (766, 'transit', 'BWI.H', DATE '2026-10-26', '185472.25-BWI.H-BWI01-042-H', 'by_city'),
        (766, 'transit', 'BWI.H', DATE '2026-10-26', '185473.25-BWI.H-BWI01-044-H', 'by_city'),
        (766, 'transit', 'BWI.H', DATE '2026-10-26', '185474.25-BWI.H-BWI01-05-H', 'by_city'),
        (766, 'transit', 'BWI.H', DATE '2026-10-26', '185475.25-BWI.H-BWI01-06-H', 'by_city'),
        (766, 'transit', 'BWI.H', DATE '2026-10-26', '185476.25-BWI.H-BWI01-07-H', 'by_city')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type)
WHERE NOT EXISTS (
    SELECT 1
    FROM public.chute_destination_gofo existing
    WHERE existing.chute_id = v.chute_id
      AND existing.effective_date IS NOT DISTINCT FROM v.effective_date
      AND existing.route IS NOT DISTINCT FROM v.route
      AND existing.sort_type IS NOT DISTINCT FROM v.sort_type
);
