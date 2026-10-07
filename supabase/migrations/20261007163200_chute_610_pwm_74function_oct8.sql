-- Chute 610 adds 74function on 2026-10-08.
-- Warehouse and city are both PWM. Prior 740003 row stays for earlier ops days.
-- Region follows the existing PWM last-mile rows.

INSERT INTO public.chute_destination (
  chute_id, warehouse, city, route, region, sort_type, effective_date, note
)
SELECT v.chute_id, v.warehouse, v.city, v.route, v.region, v.sort_type, v.effective_date, v.note
FROM (VALUES
  (610, 'PWM', 'PWM', '74function', 'JFK', 'last_mile', DATE '2026-10-08', NULL::text)
) AS v(chute_id, warehouse, city, route, region, sort_type, effective_date, note)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date = v.effective_date
);
