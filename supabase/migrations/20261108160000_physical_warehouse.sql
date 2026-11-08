-- Actual receiving physical warehouse, separate from UniMap destination_warehouse.
-- EWR.H destination stays EWR.H. From ops day 2026-11-08 it splits to EWR.H-400 / EWR.H-1160.
-- Before that ops day every EWR.H row maps to EWR.H-500 at query time.
-- BWI.H maps to BWI.H-709.

CREATE OR REPLACE FUNCTION public.gofo_physical_warehouse(
  p_destination text,
  p_city text,
  p_ops_date date DEFAULT NULL
)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_destination = 'BWI.H' THEN 'BWI.H-709'
    WHEN p_destination = 'EWR.H'
      AND p_ops_date IS NOT NULL
      AND p_ops_date < DATE '2026-11-08'
      THEN 'EWR.H-500'
    WHEN p_destination = 'EWR.H'
      AND upper(left(regexp_replace(btrim(coalesce(p_city, '')), '[^A-Za-z]', '', 'g'), 3))
        IN ('BOS', 'MHT', 'HYA', 'ALB', 'BUF', 'ERI', 'PIT', 'ROC', 'ORH', 'LDJ', 'SYR')
      THEN 'EWR.H-400'
    WHEN p_destination = 'EWR.H' THEN 'EWR.H-1160'
    ELSE NULL
  END;
$$;

COMMENT ON FUNCTION public.gofo_physical_warehouse(text, text, date) IS
  'Actual receiving WH. UniMap dest stays EWR.H/BWI.H. EWR splits 400/1160 from 2026-11-08; earlier EWR is EWR.H-500. BWI is BWI.H-709.';

REVOKE ALL ON FUNCTION public.gofo_physical_warehouse(text, text, date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.gofo_physical_warehouse(text, text, date) TO service_role, authenticated, anon;

ALTER TABLE public.chute_destination_gofo
  ADD COLUMN IF NOT EXISTS physical_warehouse text
  GENERATED ALWAYS AS (
    CASE
      WHEN destination_warehouse = 'BWI.H' THEN 'BWI.H-709'
      WHEN destination_warehouse = 'EWR.H'
        AND upper(left(regexp_replace(
              btrim(coalesce(NULLIF(split_part(route, '-', 3), ''), '')),
              '[^A-Za-z]', '', 'g'
            ), 3))
          IN ('BOS', 'MHT', 'HYA', 'ALB', 'BUF', 'ERI', 'PIT', 'ROC', 'ORH', 'LDJ', 'SYR')
        THEN 'EWR.H-400'
      WHEN destination_warehouse = 'EWR.H' THEN 'EWR.H-1160'
      ELSE NULL
    END
  ) STORED;

COMMENT ON COLUMN public.chute_destination_gofo.physical_warehouse IS
  'Current-rule actual receiving WH (EWR.H-400 / EWR.H-1160 / BWI.H-709). Pre-2026-11-08 EWR ops days still read as EWR.H-500 via gofo_physical_warehouse().';

ALTER TABLE public.chute_destination_resort
  ADD COLUMN IF NOT EXISTS physical_warehouse text
  GENERATED ALWAYS AS (
    CASE
      WHEN destination_warehouse = 'BWI.H' THEN 'BWI.H-709'
      WHEN destination_warehouse = 'EWR.H'
        AND upper(left(regexp_replace(
              btrim(coalesce(NULLIF(split_part(route, '-', 3), ''), '')),
              '[^A-Za-z]', '', 'g'
            ), 3))
          IN ('BOS', 'MHT', 'HYA', 'ALB', 'BUF', 'ERI', 'PIT', 'ROC', 'ORH', 'LDJ', 'SYR')
        THEN 'EWR.H-400'
      WHEN destination_warehouse = 'EWR.H' THEN 'EWR.H-1160'
      ELSE NULL
    END
  ) STORED;

COMMENT ON COLUMN public.chute_destination_resort.physical_warehouse IS
  'Current-rule actual receiving WH for secondary-split rows. Same EWR.H-400 / EWR.H-1160 city split as regular.';
