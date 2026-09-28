-- ORF chutes 956-968 effective 2026-09-24.
-- Keep prior 2026-06-01 rows for historical as-of mapping.
-- Chute 956 has two routes on this date with different warehouses
-- (52function @ RIC, 96function @ ORF), so sibling rows may differ by warehouse.
-- Region and sort_type still have to match.

CREATE OR REPLACE FUNCTION public.trg_chute_destination_consistency()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  sibling record;
BEGIN
  -- Disabled chute: must not coexist with active rows for same chute + date
  IF NEW.note IN ('idle', 'block') THEN
    IF EXISTS (
      SELECT 1
      FROM public.chute_destination d
      WHERE d.chute_id = NEW.chute_id
        AND d.effective_date = NEW.effective_date
        AND (TG_OP = 'INSERT' OR d.ctid <> NEW.ctid)
        AND COALESCE(d.note, '') NOT IN ('idle', 'block')
    ) THEN
      RAISE EXCEPTION
        'chute_id % on % is disabled (note=%) but active destination rows already exist',
        NEW.chute_id, NEW.effective_date, NEW.note;
    END IF;
    RETURN NEW;
  END IF;

  -- Active row: must not coexist with a disabled row for same chute + date
  IF EXISTS (
    SELECT 1
    FROM public.chute_destination d
    WHERE d.chute_id = NEW.chute_id
      AND d.effective_date = NEW.effective_date
      AND (TG_OP = 'INSERT' OR d.ctid <> NEW.ctid)
      AND d.note IN ('idle', 'block')
  ) THEN
    RAISE EXCEPTION
      'chute_id % on % is disabled; cannot insert or update an active destination row',
      NEW.chute_id, NEW.effective_date;
  END IF;

  -- Active row: region / sort_type must match sibling active rows.
  -- Warehouse may differ (chute 956 on 2026-09-24: 52function@RIC and 96function@ORF).
  SELECT d.region, d.sort_type
  INTO sibling
  FROM public.chute_destination d
  WHERE d.chute_id = NEW.chute_id
    AND d.effective_date = NEW.effective_date
    AND (TG_OP = 'INSERT' OR d.ctid <> NEW.ctid)
    AND COALESCE(d.note, '') NOT IN ('idle', 'block')
  LIMIT 1;

  IF FOUND THEN
    IF NEW.region IS DISTINCT FROM sibling.region
       OR NEW.sort_type IS DISTINCT FROM sibling.sort_type
    THEN
      RAISE EXCEPTION
        'inconsistent destination for chute_id % on %: existing (region=%, sort_type=%) vs new (region=%, sort_type=%)',
        NEW.chute_id,
        NEW.effective_date,
        sibling.region,
        sibling.sort_type,
        NEW.region,
        NEW.sort_type;
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

INSERT INTO public.chute_destination (
  chute_id, warehouse, city, route, region, sort_type, effective_date, note
)
SELECT v.chute_id, v.warehouse, v.city, v.route, v.region, v.sort_type, v.effective_date, v.note
FROM (VALUES
  (956, 'RIC', 'ORF', '52function', 'JFK', 'last_mile', DATE '2026-09-24', NULL::text),
  (956, 'ORF', 'ORF', '96function', 'JFK', 'last_mile', DATE '2026-09-24', NULL),
  (957, 'ORF', 'ORF', '960007', 'JFK', 'last_mile', DATE '2026-09-24', NULL),
  (958, 'ORF', 'ORF', '960001', 'JFK', 'last_mile', DATE '2026-09-24', NULL),
  (959, 'ORF', 'ORF', '960009', 'JFK', 'last_mile', DATE '2026-09-24', NULL),
  (960, 'ORF', 'ORF', '960010', 'JFK', 'last_mile', DATE '2026-09-24', NULL),
  (961, 'ORF', 'ORF', '960011', 'JFK', 'last_mile', DATE '2026-09-24', NULL),
  (962, 'ORF', 'ORF', '960012', 'JFK', 'last_mile', DATE '2026-09-24', NULL),
  (963, 'ORF', 'ORF', '960006', 'JFK', 'last_mile', DATE '2026-09-24', NULL),
  (964, 'ORF', 'ORF', '960004', 'JFK', 'last_mile', DATE '2026-09-24', NULL),
  (965, 'ORF', 'ORF', '960005', 'JFK', 'last_mile', DATE '2026-09-24', NULL),
  (966, 'ORF', 'ORF', '960003', 'JFK', 'last_mile', DATE '2026-09-24', NULL),
  (967, 'ORF', 'ORF', '960008', 'JFK', 'last_mile', DATE '2026-09-24', NULL),
  (968, 'ORF', 'ORF', '960002', 'JFK', 'last_mile', DATE '2026-09-24', NULL)
) AS v(chute_id, warehouse, city, route, region, sort_type, effective_date, note)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.chute_destination d
  WHERE d.chute_id = v.chute_id
    AND d.route = v.route
    AND d.warehouse = v.warehouse
    AND d.effective_date = v.effective_date
);
