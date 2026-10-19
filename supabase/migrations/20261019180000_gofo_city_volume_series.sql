-- Gofo dashboard series. Does not change city_volume_series or City / hub.
-- Display city = first 3 letters of chute_destination_gofo.city.
-- A chute listed under more than one display city is counted once,
-- under the city with the most route rows (alphabetical tie-break).

CREATE OR REPLACE FUNCTION public.list_gofo_batches(p_limit int DEFAULT 30)
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
    WHERE s.subbatch_date >= DATE '2026-10-18'
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

COMMENT ON FUNCTION public.list_gofo_batches(int) IS
  'Scrape batches from ops day 2026-10-18 onward, for the Gofo tab.';

CREATE OR REPLACE FUNCTION public.gofo_city_volume_series(p_subbatch text DEFAULT NULL)
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
      (
        SELECT s.subbatch
        FROM public.subbatch s
        WHERE s.subbatch_date >= DATE '2026-10-18'
        ORDER BY s.scraped_at DESC
        LIMIT 1
      )
    ) AS subbatch
  ),
  meta AS (
    SELECT DISTINCT ON (s.subbatch)
      s.subbatch,
      s.subbatch_date
    FROM public.subbatch s
    JOIN chosen c ON c.subbatch = s.subbatch
    WHERE s.subbatch_date >= DATE '2026-10-18'
    ORDER BY s.subbatch, s.scraped_at DESC
  ),
  current_rows AS (
    SELECT d.chute_id, d.city
    FROM public.chute_destination_gofo d
    JOIN meta m ON TRUE
    JOIN (
      SELECT g.chute_id, max(g.effective_date) AS effective_date
      FROM public.chute_destination_gofo g
      JOIN meta m2 ON g.effective_date IS NULL OR g.effective_date <= m2.subbatch_date
      GROUP BY g.chute_id
    ) cur
      ON cur.chute_id = d.chute_id
     AND d.effective_date IS NOT DISTINCT FROM cur.effective_date
  ),
  ranked AS (
    SELECT
      r.chute_id,
      upper(left(regexp_replace(btrim(r.city), '[^A-Za-z]', '', 'g'), 3)) AS city,
      count(*) AS n
    FROM current_rows r
    GROUP BY 1, 2
  ),
  chute_map AS (
    SELECT DISTINCT ON (ranked.chute_id)
      ranked.chute_id,
      ranked.city
    FROM ranked
    WHERE ranked.city <> ''
    ORDER BY ranked.chute_id, ranked.n DESC, ranked.city
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
    m.subbatch,
    m.subbatch_date,
    s.scraped_at,
    cm.city,
    sum(s.volume)::bigint AS total_volume,
    sum(GREATEST(s.volume - COALESCE(s.prev_volume, 0), 0))::bigint AS delta_volume
  FROM snaps s
  JOIN meta m ON m.subbatch = s.subbatch_id
  JOIN chute_map cm ON cm.chute_id = s.chute_id
  GROUP BY m.subbatch, m.subbatch_date, s.scraped_at, cm.city
  ORDER BY s.scraped_at, cm.city;
$$;

COMMENT ON FUNCTION public.gofo_city_volume_series(text) IS
  'Gofo tab city totals. Groups chute_destination_gofo.city by its first 3 letters. Not used by City / hub.';

GRANT EXECUTE ON FUNCTION public.list_gofo_batches(int) TO service_role, authenticated, anon;
GRANT EXECUTE ON FUNCTION public.gofo_city_volume_series(text) TO service_role, authenticated, anon;

NOTIFY pgrst, 'reload schema';
