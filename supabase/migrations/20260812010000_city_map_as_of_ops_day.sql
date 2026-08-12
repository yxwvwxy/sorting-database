-- Map chutes using the destination row effective for that batch's ops day
-- (latest effective_date <= subbatch_date), not the globally newest row.

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
    SELECT DISTINCT ON (bm.subbatch, d.chute_id)
      bm.subbatch,
      d.chute_id,
      CASE
        WHEN lower(coalesce(d.sort_type, '')) = 'transit'
          THEN NULLIF(btrim(d.warehouse), '')
        ELSE NULLIF(btrim(d.city), '')
      END AS city
    FROM batch_meta bm
    JOIN public.chute_destination d
      ON d.effective_date <= bm.subbatch_date
    ORDER BY bm.subbatch, d.chute_id, d.effective_date DESC NULLS LAST, d.id DESC
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
  LEFT JOIN chute_map m
    ON m.subbatch = s.subbatch_id
   AND m.chute_id = s.chute_id
  GROUP BY bm.subbatch, bm.subbatch_date, s.scraped_at, COALESCE(m.city, 'Unmapped')
  ORDER BY s.scraped_at, city;
$$;

COMMENT ON FUNCTION public.city_volume_series(text) IS
  'City/hub series: map each chute with destination effective for the batch ops day '
  '(latest effective_date <= subbatch_date). Transit uses warehouse; else city.';

NOTIFY pgrst, 'reload schema';
