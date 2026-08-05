-- Process history: every scrape is a new row keyed by scraped_at

UPDATE public.subbatch
SET scraped_at = COALESCE(
  scraped_at,
  ((subbatch_date + time '12:00') AT TIME ZONE 'America/New_York')
)
WHERE scraped_at IS NULL;

ALTER TABLE public.subbatch
  ALTER COLUMN scraped_at SET NOT NULL;

COMMENT ON COLUMN public.subbatch.scraped_at IS
  'Timestamp of this scrape snapshot (UTC). One row per scrape, not only latest.';

ALTER TABLE public.chute_volume DROP CONSTRAINT IF EXISTS chute_volume_subbatch_id_fkey;
ALTER TABLE public.feed_station DROP CONSTRAINT IF EXISTS feed_station_subbatch_id_fkey;
ALTER TABLE public.hourly_throughput DROP CONSTRAINT IF EXISTS hourly_throughput_subbatch_id_fkey;
ALTER TABLE public.hourly_throughput DROP CONSTRAINT IF EXISTS fk_hourly_subbatch;

ALTER TABLE public.chute_volume DROP CONSTRAINT IF EXISTS chute_volume_pkey;
ALTER TABLE public.feed_station DROP CONSTRAINT IF EXISTS feed_station_pkey;
ALTER TABLE public.hourly_throughput DROP CONSTRAINT IF EXISTS hourly_throughput_pkey;
ALTER TABLE public.subbatch DROP CONSTRAINT IF EXISTS subbatch_pkey;
ALTER TABLE public.subbatch DROP CONSTRAINT IF EXISTS unique_subbatch_date;

ALTER TABLE public.subbatch
  ADD CONSTRAINT subbatch_pkey PRIMARY KEY (subbatch, scraped_at);

CREATE INDEX IF NOT EXISTS idx_subbatch_date_scraped_at
  ON public.subbatch (subbatch_date, scraped_at DESC);

CREATE INDEX IF NOT EXISTS idx_subbatch_id_scraped_at
  ON public.subbatch (subbatch, scraped_at DESC);

ALTER TABLE public.chute_volume
  ADD COLUMN IF NOT EXISTS scraped_at timestamptz;

UPDATE public.chute_volume cv
SET scraped_at = s.scraped_at
FROM public.subbatch s
WHERE cv.subbatch_id = s.subbatch
  AND cv.scraped_at IS NULL;

ALTER TABLE public.chute_volume
  ALTER COLUMN scraped_at SET NOT NULL;

ALTER TABLE public.chute_volume
  ADD CONSTRAINT chute_volume_pkey PRIMARY KEY (subbatch_id, chute_id, scraped_at);

ALTER TABLE public.chute_volume
  ADD CONSTRAINT chute_volume_subbatch_fkey
  FOREIGN KEY (subbatch_id, scraped_at)
  REFERENCES public.subbatch (subbatch, scraped_at)
  ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_chute_volume_subbatch_scraped
  ON public.chute_volume (subbatch_id, scraped_at DESC);

ALTER TABLE public.feed_station
  ADD COLUMN IF NOT EXISTS scraped_at timestamptz;

UPDATE public.feed_station fs
SET scraped_at = s.scraped_at
FROM public.subbatch s
WHERE fs.subbatch_id = s.subbatch
  AND fs.scraped_at IS NULL;

ALTER TABLE public.feed_station
  ALTER COLUMN scraped_at SET NOT NULL;

ALTER TABLE public.feed_station
  ADD CONSTRAINT feed_station_pkey PRIMARY KEY (subbatch_id, station_id, scraped_at);

ALTER TABLE public.feed_station
  ADD CONSTRAINT feed_station_subbatch_fkey
  FOREIGN KEY (subbatch_id, scraped_at)
  REFERENCES public.subbatch (subbatch, scraped_at)
  ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_feed_station_subbatch_scraped
  ON public.feed_station (subbatch_id, scraped_at DESC);

ALTER TABLE public.hourly_throughput
  ADD COLUMN IF NOT EXISTS scraped_at timestamptz;

UPDATE public.hourly_throughput ht
SET scraped_at = s.scraped_at
FROM public.subbatch s
WHERE ht.subbatch_id = s.subbatch
  AND ht.scraped_at IS NULL;

ALTER TABLE public.hourly_throughput
  ALTER COLUMN scraped_at SET NOT NULL;

ALTER TABLE public.hourly_throughput
  ADD CONSTRAINT hourly_throughput_pkey PRIMARY KEY (subbatch_id, bucket_time, scraped_at);

ALTER TABLE public.hourly_throughput
  ADD CONSTRAINT hourly_throughput_subbatch_fkey
  FOREIGN KEY (subbatch_id, scraped_at)
  REFERENCES public.subbatch (subbatch, scraped_at)
  ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_hourly_throughput_subbatch_scraped
  ON public.hourly_throughput (subbatch_id, scraped_at DESC);
