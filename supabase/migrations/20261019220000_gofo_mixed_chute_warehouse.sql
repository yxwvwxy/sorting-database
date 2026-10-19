-- Mixed chutes also return their destination warehouse so JFK175
-- lines can sit under the JFK / PWM section.

DROP FUNCTION IF EXISTS public.gofo_mixed_chutes(text);

CREATE FUNCTION public.gofo_mixed_chutes(p_subbatch text DEFAULT NULL)
RETURNS TABLE (
  chute_id integer,
  volume bigint,
  cities text,
  warehouse text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH chosen AS (
    SELECT COALESCE(
      NULLIF(btrim(p_subbatch), ''),
      (
        SELECT s.subbatch
        FROM public.subbatch s
        WHERE s.subbatch_date >= DATE '2026-10-18'
        ORDER BY s.scraped_at DESC
        LIMIT 1
      )
    ) AS subbatch
  ),
  meta AS (
    SELECT DISTINCT ON (s.subbatch)
      s.subbatch,
      s.subbatch_date
    FROM public.subbatch s
    JOIN chosen c ON c.subbatch = s.subbatch
    WHERE s.subbatch_date >= DATE '2026-10-18'
    ORDER BY s.subbatch, s.scraped_at DESC
  ),
  current_rows AS (
    SELECT d.chute_id, d.city, d.destination_warehouse
    FROM public.chute_destination_gofo d
    JOIN meta m ON TRUE
    JOIN (
      SELECT g.chute_id, max(g.effective_date) AS effective_date
      FROM public.chute_destination_gofo g
      JOIN meta m2 ON g.effective_date IS NULL OR g.effective_date <= m2.subbatch_date
      GROUP BY g.chute_id
    ) cur
      ON cur.chute_id = d.chute_id
     AND d.effective_date IS NOT DISTINCT FROM cur.effective_date
  ),
  mixed AS (
    SELECT
      r.chute_id,
      max(r.destination_warehouse) AS warehouse,
      string_agg(
        DISTINCT upper(left(regexp_replace(btrim(r.city), '[^A-Za-z]', '', 'g'), 3)),
        ', ' ORDER BY upper(left(regexp_replace(btrim(r.city), '[^A-Za-z]', '', 'g'), 3))
      ) AS cities
    FROM current_rows r
    WHERE coalesce(upper(left(regexp_replace(btrim(r.city), '[^A-Za-z]', '', 'g'), 3)), '') <> ''
    GROUP BY r.chute_id
    HAVING count(DISTINCT upper(left(regexp_replace(btrim(r.city), '[^A-Za-z]', '', 'g'), 3))) > 1
  ),
  latest AS (
    SELECT max(cv.scraped_at) AS scraped_at
    FROM public.chute_volume cv
    JOIN chosen c ON c.subbatch = cv.subbatch_id
  )
  SELECT
    mixed.chute_id,
    cv.volume::bigint,
    mixed.cities,
    mixed.warehouse
  FROM mixed
  JOIN latest l ON TRUE
  JOIN chosen c ON TRUE
  JOIN public.chute_volume cv
    ON cv.subbatch_id = c.subbatch
   AND cv.scraped_at = l.scraped_at
   AND cv.chute_id = mixed.chute_id
  ORDER BY mixed.chute_id;
$$;

COMMENT ON FUNCTION public.gofo_mixed_chutes(text) IS
  'Chutes whose gofo routes span more than one 3-letter city, with the latest chute volume and destination warehouse.';

GRANT EXECUTE ON FUNCTION public.gofo_mixed_chutes(text) TO service_role, authenticated, anon;

NOTIFY pgrst, 'reload schema';
