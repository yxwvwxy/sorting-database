-- Carryover into new ops-day batch (Workflow Management Step 2).
-- BOS Warehouse quantity is stored as city PVD2.

CREATE TABLE IF NOT EXISTS public.city_initial_volume (
  subbatch_id text NOT NULL,
  operation_date date NOT NULL,
  city text NOT NULL,
  initial_volume bigint NOT NULL CHECK (initial_volume >= 0),
  scraped_at timestamptz NOT NULL DEFAULT now(),
  source text NOT NULL DEFAULT 'workflow_management',
  PRIMARY KEY (subbatch_id, city)
);

CREATE INDEX IF NOT EXISTS city_initial_volume_operation_date_idx
  ON public.city_initial_volume (operation_date);

COMMENT ON TABLE public.city_initial_volume IS
  'Per-ops-day initial city volumes from Workflow Management (carryover before sorter).';
COMMENT ON COLUMN public.city_initial_volume.city IS
  'Dashboard city code: RIC, ALB, SWF, SYR, PVD2 (BOS Warehouse maps to PVD2).';

ALTER TABLE public.city_initial_volume ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS city_initial_volume_select_authenticated ON public.city_initial_volume;
CREATE POLICY city_initial_volume_select_authenticated
  ON public.city_initial_volume
  FOR SELECT
  TO authenticated
  USING (true);

CREATE OR REPLACE FUNCTION public.city_volume_series(p_subbatch text DEFAULT NULL)
RETURNS TABLE (
  subbatch text,
  subbatch_date date,
  scraped_at timestamptz,
  city text,
  total_volume bigint,
  delta_volume bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH chosen AS (
    SELECT COALESCE(
      NULLIF(btrim(p_subbatch), ''),
      (SELECT s.subbatch FROM public.subbatch s ORDER BY s.scraped_at DESC LIMIT 1)
    ) AS subbatch
  ),
  batch_meta AS (
    SELECT DISTINCT ON (s.subbatch)
      s.subbatch,
      s.subbatch_date
    FROM public.subbatch s
    JOIN chosen c ON c.subbatch = s.subbatch
    ORDER BY s.subbatch, s.scraped_at DESC
  ),
  meta AS (
    SELECT subbatch, subbatch_date FROM batch_meta
    UNION
    SELECT i.subbatch_id, i.operation_date
    FROM public.city_initial_volume i
    JOIN chosen c ON c.subbatch = i.subbatch_id
    WHERE NOT EXISTS (SELECT 1 FROM batch_meta)
  ),
  initials AS (
    SELECT i.subbatch_id, i.city, i.initial_volume, i.scraped_at AS initial_scraped_at
    FROM public.city_initial_volume i
    JOIN chosen c ON c.subbatch = i.subbatch_id
  ),
  chute_map AS (
    SELECT DISTINCT ON (m.subbatch, d.chute_id)
      m.subbatch,
      d.chute_id,
      CASE
        WHEN lower(coalesce(d.sort_type, '')) = 'transit'
          THEN NULLIF(btrim(d.warehouse), '')
        ELSE NULLIF(btrim(d.city), '')
      END AS city
    FROM meta m
    JOIN public.chute_destination d
      ON d.effective_date <= m.subbatch_date
    ORDER BY m.subbatch, d.chute_id, d.effective_date DESC NULLS LAST, d.id DESC
  ),
  snaps AS (
    SELECT
      cv.subbatch_id,
      cv.scraped_at,
      cv.chute_id,
      cv.volume,
      lag(cv.volume) OVER (
        PARTITION BY cv.subbatch_id, cv.chute_id
        ORDER BY cv.scraped_at
      ) AS prev_volume
    FROM public.chute_volume cv
    JOIN chosen c ON c.subbatch = cv.subbatch_id
  ),
  chute_city AS (
    SELECT
      m.subbatch,
      m.subbatch_date,
      s.scraped_at,
      COALESCE(cm.city, 'Unmapped') AS city,
      sum(s.volume)::bigint AS chute_volume,
      sum(GREATEST(s.volume - COALESCE(s.prev_volume, 0), 0))::bigint AS delta_volume
    FROM snaps s
    JOIN meta m ON m.subbatch = s.subbatch_id
    LEFT JOIN chute_map cm
      ON cm.subbatch = s.subbatch_id
     AND cm.chute_id = s.chute_id
    GROUP BY m.subbatch, m.subbatch_date, s.scraped_at, COALESCE(cm.city, 'Unmapped')
  ),
  initial_only AS (
    SELECT
      i.subbatch_id AS subbatch,
      coalesce(m.subbatch_date, i2.operation_date) AS subbatch_date,
      i.initial_scraped_at AS scraped_at,
      i.city,
      i.initial_volume AS total_volume,
      i.initial_volume AS delta_volume
    FROM initials i
    JOIN public.city_initial_volume i2
      ON i2.subbatch_id = i.subbatch_id AND i2.city = i.city
    LEFT JOIN meta m ON m.subbatch = i.subbatch_id
    WHERE NOT EXISTS (SELECT 1 FROM snaps)
  ),
  with_initials AS (
    SELECT
      cc.subbatch,
      cc.subbatch_date,
      cc.scraped_at,
      cc.city,
      (cc.chute_volume + COALESCE(i.initial_volume, 0))::bigint AS total_volume,
      cc.delta_volume
    FROM chute_city cc
    LEFT JOIN initials i
      ON i.subbatch_id = cc.subbatch
     AND i.city = cc.city
  )
  SELECT * FROM with_initials
  UNION ALL
  SELECT * FROM initial_only
  ORDER BY scraped_at, city;
$$;

COMMENT ON FUNCTION public.city_volume_series(text) IS
  'City/hub series: chute volumes mapped by ops-day destination, plus Workflow Management initial carryover for RIC/ALB/SWF/SYR/PVD2.';

NOTIFY pgrst, 'reload schema';
