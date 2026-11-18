-- Persist completed-ops-day A+C city totals. Dashboard reads this table;
-- recompute only when a completed day is missing.

CREATE TABLE IF NOT EXISTS public.gofo_city_ac_daily (
  ops_day date NOT NULL,
  section_group text NOT NULL CHECK (section_group IN ('uni_hub', 'other')),
  city text NOT NULL,
  volume bigint NOT NULL DEFAULT 0,
  refreshed_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (ops_day, section_group, city)
);

COMMENT ON TABLE public.gofo_city_ac_daily IS
  'Final A+C city volumes by completed ops day. B (resort) excluded.';

ALTER TABLE public.gofo_city_ac_daily ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS gofo_city_ac_daily_select ON public.gofo_city_ac_daily;
CREATE POLICY gofo_city_ac_daily_select
  ON public.gofo_city_ac_daily
  FOR SELECT
  TO authenticated, anon
  USING (true);

REVOKE ALL ON TABLE public.gofo_city_ac_daily FROM PUBLIC;
GRANT SELECT ON TABLE public.gofo_city_ac_daily TO service_role, authenticated, anon;

-- Recompute one ops day from latest A and C scrapes only (no full time series).
CREATE OR REPLACE FUNCTION public.refresh_gofo_city_ac_daily(p_ops_day date)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  batch_rec record;
BEGIN
  IF p_ops_day IS NULL OR p_ops_day < DATE '2026-10-18' THEN
    RETURN;
  END IF;

  DELETE FROM public.gofo_city_ac_daily WHERE ops_day = p_ops_day;

  FOR batch_rec IN
    SELECT DISTINCT ON (s.subbatch)
      s.subbatch,
      s.batch_phase
    FROM public.subbatch s
    WHERE s.subbatch_date = p_ops_day
      AND COALESCE(s.batch_phase, 1) IN (1, 3)
      AND COALESCE(s.plan_kind, 'regular') <> 'resort_by_route'
    ORDER BY s.subbatch, s.scraped_at DESC
  LOOP
    INSERT INTO public.gofo_city_ac_daily (ops_day, section_group, city, volume, refreshed_at)
    WITH meta AS (
      SELECT p_ops_day AS subbatch_date, batch_rec.subbatch AS subbatch
    ),
    switch AS (
      SELECT
        EXISTS (
          SELECT 1 FROM public.chute_destination_gofo g
          WHERE g.effective_date = p_ops_day
        )
        AND EXISTS (
          SELECT 1 FROM public.chute_destination_gofo g
          WHERE g.end_date = p_ops_day
        ) AS same_day_cut,
        (
          SELECT ps.switch_at
          FROM public.gofo_plan_switch ps
          WHERE ps.ops_date = p_ops_day
        ) AS switch_at
    ),
    morning_cur AS (
      SELECT g.chute_id, max(g.effective_date) AS effective_date
      FROM public.chute_destination_gofo g
      WHERE (g.effective_date IS NULL OR g.effective_date < p_ops_day)
        AND (g.end_date IS NULL OR g.end_date >= p_ops_day)
      GROUP BY g.chute_id
    ),
    afternoon_cur AS (
      SELECT g.chute_id, max(g.effective_date) AS effective_date
      FROM public.chute_destination_gofo g
      WHERE (g.effective_date IS NULL OR g.effective_date <= p_ops_day)
        AND (
          CASE
            WHEN (SELECT same_day_cut FROM switch)
              THEN g.end_date IS NULL
                OR g.end_date > p_ops_day
                OR g.effective_date = p_ops_day
            ELSE g.end_date IS NULL OR g.end_date >= p_ops_day
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
      WHERE d.end_date IS NULL OR d.end_date >= p_ops_day
    ),
    afternoon_rows AS (
      SELECT d.chute_id, d.destination_warehouse, d.sort_type, d.city
      FROM public.chute_destination_gofo d
      JOIN afternoon_cur cur
        ON cur.chute_id = d.chute_id
       AND d.effective_date IS NOT DISTINCT FROM cur.effective_date
      WHERE CASE
        WHEN (SELECT same_day_cut FROM switch)
          THEN d.end_date IS NULL
            OR d.end_date > p_ops_day
            OR d.effective_date = p_ops_day
        ELSE d.end_date IS NULL OR d.end_date >= p_ops_day
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
    latest AS (
      SELECT MAX(cv.scraped_at) AS scraped_at
      FROM public.chute_volume cv
      WHERE cv.subbatch_id = batch_rec.subbatch
    ),
    phase_pick AS (
      SELECT
        CASE
          WHEN (SELECT same_day_cut FROM switch) THEN
            CASE
              WHEN batch_rec.batch_phase = 1 THEN 'morning'
              WHEN batch_rec.batch_phase = 3 THEN 'afternoon'
              WHEN (SELECT switch_at FROM switch) IS NULL THEN 'morning'
              ELSE 'afternoon'
            END
          ELSE 'afternoon'
        END AS phase
    ),
    attributed AS (
      SELECT
        CASE WHEN cm.section = 'uni_hub' THEN 'uni_hub' ELSE 'other' END AS section_group,
        cm.city,
        cv.volume::bigint AS volume
      FROM public.chute_volume cv
      JOIN latest l ON l.scraped_at = cv.scraped_at
      JOIN map_from cm
        ON cm.chute_id = cv.chute_id
       AND cm.phase = (SELECT phase FROM phase_pick)
      WHERE cv.subbatch_id = batch_rec.subbatch
        AND cm.section IS NOT NULL
        AND coalesce(cm.city, '') <> ''
    ),
    summed AS (
      SELECT section_group, city, SUM(volume)::bigint AS volume
      FROM attributed
      GROUP BY section_group, city
    )
    SELECT
      p_ops_day,
      s.section_group,
      s.city,
      s.volume,
      now()
    FROM summed s
    ON CONFLICT (ops_day, section_group, city)
    DO UPDATE SET
      volume = public.gofo_city_ac_daily.volume + EXCLUDED.volume,
      refreshed_at = EXCLUDED.refreshed_at;
  END LOOP;
END;
$$;

COMMENT ON FUNCTION public.refresh_gofo_city_ac_daily(date) IS
  'Replace stored A+C city totals for one ops day from latest A/C scrapes.';

REVOKE ALL ON FUNCTION public.refresh_gofo_city_ac_daily(date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.refresh_gofo_city_ac_daily(date) TO service_role, authenticated, anon;

DROP FUNCTION IF EXISTS public.gofo_city_ac_daily_summary(int);

CREATE FUNCTION public.gofo_city_ac_daily_summary(p_days int DEFAULT 7)
RETURNS TABLE (
  ops_day date,
  section_group text,
  city text,
  volume bigint
)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  et_ts timestamp := timezone('America/New_York', now());
  et_today date := et_ts::date;
  end_day date;
  start_day date;
  days int := GREATEST(COALESCE(p_days, 7), 1);
  d date;
BEGIN
  IF et_ts::time >= time '16:30' THEN
    end_day := et_today;
  ELSE
    end_day := et_today - 1;
  END IF;
  start_day := end_day - (days - 1);

  d := start_day;
  WHILE d <= end_day LOOP
    IF d >= DATE '2026-10-18'
       AND NOT EXISTS (
         SELECT 1 FROM public.gofo_city_ac_daily t WHERE t.ops_day = d
       )
       AND EXISTS (
         SELECT 1 FROM public.subbatch s
         WHERE s.subbatch_date = d
           AND COALESCE(s.batch_phase, 1) IN (1, 3)
           AND COALESCE(s.plan_kind, 'regular') <> 'resort_by_route'
       )
    THEN
      PERFORM public.refresh_gofo_city_ac_daily(d);
    END IF;
    d := d + 1;
  END LOOP;

  RETURN QUERY
  SELECT t.ops_day, t.section_group, t.city, t.volume
  FROM public.gofo_city_ac_daily t
  WHERE t.ops_day BETWEEN start_day AND end_day
  ORDER BY t.ops_day DESC, t.section_group, t.city;
END;
$$;

COMMENT ON FUNCTION public.gofo_city_ac_daily_summary(int) IS
  'Read stored A+C city totals for the last N completed ops days; backfill missing days once.';

REVOKE ALL ON FUNCTION public.gofo_city_ac_daily_summary(int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.gofo_city_ac_daily_summary(int) TO service_role, authenticated, anon;
