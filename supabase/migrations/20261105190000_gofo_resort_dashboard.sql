-- Segment B uses 二次分拣模版1105: every configured chute is EWR.H by_route.
-- City totals and chute counts for that segment come from chute_destination_resort.

CREATE OR REPLACE FUNCTION public.gofo_resort_city_volume_series(p_subbatch text)
RETURNS TABLE (
  subbatch text,
  subbatch_date date,
  scraped_at timestamptz,
  section text,
  city text,
  total_volume bigint,
  delta_volume bigint,
  chute_count bigint
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  batch text;
BEGIN
  SELECT COALESCE(NULLIF(btrim(p_subbatch), ''), (
    SELECT s.subbatch
    FROM public.subbatch s
    WHERE s.plan_kind = 'resort_by_route'
    ORDER BY s.scraped_at DESC
    LIMIT 1
  )) INTO batch;

  IF batch IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH meta AS (
    SELECT DISTINCT ON (s.subbatch)
      s.subbatch,
      s.subbatch_date
    FROM public.subbatch s
    WHERE s.subbatch = batch
    ORDER BY s.subbatch, s.scraped_at DESC
  ),
  resort_map AS (
    SELECT DISTINCT ON (d.chute_id)
      d.chute_id,
      'ewr_one'::text AS section,
      upper(left(regexp_replace(btrim(d.city), '[^A-Za-z]', '', 'g'), 3)) AS city
    FROM public.chute_destination_resort d
    JOIN meta m
      ON (d.effective_date IS NULL OR d.effective_date <= m.subbatch_date)
     AND (d.end_date IS NULL OR d.end_date >= m.subbatch_date)
    WHERE d.destination_warehouse = 'EWR.H'
      AND d.sort_type = 'by_route'
      AND coalesce(d.city, '') <> ''
    ORDER BY d.chute_id, d.effective_date DESC NULLS LAST, d.id DESC
  ),
  snaps AS (
    SELECT
      cv.subbatch_id,
      cv.scraped_at,
      cv.chute_id,
      cv.volume,
      lag(cv.volume) OVER (
        PARTITION BY cv.subbatch_id, cv.chute_id
        ORDER BY cv.scraped_at
      ) AS prev_volume
    FROM public.chute_volume cv
    WHERE cv.subbatch_id = batch
  ),
  attributed AS (
    SELECT
      s.subbatch_id,
      s.scraped_at,
      s.chute_id,
      rm.section,
      rm.city,
      GREATEST(s.volume - COALESCE(s.prev_volume, 0), 0)::bigint AS delta_volume
    FROM snaps s
    JOIN resort_map rm ON rm.chute_id = s.chute_id
  ),
  per_scrape AS (
    SELECT
      a.subbatch_id,
      a.scraped_at,
      a.section,
      a.city,
      sum(a.delta_volume)::bigint AS delta_volume,
      count(DISTINCT a.chute_id)::bigint AS chute_count
    FROM attributed a
    GROUP BY a.subbatch_id, a.scraped_at, a.section, a.city
  ),
  scrape_times AS (
    SELECT DISTINCT s.subbatch_id, s.scraped_at
    FROM snaps s
  ),
  cities AS (
    SELECT DISTINCT p.section, p.city
    FROM per_scrape p
  ),
  grid AS (
    SELECT
      st.subbatch_id,
      st.scraped_at,
      c.section,
      c.city,
      COALESCE(p.delta_volume, 0)::bigint AS delta_volume,
      COALESCE(p.chute_count, 0)::bigint AS chute_count
    FROM scrape_times st
    CROSS JOIN cities c
    LEFT JOIN per_scrape p
      ON p.subbatch_id = st.subbatch_id
     AND p.scraped_at = st.scraped_at
     AND p.section = c.section
     AND p.city = c.city
  )
  SELECT
    m.subbatch,
    m.subbatch_date,
    g.scraped_at,
    g.section,
    g.city,
    sum(g.delta_volume) OVER (
      PARTITION BY g.section, g.city
      ORDER BY g.scraped_at
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )::bigint AS total_volume,
    g.delta_volume,
    g.chute_count
  FROM grid g
  JOIN meta m ON m.subbatch = g.subbatch_id
  ORDER BY g.scraped_at, g.section, g.city;
END;
$$;

COMMENT ON FUNCTION public.gofo_resort_city_volume_series(text) IS
  'Segment B city totals. Every resort chute is EWR.H one route. A and C keep gofo_city_volume_series.';

REVOKE ALL ON FUNCTION public.gofo_resort_city_volume_series(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.gofo_resort_city_volume_series(text) TO service_role, authenticated, anon;

CREATE OR REPLACE FUNCTION public.gofo_resort_chute_counts(p_operation_date date)
RETURNS TABLE (
  section text,
  place text,
  chute_count bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    'ewr_one'::text AS section,
    upper(left(regexp_replace(btrim(d.city), '[^A-Za-z]', '', 'g'), 3)) AS place,
    count(DISTINCT d.chute_id)::bigint AS chute_count
  FROM public.chute_destination_resort d
  WHERE d.destination_warehouse = 'EWR.H'
    AND d.sort_type = 'by_route'
    AND coalesce(d.city, '') <> ''
    AND (d.effective_date IS NULL OR d.effective_date <= p_operation_date)
    AND (d.end_date IS NULL OR d.end_date >= p_operation_date)
  GROUP BY 1, 2;
$$;

COMMENT ON FUNCTION public.gofo_resort_chute_counts(date) IS
  'Configured segment-B chute counts. All rows are EWR.H one route, grouped by city.';

REVOKE ALL ON FUNCTION public.gofo_resort_chute_counts(date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.gofo_resort_chute_counts(date) TO service_role, authenticated, anon;

NOTIFY pgrst, 'reload schema';
