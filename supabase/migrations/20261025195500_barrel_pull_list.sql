-- Tue / Thu / Sun pull list for EWR.H one-route barrels.
-- A pull empties the barrel, so the next list starts the pull day itself
-- and stops the day before the next pull. About 200 is full.
-- Two-day lists (Tue, Thu, or a chute reset by a config change) use the
-- lowest 20-wide bucket from the last 7 closed days where the next day
-- reaches 200 at least 90% of the time. Three closed days use 200 itself.
-- A changed chute is bundled at the change, so only days on the current
-- route count.

CREATE OR REPLACE FUNCTION public.barrel_pull_list(p_as_of timestamptz DEFAULT now())
RETURNS TABLE (
  pull_date date,
  window_start date,
  window_end date,
  is_pull_day boolean,
  two_day_line integer,
  chute_id integer,
  route text,
  day_volumes jsonb,
  total integer,
  line integer
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH clock AS (
    SELECT (p_as_of AT TIME ZONE 'America/New_York') AS et
  ),
  params AS (
    SELECT
      et::date AS calendar_date,
      CASE
        WHEN et::time >= TIME '19:30' THEN et::date + 1
        ELSE et::date
      END AS ops_date,
      EXTRACT(DOW FROM et::date)::integer AS dow
    FROM clock
  ),
  schedule AS (
    SELECT
      p.ops_date,
      p.dow IN (0, 2, 4) AS is_pull_day,
      CASE p.dow
        WHEN 0 THEN p.calendar_date
        WHEN 1 THEN p.calendar_date + 1
        WHEN 2 THEN p.calendar_date
        WHEN 3 THEN p.calendar_date + 1
        WHEN 4 THEN p.calendar_date
        WHEN 5 THEN p.calendar_date + 2
        ELSE p.calendar_date + 1
      END AS pull_date
    FROM params p
  ),
  bounds AS (
    SELECT
      s.ops_date,
      s.is_pull_day,
      s.pull_date,
      CASE EXTRACT(DOW FROM s.pull_date)::integer
        WHEN 0 THEN s.pull_date - 3
        ELSE s.pull_date - 2
      END AS window_start,
      s.pull_date - 1 AS window_end,
      GREATEST(DATE '2026-10-18', s.ops_date - 7) AS history_start
    FROM schedule s
  ),
  snaps AS (
    SELECT DISTINCT ON (s.subbatch_date)
      s.subbatch_date AS ops_day,
      s.subbatch,
      s.scraped_at
    FROM public.subbatch s
    JOIN bounds b
      ON s.subbatch_date >= b.history_start
     AND s.subbatch_date < b.ops_date
    ORDER BY s.subbatch_date, s.scraped_at DESC
  ),
  closing AS (
    SELECT sn.ops_day, cv.chute_id, cv.volume
    FROM snaps sn
    JOIN public.chute_volume cv
      ON cv.subbatch_id = sn.subbatch
     AND cv.scraped_at = sn.scraped_at
  ),
  route_day AS (
    SELECT g.ops_day, g.chute_id, min(g.route) AS route
    FROM (
      SELECT sn.ops_day, d.chute_id, d.route
      FROM snaps sn
      JOIN public.chute_destination_gofo d
        ON (d.effective_date IS NULL OR d.effective_date <= sn.ops_day)
       AND (d.end_date IS NULL OR d.end_date >= sn.ops_day)
      WHERE d.destination_warehouse = 'EWR.H'
        AND d.sort_type = 'by_route'
        AND d.route IS NOT NULL
    ) g
    GROUP BY g.ops_day, g.chute_id
    HAVING count(*) = 1
  ),
  triples AS (
    SELECT
      COALESCE(c0.volume, 0) + COALESCE(c1.volume, 0) AS sum2,
      COALESCE(c0.volume, 0) + COALESCE(c1.volume, 0) + COALESCE(c2.volume, 0) AS stock
    FROM snaps d0
    JOIN snaps d1 ON d1.ops_day = d0.ops_day + 1
    JOIN snaps d2 ON d2.ops_day = d0.ops_day + 2
    JOIN route_day a0 ON a0.ops_day = d0.ops_day
    JOIN route_day a1
      ON a1.ops_day = d1.ops_day
     AND a1.chute_id = a0.chute_id
     AND a1.route = a0.route
    JOIN route_day a2
      ON a2.ops_day = d2.ops_day
     AND a2.chute_id = a0.chute_id
     AND a2.route = a0.route
    LEFT JOIN closing c0 ON c0.ops_day = d0.ops_day AND c0.chute_id = a0.chute_id
    LEFT JOIN closing c1 ON c1.ops_day = d1.ops_day AND c1.chute_id = a0.chute_id
    LEFT JOIN closing c2 ON c2.ops_day = d2.ops_day AND c2.chute_id = a0.chute_id
    WHERE COALESCE(c0.volume, 0) + COALESCE(c1.volume, 0) > 0
  ),
  buckets AS (
    SELECT
      ((sum2 / 20) * 20)::integer AS bucket,
      count(*) AS n,
      (count(*) FILTER (WHERE stock >= 200))::numeric / count(*) AS pct
    FROM triples
    GROUP BY 1
  ),
  line AS (
    SELECT COALESCE((
      SELECT min(b.bucket)
      FROM buckets b
      WHERE b.n >= 20
        AND b.pct >= 0.90
        AND NOT EXISTS (
          SELECT 1
          FROM buckets higher
          WHERE higher.bucket > b.bucket
            AND higher.n >= 20
            AND higher.pct < 0.90
        )
    ), 140)::integer AS two_day_line
  ),
  current_chute AS (
    SELECT g.chute_id, min(g.route) AS route
    FROM (
      SELECT d.chute_id, d.route
      FROM public.chute_destination_gofo d
      JOIN bounds b
        ON (d.effective_date IS NULL OR d.effective_date <= b.pull_date)
       AND (d.end_date IS NULL OR d.end_date >= b.pull_date)
      WHERE d.destination_warehouse = 'EWR.H'
        AND d.sort_type = 'by_route'
        AND d.route IS NOT NULL
    ) g
    GROUP BY g.chute_id
    HAVING count(*) = 1
  ),
  window_days AS (
    SELECT d::date AS ops_day
    FROM bounds b
    CROSS JOIN LATERAL generate_series(b.window_start, b.window_end, INTERVAL '1 day') AS d
  ),
  scored AS (
    SELECT
      c.chute_id,
      c.route,
      count(*) FILTER (WHERE rd.chute_id IS NOT NULL AND sn.ops_day IS NOT NULL)::integer AS counted_days,
      COALESCE(
        sum(cl.volume) FILTER (WHERE rd.chute_id IS NOT NULL AND sn.ops_day IS NOT NULL),
        0
      )::integer AS total,
      CASE
        WHEN count(*) FILTER (WHERE rd.chute_id IS NOT NULL AND sn.ops_day IS NOT NULL) >= 3 THEN 200
        ELSE (SELECT ln.two_day_line FROM line ln)
      END::integer AS applied_line,
      jsonb_agg(
        jsonb_build_object(
          'date', to_char(wd.ops_day, 'YYYY-MM-DD'),
          'volume', CASE
            WHEN rd.chute_id IS NOT NULL AND sn.ops_day IS NOT NULL THEN COALESCE(cl.volume, 0)
            ELSE NULL
          END,
          'counted', (rd.chute_id IS NOT NULL AND sn.ops_day IS NOT NULL)
        )
        ORDER BY wd.ops_day
      ) AS day_volumes
    FROM current_chute c
    CROSS JOIN window_days wd
    LEFT JOIN route_day rd
      ON rd.ops_day = wd.ops_day
     AND rd.chute_id = c.chute_id
     AND rd.route = c.route
    LEFT JOIN snaps sn ON sn.ops_day = wd.ops_day
    LEFT JOIN closing cl
      ON cl.ops_day = wd.ops_day
     AND cl.chute_id = c.chute_id
    GROUP BY c.chute_id, c.route
  ),
  picks AS (
    SELECT s.chute_id, s.route, s.day_volumes, s.total, s.applied_line
    FROM scored s
    WHERE s.counted_days >= 2
      AND s.total > 0
      AND s.total < s.applied_line
  )
  SELECT
    b.pull_date,
    b.window_start,
    b.window_end,
    b.is_pull_day,
    ln.two_day_line,
    p.chute_id,
    p.route,
    p.day_volumes,
    p.total,
    p.applied_line
  FROM picks p
  CROSS JOIN bounds b
  CROSS JOIN line ln
  WHERE b.is_pull_day
  UNION ALL
  SELECT
    b.pull_date,
    b.window_start,
    b.window_end,
    b.is_pull_day,
    ln.two_day_line,
    NULL::integer,
    NULL::text,
    NULL::jsonb,
    NULL::integer,
    NULL::integer
  FROM bounds b
  CROSS JOIN line ln
  WHERE NOT b.is_pull_day
     OR NOT EXISTS (SELECT 1 FROM picks);
$$;

COMMENT ON FUNCTION public.barrel_pull_list(timestamptz) IS
  'EWR.H one-route chutes to pull on Tuesday, Thursday, and Sunday.';

REVOKE ALL ON FUNCTION public.barrel_pull_list(timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.barrel_pull_list(timestamptz) TO service_role, authenticated, anon;
