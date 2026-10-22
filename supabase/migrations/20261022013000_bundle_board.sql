-- Bundle tab: unique bundle counts at the Gofo display grain, plus shipment
-- outliers. One route is an EWR.H city whose current chute has a single route.
-- Each bundle is its latest status, so the status history does not add rows.

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
  WITH current_rows AS (
    SELECT d.chute_id, d.destination_warehouse, d.sort_type, d.city
    FROM public.chute_destination_gofo d
    JOIN (
      SELECT g.chute_id, max(g.effective_date) AS effective_date
      FROM public.chute_destination_gofo g
      WHERE (g.effective_date IS NULL OR g.effective_date <= p_operation_date)
        AND (g.end_date IS NULL OR g.end_date >= p_operation_date)
      GROUP BY g.chute_id
    ) cur
      ON cur.chute_id = d.chute_id
     AND d.effective_date IS NOT DISTINCT FROM cur.effective_date
     AND (d.end_date IS NULL OR d.end_date >= p_operation_date)
  ),
  tagged AS (
    SELECT
      r.chute_id,
      r.destination_warehouse AS warehouse,
      count(*) AS route_rows,
      count(DISTINCT city3) FILTER (WHERE coalesce(city3, '') <> '') AS city_n,
      min(city3) FILTER (WHERE coalesce(city3, '') <> '') AS only_city
    FROM (
      SELECT
        chute_id,
        destination_warehouse,
        upper(left(regexp_replace(btrim(city), '[^A-Za-z]', '', 'g'), 3)) AS city3
      FROM current_rows
    ) r
    GROUP BY r.chute_id, r.destination_warehouse
  ),
  one_cities AS (
    SELECT DISTINCT only_city AS city
    FROM tagged
    WHERE warehouse = 'EWR.H' AND route_rows = 1 AND city_n = 1 AND only_city IS NOT NULL
  ),
  multi_cities AS (
    SELECT DISTINCT only_city AS city
    FROM tagged
    WHERE warehouse = 'EWR.H' AND route_rows > 1 AND city_n = 1 AND only_city IS NOT NULL
  ),
  latest AS (
    SELECT DISTINCT ON (b.bundle_id)
      b.bundle_id,
      b.dest_transit_whs AS warehouse,
      b.area,
      b.status,
      b.generated_time,
      NULLIF(upper(split_part(NULLIF(b.area, '-'), '-', 1)), '') AS area_city,
      CASE
        WHEN btrim(coalesce(b.shpt, '')) ~ '^[0-9]+(\.[0-9]+)?$'
          THEN btrim(b.shpt)::numeric::integer
        ELSE NULL
      END AS shipment_count
    FROM public.bundle_snapshot b
    WHERE b.operation_date = p_operation_date
    ORDER BY b.bundle_id, b.scraped_at DESC, b.generated_time DESC
  ),
  classed AS (
    SELECT
      l.*,
      COALESCE(
        l.warehouse = 'EWR.H' AND l.area_city IN (SELECT city FROM one_cities),
        false
      ) AS is_one,
      COALESCE(
        l.warehouse = 'EWR.H' AND l.area_city IN (SELECT city FROM multi_cities),
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
    NULL::text,
    NULL::integer,
    NULL::timestamptz
  FROM classed c
  WHERE c.warehouse IS NOT NULL
    AND c.warehouse NOT IN ('EWR.H', 'BWI.H', 'JFK175', 'PWM417')
  GROUP BY c.hub_place
  UNION ALL
  SELECT 'count', 'jfk', 'JFK', count(*)::bigint, NULL, NULL, NULL, NULL, NULL, NULL
  FROM classed WHERE warehouse = 'JFK175'
  UNION ALL
  SELECT 'count', 'pwm', 'PWM', count(*)::bigint, NULL, NULL, NULL, NULL, NULL, NULL
  FROM classed WHERE warehouse = 'PWM417'
  UNION ALL
  SELECT 'count', 'ewr', 'EWR.H', count(*)::bigint, NULL, NULL, NULL, NULL, NULL, NULL
  FROM classed WHERE warehouse = 'EWR.H'
  UNION ALL
  SELECT 'count', 'ewr_one', 'EWR.H', count(*)::bigint, NULL, NULL, NULL, NULL, NULL, NULL
  FROM classed WHERE is_one
  UNION ALL
  SELECT 'count', 'ewr_multi', 'EWR.H', count(*)::bigint, NULL, NULL, NULL, NULL, NULL, NULL
  FROM classed WHERE is_multi
  UNION ALL
  SELECT 'count', 'bwi', 'BWI.H', count(*)::bigint, NULL, NULL, NULL, NULL, NULL, NULL
  FROM classed WHERE warehouse = 'BWI.H'
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
  'Bundle tab counts and shipment outliers. Counts are unique bundle ids. Outliers are the latest status whose shipment count is under 100 or over 300.';

REVOKE ALL ON FUNCTION public.bundle_board(date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.bundle_board(date) TO service_role, authenticated, anon;

NOTIFY pgrst, 'reload schema';
