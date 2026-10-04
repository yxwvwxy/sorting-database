-- Chute 569: placeholder route MDT is replaced from ops day 2026-09-15
-- by numeric route 580099. The 2026-06-01 row stays for earlier days.

INSERT INTO public.chute_destination (
  chute_id, warehouse, city, route, region, sort_type, effective_date, note
)
SELECT 569, 'MDT', 'MDT', '580099', 'JFK', 'last_mile', DATE '2026-09-15', NULL
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination d
  WHERE d.chute_id = 569
    AND d.route = '580099'
    AND d.effective_date = DATE '2026-09-15'
);
