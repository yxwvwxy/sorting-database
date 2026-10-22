-- The SQL function kept a generic plan and spilled hundreds of megabytes
-- while scanning every chute volume. A 71-snap day took about 8s and the
-- dashboard statement was canceled. Plan it for the requested batch.

DROP FUNCTION IF EXISTS public.gofo_city_volume_series(text);

CREATE FUNCTION public.gofo_city_volume_series(p_subbatch text DEFAULT NULL)
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
  SELECT COALESCE(
    NULLIF(btrim(p_subbatch), ''),
    (
      SELECT s.subbatch
      FROM public.subbatch s
      WHERE s.subbatch_date >= DATE '2026-10-18'
      ORDER BY s.scraped_at DESC
      LIMIT 1
    )
  )
  INTO batch;

  RETURN QUERY EXECUTE format($q$
    WITH meta AS (
      SELECT DISTINCT ON (s.subbatch)
        s.subbatch,
        s.subbatch_date
      FROM public.subbatch s
      WHERE s.subbatch = %L
        AND s.subbatch_date >= DATE '2026-10-18'
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
      WHERE cv.subbatch_id = %L
    )
    SELECT
      m.subbatch,
      m.subbatch_date,
      s.scraped_at,
      cm.section,
      cm.city,
      sum(s.volume)::bigint AS total_volume,
      sum(GREATEST(s.volume - COALESCE(s.prev_volume, 0), 0))::bigint AS delta_volume,
      count(DISTINCT s.chute_id)::bigint AS chute_count
    FROM snaps s
    JOIN meta m ON m.subbatch = s.subbatch_id
    JOIN chute_map cm ON cm.chute_id = s.chute_id
    WHERE cm.section IS NOT NULL
      AND coalesce(cm.city, '') <> ''
    GROUP BY m.subbatch, m.subbatch_date, s.scraped_at, cm.section, cm.city
    ORDER BY s.scraped_at, cm.section, cm.city
  $q$, batch, batch);
END;
$$;

COMMENT ON FUNCTION public.gofo_city_volume_series(text) IS
  'Gofo city totals by section, with the number of chutes in each city. Planned for the requested batch.';

REVOKE ALL ON FUNCTION public.gofo_city_volume_series(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.gofo_city_volume_series(text) TO service_role, authenticated, anon;

NOTIFY pgrst, 'reload schema';
