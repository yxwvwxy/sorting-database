-- Pull tab: configured non-JFK chutes with latest batch volume 1..99.

DROP FUNCTION IF EXISTS public.barrel_pull_list(timestamptz);

CREATE OR REPLACE FUNCTION public.barrel_pull_list(p_subbatch text DEFAULT NULL)
RETURNS TABLE (
  ops_date date,
  subbatch text,
  batch_phase integer,
  scraped_at timestamptz,
  chute_id integer,
  volume integer
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH picked AS (
    SELECT s.subbatch, s.subbatch_date, s.batch_phase, s.scraped_at
    FROM public.subbatch s
    WHERE p_subbatch IS NULL OR s.subbatch = p_subbatch
    ORDER BY
      CASE WHEN p_subbatch IS NULL THEN 0 ELSE 1 END,
      s.scraped_at DESC
    LIMIT 1
  ),
  configured AS (
    SELECT DISTINCT d.chute_id
    FROM (
      SELECT g.chute_id, g.destination_warehouse, g.effective_date, g.end_date
      FROM public.chute_destination_gofo g
      UNION ALL
      SELECT r.chute_id, r.destination_warehouse, r.effective_date, r.end_date
      FROM public.chute_destination_resort r
    ) d
    JOIN picked p
      ON (d.effective_date IS NULL OR d.effective_date <= p.subbatch_date)
     AND (d.end_date IS NULL OR d.end_date >= p.subbatch_date)
    WHERE d.destination_warehouse IS NULL
       OR d.destination_warehouse NOT ILIKE '%JFK%'
  )
  SELECT
    p.subbatch_date AS ops_date,
    p.subbatch,
    p.batch_phase,
    p.scraped_at,
    cv.chute_id,
    cv.volume::integer AS volume
  FROM picked p
  JOIN public.chute_volume cv
    ON cv.subbatch_id = p.subbatch
   AND cv.scraped_at = p.scraped_at
  JOIN configured cfg ON cfg.chute_id = cv.chute_id
  WHERE cv.volume > 0
    AND cv.volume < 100
  ORDER BY
    CASE
      WHEN cv.chute_id >= 10000 AND cv.chute_id % 100 = 1
        THEN cv.chute_id / 100
      ELSE cv.chute_id
    END,
    cv.chute_id;
$$;

COMMENT ON FUNCTION public.barrel_pull_list(text) IS
  'Configured non-JFK chutes whose latest scrape volume for the batch is between 1 and 99. Physical split ids sort together.';

REVOKE ALL ON FUNCTION public.barrel_pull_list(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.barrel_pull_list(text) TO service_role, authenticated, anon;

NOTIFY pgrst, 'reload schema';
