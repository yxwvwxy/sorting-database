-- Past N *completed* ops days (exclude the in-progress ops day).
-- Split rows by uni_hub vs other sections (other still merges city across sections).

DROP FUNCTION IF EXISTS public.gofo_city_ac_daily_summary(int);

CREATE FUNCTION public.gofo_city_ac_daily_summary(p_days int DEFAULT 7)
RETURNS TABLE (
  ops_day date,
  section_group text,
  city text,
  volume bigint
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  et_ts timestamp := timezone('America/New_York', now());
  et_today date := et_ts::date;
  end_day date;
  start_day date;
  days int := GREATEST(COALESCE(p_days, 7), 1);
BEGIN
  -- Ops day D closes / D+1 opens at calendar D 16:30 ET (from ops day 2026-11-09).
  IF et_ts::time >= time '16:30' THEN
    end_day := et_today;
  ELSE
    end_day := et_today - 1;
  END IF;
  start_day := end_day - (days - 1);

  RETURN QUERY
  WITH batches AS (
    SELECT DISTINCT ON (s.subbatch_date, s.subbatch)
      s.subbatch_date AS ops_day,
      s.subbatch
    FROM public.subbatch s
    WHERE s.subbatch_date BETWEEN start_day AND end_day
      AND s.subbatch_date >= DATE '2026-10-18'
      AND COALESCE(s.batch_phase, 1) IN (1, 3)
      AND COALESCE(s.plan_kind, 'regular') <> 'resort_by_route'
    ORDER BY s.subbatch_date, s.subbatch, s.scraped_at DESC
  ),
  series AS (
    SELECT
      b.ops_day,
      b.subbatch,
      CASE WHEN v.section = 'uni_hub' THEN 'uni_hub' ELSE 'other' END AS section_group,
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
      s.section_group,
      s.city,
      SUM(s.total_volume)::bigint AS vol
    FROM series s
    JOIN latest l
      ON l.subbatch = s.subbatch
     AND l.scraped_at = s.scraped_at
    GROUP BY s.ops_day, s.section_group, s.city
  )
  SELECT f.ops_day, f.section_group, f.city, f.vol
  FROM final f
  ORDER BY f.ops_day DESC, f.section_group, f.city;
END;
$$;

COMMENT ON FUNCTION public.gofo_city_ac_daily_summary(int) IS
  'Past N completed ops days city volume (A+C only). section_group = uni_hub|other.';

REVOKE ALL ON FUNCTION public.gofo_city_ac_daily_summary(int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.gofo_city_ac_daily_summary(int) TO service_role, authenticated, anon;
