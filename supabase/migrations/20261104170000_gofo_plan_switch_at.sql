-- Mid-ops regular-plan cutovers store their clock in gofo_plan_switch.
-- Ops day 2026-10-29 used 12:10 ET. Ops day 2026-11-05 uses the scrape time
-- when batch 3 is first seen (458隔口配置 ends / 458隔口-多细分1103 starts).
-- Until that 11/5 switch_at is recorded, same-day cut rows stay on the prior plan.

CREATE TABLE IF NOT EXISTS public.gofo_plan_switch (
  ops_date date PRIMARY KEY,
  switch_at timestamptz NOT NULL,
  note text,
  recorded_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.gofo_plan_switch IS
  'Clock when a same-ops-day regular chute plan cutover takes effect. Scrapes before switch_at use the prior plan; scrapes at/after use the new plan.';

ALTER TABLE public.gofo_plan_switch ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS gofo_plan_switch_select_authenticated ON public.gofo_plan_switch;
CREATE POLICY gofo_plan_switch_select_authenticated
  ON public.gofo_plan_switch
  FOR SELECT
  TO authenticated
  USING (true);

GRANT SELECT ON public.gofo_plan_switch TO authenticated, anon, service_role;
GRANT ALL ON public.gofo_plan_switch TO service_role;

INSERT INTO public.gofo_plan_switch (ops_date, switch_at, note)
VALUES (
  DATE '2026-10-29',
  (DATE '2026-10-29' + TIME '12:10') AT TIME ZONE 'America/New_York',
  '458隔口配置 mid-day cutover'
)
ON CONFLICT (ops_date) DO NOTHING;

-- Same-ops-day mid-switch pattern (like 10/29): prior plan end_date and new
-- plan effective_date are both the ops day. Clock lives in gofo_plan_switch.
UPDATE public.chute_destination_gofo
SET end_date = DATE '2026-11-05'
WHERE end_date = DATE '2026-11-04';

CREATE OR REPLACE FUNCTION public.record_gofo_plan_switch(
  p_ops_date date,
  p_switch_at timestamptz,
  p_note text DEFAULT NULL
)
RETURNS timestamptz
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  existing timestamptz;
BEGIN
  SELECT switch_at INTO existing
  FROM public.gofo_plan_switch
  WHERE ops_date = p_ops_date;

  IF existing IS NOT NULL THEN
    RETURN existing;
  END IF;

  INSERT INTO public.gofo_plan_switch (ops_date, switch_at, note)
  VALUES (
    p_ops_date,
    p_switch_at,
    COALESCE(p_note, 'regular plan cutover')
  );

  -- Chutes absent from 458隔口-多细分1103 end when that plan starts.
  IF p_ops_date = DATE '2026-11-05' THEN
    UPDATE public.chute_destination_gofo
    SET end_date = p_ops_date
    WHERE end_date IS NULL
      AND chute_id IN (269, 320)
      AND (effective_date IS NULL OR effective_date <= p_ops_date);
  END IF;

  RETURN p_switch_at;
END;
$$;

COMMENT ON FUNCTION public.record_gofo_plan_switch(date, timestamptz, text) IS
  'Record the scrape-time clock for a same-ops-day regular plan cutover. Idempotent per ops_date.';

REVOKE ALL ON FUNCTION public.record_gofo_plan_switch(date, timestamptz, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.record_gofo_plan_switch(date, timestamptz, text) TO service_role;

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
          WHEN (SELECT same_day_cut FROM switch)
           AND (
             (SELECT switch_at FROM switch) IS NULL
             OR cv.scraped_at < (SELECT switch_at FROM switch)
           )
            THEN 'morning'
          ELSE 'afternoon'
        END AS phase
      FROM public.chute_volume cv
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
  'Gofo city totals by section. On same-day plan cutovers, scrapes before gofo_plan_switch.switch_at use the prior plan; later scrapes use the new plan. Until switch_at is recorded, all scrapes stay on the prior plan.';

REVOKE ALL ON FUNCTION public.gofo_city_volume_series(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.gofo_city_volume_series(text) TO service_role, authenticated, anon;

NOTIFY pgrst, 'reload schema';
