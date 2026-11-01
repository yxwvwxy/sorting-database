-- 2026-11-01: 17:10 ET is the last scrape of ops day 11/1;
-- 17:30 ET opens ops day 11/2.

CREATE OR REPLACE FUNCTION public.ops_switch_at(p_day date)
RETURNS timestamptz
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT (
    p_day::timestamp
    + CASE
        WHEN p_day = DATE '2026-11-01' THEN TIME '17:30'
        WHEN p_day IN (DATE '2026-10-22', DATE '2026-10-25') THEN TIME '18:30'
        ELSE TIME '19:30'
      END
  ) AT TIME ZONE 'America/New_York';
$$;

COMMENT ON FUNCTION public.ops_switch_at(date) IS
  'Eastern instant when this calendar date opens the next ops day. Default 19:30; 18:30 on 2026-10-22/25; 17:30 on 2026-11-01.';
