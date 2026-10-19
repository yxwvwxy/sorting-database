-- Ops days from 2026-10-18 stay in chute_destination_gofo, but are not
-- published through the GitHub dashboard RPCs until mapping is turned back on.

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
    WHERE s.subbatch_date < DATE '2026-10-18'
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

COMMENT ON FUNCTION public.list_scrape_batches(int) IS
  'Recent scrape batches for the dashboard. Ops days from 2026-10-18 are omitted.';

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
      (
        SELECT s.subbatch
        FROM public.subbatch s
        WHERE s.subbatch_date < DATE '2026-10-18'
        ORDER BY s.scraped_at DESC
        LIMIT 1
      )
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
  meta AS (
    SELECT subbatch, subbatch_date FROM batch_meta
    UNION
    SELECT i.subbatch_id, i.operation_date
    FROM public.city_initial_volume i
    JOIN chosen c ON c.subbatch = i.subbatch_id
    WHERE NOT EXISTS (SELECT 1 FROM batch_meta)
  ),
  initials AS (
    SELECT
      i.subbatch_id,
      i.city,
      i.initial_volume,
      i.scraped_at AS initial_scraped_at
    FROM public.city_initial_volume i
    JOIN chosen c ON c.subbatch = i.subbatch_id
    WHERE EXTRACT(HOUR FROM (i.scraped_at AT TIME ZONE 'America/New_York')) = 21
      AND EXTRACT(MINUTE FROM (i.scraped_at AT TIME ZONE 'America/New_York')) >= 30
      AND EXTRACT(MINUTE FROM (i.scraped_at AT TIME ZONE 'America/New_York')) < 50
  ),
  destinations AS (
    SELECT
      d.chute_id,
      d.warehouse,
      d.city,
      d.sort_type,
      d.effective_date,
      d.id,
      'legacy'::text AS source
    FROM public.chute_destination d
  ),
  chute_map AS (
    SELECT DISTINCT ON (m.subbatch, d.chute_id)
      m.subbatch,
      d.chute_id,
      CASE
        WHEN lower(coalesce(d.sort_type, '')) = 'transit'
          THEN NULLIF(btrim(d.warehouse), '')
        ELSE NULLIF(btrim(d.city), '')
      END AS city
    FROM meta m
    JOIN destinations d
      ON d.effective_date <= m.subbatch_date
     AND m.subbatch_date < DATE '2026-10-18'
     AND d.source = 'legacy'
    ORDER BY m.subbatch, d.chute_id, d.effective_date DESC NULLS LAST, d.id DESC
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
  ),
  chute_city AS (
    SELECT
      m.subbatch,
      m.subbatch_date,
      s.scraped_at,
      COALESCE(cm.city, 'Unmapped') AS city,
      sum(s.volume)::bigint AS chute_volume,
      sum(GREATEST(s.volume - COALESCE(s.prev_volume, 0), 0))::bigint AS delta_volume
    FROM snaps s
    JOIN meta m ON m.subbatch = s.subbatch_id
    LEFT JOIN chute_map cm
      ON cm.subbatch = s.subbatch_id
     AND cm.chute_id = s.chute_id
    WHERE m.subbatch_date < DATE '2026-10-18'
    GROUP BY m.subbatch, m.subbatch_date, s.scraped_at, COALESCE(cm.city, 'Unmapped')
  ),
  initial_only AS (
    SELECT
      i.subbatch_id AS subbatch,
      coalesce(m.subbatch_date, i2.operation_date) AS subbatch_date,
      i.initial_scraped_at AS scraped_at,
      i.city,
      i.initial_volume AS total_volume,
      i.initial_volume AS delta_volume
    FROM initials i
    JOIN public.city_initial_volume i2
      ON i2.subbatch_id = i.subbatch_id AND i2.city = i.city
    LEFT JOIN meta m ON m.subbatch = i.subbatch_id
    WHERE NOT EXISTS (SELECT 1 FROM snaps)
      AND coalesce(m.subbatch_date, i2.operation_date) < DATE '2026-10-18'
  ),
  with_initials AS (
    SELECT
      cc.subbatch,
      cc.subbatch_date,
      cc.scraped_at,
      cc.city,
      (cc.chute_volume + COALESCE(i.initial_volume, 0))::bigint AS total_volume,
      cc.delta_volume
    FROM chute_city cc
    LEFT JOIN initials i
      ON i.subbatch_id = cc.subbatch
     AND i.city = cc.city
  )
  SELECT * FROM with_initials
  UNION ALL
  SELECT * FROM initial_only
  ORDER BY scraped_at, city;
$$;

COMMENT ON FUNCTION public.city_volume_series(text) IS
  'City/hub series for the dashboard. Ops days before 2026-10-18 map through chute_destination. From 2026-10-18 the series is empty; chute_destination_gofo is not published here.';

GRANT EXECUTE ON FUNCTION public.list_scrape_batches(int) TO service_role, authenticated, anon;
GRANT EXECUTE ON FUNCTION public.city_volume_series(text) TO service_role, authenticated, anon;

NOTIFY pgrst, 'reload schema';
