-- A chute with exactly one route number is sort_type by_route.
-- uni_hub rows have no route and stay uni_hub.

UPDATE public.chute_destination_gofo d
SET sort_type = 'by_route'
WHERE d.route IS NOT NULL
  AND d.chute_id IN (
    SELECT g.chute_id
    FROM public.chute_destination_gofo g
    WHERE g.route IS NOT NULL
    GROUP BY g.chute_id
    HAVING count(*) = 1
  );
