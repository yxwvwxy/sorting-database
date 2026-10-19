-- Record hub chutes in sort_type instead of route.
-- Rows whose route is uni_hub move that value to sort_type and clear route.

ALTER TABLE public.chute_destination_gofo
  ADD COLUMN sort_type text;

COMMENT ON COLUMN public.chute_destination_gofo.sort_type IS
  'Hub handling such as uni_hub. Individual route strings stay in route.';

UPDATE public.chute_destination_gofo
SET sort_type = route,
    route = NULL
WHERE route = 'uni_hub';
