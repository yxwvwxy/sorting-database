-- uni_hub chutes have no route, so city comes from the warehouse code.
-- ATL441 -> ATL. Other rows still take city from the third route segment.

ALTER TABLE public.chute_destination_gofo
  DROP COLUMN city;

ALTER TABLE public.chute_destination_gofo
  ADD COLUMN city text
  GENERATED ALWAYS AS (
    CASE
      WHEN sort_type = 'uni_hub' THEN NULLIF(left(destination_warehouse, 3), '')
      ELSE NULLIF(split_part(route, '-', 3), '')
    END
  ) STORED;

COMMENT ON COLUMN public.chute_destination_gofo.city IS
  'For uni_hub, the first three letters of destination_warehouse. Otherwise the third hyphen-separated segment of route.';
