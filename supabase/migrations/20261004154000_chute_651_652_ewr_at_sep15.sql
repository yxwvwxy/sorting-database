-- Chutes 651 and 652 move to EWR / AT on 2026-09-15.
-- Prior MDT rows stay for earlier ops days.

INSERT INTO public.chute_destination (
  chute_id, warehouse, city, route, region, sort_type, effective_date, note
)
SELECT v.chute_id, v.warehouse, v.city, v.route, v.region, v.sort_type, v.effective_date, v.note
FROM (VALUES
  (651, 'EWR', 'AT', '180004', 'JFK', 'last_mile', DATE '2026-09-15', NULL::text),
  (652, 'EWR', 'AT', '180003', 'JFK', 'last_mile', DATE '2026-09-15', NULL)
) AS v(chute_id, warehouse, city, route, region, sort_type, effective_date, note)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date = v.effective_date
);
