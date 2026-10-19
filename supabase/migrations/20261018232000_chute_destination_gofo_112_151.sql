-- New sorter map from the 2026-10-18 screenshot, chutes 112-120 and 151.
-- Chute 118 is bundle type others, with no destination warehouse.

ALTER TABLE public.chute_destination_gofo
  DROP CONSTRAINT chute_destination_gofo_bundle_type_check;

ALTER TABLE public.chute_destination_gofo
  ADD CONSTRAINT chute_destination_gofo_bundle_type_check
  CHECK (bundle_type IN ('transit', 'last_mile', 'others'));

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
    (112::integer, 'transit'::text, 'EWR.H'::text, DATE '2026-10-18', '185215.22-EWR.H-LDJ01-016-G'::text),
    (113, 'transit', 'EWR.H', DATE '2026-10-18', '185214.22-EWR.H-LDJ01-015-G'),
    (114, 'transit', 'EWR.H', DATE '2026-10-18', '185213.22-EWR.H-LDJ01-014-G'),
    (115, 'transit', 'EWR.H', DATE '2026-10-18', '185212.22-EWR.H-LDJ01-013-G'),
    (116, 'transit', 'BWI.H', DATE '2026-10-18', '185549.25-BWI.H-RIC01-001-H'),
    (116, 'transit', 'BWI.H', DATE '2026-10-18', '185550.25-BWI.H-RIC01-002-H'),
    (116, 'transit', 'BWI.H', DATE '2026-10-18', '185551.25-BWI.H-RIC01-003-H'),
    (116, 'transit', 'BWI.H', DATE '2026-10-18', '185552.25-BWI.H-RIC01-004-H'),
    (116, 'transit', 'BWI.H', DATE '2026-10-18', '185553.25-BWI.H-RIC01-005-H'),
    (117, 'transit', 'BWI.H', DATE '2026-10-18', '185554.25-BWI.H-RIC01-006-H'),
    (117, 'transit', 'BWI.H', DATE '2026-10-18', '185555.25-BWI.H-RIC01-007-H'),
    (117, 'transit', 'BWI.H', DATE '2026-10-18', '185556.25-BWI.H-RIC01-008-H'),
    (117, 'transit', 'BWI.H', DATE '2026-10-18', '185557.25-BWI.H-RIC01-009-H'),
    (117, 'transit', 'BWI.H', DATE '2026-10-18', '185558.25-BWI.H-RIC01-010-H'),
    (117, 'transit', 'BWI.H', DATE '2026-10-18', '185559.25-BWI.H-RIC01-011-H'),
    (118, 'others', NULL, DATE '2026-10-18', '181894.GOFO Rejected'),
    (118, 'others', NULL, DATE '2026-10-18', '171894.GOFO Rejected'),
    (119, 'transit', 'BWI.H', DATE '2026-10-18', '185471.25-BWI.H-BWI01-041-H'),
    (119, 'transit', 'BWI.H', DATE '2026-10-18', '185472.25-BWI.H-BWI01-042-H'),
    (119, 'transit', 'BWI.H', DATE '2026-10-18', '185473.25-BWI.H-BWI01-044-H'),
    (119, 'transit', 'BWI.H', DATE '2026-10-18', '185474.25-BWI.H-BWI01-05-H'),
    (119, 'transit', 'BWI.H', DATE '2026-10-18', '185475.25-BWI.H-BWI01-06-H'),
    (119, 'transit', 'BWI.H', DATE '2026-10-18', '185476.25-BWI.H-BWI01-07-H'),
    (120, 'transit', 'BWI.H', DATE '2026-10-18', '185463.25-BWI.H-BWI01-001-H'),
    (120, 'transit', 'BWI.H', DATE '2026-10-18', '185464.25-BWI.H-BWI01-02-H'),
    (120, 'transit', 'BWI.H', DATE '2026-10-18', '185465.25-BWI.H-BWI01-025-H'),
    (120, 'transit', 'BWI.H', DATE '2026-10-18', '185466.25-BWI.H-BWI01-028-H'),
    (120, 'transit', 'BWI.H', DATE '2026-10-18', '185467.25-BWI.H-BWI01-03-H'),
    (120, 'transit', 'BWI.H', DATE '2026-10-18', '185468.25-BWI.H-BWI01-039-H'),
    (120, 'transit', 'BWI.H', DATE '2026-10-18', '185469.25-BWI.H-BWI01-04-H'),
    (151, 'transit', 'EWR.H', DATE '2026-10-18', '185245.22-EWR.H-LDJ01-63-G')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date IS NOT DISTINCT FROM v.effective_date
);
