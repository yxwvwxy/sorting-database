-- New sorter map from the 2026-10-18 screenshot, chutes 367-369.
-- 367 and 368 are transit to JFK175. 369 is transit to BWI.H.

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
    (367::integer, 'transit'::text, 'JFK175'::text, DATE '2026-10-18', '185011.21-JFK.H-JFK01-32-U'::text),
    (367, 'transit', 'JFK175', DATE '2026-10-18', '185012.21-JFK.H-JFK01-33-U'),
    (367, 'transit', 'JFK175', DATE '2026-10-18', '185013.21-JFK.H-JFK01-34-U'),
    (367, 'transit', 'JFK175', DATE '2026-10-18', '185014.21-JFK.H-JFK01-35-U'),
    (367, 'transit', 'JFK175', DATE '2026-10-18', '185016.21-JFK.H-JFK01-37-U'),
    (367, 'transit', 'JFK175', DATE '2026-10-18', '185017.21-JFK.H-JFK01-38-U'),
    (367, 'transit', 'JFK175', DATE '2026-10-18', '185018.21-JFK.H-JFK01-39-U'),
    (367, 'transit', 'JFK175', DATE '2026-10-18', '185019.21-JFK.H-JFK01-40-U'),
    (367, 'transit', 'JFK175', DATE '2026-10-18', '185015.21-JFK.H-JFK01-36-G'),
    (367, 'transit', 'JFK175', DATE '2026-10-18', '185576.21-JFK.H-JFK01-31-G'),
    (368, 'transit', 'JFK175', DATE '2026-10-18', '175002.21-JFK.H-JFK01-12-U'),
    (368, 'transit', 'JFK175', DATE '2026-10-18', '175003.21-JFK.H-JFK01-13-U'),
    (368, 'transit', 'JFK175', DATE '2026-10-18', '175004.21-JFK.H-JFK01-14-U'),
    (368, 'transit', 'JFK175', DATE '2026-10-18', '175005.21-JFK.H-JFK01-15-U'),
    (368, 'transit', 'JFK175', DATE '2026-10-18', '175006.21-JFK.H-JFK01-16-U'),
    (368, 'transit', 'JFK175', DATE '2026-10-18', '185007.21-JFK.H-JFK01-07-U'),
    (368, 'transit', 'JFK175', DATE '2026-10-18', '185008.21-JFK.H-JFK01-08-U'),
    (368, 'transit', 'JFK175', DATE '2026-10-18', '185010.21-JFK.H-JFK01-10-U'),
    (368, 'transit', 'JFK175', DATE '2026-10-18', '185002.21-JFK.H-JFK01-02-U'),
    (368, 'transit', 'JFK175', DATE '2026-10-18', '185003.21-JFK.H-JFK01-03-U'),
    (368, 'transit', 'JFK175', DATE '2026-10-18', '185004.21-JFK.H-JFK01-04-U'),
    (368, 'transit', 'JFK175', DATE '2026-10-18', '185006.21-JFK.H-JFK01-06-U'),
    (368, 'transit', 'JFK175', DATE '2026-10-18', '185001.21-JFK.H-JFK01-01-U'),
    (369, 'transit', 'BWI.H', DATE '2026-10-18', '185484.25-BWI.H-BWI01-15-H'),
    (369, 'transit', 'BWI.H', DATE '2026-10-18', '185485.25-BWI.H-BWI01-16-H'),
    (369, 'transit', 'BWI.H', DATE '2026-10-18', '185486.25-BWI.H-BWI01-17-H'),
    (369, 'transit', 'BWI.H', DATE '2026-10-18', '185487.25-BWI.H-BWI01-18-H'),
    (369, 'transit', 'BWI.H', DATE '2026-10-18', '185488.25-BWI.H-BWI01-19-H'),
    (369, 'transit', 'BWI.H', DATE '2026-10-18', '185489.25-BWI.H-BWI01-20-H'),
    (369, 'transit', 'BWI.H', DATE '2026-10-18', '185490.25-BWI.H-BWI01-21-H')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date IS NOT DISTINCT FROM v.effective_date
);
