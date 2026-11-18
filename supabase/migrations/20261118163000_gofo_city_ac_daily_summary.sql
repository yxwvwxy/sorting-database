-- Rolling A+C city volume by ops day for Bundle & Sum tab.
-- Excludes B (secondary split / resort). Latest scrape per A/C batch.

CREATE OR REPLACE FUNCTION public.gofo_city_ac_daily_summary(p_days int DEFAULT 7)
RETURNS TABLE (
  ops_day date,
  city text,
  volume bigint
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  et_today date := (timezone('America/New_York', now()))::date;
  start_day date;
  days int := GREATEST(COALESCE(p_days, 7), 1);
  rec record;
BEGIN
  start_day = et_today - (days - 1);

  RETURN QUERY
  WITH batches AS (
    SELECT DISTINCT ON (s.subbatch_date, s.subbatch)
      s.subbatch_date AS ops_day,
      s.subbatch
    FROM public.subbatch s
    WHERE s.subbatch_date BETWEEN start_day AND et_today
      AND s.subbatch_date >= DATE '2026-10-18'
      AND COALESCE(s.batch_phase, 1) IN (1, 3)
      AND COALESCE(s.plan_kind, 'regular') <> 'resort_by_route'
    ORDER BY s.subbatch_date, s.subbatch, s.scraped_at DESC
  ),
  series AS (
    SELECT
      b.ops_day,
      b.subbatch,
      v.city,
      v.scraped_at,
      v.total_volume
    FROM batches b
    CROSS JOIN LATERAL public.gofo_city_volume_series(b.subbatch) v
    WHERE v.city IS NOT NULL
      AND v.section IS NOT NULL
  ),
  latest AS (
    SELECT subbatch, MAX(scraped_at) AS scraped_at
    FROM series
    GROUP BY subbatch
  ),
  final AS (
    SELECT
      s.ops_day,
      s.city,
      SUM(s.total_volume)::bigint AS vol
    FROM series s
    JOIN latest l
      ON l.subbatch = s.subbatch
     AND l.scraped_at = s.scraped_at
    GROUP BY s.ops_day, s.city
  )
  SELECT f.ops_day, f.city, f.vol
  FROM final f
  ORDER BY f.ops_day DESC, f.city;
END;
$$;

COMMENT ON FUNCTION public.gofo_city_ac_daily_summary(int) IS
  'Past N ops days city volume: final A+C scrapes only (excludes B secondary split).';

REVOKE ALL ON FUNCTION public.gofo_city_ac_daily_summary(int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.gofo_city_ac_daily_summary(int) TO service_role, authenticated, anon;
