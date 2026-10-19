-- New sorter map from the 2026-10-18 screenshots, chutes 1053-1070.
-- 1067-1070 suffixes are three digits. Chutes 1051 and 1052 were not on the screenshot.

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
    (1053::integer, 'transit'::text, 'EWR.H'::text, DATE '2026-10-18', '185293.22-EWR.H-PHL01-69-G'::text),
    (1054, 'transit', 'EWR.H', DATE '2026-10-18', '185292.22-EWR.H-PHL01-68-G'),
    (1055, 'transit', 'EWR.H', DATE '2026-10-18', '185291.22-EWR.H-PHL01-47-G'),
    (1056, 'transit', 'EWR.H', DATE '2026-10-18', '185290.22-EWR.H-PHL01-46-G'),
    (1057, 'transit', 'EWR.H', DATE '2026-10-18', '185289.22-EWR.H-PHL01-45-G'),
    (1058, 'transit', 'EWR.H', DATE '2026-10-18', '185288.22-EWR.H-PHL01-44-G'),
    (1059, 'transit', 'EWR.H', DATE '2026-10-18', '185287.22-EWR.H-PHL01-43-G'),
    (1060, 'transit', 'EWR.H', DATE '2026-10-18', '185286.22-EWR.H-PHL01-41-G'),
    (1061, 'transit', 'EWR.H', DATE '2026-10-18', '185285.22-EWR.H-PHL01-35-G'),
    (1062, 'transit', 'EWR.H', DATE '2026-10-18', '185284.22-EWR.H-PHL01-34-G'),
    (1063, 'transit', 'EWR.H', DATE '2026-10-18', '185283.22-EWR.H-PHL01-33-G'),
    (1064, 'transit', 'EWR.H', DATE '2026-10-18', '185282.22-EWR.H-PHL01-20-G'),
    (1065, 'transit', 'EWR.H', DATE '2026-10-18', '185281.22-EWR.H-PHL01-19-G'),
    (1066, 'transit', 'EWR.H', DATE '2026-10-18', '185280.22-EWR.H-PHL01-18-G'),
    (1067, 'transit', 'EWR.H', DATE '2026-10-18', '185279.22-EWR.H-PHL01-098-G'),
    (1068, 'transit', 'EWR.H', DATE '2026-10-18', '185278.22-EWR.H-PHL01-070-G'),
    (1069, 'transit', 'EWR.H', DATE '2026-10-18', '185277.22-EWR.H-PHL01-049-G'),
    (1070, 'transit', 'EWR.H', DATE '2026-10-18', '185276.22-EWR.H-PHL01-048-G')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route IS NOT DISTINCT FROM v.route
    AND d.effective_date IS NOT DISTINCT FROM v.effective_date
);
