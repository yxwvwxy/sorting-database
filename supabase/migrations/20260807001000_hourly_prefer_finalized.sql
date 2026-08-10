-- Prefer post-close (finalized) hourly captures for completed hours.
-- In-progress current hour still uses the latest scrape (:10/:30/:50 updates).

CREATE OR REPLACE FUNCTION public.hourly_throughput_series(p_subbatch text)
RETURNS TABLE (
  bucket_time timestamptz,
  hourly_volume integer,
  cumulative_volume integer,
  scraped_at timestamptz,
  first_scraped_at timestamptz,
  last_scraped_at timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  RETURN QUERY
  WITH bounds AS (
    SELECT
      COALESCE(
        (SELECT MIN(fs.scraped_at) FROM public.feed_station fs WHERE fs.subbatch_id = p_subbatch),
        (SELECT MIN(ht.scraped_at) FROM public.hourly_throughput ht WHERE ht.subbatch_id = p_subbatch)
      ) AS first_scraped_at,
      COALESCE(
        (SELECT MAX(fs.scraped_at) FROM public.feed_station fs WHERE fs.subbatch_id = p_subbatch),
        (SELECT MAX(ht.scraped_at) FROM public.hourly_throughput ht WHERE ht.subbatch_id = p_subbatch)
      ) AS last_scraped_at
  ),
  latest AS (
    SELECT DISTINCT ON (ht.bucket_time)
      (ht.bucket_time AT TIME ZONE 'UTC') AS bucket_time,
      ht.hourly_volume,
      ht.cumulative_volume,
      ht.scraped_at
    FROM public.hourly_throughput ht
    WHERE ht.subbatch_id = p_subbatch
    ORDER BY
      ht.bucket_time,
      -- Finalized (scraped after that ET clock hour closed) wins over in-progress.
      CASE
        WHEN ht.scraped_at >= (ht.bucket_time AT TIME ZONE 'America/New_York') + interval '1 hour'
          THEN 0
        ELSE 1
      END,
      -- Freeze completed hours on the first post-close capture.
      CASE
        WHEN ht.scraped_at >= (ht.bucket_time AT TIME ZONE 'America/New_York') + interval '1 hour'
          THEN ht.scraped_at
        ELSE 'infinity'::timestamptz
      END ASC,
      -- Current / not-yet-finalized hour: newest :10/:30/:50 update.
      ht.scraped_at DESC
  )
  SELECT
    l.bucket_time,
    l.hourly_volume,
    l.cumulative_volume,
    l.scraped_at,
    b.first_scraped_at,
    b.last_scraped_at
  FROM latest l
  CROSS JOIN bounds b
  ORDER BY l.bucket_time;
END;
$$;

COMMENT ON FUNCTION public.hourly_throughput_series(text) IS
  'One row per clock hour: finalized (first post-close) when available; else latest in-progress scrape.';

NOTIFY pgrst, 'reload schema';
