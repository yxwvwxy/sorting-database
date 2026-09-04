-- ROC chutes 905-912: warehouse BUF→ROC, new routes effective 2026-09-02.
-- Keep prior 2026-06-01 rows for historical as-of mapping.
-- Chute 912 has two active routes (940008 + 94function), same pattern as BUF 45function.

INSERT INTO public.chute_destination (
  chute_id, warehouse, city, route, region, sort_type, effective_date, note
)
SELECT v.chute_id, v.warehouse, v.city, v.route, v.region, v.sort_type, v.effective_date, v.note
FROM (VALUES
  (905, 'ROC', 'ROC', '940007', 'JFK', 'last_mile', DATE '2026-09-02', NULL::text),
  (906, 'ROC', 'ROC', '940006', 'JFK', 'last_mile', DATE '2026-09-02', NULL),
  (907, 'ROC', 'ROC', '940005', 'JFK', 'last_mile', DATE '2026-09-02', NULL),
  (908, 'ROC', 'ROC', '940004', 'JFK', 'last_mile', DATE '2026-09-02', NULL),
  (909, 'ROC', 'ROC', '940003', 'JFK', 'last_mile', DATE '2026-09-02', NULL),
  (910, 'ROC', 'ROC', '940002', 'JFK', 'last_mile', DATE '2026-09-02', NULL),
  (911, 'ROC', 'ROC', '940001', 'JFK', 'last_mile', DATE '2026-09-02', NULL),
  (912, 'ROC', 'ROC', '940008', 'JFK', 'last_mile', DATE '2026-09-02', NULL),
  (912, 'ROC', 'ROC', '94function', 'JFK', 'last_mile', DATE '2026-09-02', NULL)
) AS v(chute_id, warehouse, city, route, region, sort_type, effective_date, note)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.effective_date = v.effective_date
);
