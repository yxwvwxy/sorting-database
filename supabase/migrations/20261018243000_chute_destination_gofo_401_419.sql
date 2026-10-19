-- New sorter map from the 2026-10-18 screenshots, chutes 401-419.
-- Warehouses are EWR.H, BWI.H, and JFK175, so routes are stored.

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
    (401::integer, 'transit'::text, 'EWR.H'::text, DATE '2026-10-18', '185640.22-EWR.H-PNE01-82-G'::text),
    (402, 'transit', 'EWR.H', DATE '2026-10-18', '185356.22-EWR.H-PNE01-81-G'),
    (403, 'transit', 'EWR.H', DATE '2026-10-18', '185639.22-EWR.H-PNE01-80-G'),
    (404, 'transit', 'EWR.H', DATE '2026-10-18', '185638.22-EWR.H-PNE01-56-G'),
    (405, 'transit', 'EWR.H', DATE '2026-10-18', '185450.22-EWR.H-TEB01-38-G'),
    (406, 'transit', 'EWR.H', DATE '2026-10-18', '185449.22-EWR.H-TEB01-37-G'),
    (407, 'transit', 'EWR.H', DATE '2026-10-18', '185448.22-EWR.H-TEB01-36-G'),
    (408, 'transit', 'EWR.H', DATE '2026-10-18', '185447.22-EWR.H-TEB01-35-G'),
    (409, 'transit', 'EWR.H', DATE '2026-10-18', '185446.22-EWR.H-TEB01-34-G'),
    (410, 'transit', 'EWR.H', DATE '2026-10-18', '185445.22-EWR.H-TEB01-33-G'),
    (411, 'transit', 'EWR.H', DATE '2026-10-18', '185444.22-EWR.H-TEB01-32-G'),
    (412, 'transit', 'EWR.H', DATE '2026-10-18', '185443.22-EWR.H-TEB01-31-G'),
    (413, 'transit', 'EWR.H', DATE '2026-10-18', '185442.22-EWR.H-TEB01-29-G'),
    (414, 'transit', 'EWR.H', DATE '2026-10-18', '185441.22-EWR.H-TEB01-28-G'),
    (415, 'transit', 'EWR.H', DATE '2026-10-18', '185440.22-EWR.H-TEB01-26-G'),
    (416, 'transit', 'BWI.H', DATE '2026-10-18', '185524.25-BWI.H-IAD01-031-H'),
    (416, 'transit', 'BWI.H', DATE '2026-10-18', '185525.25-BWI.H-IAD01-033-H'),
    (416, 'transit', 'BWI.H', DATE '2026-10-18', '185526.25-BWI.H-IAD01-037-H'),
    (416, 'transit', 'BWI.H', DATE '2026-10-18', '185527.25-BWI.H-IAD01-049-H'),
    (416, 'transit', 'BWI.H', DATE '2026-10-18', '185528.25-BWI.H-IAD01-050-H'),
    (416, 'transit', 'BWI.H', DATE '2026-10-18', '185529.25-BWI.H-IAD01-052-H'),
    (416, 'transit', 'BWI.H', DATE '2026-10-18', '185530.25-BWI.H-IAD01-053-H'),
    (416, 'transit', 'BWI.H', DATE '2026-10-18', '185664.25-BWI.H-IAD01-001-H'),
    (417, 'transit', 'JFK175', DATE '2026-10-18', '185185.22-EWR.H-FRG01-60-U'),
    (417, 'transit', 'JFK175', DATE '2026-10-18', '185186.22-EWR.H-FRG01-61-U'),
    (417, 'transit', 'JFK175', DATE '2026-10-18', '185187.22-EWR.H-FRG01-62-U'),
    (417, 'transit', 'JFK175', DATE '2026-10-18', '185188.22-EWR.H-FRG01-63-U'),
    (417, 'transit', 'JFK175', DATE '2026-10-18', '185189.22-EWR.H-FRG01-64-U'),
    (417, 'transit', 'JFK175', DATE '2026-10-18', '185191.22-EWR.H-FRG01-66-U'),
    (417, 'transit', 'JFK175', DATE '2026-10-18', '185193.22-EWR.H-FRG01-68-U'),
    (417, 'transit', 'JFK175', DATE '2026-10-18', '185194.22-EWR.H-FRG01-69-U'),
    (417, 'transit', 'JFK175', DATE '2026-10-18', '185190.22-EWR.H-FRG01-65-U'),
    (418, 'transit', 'JFK175', DATE '2026-10-18', '185176.22-EWR.H-FRG01-51-U'),
    (418, 'transit', 'JFK175', DATE '2026-10-18', '185177.22-EWR.H-FRG01-52-U'),
    (418, 'transit', 'JFK175', DATE '2026-10-18', '185178.22-EWR.H-FRG01-53-U'),
    (418, 'transit', 'JFK175', DATE '2026-10-18', '185179.22-EWR.H-FRG01-54-U'),
    (418, 'transit', 'JFK175', DATE '2026-10-18', '185182.22-EWR.H-FRG01-57-U'),
    (418, 'transit', 'JFK175', DATE '2026-10-18', '185183.22-EWR.H-FRG01-58-U'),
    (418, 'transit', 'JFK175', DATE '2026-10-18', '185184.22-EWR.H-FRG01-59-U'),
    (419, 'transit', 'BWI.H', DATE '2026-10-18', '185491.25-BWI.H-BWI01-22-H'),
    (419, 'transit', 'BWI.H', DATE '2026-10-18', '185492.25-BWI.H-BWI01-23-H'),
    (419, 'transit', 'BWI.H', DATE '2026-10-18', '185493.25-BWI.H-BWI01-24-H'),
    (419, 'transit', 'BWI.H', DATE '2026-10-18', '185494.25-BWI.H-BWI01-38-H'),
    (419, 'transit', 'BWI.H', DATE '2026-10-18', '185574.25-BWI.H-BWI01-027-H'),
    (419, 'transit', 'BWI.H', DATE '2026-10-18', '185656.25-BWI.H-BWI01-026-H'),
    (419, 'transit', 'BWI.H', DATE '2026-10-18', '185657.25-BWI.H-BWI01-043-H')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination_gofo d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date IS NOT DISTINCT FROM v.effective_date
);
