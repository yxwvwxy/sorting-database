-- Count mixed-city chutes in the Chute count table, by destination warehouse.

CREATE OR REPLACE FUNCTION public.gofo_chute_counts(p_operation_date date)
RETURNS TABLE (
  section text,
  place text,
  chute_count bigint
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
  chute_stats AS (
    SELECT
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
      FROM current_rows
    ) t
    GROUP BY t.chute_id
  ),
  mapped AS (
    SELECT
      CASE
        WHEN warehouse = 'BWI.H' THEN 'bwi'
        WHEN is_uni_hub THEN 'uni_hub'
        WHEN warehouse IN ('JFK175', 'PWM417') THEN 'jfk_pwm'
        WHEN warehouse = 'EWR.H' AND route_rows = 1 THEN 'ewr_one'
        WHEN warehouse = 'EWR.H' AND route_rows > 1 THEN 'ewr_multi'
        ELSE 'other'
      END AS section,
      CASE
        WHEN city_n > 1 THEN 'mixed'
        WHEN warehouse = 'PWM417' THEN 'PWM'
        ELSE only_city
      END AS place
    FROM chute_stats
  )
  SELECT
    m.section,
    m.place,
    count(*)::bigint AS chute_count
  FROM mapped m
  WHERE m.section IN ('uni_hub', 'jfk_pwm', 'ewr_one', 'ewr_multi', 'bwi')
  GROUP BY m.section, m.place;
$$;

COMMENT ON FUNCTION public.gofo_chute_counts(date) IS
  'Configured Gofo chute counts for an ops day, by section and place. Mixed-city chutes count under their destination warehouse with place = mixed.';

NOTIFY pgrst, 'reload schema';
