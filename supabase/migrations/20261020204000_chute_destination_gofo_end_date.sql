-- end_date is the last ops day a row applies, inclusive.
-- Null means the row is still current. A changed chute keeps its old
-- effective_date and receives an end_date so later batches do not treat
-- the closed setting as still active with zero volume.

ALTER TABLE public.chute_destination_gofo
  ADD COLUMN end_date date;

ALTER TABLE public.chute_destination_gofo
  ADD CONSTRAINT chute_destination_gofo_end_after_effective_chk
  CHECK (end_date IS NULL OR effective_date IS NULL OR end_date >= effective_date);

COMMENT ON COLUMN public.chute_destination_gofo.end_date IS
  'Last ops day this row applies, inclusive. Null means the row is still current.';

UPDATE public.chute_destination_gofo
SET end_date = DATE '2026-10-19'
WHERE chute_id IN (
  267, 514, 515, 665,
  710, 711, 712, 713, 714, 715, 716,
  860, 861, 862, 863, 864, 865, 866,
  914, 915, 916
);

CREATE OR REPLACE FUNCTION public.gofo_city_volume_series(p_subbatch text DEFAULT NULL)
RETURNS TABLE (
  subbatch text,
  subbatch_date date,
  scraped_at timestamptz,
  section text,
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
    SELECT d.chute_id, d.destination_warehouse, d.sort_type, d.city
    FROM public.chute_destination_gofo d
    JOIN meta m ON TRUE
    JOIN (
      SELECT g.chute_id, max(g.effective_date) AS effective_date
      FROM public.chute_destination_gofo g
      JOIN meta m2
        ON (g.effective_date IS NULL OR g.effective_date <= m2.subbatch_date)
       AND (g.end_date IS NULL OR g.end_date >= m2.subbatch_date)
      GROUP BY g.chute_id
    ) cur
      ON cur.chute_id = d.chute_id
     AND d.effective_date IS NOT DISTINCT FROM cur.effective_date
     AND (d.end_date IS NULL OR d.end_date >= m.subbatch_date)
  ),
  tagged AS (
    SELECT
      r.chute_id,
      r.destination_warehouse AS warehouse,
      r.sort_type,
      upper(left(regexp_replace(btrim(r.city), '[^A-Za-z]', '', 'g'), 3)) AS city3
    FROM current_rows r
  ),
  chute_stats AS (
    SELECT
      t.chute_id,
      max(t.warehouse) AS warehouse,
      bool_or(t.sort_type = 'uni_hub') AS is_uni_hub,
      count(*) AS route_rows,
      count(DISTINCT t.city3) FILTER (WHERE coalesce(t.city3, '') <> '') AS city_n,
      min(t.city3) FILTER (WHERE coalesce(t.city3, '') <> '') AS only_city
    FROM tagged t
    GROUP BY t.chute_id
  ),
  chute_map AS (
    SELECT
      s.chute_id,
      CASE
        WHEN s.city_n > 1 THEN NULL
        WHEN s.warehouse = 'BWI.H' THEN 'bwi'
        WHEN s.is_uni_hub THEN 'uni_hub'
        WHEN s.warehouse IN ('JFK175', 'PWM417') THEN 'jfk_pwm'
        WHEN s.warehouse = 'EWR.H' AND s.route_rows = 1 THEN 'ewr_one'
        WHEN s.warehouse = 'EWR.H' AND s.route_rows > 1 THEN 'ewr_multi'
        ELSE NULL
      END AS section,
      CASE
        WHEN s.city_n > 1 THEN NULL
        WHEN s.warehouse = 'PWM417' THEN 'PWM'
        ELSE s.only_city
      END AS city
    FROM chute_stats s
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
    cm.section,
    cm.city,
    sum(s.volume)::bigint AS total_volume,
    sum(GREATEST(s.volume - COALESCE(s.prev_volume, 0), 0))::bigint AS delta_volume
  FROM snaps s
  JOIN meta m ON m.subbatch = s.subbatch_id
  JOIN chute_map cm ON cm.chute_id = s.chute_id
  WHERE cm.section IS NOT NULL
    AND coalesce(cm.city, '') <> ''
  GROUP BY m.subbatch, m.subbatch_date, s.scraped_at, cm.section, cm.city
  ORDER BY s.scraped_at, cm.section, cm.city;
$$;

COMMENT ON FUNCTION public.gofo_city_volume_series(text) IS
  'Gofo city totals by section. A chute row applies when effective_date <= the ops day and end_date is null or still on or after that day.';

CREATE OR REPLACE FUNCTION public.gofo_mixed_chutes(p_subbatch text DEFAULT NULL)
RETURNS TABLE (
  chute_id integer,
  volume bigint,
  cities text,
  warehouse text
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
    SELECT d.chute_id, d.city, d.destination_warehouse
    FROM public.chute_destination_gofo d
    JOIN meta m ON TRUE
    JOIN (
      SELECT g.chute_id, max(g.effective_date) AS effective_date
      FROM public.chute_destination_gofo g
      JOIN meta m2
        ON (g.effective_date IS NULL OR g.effective_date <= m2.subbatch_date)
       AND (g.end_date IS NULL OR g.end_date >= m2.subbatch_date)
      GROUP BY g.chute_id
    ) cur
      ON cur.chute_id = d.chute_id
     AND d.effective_date IS NOT DISTINCT FROM cur.effective_date
     AND (d.end_date IS NULL OR d.end_date >= m.subbatch_date)
  ),
  mixed AS (
    SELECT
      r.chute_id,
      max(r.destination_warehouse) AS warehouse,
      string_agg(
        DISTINCT upper(left(regexp_replace(btrim(r.city), '[^A-Za-z]', '', 'g'), 3)),
        ', ' ORDER BY upper(left(regexp_replace(btrim(r.city), '[^A-Za-z]', '', 'g'), 3))
      ) AS cities
    FROM current_rows r
    WHERE coalesce(upper(left(regexp_replace(btrim(r.city), '[^A-Za-z]', '', 'g'), 3)), '') <> ''
    GROUP BY r.chute_id
    HAVING count(DISTINCT upper(left(regexp_replace(btrim(r.city), '[^A-Za-z]', '', 'g'), 3))) > 1
  ),
  latest AS (
    SELECT max(cv.scraped_at) AS scraped_at
    FROM public.chute_volume cv
    JOIN chosen c ON c.subbatch = cv.subbatch_id
  )
  SELECT
    mixed.chute_id,
    cv.volume::bigint,
    mixed.cities,
    mixed.warehouse
  FROM mixed
  JOIN latest l ON TRUE
  JOIN chosen c ON TRUE
  JOIN public.chute_volume cv
    ON cv.subbatch_id = c.subbatch
   AND cv.scraped_at = l.scraped_at
   AND cv.chute_id = mixed.chute_id
  ORDER BY mixed.chute_id;
$$;

COMMENT ON FUNCTION public.gofo_mixed_chutes(text) IS
  'Chutes whose current gofo routes span more than one 3-letter city. Rows with an end_date before the ops day are not current.';

NOTIFY pgrst, 'reload schema';
