-- Regular plan cutover mid ops day 2026-11-11.
-- A/C: 第一次分拣模版1111-单量上涨手工分拣 (UniMap id 619).
-- Same-day mid-switch: prior touched rows end_date = 2026-11-11;
-- new/changed rows effective_date = 2026-11-11. Unchanged keep end_date null.

UPDATE public.chute_destination_gofo
SET end_date = DATE '2026-11-11'
WHERE end_date IS NULL
  AND chute_id IN (169,219,268,467,469,516,17001);

INSERT INTO public.chute_destination_gofo (
    chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type
)
SELECT v.chute_id, v.bundle_type, v.destination_warehouse, v.effective_date, v.route, v.sort_type
FROM (
    VALUES
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185415.22-EWR.H-TEB01-01-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185416.22-EWR.H-TEB01-02-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185417.22-EWR.H-TEB01-03-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185418.22-EWR.H-TEB01-04-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185419.22-EWR.H-TEB01-05-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185420.22-EWR.H-TEB01-06-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185421.22-EWR.H-TEB01-07-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185422.22-EWR.H-TEB01-08-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185423.22-EWR.H-TEB01-09-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185424.22-EWR.H-TEB01-10-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185425.22-EWR.H-TEB01-11-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185426.22-EWR.H-TEB01-12-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185427.22-EWR.H-TEB01-13-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185428.22-EWR.H-TEB01-14-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185429.22-EWR.H-TEB01-15-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185430.22-EWR.H-TEB01-16-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185431.22-EWR.H-TEB01-17-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185432.22-EWR.H-TEB01-18-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185433.22-EWR.H-TEB01-19-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185434.22-EWR.H-TEB01-20-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185435.22-EWR.H-TEB01-21-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185436.22-EWR.H-TEB01-22-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185437.22-EWR.H-TEB01-23-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185438.22-EWR.H-TEB01-24-G', 'by_city'),
        (169, 'transit', 'EWR.H', DATE '2026-11-11', '185439.22-EWR.H-TEB01-25-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185440.22-EWR.H-TEB01-26-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185441.22-EWR.H-TEB01-28-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185442.22-EWR.H-TEB01-29-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185443.22-EWR.H-TEB01-31-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185444.22-EWR.H-TEB01-32-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185445.22-EWR.H-TEB01-33-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185446.22-EWR.H-TEB01-34-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185447.22-EWR.H-TEB01-35-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185448.22-EWR.H-TEB01-36-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185449.22-EWR.H-TEB01-37-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185450.22-EWR.H-TEB01-38-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185451.22-EWR.H-TEB01-39-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185452.22-EWR.H-TEB01-41-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185453.22-EWR.H-TEB01-42-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185454.22-EWR.H-TEB01-43-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185455.22-EWR.H-TEB01-44-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185456.22-EWR.H-TEB01-45-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185457.22-EWR.H-TEB01-46-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185458.22-EWR.H-TEB01-47-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185459.22-EWR.H-TEB01-48-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185460.22-EWR.H-TEB01-49-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185461.22-EWR.H-TEB01-50-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185462.22-EWR.H-TEB01-51-G', 'by_city'),
        (219, 'transit', 'EWR.H', DATE '2026-11-11', '185655.22-EWR.H-TEB01-40-G', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185597.22-EWR.H-LGA02-M01-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185598.22-EWR.H-LGA02-M02-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185599.22-EWR.H-LGA02-M03-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185600.22-EWR.H-LGA02-M04-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185601.22-EWR.H-LGA02-M05-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185602.22-EWR.H-LGA02-M06-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185603.22-EWR.H-LGA02-M07-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185604.22-EWR.H-LGA02-M08-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185605.22-EWR.H-LGA02-M09-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185606.22-EWR.H-LGA02-M10-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185607.22-EWR.H-LGA02-M11-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185608.22-EWR.H-LGA02-M12-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185609.22-EWR.H-LGA02-M13-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185610.22-EWR.H-LGA02-M14-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185611.22-EWR.H-LGA02-M15-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185612.22-EWR.H-LGA02-M16-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185613.22-EWR.H-LGA02-M17-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185614.22-EWR.H-LGA02-M18-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185615.22-EWR.H-LGA02-M19-H', 'by_city'),
        (268, 'transit', 'EWR.H', DATE '2026-11-11', '185616.22-EWR.H-LGA02-M20-H', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-11', '185212.22-EWR.H-LDJ01-013-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-11', '185213.22-EWR.H-LDJ01-014-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-11', '185214.22-EWR.H-LDJ01-015-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-11', '185215.22-EWR.H-LDJ01-016-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-11', '185216.22-EWR.H-LDJ01-017-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-11', '185217.22-EWR.H-LDJ01-019-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-11', '185218.22-EWR.H-LDJ01-020-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-11', '185219.22-EWR.H-LDJ01-021-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-11', '185220.22-EWR.H-LDJ01-022-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-11', '185221.22-EWR.H-LDJ01-023-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-11', '185222.22-EWR.H-LDJ01-024-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-11', '185223.22-EWR.H-LDJ01-025-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-11', '185224.22-EWR.H-LDJ01-03-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-11', '185228.22-EWR.H-LDJ01-18-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-11', '185229.22-EWR.H-LDJ01-42-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-11', '185230.22-EWR.H-LDJ01-43-G', 'by_city'),
        (467, 'transit', 'EWR.H', DATE '2026-11-11', '185231.22-EWR.H-LDJ01-44-G', 'by_city'),
        (469, 'transit', 'EWR.H', DATE '2026-11-11', '185617.22-EWR.H-LGA02-M30-H', 'by_city'),
        (469, 'transit', 'EWR.H', DATE '2026-11-11', '185618.22-EWR.H-LGA02-M31-H', 'by_city'),
        (469, 'transit', 'EWR.H', DATE '2026-11-11', '185619.22-EWR.H-LGA02-M32-H', 'by_city'),
        (469, 'transit', 'EWR.H', DATE '2026-11-11', '185620.22-EWR.H-LGA02-M33-H', 'by_city'),
        (469, 'transit', 'EWR.H', DATE '2026-11-11', '185621.22-EWR.H-LGA02-M34-H', 'by_city'),
        (469, 'transit', 'EWR.H', DATE '2026-11-11', '185622.22-EWR.H-LGA02-M35-H', 'by_city'),
        (469, 'transit', 'EWR.H', DATE '2026-11-11', '185623.22-EWR.H-LGA02-M36-H', 'by_city'),
        (469, 'transit', 'EWR.H', DATE '2026-11-11', '185624.22-EWR.H-LGA02-M37-H', 'by_city'),
        (469, 'transit', 'EWR.H', DATE '2026-11-11', '185625.22-EWR.H-LGA02-M38-H', 'by_city'),
        (469, 'transit', 'EWR.H', DATE '2026-11-11', '185626.22-EWR.H-LGA02-M39-H', 'by_city'),
        (469, 'transit', 'EWR.H', DATE '2026-11-11', '185627.22-EWR.H-LGA02-M40-H', 'by_city'),
        (469, 'transit', 'EWR.H', DATE '2026-11-11', '185628.22-EWR.H-LGA02-M41-H', 'by_city'),
        (469, 'transit', 'EWR.H', DATE '2026-11-11', '185629.22-EWR.H-LGA02-M42-H', 'by_city'),
        (469, 'transit', 'EWR.H', DATE '2026-11-11', '185630.22-EWR.H-LGA02-M43-H', 'by_city'),
        (469, 'transit', 'EWR.H', DATE '2026-11-11', '185631.22-EWR.H-LGA02-M44-H', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185225.22-EWR.H-LDJ01-057-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185226.22-EWR.H-LDJ01-062-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185227.22-EWR.H-LDJ01-067-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185232.22-EWR.H-LDJ01-45-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185233.22-EWR.H-LDJ01-46-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185234.22-EWR.H-LDJ01-47-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185235.22-EWR.H-LDJ01-48-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185236.22-EWR.H-LDJ01-49-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185237.22-EWR.H-LDJ01-50-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185238.22-EWR.H-LDJ01-51-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185239.22-EWR.H-LDJ01-52-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185240.22-EWR.H-LDJ01-53-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185241.22-EWR.H-LDJ01-55-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185242.22-EWR.H-LDJ01-56-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185243.22-EWR.H-LDJ01-60-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185244.22-EWR.H-LDJ01-61-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185245.22-EWR.H-LDJ01-63-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185246.22-EWR.H-LDJ01-64-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185247.22-EWR.H-LDJ01-65-G', 'by_city'),
        (516, 'transit', 'EWR.H', DATE '2026-11-11', '185248.22-EWR.H-LDJ01-66-G', 'by_city'),
        (17001, 'transit', 'EWR.H', DATE '2026-11-11', '185684.22-EWR.H-ORH01-011-G', 'by_route')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type)
WHERE NOT EXISTS (
    SELECT 1
    FROM public.chute_destination_gofo existing
    WHERE existing.chute_id = v.chute_id
      AND existing.destination_warehouse IS NOT DISTINCT FROM v.destination_warehouse
      AND existing.effective_date IS NOT DISTINCT FROM v.effective_date
      AND existing.route IS NOT DISTINCT FROM v.route
      AND existing.sort_type IS NOT DISTINCT FROM v.sort_type
      AND existing.end_date IS NULL
);

-- touched=7 added=[469, 17001] ended=[] dest_sort=[] route_only=[169, 219, 268, 467, 516]
-- plan id=619 name=第一次分拣模版1111-单量上涨手工分拣
