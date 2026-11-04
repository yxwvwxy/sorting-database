-- Ops-day batch index + plan kind for the three-batch schedule.
-- batch_phase: 1 evening regular, 2 mid-night resort_by_route, 3 morning regular.
-- plan_kind: 'regular' | 'resort_by_route'

ALTER TABLE public.subbatch
  ADD COLUMN IF NOT EXISTS batch_phase smallint,
  ADD COLUMN IF NOT EXISTS plan_kind text;

ALTER TABLE public.subbatch
  DROP CONSTRAINT IF EXISTS subbatch_batch_phase_check;
ALTER TABLE public.subbatch
  ADD CONSTRAINT subbatch_batch_phase_check
  CHECK (batch_phase IS NULL OR batch_phase IN (1, 2, 3));

ALTER TABLE public.subbatch
  DROP CONSTRAINT IF EXISTS subbatch_plan_kind_check;
ALTER TABLE public.subbatch
  ADD CONSTRAINT subbatch_plan_kind_check
  CHECK (plan_kind IS NULL OR plan_kind IN ('regular', 'resort_by_route'));

COMMENT ON COLUMN public.subbatch.batch_phase IS
  '1 = evening regular, 2 = mid-night resort_by_route, 3 = morning regular. Null for pre-three-batch scrapes.';
COMMENT ON COLUMN public.subbatch.plan_kind IS
  'regular for batch 1/3; resort_by_route for batch 2 (UniMap 二次分拣细分).';

DROP FUNCTION IF EXISTS public.save_scrape_snapshot(text, integer, date, timestamptz, jsonb, jsonb, jsonb);

CREATE FUNCTION public.save_scrape_snapshot(
  p_subbatch text,
  p_machine_id integer,
  p_subbatch_date date,
  p_scraped_at timestamptz,
  p_hourly jsonb DEFAULT '[]'::jsonb,
  p_chutes jsonb DEFAULT '[]'::jsonb,
  p_feeds jsonb DEFAULT '[]'::jsonb,
  p_batch_phase smallint DEFAULT NULL,
  p_plan_kind text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.subbatch (
    subbatch, machine_id, subbatch_date, scraped_at, batch_phase, plan_kind
  )
  VALUES (
    p_subbatch,
    p_machine_id,
    p_subbatch_date,
    p_scraped_at,
    p_batch_phase,
    p_plan_kind
  );

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

REVOKE ALL ON FUNCTION public.save_scrape_snapshot(
  text, integer, date, timestamptz, jsonb, jsonb, jsonb, smallint, text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.save_scrape_snapshot(
  text, integer, date, timestamptz, jsonb, jsonb, jsonb, smallint, text
) TO service_role;

DROP FUNCTION IF EXISTS public.list_scrape_batches(int);

CREATE FUNCTION public.list_scrape_batches(p_limit int DEFAULT 30)
RETURNS TABLE (
  subbatch text,
  subbatch_date date,
  scrape_count bigint,
  first_scraped_at timestamptz,
  last_scraped_at timestamptz,
  latest_total bigint,
  batch_phase smallint,
  plan_kind text
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
      max(s.scraped_at) AS last_scraped_at,
      max(s.batch_phase) AS batch_phase,
      max(s.plan_kind) AS plan_kind
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
    COALESCE(v.latest_total, 0) AS latest_total,
    b.batch_phase,
    b.plan_kind
  FROM batch_times b
  LEFT JOIN latest_vol v ON v.subbatch_id = b.subbatch
  ORDER BY b.last_scraped_at DESC
  LIMIT GREATEST(COALESCE(p_limit, 30), 1);
$$;

COMMENT ON FUNCTION public.list_scrape_batches(int) IS
  'Recent scrape batches with optional batch_phase (#1/#2/#3) and plan_kind.';

GRANT EXECUTE ON FUNCTION public.list_scrape_batches(int) TO service_role, authenticated, anon;

DROP FUNCTION IF EXISTS public.list_gofo_batches(int);

CREATE FUNCTION public.list_gofo_batches(p_limit int DEFAULT 30)
RETURNS TABLE (
  subbatch text,
  subbatch_date date,
  scrape_count bigint,
  first_scraped_at timestamptz,
  last_scraped_at timestamptz,
  latest_total bigint,
  batch_phase smallint,
  plan_kind text
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
      max(s.scraped_at) AS last_scraped_at,
      max(s.batch_phase) AS batch_phase,
      max(s.plan_kind) AS plan_kind
    FROM public.subbatch s
    WHERE s.subbatch_date >= DATE '2026-10-18'
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
    COALESCE(v.latest_total, 0) AS latest_total,
    b.batch_phase,
    b.plan_kind
  FROM batch_times b
  LEFT JOIN latest_vol v ON v.subbatch_id = b.subbatch
  ORDER BY b.last_scraped_at DESC
  LIMIT GREATEST(COALESCE(p_limit, 30), 1);
$$;

COMMENT ON FUNCTION public.list_gofo_batches(int) IS
  'Gofo scrape batches from 2026-10-18 with optional batch_phase and plan_kind.';

GRANT EXECUTE ON FUNCTION public.list_gofo_batches(int) TO service_role, authenticated, anon;

NOTIFY pgrst, 'reload schema';
