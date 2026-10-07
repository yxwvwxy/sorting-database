-- Chutes 554, 608, 956, and 1002 switch to GOFO on 2026-10-08.
-- Warehouse is EWR.H. Region stays JFK, matching the existing EWR rows.
-- Prior rows stay for earlier ops days.

ALTER TABLE public.chute_destination DROP CONSTRAINT chk_all_rules;

ALTER TABLE public.chute_destination
  ADD CONSTRAINT chk_all_rules CHECK (
    (
      note = ANY (ARRAY['idle'::text, 'block'::text])
      AND warehouse IS NULL
      AND city IS NULL
      AND route = '000000'
      AND region IS NULL
      AND sort_type IS NULL
    )
    OR (
      note IS DISTINCT FROM 'idle'::text
      AND note IS DISTINCT FROM 'block'::text
      AND warehouse IS NOT NULL
      AND region IS NOT NULL
      AND sort_type = ANY (ARRAY['transit'::text, 'last_mile'::text, 'GOFO'::text])
    )
  );

INSERT INTO public.chute_destination (
  chute_id, warehouse, city, route, region, sort_type, effective_date, note
)
SELECT v.chute_id, v.warehouse, v.city, v.route, v.region, v.sort_type, v.effective_date, v.note
FROM (VALUES
  (554, 'EWR.H', 'LDJ01', '56', 'JFK', 'GOFO', DATE '2026-10-08', NULL::text),
  (608, 'EWR.H', 'LDJ01', '57', 'JFK', 'GOFO', DATE '2026-10-08', NULL),
  (956, 'EWR.H', 'TEB01', '17', 'JFK', 'GOFO', DATE '2026-10-08', NULL),
  (1002, 'EWR.H', 'TEB01', '16', 'JFK', 'GOFO', DATE '2026-10-08', NULL)
) AS v(chute_id, warehouse, city, route, region, sort_type, effective_date, note)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date = v.effective_date
);
