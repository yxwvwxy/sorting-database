-- Gofo bundle counts follow the selected batch: bundles created during
-- that ops day, through the batch's latest chute scrape.
-- The bundle tab is the previous 24 hours, at each bundle's latest status.
-- 2026-10-22 opens the next ops day at 18:30 ET. Every other evening is 19:30.

CREATE OR REPLACE FUNCTION public.ops_switch_at(p_day date)
RETURNS timestamptz
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT (
    p_day::timestamp
    + CASE
        WHEN p_day = DATE '2026-10-22' THEN TIME '18:30'
        ELSE TIME '19:30'
      END
  ) AT TIME ZONE 'America/New_York';
$$;

CREATE OR REPLACE FUNCTION public.ops_day_of(p_at timestamptz)
RETURNS date
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT CASE
    WHEN p_at >= public.ops_switch_at((p_at AT TIME ZONE 'America/New_York')::date)
      THEN (p_at AT TIME ZONE 'America/New_York')::date + 1
    ELSE (p_at AT TIME ZONE 'America/New_York')::date
  END;
$$;

COMMENT ON FUNCTION public.ops_switch_at(date) IS
  'Eastern instant when this calendar date opens the next ops day. 19:30, except 18:30 on 2026-10-22.';
COMMENT ON FUNCTION public.ops_day_of(timestamptz) IS
  'Ops day that contains this instant. The evening switch belongs to the next ops day.';

