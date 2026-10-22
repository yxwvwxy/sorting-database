-- A bundle keeps one row per status. Created, then Shipped, is two rows
-- for the same bundle id, and that sequence is its trajectory.

ALTER TABLE public.bundle_snapshot
  DROP CONSTRAINT bundle_snapshot_pkey;

ALTER TABLE public.bundle_snapshot
  ALTER COLUMN status SET NOT NULL;

ALTER TABLE public.bundle_snapshot
  ADD CONSTRAINT bundle_snapshot_pkey PRIMARY KEY (bundle_id, status);

COMMENT ON TABLE public.bundle_snapshot IS
  'Bundle Management exports. One row per bundle_id and status. A later status for the same bundle is a new row.';
COMMENT ON COLUMN public.bundle_snapshot.first_seen_at IS
  'When this bundle_id and status was first inserted.';
COMMENT ON COLUMN public.bundle_snapshot.operation_date IS
  'Ops day of the UniMap date that contained this bundle.';

NOTIFY pgrst, 'reload schema';
