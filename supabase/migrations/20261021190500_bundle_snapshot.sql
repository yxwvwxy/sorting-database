-- Hourly UniMap Bundle Management exports. No seed data.
-- One captured_hour is one download. The same bundle_id is stored again
-- each hour so status changes stay visible. A rerun in that hour upserts
-- on (subbatch_id, captured_hour, bundle_id).
-- operation_date is the ops day used for Generated Date From/To. Evening
-- bundles from the previous calendar day belong to that ops day, so
-- generated_time can fall on the day before operation_date.

CREATE TABLE public.bundle_snapshot (
  subbatch_id text NOT NULL,
  operation_date date NOT NULL,
  captured_hour timestamptz NOT NULL,
  scraped_at timestamptz NOT NULL DEFAULT now(),
  bundle_id text NOT NULL,
  bundle_type text NOT NULL,
  carrier_id text,
  dest_transit_whs text,
  seal_id text,
  area text,
  shpt text,
  current_whs text NOT NULL,
  generated_time timestamptz,
  status text,
  notes text,
  operator text,
  operator_id text,
  PRIMARY KEY (subbatch_id, captured_hour, bundle_id),
  CONSTRAINT bundle_snapshot_captured_hour_truncated
    CHECK (captured_hour = date_trunc('hour', captured_hour))
);

CREATE INDEX bundle_snapshot_operation_date_idx
  ON public.bundle_snapshot (operation_date, captured_hour DESC);

COMMENT ON TABLE public.bundle_snapshot IS
  'Hourly Bundle Management export. One captured_hour is one download for an ops day and batch.';
COMMENT ON COLUMN public.bundle_snapshot.subbatch_id IS
  'Batch number, e.g. NJSUB-202610202100.';
COMMENT ON COLUMN public.bundle_snapshot.operation_date IS
  'Ops day used for Generated Date From/To. Evening of the previous calendar day belongs to this date.';
COMMENT ON COLUMN public.bundle_snapshot.captured_hour IS
  'Start of the Eastern clock hour of the export. A rerun in the same hour upserts these rows.';
COMMENT ON COLUMN public.bundle_snapshot.scraped_at IS
  'Exact time the Excel was downloaded.';
COMMENT ON COLUMN public.bundle_snapshot.shpt IS
  'SHPT from the export. Text because the portal can show values like 1/9.';
COMMENT ON COLUMN public.bundle_snapshot.generated_time IS
  'Generated Time from the export, with offset.';
COMMENT ON COLUMN public.bundle_snapshot.operator IS
  'Operator name from the export.';

ALTER TABLE public.bundle_snapshot ENABLE ROW LEVEL SECURITY;

CREATE POLICY bundle_snapshot_select_authenticated
  ON public.bundle_snapshot
  FOR SELECT
  TO authenticated
  USING (true);

REVOKE ALL ON public.bundle_snapshot FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.bundle_snapshot TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.bundle_snapshot TO service_role;

NOTIFY pgrst, 'reload schema';
