-- Feed station series for hourly stacked dashboard.

CREATE OR REPLACE FUNCTION public.station_name(p_station_id integer)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_station_id
    WHEN 1 THEN 'Upper station 1'
    WHEN 2 THEN 'Upper station 2'
    WHEN 3 THEN 'Upper station 3'
    WHEN 4 THEN 'Upper station 4'
    WHEN 5 THEN 'Upper station 5'
    WHEN 6 THEN 'Lower station 1'
    WHEN 7 THEN 'Lower station 2'
    WHEN 8 THEN 'Lower station 3'
    WHEN 9 THEN 'Lower station 4'
    WHEN 10 THEN 'Lower station 5'
    ELSE 'Station ' || p_station_id::text
  END;
$$;

CREATE OR REPLACE FUNCTION public.feed_station_series(p_subbatch text)
RETURNS TABLE (
  station_id integer,
  station_name text,
  scraped_at timestamptz,
  volume bigint,
  is_hour_boundary boolean
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
  SELECT
    fs.station_id,
    public.station_name(fs.station_id) AS station_name,
    fs.scraped_at,
    fs.volume::bigint,
    (
      EXTRACT(MINUTE FROM (fs.scraped_at AT TIME ZONE 'America/New_York')) BETWEEN 25 AND 40
    ) AS is_hour_boundary
  FROM public.feed_station fs
  WHERE fs.subbatch_id = p_subbatch
  ORDER BY fs.scraped_at, fs.station_id;
END;
$$;

COMMENT ON FUNCTION public.feed_station_series(text) IS
  'Per-scrape feed station volumes for a subbatch. is_hour_boundary marks ~:30 ET snapshots.';

REVOKE ALL ON FUNCTION public.feed_station_series(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.station_name(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.feed_station_series(text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.station_name(integer) TO authenticated, service_role;