REVOKE ALL ON FUNCTION public.ops_switch_at(date) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.ops_day_of(timestamptz) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.gofo_bundle_counts(p_operation_date date)
RETURNS TABLE (
  warehouse text,
  city text,
  bundle_count bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH bounds AS (
    SELECT
      public.ops_switch_at(p_operation_date - 1) AS starts_at,
      public.ops_switch_at(p_operation_date) AS ends_at
  ),
  as_of AS (
    SELECT max(cv.scraped_at) AS scraped_at
    FROM public.chute_volume cv
    JOIN public.subbatch s ON s.subbatch = cv.subbatch_id
    WHERE s.subbatch_date = p_operation_date
  ),
  latest AS (
    SELECT DISTINCT ON (b.bundle_id)
      b.bundle_id,
      b.dest_transit_whs,
      b.area
    FROM public.bundle_snapshot b
    CROSS JOIN bounds
    CROSS JOIN as_of
    WHERE b.generated_time >= bounds.starts_at
      AND b.generated_time < bounds.ends_at
      AND b.generated_time <= COALESCE(as_of.scraped_at, bounds.ends_at)
    ORDER BY b.bundle_id, b.scraped_at DESC, b.generated_time DESC
  )
  SELECT
    l.dest_transit_whs AS warehouse,
    NULLIF(upper(split_part(NULLIF(l.area, '-'), '-', 1)), '') AS city,
    count(*)::bigint AS bundle_count
  FROM latest l
  WHERE l.dest_transit_whs IS NOT NULL
  GROUP BY 1, 2;
$$;

COMMENT ON FUNCTION public.gofo_bundle_counts(date) IS
  'Bundles created during the ops day, through that batch''s latest chute scrape. One row per destination warehouse and area city.';

REVOKE ALL ON FUNCTION public.gofo_bundle_counts(date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.gofo_bundle_counts(date) TO service_role, authenticated, anon;

CREATE OR REPLACE FUNCTION public.bundle_board(p_operation_date date)
RETURNS TABLE (
  row_kind text,
  group_name text,
  place text,
  bundle_count bigint,
  bundle_id text,
  warehouse text,
  area text,
  status text,
  shipment_count integer,
  generated_time timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH latest AS (
    SELECT DISTINCT ON (b.bundle_id)
      b.bundle_id,
      b.dest_transit_whs AS warehouse,
      b.area,
      b.status,
      b.generated_time,
      public.ops_day_of(b.generated_time) AS ops_day,
      NULLIF(upper(split_part(NULLIF(b.area, '-'), '-', 1)), '') AS area_city,
      CASE
        WHEN btrim(coalesce(b.shpt, '')) ~ '^[0-9]+(\.[0-9]+)?$'
          THEN btrim(b.shpt)::numeric::integer
        ELSE NULL
      END AS shipment_count
    FROM public.bundle_snapshot b
    WHERE b.generated_time >= now() - interval '24 hours'
    ORDER BY b.bundle_id, b.scraped_at DESC, b.generated_time DESC
  ),
  days AS (
    SELECT DISTINCT l.ops_day
    FROM latest l
    WHERE l.ops_day IS NOT NULL
  ),
  current_rows AS (
    SELECT d.ops_day, g.chute_id, g.destination_warehouse, g.sort_type, g.city
    FROM days d
    JOIN public.chute_destination_gofo g
      ON (g.effective_date IS NULL OR g.effective_date <= d.ops_day)
     AND (g.end_date IS NULL OR g.end_date >= d.ops_day)
    JOIN (
      SELECT d2.ops_day, g2.chute_id, max(g2.effective_date) AS effective_date
      FROM days d2
      JOIN public.chute_destination_gofo g2
        ON (g2.effective_date IS NULL OR g2.effective_date <= d2.ops_day)
       AND (g2.end_date IS NULL OR g2.end_date >= d2.ops_day)
      GROUP BY d2.ops_day, g2.chute_id
    ) cur
      ON cur.ops_day = d.ops_day
     AND cur.chute_id = g.chute_id
     AND g.effective_date IS NOT DISTINCT FROM cur.effective_date
  ),
  tagged AS (
    SELECT
      r.ops_day,
      r.chute_id,
      r.destination_warehouse AS warehouse,
      count(*) AS route_rows,
      count(DISTINCT city3) FILTER (WHERE coalesce(city3, '') <> '') AS city_n,
      min(city3) FILTER (WHERE coalesce(city3, '') <> '') AS only_city
    FROM (
      SELECT
        ops_day,
        chute_id,
        destination_warehouse,
        upper(left(regexp_replace(btrim(city), '[^A-Za-z]', '', 'g'), 3)) AS city3
      FROM current_rows
    ) r
    GROUP BY r.ops_day, r.chute_id, r.destination_warehouse
  ),
  one_cities AS (
    SELECT DISTINCT ops_day, only_city AS city
    FROM tagged
    WHERE warehouse = 'EWR.H' AND route_rows = 1 AND city_n = 1 AND only_city IS NOT NULL
  ),
  multi_cities AS (
    SELECT DISTINCT ops_day, only_city AS city
    FROM tagged
    WHERE warehouse = 'EWR.H' AND route_rows > 1 AND city_n = 1 AND only_city IS NOT NULL
  ),
  classed AS (
    SELECT
      l.*,
      COALESCE(
        l.warehouse = 'EWR.H' AND EXISTS (
          SELECT 1 FROM one_cities o
          WHERE o.ops_day = l.ops_day AND o.city = l.area_city
        ),
        false
      ) AS is_one,
      COALESCE(
        l.warehouse = 'EWR.H' AND EXISTS (
          SELECT 1 FROM multi_cities m
          WHERE m.ops_day = l.ops_day AND m.city = l.area_city
        ),
        false
      ) AS is_multi,
      CASE
        WHEN l.warehouse IS NULL THEN NULL
        WHEN l.warehouse = 'JFK175' THEN 'JFK'
        WHEN l.warehouse = 'PWM417' THEN 'PWM'
        WHEN l.warehouse IN ('BWI.H', 'EWR.H') THEN l.warehouse
        ELSE NULLIF(left(l.warehouse, 3), '')
      END AS hub_place
    FROM latest l
  )
  SELECT
    'count'::text,
    'uni_hub'::text,
    c.hub_place,
    count(*)::bigint,
    NULL::text,
    NULL::text,
    NULL::text,
    coalesce(c.status, ''),
    NULL::integer,
    NULL::timestamptz
  FROM classed c
  WHERE c.warehouse IS NOT NULL
    AND c.warehouse NOT IN ('EWR.H', 'BWI.H', 'JFK175', 'PWM417')
  GROUP BY c.hub_place, c.status
  UNION ALL
  SELECT 'count', 'jfk', 'JFK', count(*)::bigint, NULL, NULL, NULL, coalesce(status, ''), NULL, NULL
  FROM classed WHERE warehouse = 'JFK175'
  GROUP BY status
  UNION ALL
  SELECT 'count', 'pwm', 'PWM', count(*)::bigint, NULL, NULL, NULL, coalesce(status, ''), NULL, NULL
  FROM classed WHERE warehouse = 'PWM417'
  GROUP BY status
  UNION ALL
  SELECT 'count', 'ewr', 'EWR.H', count(*)::bigint, NULL, NULL, NULL, coalesce(status, ''), NULL, NULL
  FROM classed WHERE warehouse = 'EWR.H'
  GROUP BY status
  UNION ALL
  SELECT 'count', 'ewr_one', 'EWR.H', count(*)::bigint, NULL, NULL, NULL, coalesce(status, ''), NULL, NULL
  FROM classed WHERE is_one
  GROUP BY status
  UNION ALL
  SELECT 'count', 'ewr_multi', 'EWR.H', count(*)::bigint, NULL, NULL, NULL, coalesce(status, ''), NULL, NULL
  FROM classed WHERE is_multi
  GROUP BY status
  UNION ALL
  SELECT 'count', 'bwi', 'BWI.H', count(*)::bigint, NULL, NULL, NULL, coalesce(status, ''), NULL, NULL
  FROM classed WHERE warehouse = 'BWI.H'
  GROUP BY status
  UNION ALL
  SELECT
    'outlier',
    CASE WHEN is_one THEN 'ewr_one' ELSE 'other' END,
    hub_place,
    NULL::bigint,
    bundle_id,
    warehouse,
    area,
    status,
    shipment_count,
    generated_time
  FROM classed
  WHERE shipment_count < 100 OR shipment_count > 300;
$$;

COMMENT ON FUNCTION public.bundle_board(date) IS
  'Bundle tab for the previous 24 hours. p_operation_date is unused so older pages keep calling it. A bundle is counted once, at its latest status. One-route and multiple-route use the chute plan of the bundle''s own ops day.';

REVOKE ALL ON FUNCTION public.bundle_board(date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.bundle_board(date) TO service_role, authenticated, anon;

NOTIFY pgrst, 'reload schema';
