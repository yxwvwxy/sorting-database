-- Daily pull list: Eastern calendar day N shows ops day N closing volumes
-- under 200. Physical left/right splits (101 / 10101) sort together.

DROP FUNCTION IF EXISTS public.barrel_pull_list(timestamptz);

CREATE FUNCTION public.barrel_pull_list(p_as_of timestamptz DEFAULT now())
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
  closing AS (
    SELECT cv.chute_id, cv.volume::integer AS volume
    FROM public.chute_volume cv
    JOIN clock c ON TRUE
    JOIN LATERAL (
      SELECT s.subbatch, s.scraped_at
      FROM public.subbatch s
      WHERE s.subbatch_date = c.ops_date
      ORDER BY s.scraped_at DESC
      LIMIT 1
    ) sn ON cv.subbatch_id = sn.subbatch
     AND cv.scraped_at = sn.scraped_at
    WHERE cv.volume < 200
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
  'Chutes whose closing volume on the Eastern calendar ops day is under 200. Physical split ids (101 / 10101) sort together.';

REVOKE ALL ON FUNCTION public.barrel_pull_list(timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.barrel_pull_list(timestamptz) TO service_role, authenticated, anon;

NOTIFY pgrst, 'reload schema';
