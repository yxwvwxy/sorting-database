-- 2026-10-25 opens the next ops day at 18:30 ET, same as 2026-10-22.
-- The 18:10 scrape stays on 2026-10-25. 18:30 reads the new batch.

CREATE OR REPLACE FUNCTION public.ops_switch_at(p_day date)
RETURNS timestamptz
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT (
    p_day::timestamp
    + CASE
        WHEN p_day IN (DATE '2026-10-22', DATE '2026-10-25') THEN TIME '18:30'
        ELSE TIME '19:30'
      END
  ) AT TIME ZONE 'America/New_York';
$$;

COMMENT ON FUNCTION public.ops_switch_at(date) IS
  'Eastern instant when this calendar date opens the next ops day. 19:30, except 18:30 on 2026-10-22 and 2026-10-25.';
