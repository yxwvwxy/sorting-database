-- One row per bundle. Hourly exports repeat the whole UTC day, so a second
-- copy of an unchanged bundle is not inserted. A later export that changes
-- status updates this row. first_seen_at stays, scraped_at moves forward.
-- operation_date is the ops day of generated_time (19:30 ET), not the date
-- typed into UniMap's filter.

ALTER TABLE public.bundle_snapshot
  DROP CONSTRAINT bundle_snapshot_captured_hour_truncated;

ALTER TABLE public.bundle_snapshot
  DROP CONSTRAINT bundle_snapshot_pkey;

DROP INDEX public.bundle_snapshot_operation_date_idx;

ALTER TABLE public.bundle_snapshot
  DROP COLUMN captured_hour;

ALTER TABLE public.bundle_snapshot
  ADD COLUMN first_seen_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.bundle_snapshot
  ADD CONSTRAINT bundle_snapshot_pkey PRIMARY KEY (bundle_id);

CREATE INDEX bundle_snapshot_operation_date_idx
  ON public.bundle_snapshot (operation_date);

COMMENT ON TABLE public.bundle_snapshot IS
  'Bundle Management exports. One row per bundle_id. Hourly repeats of the same bundle update this row instead of inserting another.';
COMMENT ON COLUMN public.bundle_snapshot.operation_date IS
  'Ops day from generated_time: 19:30 ET onward belongs to the next calendar date. Independent of the UTC date selected in UniMap.';
COMMENT ON COLUMN public.bundle_snapshot.first_seen_at IS
  'When this bundle_id was first inserted.';
COMMENT ON COLUMN public.bundle_snapshot.scraped_at IS
  'When an export last contained this bundle. Unchanged repeats do not add a row.';

NOTIFY pgrst, 'reload schema';
