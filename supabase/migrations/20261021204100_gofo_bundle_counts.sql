-- Distinct bundle ids for a Gofo ops day, by destination warehouse and the
-- city code in front of the area hyphen. Status history does not add to the count.

CREATE OR REPLACE FUNCTION public.gofo_bundle_counts(p_operation_date date)
RETURNS TABLE (
  warehouse text,
  city text,
  bundle_count bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    b.dest_transit_whs AS warehouse,
    NULLIF(upper(split_part(NULLIF(b.area, '-'), '-', 1)), '') AS city,
    count(DISTINCT b.bundle_id)::bigint AS bundle_count
  FROM public.bundle_snapshot b
  WHERE b.operation_date = p_operation_date
    AND b.dest_transit_whs IS NOT NULL
  GROUP BY 1, 2;
$$;

COMMENT ON FUNCTION public.gofo_bundle_counts(date) IS
  'Unique bundle ids on an ops day, grouped by destination warehouse and area city.';

REVOKE ALL ON FUNCTION public.gofo_bundle_counts(date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.gofo_bundle_counts(date) TO service_role, authenticated, anon;

NOTIFY pgrst, 'reload schema';
