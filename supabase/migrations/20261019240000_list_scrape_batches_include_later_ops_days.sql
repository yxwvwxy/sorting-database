-- Feed & hourly keeps the same board and reads list_scrape_batches.
-- Later ops days already have feed_station and hourly_throughput rows,
-- so include them again. City / hub still stops at 2026-10-16 in the page
-- and city_volume_series still omits ops days from 2026-10-18.

CREATE OR REPLACE FUNCTION public.list_scrape_batches(p_limit int DEFAULT 30)
RETURNS TABLE (
  subbatch text,
  subbatch_date date,
  scrape_count bigint,
  first_scraped_at timestamptz,
  last_scraped_at timestamptz,
  latest_total bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH batch_times AS (
    SELECT
      s.subbatch,
      s.subbatch_date,
      count(*)::bigint AS scrape_count,
      min(s.scraped_at) AS first_scraped_at,
      max(s.scraped_at) AS last_scraped_at
    FROM public.subbatch s
    GROUP BY s.subbatch, s.subbatch_date
  ),
  latest_vol AS (
    SELECT cv.subbatch_id, sum(cv.volume)::bigint AS latest_total
    FROM public.chute_volume cv
    JOIN (
      SELECT subbatch_id, max(scraped_at) AS scraped_at
      FROM public.chute_volume
      GROUP BY subbatch_id
    ) latest ON latest.subbatch_id = cv.subbatch_id AND latest.scraped_at = cv.scraped_at
    GROUP BY cv.subbatch_id
  )
  SELECT
    b.subbatch,
    b.subbatch_date,
    b.scrape_count,
    b.first_scraped_at,
    b.last_scraped_at,
    COALESCE(v.latest_total, 0) AS latest_total
  FROM batch_times b
  LEFT JOIN latest_vol v ON v.subbatch_id = b.subbatch
  ORDER BY b.last_scraped_at DESC
  LIMIT GREATEST(COALESCE(p_limit, 30), 1);
$$;

COMMENT ON FUNCTION public.list_scrape_batches(int) IS
  'Recent scrape batches. Feed & hourly shows every ops day. City / hub still filters to 2026-10-16 in the page.';

GRANT EXECUTE ON FUNCTION public.list_scrape_batches(int) TO service_role, authenticated, anon;

NOTIFY pgrst, 'reload schema';
