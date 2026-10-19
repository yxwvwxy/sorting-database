-- Chutes with more than one route are sort_type by_city.
-- Chute 118 is others and stays without a sort_type.

UPDATE public.chute_destination_gofo d
SET sort_type = 'by_city'
WHERE d.chute_id <> 118
  AND d.chute_id IN (
    SELECT g.chute_id
    FROM public.chute_destination_gofo g
    WHERE g.route IS NOT NULL
    GROUP BY g.chute_id
    HAVING count(*) > 1
  );
