-- Pull list: only configured chutes with closing volume in 1..199.

CREATE OR REPLACE FUNCTION public.barrel_pull_list(p_as_of timestamptz DEFAULT now())
RETURNS TABLE (
  ops_date date,
  chute_id integer,
  volume integer
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH clock AS (
    SELECT (p_as_of AT TIME ZONE 'America/New_York')::date AS ops_date
  ),
  configured AS (
    SELECT DISTINCT d.chute_id
    FROM public.chute_destination_gofo d
    JOIN clock c
      ON (d.effective_date IS NULL OR d.effective_date <= c.ops_date)
     AND (d.end_date IS NULL OR d.end_date >= c.ops_date)
  ),
  closing AS (
    SELECT cv.chute_id, cv.volume::integer AS volume
    FROM public.chute_volume cv
    JOIN clock c ON TRUE
    JOIN configured cfg ON cfg.chute_id = cv.chute_id
    JOIN LATERAL (
      SELECT s.subbatch, s.scraped_at
      FROM public.subbatch s
      WHERE s.subbatch_date = c.ops_date
      ORDER BY s.scraped_at DESC
      LIMIT 1
    ) sn ON cv.subbatch_id = sn.subbatch
     AND cv.scraped_at = sn.scraped_at
    WHERE cv.volume > 0
      AND cv.volume < 200
  )
  SELECT
    c.ops_date,
    cl.chute_id,
    cl.volume
  FROM closing cl
  CROSS JOIN clock c
  ORDER BY
    CASE
      WHEN cl.chute_id >= 10000 AND cl.chute_id % 100 = 1
        THEN cl.chute_id / 100
      ELSE cl.chute_id
    END,
    cl.chute_id;
$$;

COMMENT ON FUNCTION public.barrel_pull_list(timestamptz) IS
  'Configured chutes whose Eastern-calendar ops-day closing volume is between 1 and 199. Physical split ids sort together.';

NOTIFY pgrst, 'reload schema';
