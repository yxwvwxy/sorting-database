CREATE OR REPLACE FUNCTION public.save_scrape_snapshot(
  p_subbatch text,
  p_machine_id integer,
  p_subbatch_date date,
  p_scraped_at timestamptz,
  p_hourly jsonb DEFAULT '[]'::jsonb,
  p_chutes jsonb DEFAULT '[]'::jsonb,
  p_feeds jsonb DEFAULT '[]'::jsonb
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.subbatch (subbatch, machine_id, subbatch_date, scraped_at)
  VALUES (p_subbatch, p_machine_id, p_subbatch_date, p_scraped_at);

  INSERT INTO public.hourly_throughput (
    subbatch_id, bucket_time, hourly_volume, cumulative_volume, scraped_at
  )
  SELECT
    p_subbatch,
    (elem->>'bucket_time')::timestamp,
    (elem->>'hourly_volume')::integer,
    (elem->>'cumulative_volume')::integer,
    p_scraped_at
  FROM jsonb_array_elements(p_hourly) AS elem;

  INSERT INTO public.chute_volume (subbatch_id, chute_id, volume, scraped_at)
  SELECT
    p_subbatch,
    (elem->>'chute_id')::integer,
    (elem->>'volume')::integer,
    p_scraped_at
  FROM jsonb_array_elements(p_chutes) AS elem;

  INSERT INTO public.feed_station (subbatch_id, station_id, volume, scraped_at)
  SELECT
    p_subbatch,
    (elem->>'station_id')::integer,
    (elem->>'volume')::integer,
    p_scraped_at
  FROM jsonb_array_elements(p_feeds) AS elem;
END;
$$;

REVOKE ALL ON FUNCTION public.save_scrape_snapshot(text, integer, date, timestamptz, jsonb, jsonb, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.save_scrape_snapshot(text, integer, date, timestamptz, jsonb, jsonb, jsonb) TO service_role;
