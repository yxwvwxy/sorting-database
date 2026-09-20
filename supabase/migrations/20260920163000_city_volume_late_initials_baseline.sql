-- Late first scrape of an ops day: 5-city totals are Workflow 存量 plus
-- chute increment after that scrape (not full overnight chute + afternoon warehouse).
-- 21:30 opening initials still add full subsequent chute (baseline 0).

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
      i.scraped_at AS initial_scraped_at,
      (
        EXTRACT(HOUR FROM (i.scraped_at AT TIME ZONE 'America/New_York')) = 21
        AND EXTRACT(MINUTE FROM (i.scraped_at AT TIME ZONE 'America/New_York')) >= 30
      ) AS is_opening
    FROM public.city_initial_volume i
    JOIN chosen c ON c.subbatch = i.subbatch_id
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
    JOIN public.chute_destination d
      ON d.effective_date <= m.subbatch_date
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
      sum(s.volume)::bigint AS chute_volume
    FROM snaps s
    JOIN meta m ON m.subbatch = s.subbatch_id
    LEFT JOIN chute_map cm
      ON cm.subbatch = s.subbatch_id
     AND cm.chute_id = s.chute_id
    GROUP BY m.subbatch, m.subbatch_date, s.scraped_at, COALESCE(cm.city, 'Unmapped')
  ),
  -- First chute snapshot at/after late initials: 5-city 隔口 baseline (not added to total).
  late_baseline AS (
    SELECT DISTINCT ON (cc.subbatch, cc.city)
      cc.subbatch,
      cc.city,
      cc.chute_volume AS baseline_chute
    FROM chute_city cc
    JOIN initials i
      ON i.subbatch_id = cc.subbatch
     AND i.city = cc.city
     AND NOT i.is_opening
    WHERE cc.scraped_at >= i.initial_scraped_at - interval '30 seconds'
    ORDER BY cc.subbatch, cc.city, cc.scraped_at
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
  ),
  combined AS (
    SELECT
      cc.subbatch,
      cc.subbatch_date,
      cc.scraped_at,
      cc.city,
      CASE
        WHEN i.initial_volume IS NOT NULL THEN
          (
            i.initial_volume
            + GREATEST(cc.chute_volume - COALESCE(b.baseline_chute, 0), 0)
          )::bigint
        ELSE cc.chute_volume
      END AS total_volume
    FROM chute_city cc
    LEFT JOIN initials i
      ON i.subbatch_id = cc.subbatch
     AND i.city = cc.city
    LEFT JOIN late_baseline b
      ON b.subbatch = cc.subbatch
     AND b.city = cc.city
  ),
  with_delta AS (
    SELECT
      subbatch,
      subbatch_date,
      scraped_at,
      city,
      total_volume,
      GREATEST(
        total_volume
        - COALESCE(
            lag(total_volume) OVER (
              PARTITION BY subbatch, city
              ORDER BY scraped_at
            ),
            0
          ),
        0
      )::bigint AS delta_volume
    FROM combined
  )
  SELECT * FROM with_delta
  UNION ALL
  SELECT * FROM initial_only
  ORDER BY scraped_at, city;
$$;

COMMENT ON FUNCTION public.city_volume_series(text) IS
  'City/hub series. Other cities: chute cumulative. RIC/ALB/SWF/SYR/PVD2: Workflow 存量 + chute increment after 存量 capture (full chute after 21:30 opening; late first scrape uses that scrape as 隔口 baseline).';

GRANT EXECUTE ON FUNCTION public.city_volume_series(text) TO service_role, authenticated, anon;

NOTIFY pgrst, 'reload schema';
