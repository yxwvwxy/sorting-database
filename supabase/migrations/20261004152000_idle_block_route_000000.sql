-- Idle and block chutes keep no warehouse/city, but the route number is 000000.

ALTER TABLE public.chute_destination DROP CONSTRAINT chk_all_rules;

UPDATE public.chute_destination
SET route = '000000'
WHERE note IN ('idle', 'block')
  AND route IS DISTINCT FROM '000000';

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
      AND sort_type = ANY (ARRAY['transit'::text, 'last_mile'::text])
    )
  );
