-- Ops day 2026-11-09 opens at 2026-11-08 16:30 ET (4pm–4pm window).
-- Corrects the prior migration that used 2026-11-10 as the first 16:30 day.

CREATE OR REPLACE FUNCTION public.ops_switch_at(p_day date)
RETURNS timestamptz
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT (
    timezone(
      'America/New_York',
      p_day + CASE
        WHEN p_day >= DATE '2026-11-08' THEN TIME '16:30'
        WHEN p_day = DATE '2026-11-01' THEN TIME '17:30'
        WHEN p_day IN (DATE '2026-10-22', DATE '2026-10-25') THEN TIME '18:30'
        ELSE TIME '19:30'
      END
    )
  )
$$;

COMMENT ON FUNCTION public.ops_switch_at(date) IS
  'Eastern instant when this calendar date opens the next ops day. From 2026-11-08: 16:30 (ops day +1); earlier default 19:30; 18:30 on 2026-10-22/25; 17:30 on 2026-11-01.';
