-- From ops day 2026-11-22 segment C:
--   PVD + AVP move into EWR.H-400
--   the former EWR.H-1160 bucket is renamed EWR.H-500
-- A/B of 2026-11-22 (and earlier split days) keep the prior 400/1160 rule.

CREATE OR REPLACE FUNCTION public.gofo_physical_warehouse(
  p_destination text,
  p_city text,
  p_ops_date date DEFAULT NULL,
  p_batch_phase int DEFAULT NULL
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
      AND (
        p_ops_date IS NULL
        OR p_ops_date > DATE '2026-11-22'
        OR (p_ops_date = DATE '2026-11-22' AND COALESCE(p_batch_phase, 3) = 3)
      )
      AND upper(left(regexp_replace(btrim(coalesce(p_city, '')), '[^A-Za-z]', '', 'g'), 3))
        IN (
          'BOS', 'MHT', 'HYA', 'ALB', 'BUF', 'ERI', 'PIT', 'ROC', 'ORH', 'LDJ', 'SYR',
          'PVD', 'AVP'
        )
      THEN 'EWR.H-400'
    WHEN p_destination = 'EWR.H'
      AND (
        p_ops_date IS NULL
        OR p_ops_date > DATE '2026-11-22'
        OR (p_ops_date = DATE '2026-11-22' AND COALESCE(p_batch_phase, 3) = 3)
      )
      THEN 'EWR.H-500'
    WHEN p_destination = 'EWR.H'
      AND upper(left(regexp_replace(btrim(coalesce(p_city, '')), '[^A-Za-z]', '', 'g'), 3))
        IN ('BOS', 'MHT', 'HYA', 'ALB', 'BUF', 'ERI', 'PIT', 'ROC', 'ORH', 'LDJ', 'SYR')
      THEN 'EWR.H-400'
    WHEN p_destination = 'EWR.H' THEN 'EWR.H-1160'
    ELSE NULL
  END;
$$;

COMMENT ON FUNCTION public.gofo_physical_warehouse(text, text, date, int) IS
  'Actual receiving WH. From 2026-11-22 C: EWR.H-400 includes PVD/AVP; other EWR is EWR.H-500. 2026-11-08..11/22 A/B keep 400/1160. Pre-2026-11-08 EWR is EWR.H-500. BWI is BWI.H-709.';

-- Drop 3-arg overload if still present; keep a compatible wrapper.
DROP FUNCTION IF EXISTS public.gofo_physical_warehouse(text, text, date);

CREATE OR REPLACE FUNCTION public.gofo_physical_warehouse(
  p_destination text,
  p_city text,
  p_ops_date date DEFAULT NULL
)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT public.gofo_physical_warehouse(p_destination, p_city, p_ops_date, NULL::int);
$$;

REVOKE ALL ON FUNCTION public.gofo_physical_warehouse(text, text, date) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.gofo_physical_warehouse(text, text, date, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.gofo_physical_warehouse(text, text, date) TO service_role, authenticated, anon;
GRANT EXECUTE ON FUNCTION public.gofo_physical_warehouse(text, text, date, int) TO service_role, authenticated, anon;

-- Current-rule stored columns: PVD/AVP in 400; remaining EWR → 500.
ALTER TABLE public.chute_destination_gofo
  DROP COLUMN IF EXISTS physical_warehouse;

ALTER TABLE public.chute_destination_gofo
  ADD COLUMN physical_warehouse text
  GENERATED ALWAYS AS (
    CASE
      WHEN destination_warehouse = 'BWI.H' THEN 'BWI.H-709'
      WHEN destination_warehouse = 'EWR.H'
        AND upper(left(regexp_replace(
              btrim(coalesce(NULLIF(split_part(route, '-', 3), ''), '')),
              '[^A-Za-z]', '', 'g'
            ), 3))
          IN (
            'BOS', 'MHT', 'HYA', 'ALB', 'BUF', 'ERI', 'PIT', 'ROC', 'ORH', 'LDJ', 'SYR',
            'PVD', 'AVP'
          )
        THEN 'EWR.H-400'
      WHEN destination_warehouse = 'EWR.H' THEN 'EWR.H-500'
      ELSE NULL
    END
  ) STORED;

COMMENT ON COLUMN public.chute_destination_gofo.physical_warehouse IS
  'Current-rule actual receiving WH (EWR.H-400 incl. PVD/AVP / EWR.H-500 / BWI.H-709). Historical ops days use gofo_physical_warehouse().';

ALTER TABLE public.chute_destination_resort
  DROP COLUMN IF EXISTS physical_warehouse;

ALTER TABLE public.chute_destination_resort
  ADD COLUMN physical_warehouse text
  GENERATED ALWAYS AS (
    CASE
      WHEN destination_warehouse = 'BWI.H' THEN 'BWI.H-709'
      WHEN destination_warehouse = 'EWR.H'
        AND upper(left(regexp_replace(
              btrim(coalesce(NULLIF(split_part(route, '-', 3), ''), '')),
              '[^A-Za-z]', '', 'g'
            ), 3))
          IN (
            'BOS', 'MHT', 'HYA', 'ALB', 'BUF', 'ERI', 'PIT', 'ROC', 'ORH', 'LDJ', 'SYR',
            'PVD', 'AVP'
          )
        THEN 'EWR.H-400'
      WHEN destination_warehouse = 'EWR.H' THEN 'EWR.H-500'
      ELSE NULL
    END
  ) STORED;

COMMENT ON COLUMN public.chute_destination_resort.physical_warehouse IS
  'Current-rule actual receiving WH for secondary-split rows. Same EWR.H-400 / EWR.H-500 city split as regular.';
