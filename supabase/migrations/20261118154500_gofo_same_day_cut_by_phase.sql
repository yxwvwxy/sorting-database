-- Same-day regular-plan cutovers (A stays on prior plan, C uses new plan)
-- must key off segment/batch_phase, not scrape clock.
-- Late A closing scrapes (e.g. 11/11 14:10 on A Batch No) must keep morning map.

CREATE OR REPLACE FUNCTION public.gofo_city_volume_series(p_subbatch text DEFAULT NULL)
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
    switch AS (
      SELECT
        EXISTS (
          SELECT 1
          FROM public.chute_destination_gofo g
          JOIN meta m ON g.effective_date = m.subbatch_date
        )
        AND EXISTS (
          SELECT 1
          FROM public.chute_destination_gofo g
          JOIN meta m ON g.end_date = m.subbatch_date
        ) AS same_day_cut,
        (
          SELECT ps.switch_at
          FROM public.gofo_plan_switch ps
          JOIN meta m ON ps.ops_date = m.subbatch_date
        ) AS switch_at
    ),
    morning_cur AS (
      SELECT g.chute_id, max(g.effective_date) AS effective_date
      FROM public.chute_destination_gofo g
      JOIN meta m
        ON (g.effective_date IS NULL OR g.effective_date < m.subbatch_date)
       AND (g.end_date IS NULL OR g.end_date >= m.subbatch_date)
      GROUP BY g.chute_id
    ),
    afternoon_cur AS (
      SELECT g.chute_id, max(g.effective_date) AS effective_date
      FROM public.chute_destination_gofo g
      JOIN meta m
        ON (g.effective_date IS NULL OR g.effective_date <= m.subbatch_date)
       AND (
         CASE
           WHEN (SELECT same_day_cut FROM switch)
             THEN g.end_date IS NULL
               OR g.end_date > m.subbatch_date
               OR g.effective_date = m.subbatch_date
           ELSE g.end_date IS NULL OR g.end_date >= m.subbatch_date
         END
       )
      GROUP BY g.chute_id
    ),
    morning_rows AS (
      SELECT d.chute_id, d.destination_warehouse, d.sort_type, d.city
      FROM public.chute_destination_gofo d
      JOIN morning_cur cur
        ON cur.chute_id = d.chute_id
       AND d.effective_date IS NOT DISTINCT FROM cur.effective_date
      JOIN meta m ON (d.end_date IS NULL OR d.end_date >= m.subbatch_date)
    ),
    afternoon_rows AS (
      SELECT d.chute_id, d.destination_warehouse, d.sort_type, d.city
      FROM public.chute_destination_gofo d
      JOIN afternoon_cur cur
        ON cur.chute_id = d.chute_id
       AND d.effective_date IS NOT DISTINCT FROM cur.effective_date
      JOIN meta m ON TRUE
      WHERE CASE
        WHEN (SELECT same_day_cut FROM switch)
          THEN d.end_date IS NULL
            OR d.end_date > m.subbatch_date
            OR d.effective_date = m.subbatch_date
        ELSE d.end_date IS NULL OR d.end_date >= m.subbatch_date
      END
    ),
    map_from AS (
      SELECT
        phase,
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
      FROM (
        SELECT
          'morning'::text AS phase,
          t.chute_id,
          max(t.warehouse) AS warehouse,
          bool_or(t.sort_type = 'uni_hub') AS is_uni_hub,
          count(*) AS route_rows,
          count(DISTINCT t.city3) FILTER (WHERE coalesce(t.city3, '') <> '') AS city_n,
          min(t.city3) FILTER (WHERE coalesce(t.city3, '') <> '') AS only_city
        FROM (
          SELECT
            chute_id,
            destination_warehouse AS warehouse,
            sort_type,
            upper(left(regexp_replace(btrim(city), '[^A-Za-z]', '', 'g'), 3)) AS city3
          FROM morning_rows
        ) t
        GROUP BY t.chute_id
        UNION ALL
        SELECT
          'afternoon'::text AS phase,
          t.chute_id,
          max(t.warehouse) AS warehouse,
          bool_or(t.sort_type = 'uni_hub') AS is_uni_hub,
          count(*) AS route_rows,
          count(DISTINCT t.city3) FILTER (WHERE coalesce(t.city3, '') <> '') AS city_n,
          min(t.city3) FILTER (WHERE coalesce(t.city3, '') <> '') AS only_city
        FROM (
          SELECT
            chute_id,
            destination_warehouse AS warehouse,
            sort_type,
            upper(left(regexp_replace(btrim(city), '[^A-Za-z]', '', 'g'), 3)) AS city3
          FROM afternoon_rows
        ) t
        GROUP BY t.chute_id
      ) s
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
        ) AS prev_volume,
        CASE
          WHEN (SELECT same_day_cut FROM switch) THEN
            CASE
              -- A segment Batch No always uses pre-cut plan, even if scraped late.
              WHEN sb.batch_phase = 1 THEN 'morning'
              -- C segment Batch No always uses post-cut plan.
              WHEN sb.batch_phase = 3 THEN 'afternoon'
              -- Legacy / pre-phase rows: keep switch_at clock (e.g. 10/29 12:10).
              WHEN (SELECT switch_at FROM switch) IS NULL
                OR cv.scraped_at < (SELECT switch_at FROM switch)
                THEN 'morning'
              ELSE 'afternoon'
            END
          ELSE 'afternoon'
        END AS phase
      FROM public.chute_volume cv
      LEFT JOIN public.subbatch sb
        ON sb.subbatch = cv.subbatch_id
       AND sb.scraped_at = cv.scraped_at
      WHERE cv.subbatch_id = %L
    ),
    attributed AS (
      SELECT
        s.subbatch_id,
        s.scraped_at,
        s.chute_id,
        cm.section,
        cm.city,
        GREATEST(s.volume - COALESCE(s.prev_volume, 0), 0)::bigint AS delta_volume
      FROM snaps s
      JOIN map_from cm
        ON cm.chute_id = s.chute_id
       AND cm.phase = s.phase
      WHERE cm.section IS NOT NULL
        AND coalesce(cm.city, '') <> ''
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
    ORDER BY g.scraped_at, g.section, g.city
  $q$, batch, batch);
END;
$$;

COMMENT ON FUNCTION public.gofo_city_volume_series(text) IS
  'Gofo city totals by section. On same-day plan cutovers, A (batch_phase 1) keeps the prior plan and C (batch_phase 3) uses the new plan, regardless of scrape clock. Pre-phase rows still fall back to gofo_plan_switch.switch_at.';

COMMENT ON TABLE public.gofo_plan_switch IS
  'Clock/note for a same-ops-day regular chute plan cutover (usually C open). Segment mapping prefers subbatch.batch_phase; switch_at remains fallback for pre-phase scrapes.';

NOTIFY pgrst, 'reload schema';
