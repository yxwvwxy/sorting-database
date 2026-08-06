-- City-level totals and 20-min deltas from chute snapshots + chute_destination.city

CREATE OR REPLACE FUNCTION public.city_volume_series(p_subbatch text DEFAULT NULL)
RETURNS TABLE (
  subbatch text,
  subbatch_date date,
  scraped_at timestamptz,
  city text,
  total_volume bigint,
  delta_volume bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH chosen AS (
    SELECT COALESCE(
      NULLIF(btrim(p_subbatch), ''),
      (SELECT s.subbatch FROM public.subbatch s ORDER BY s.scraped_at DESC LIMIT 1)
    ) AS subbatch
  ),
  batch_meta AS (
    SELECT DISTINCT ON (s.subbatch)
      s.subbatch,
      s.subbatch_date
    FROM public.subbatch s
    JOIN chosen c ON c.subbatch = s.subbatch
    ORDER BY s.subbatch, s.scraped_at DESC
  ),
  chute_map AS (
    SELECT DISTINCT ON (d.chute_id)
      d.chute_id,
      COALESCE(NULLIF(btrim(d.city), ''), 'Unmapped') AS city
    FROM public.chute_destination d
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
    JOIN chosen c ON c.subbatch = cv.subbatch_id
  )
  SELECT
    bm.subbatch,
    bm.subbatch_date,
    s.scraped_at,
    COALESCE(m.city, 'Unmapped') AS city,
    sum(s.volume)::bigint AS total_volume,
    sum(GREATEST(s.volume - COALESCE(s.prev_volume, 0), 0))::bigint AS delta_volume
  FROM snaps s
  JOIN batch_meta bm ON bm.subbatch = s.subbatch_id
  LEFT JOIN chute_map m ON m.chute_id = s.chute_id
  GROUP BY bm.subbatch, bm.subbatch_date, s.scraped_at, COALESCE(m.city, 'Unmapped')
  ORDER BY s.scraped_at, city;
$$;

COMMENT ON FUNCTION public.city_volume_series(text) IS
  'Per-scrape city totals and increments (current chute total - previous scrape) for a subbatch.';

CREATE OR REPLACE FUNCTION public.list_scrape_batches(p_limit int DEFAULT 30)
RETURNS TABLE (
  subbatch text,
  subbatch_date date,
  scrape_count bigint,
  first_scraped_at timestamptz,
  last_scraped_at timestamptz,
  latest_total bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH batch_times AS (
    SELECT
      s.subbatch,
      s.subbatch_date,
      count(*)::bigint AS scrape_count,
      min(s.scraped_at) AS first_scraped_at,
      max(s.scraped_at) AS last_scraped_at
    FROM public.subbatch s
    GROUP BY s.subbatch, s.subbatch_date
  ),
  latest_vol AS (
    SELECT cv.subbatch_id, sum(cv.volume)::bigint AS latest_total
    FROM public.chute_volume cv
    JOIN (
      SELECT subbatch_id, max(scraped_at) AS scraped_at
      FROM public.chute_volume
      GROUP BY subbatch_id
    ) latest ON latest.subbatch_id = cv.subbatch_id AND latest.scraped_at = cv.scraped_at
    GROUP BY cv.subbatch_id
  )
  SELECT
    b.subbatch,
    b.subbatch_date,
    b.scrape_count,
    b.first_scraped_at,
    b.last_scraped_at,
    COALESCE(v.latest_total, 0) AS latest_total
  FROM batch_times b
  LEFT JOIN latest_vol v ON v.subbatch_id = b.subbatch
  ORDER BY b.last_scraped_at DESC
  LIMIT GREATEST(COALESCE(p_limit, 30), 1);
$$;

GRANT EXECUTE ON FUNCTION public.city_volume_series(text) TO service_role, authenticated, anon;
GRANT EXECUTE ON FUNCTION public.list_scrape_batches(int) TO service_role, authenticated, anon;
