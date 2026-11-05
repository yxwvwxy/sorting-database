-- B-segment plan 二次分拣模版1105 (UniMap id 560, renamed from 二次分拣细分).
-- Config matches the prior 252-chute read. Stored apart from chute_destination_gofo
-- so A/C keep the regular plan. Applies to segment B only, from the first
-- stored B scrape on ops day 2026-11-05 (NJSUB-202611050209 at 03:10:14 ET).

CREATE TABLE IF NOT EXISTS public.gofo_resort_plan (
  plan_name text PRIMARY KEY,
  uni_map_id integer NOT NULL,
  starts_at timestamptz NOT NULL,
  note text
);

COMMENT ON TABLE public.gofo_resort_plan IS
  'When the secondary-split plan starts. Only segment B (batch_phase 2) uses it. A and C stay on the regular plan.';

ALTER TABLE public.gofo_resort_plan ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS gofo_resort_plan_select_authenticated ON public.gofo_resort_plan;
CREATE POLICY gofo_resort_plan_select_authenticated
  ON public.gofo_resort_plan
  FOR SELECT
  TO authenticated
  USING (true);
GRANT SELECT ON public.gofo_resort_plan TO authenticated, anon, service_role;
GRANT ALL ON public.gofo_resort_plan TO service_role;

INSERT INTO public.gofo_resort_plan (plan_name, uni_map_id, starts_at, note)
VALUES (
  '二次分拣模版1105',
  560,
  TIMESTAMPTZ '2026-11-05 03:10:14.570732-05',
  'First B-segment capture NJSUB-202611050209 on ops day 2026-11-05'
)
ON CONFLICT (plan_name) DO UPDATE
SET uni_map_id = EXCLUDED.uni_map_id,
    starts_at = EXCLUDED.starts_at,
    note = EXCLUDED.note;

CREATE TABLE IF NOT EXISTS public.chute_destination_resort (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  chute_id integer NOT NULL,
  bundle_type text,
  destination_warehouse text,
  effective_date date,
  route text,
  note text,
  sort_type text,
  city text GENERATED ALWAYS AS (
    CASE
      WHEN sort_type = 'uni_hub' THEN NULLIF(left(destination_warehouse, 3), '')
      ELSE NULLIF(split_part(route, '-', 3), '')
    END
  ) STORED,
  end_date date
);

COMMENT ON TABLE public.chute_destination_resort IS
  'Secondary-split chute map (二次分拣模版1105). Used only for segment B. A and C read chute_destination_gofo.';

ALTER TABLE public.chute_destination_resort ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS chute_destination_resort_select_authenticated ON public.chute_destination_resort;
CREATE POLICY chute_destination_resort_select_authenticated
  ON public.chute_destination_resort
  FOR SELECT
  TO authenticated
  USING (true);
GRANT SELECT ON public.chute_destination_resort TO authenticated, anon, service_role;
GRANT ALL ON public.chute_destination_resort TO service_role;

INSERT INTO public.chute_structure (chute_id, lane_id)
SELECT v.chute_id, p.lane_id
FROM (VALUES
    (17001, 170),
    (22001, 220)
) AS v(chute_id, parent_id)
JOIN public.chute_structure p ON p.chute_id = v.parent_id
WHERE NOT EXISTS (
    SELECT 1 FROM public.chute_structure s WHERE s.chute_id = v.chute_id
);

INSERT INTO public.chute_destination_resort (
    chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type
)
SELECT v.chute_id, v.bundle_type, v.destination_warehouse, v.effective_date, v.route, v.sort_type
FROM (
    VALUES
        (101, 'transit', 'EWR.H', DATE '2026-11-05', '185630.22-EWR.H-LGA02-M43-H', 'by_route'),
        (102, 'transit', 'EWR.H', DATE '2026-11-05', '185628.22-EWR.H-LGA02-M41-H', 'by_route'),
        (103, 'transit', 'EWR.H', DATE '2026-11-05', '185626.22-EWR.H-LGA02-M39-H', 'by_route'),
        (104, 'transit', 'EWR.H', DATE '2026-11-05', '185624.22-EWR.H-LGA02-M37-H', 'by_route'),
        (105, 'transit', 'EWR.H', DATE '2026-11-05', '185622.22-EWR.H-LGA02-M35-H', 'by_route'),
        (106, 'transit', 'EWR.H', DATE '2026-11-05', '185620.22-EWR.H-LGA02-M33-H', 'by_route'),
        (107, 'transit', 'EWR.H', DATE '2026-11-05', '185618.22-EWR.H-LGA02-M31-H', 'by_route'),
        (108, 'transit', 'EWR.H', DATE '2026-11-05', '185616.22-EWR.H-LGA02-M20-H', 'by_route'),
        (109, 'transit', 'EWR.H', DATE '2026-11-05', '185614.22-EWR.H-LGA02-M18-H', 'by_route'),
        (110, 'transit', 'EWR.H', DATE '2026-11-05', '185612.22-EWR.H-LGA02-M16-H', 'by_route'),
        (111, 'transit', 'EWR.H', DATE '2026-11-05', '185610.22-EWR.H-LGA02-M14-H', 'by_route'),
        (112, 'transit', 'EWR.H', DATE '2026-11-05', '185608.22-EWR.H-LGA02-M12-H', 'by_route'),
        (113, 'transit', 'EWR.H', DATE '2026-11-05', '185606.22-EWR.H-LGA02-M10-H', 'by_route'),
        (114, 'transit', 'EWR.H', DATE '2026-11-05', '185604.22-EWR.H-LGA02-M08-H', 'by_route'),
        (115, 'transit', 'EWR.H', DATE '2026-11-05', '185602.22-EWR.H-LGA02-M06-H', 'by_route'),
        (116, 'transit', 'EWR.H', DATE '2026-11-05', '185600.22-EWR.H-LGA02-M04-H', 'by_route'),
        (117, 'transit', 'EWR.H', DATE '2026-11-05', '185598.22-EWR.H-LGA02-M02-H', 'by_route'),
        (151, 'transit', 'EWR.H', DATE '2026-11-05', '185171.22-EWR.H-BUF01-020-H', 'by_route'),
        (152, 'transit', 'EWR.H', DATE '2026-11-05', '185170.22-EWR.H-BUF01-019-H', 'by_route'),
        (153, 'transit', 'EWR.H', DATE '2026-11-05', '185169.22-EWR.H-BUF01-018-H', 'by_route'),
        (154, 'transit', 'EWR.H', DATE '2026-11-05', '185568.22-EWR.H-BUF01-017-H', 'by_route'),
        (155, 'transit', 'EWR.H', DATE '2026-11-05', '185168.22-EWR.H-BUF01-016-H', 'by_route'),
        (156, 'transit', 'EWR.H', DATE '2026-11-05', '185167.22-EWR.H-BUF01-015-H', 'by_route'),
        (157, 'transit', 'EWR.H', DATE '2026-11-05', '185166.22-EWR.H-BUF01-014-H', 'by_route'),
        (158, 'transit', 'EWR.H', DATE '2026-11-05', '185165.22-EWR.H-BUF01-013-H', 'by_route'),
        (159, 'transit', 'EWR.H', DATE '2026-11-05', '185164.22-EWR.H-BUF01-012-H', 'by_route'),
        (160, 'transit', 'EWR.H', DATE '2026-11-05', '185163.22-EWR.H-BUF01-011-H', 'by_route'),
        (161, 'transit', 'EWR.H', DATE '2026-11-05', '185162.22-EWR.H-BUF01-010-H', 'by_route'),
        (162, 'transit', 'EWR.H', DATE '2026-11-05', '185161.22-EWR.H-BUF01-009-H', 'by_route'),
        (163, 'transit', 'EWR.H', DATE '2026-11-05', '185160.22-EWR.H-BUF01-008-H', 'by_route'),
        (164, 'transit', 'EWR.H', DATE '2026-11-05', '185159.22-EWR.H-BUF01-007-H', 'by_route'),
        (165, 'transit', 'EWR.H', DATE '2026-11-05', '185158.22-EWR.H-BUF01-006-H', 'by_route'),
        (166, 'transit', 'EWR.H', DATE '2026-11-05', '185157.22-EWR.H-BUF01-005-H', 'by_route'),
        (167, 'transit', 'EWR.H', DATE '2026-11-05', '185156.22-EWR.H-BUF01-004-H', 'by_route'),
        (168, 'transit', 'EWR.H', DATE '2026-11-05', '185155.22-EWR.H-BUF01-003-H', 'by_route'),
        (201, 'transit', 'EWR.H', DATE '2026-11-05', '185389.22-EWR.H-ROC01-18-H', 'by_route'),
        (202, 'transit', 'EWR.H', DATE '2026-11-05', '185388.22-EWR.H-ROC01-17-H', 'by_route'),
        (203, 'transit', 'EWR.H', DATE '2026-11-05', '185387.22-EWR.H-ROC01-16-H', 'by_route'),
        (204, 'transit', 'EWR.H', DATE '2026-11-05', '185386.22-EWR.H-ROC01-15-H', 'by_route'),
        (205, 'transit', 'EWR.H', DATE '2026-11-05', '185385.22-EWR.H-ROC01-14-H', 'by_route'),
        (206, 'transit', 'EWR.H', DATE '2026-11-05', '185384.22-EWR.H-ROC01-13-H', 'by_route'),
        (207, 'transit', 'EWR.H', DATE '2026-11-05', '185383.22-EWR.H-ROC01-06-H', 'by_route'),
        (208, 'transit', 'EWR.H', DATE '2026-11-05', '185382.22-EWR.H-ROC01-05-H', 'by_route'),
        (209, 'transit', 'EWR.H', DATE '2026-11-05', '185381.22-EWR.H-ROC01-03-H', 'by_route'),
        (210, 'transit', 'EWR.H', DATE '2026-11-05', '185670.22-EWR.H-ROC01-021-H', 'by_route'),
        (211, 'transit', 'EWR.H', DATE '2026-11-05', '185380.22-EWR.H-ROC01-020-H', 'by_route'),
        (212, 'transit', 'EWR.H', DATE '2026-11-05', '185379.22-EWR.H-ROC01-02-H', 'by_route'),
        (213, 'transit', 'EWR.H', DATE '2026-11-05', '185378.22-EWR.H-ROC01-012-H', 'by_route'),
        (214, 'transit', 'EWR.H', DATE '2026-11-05', '185377.22-EWR.H-ROC01-011-H', 'by_route'),
        (215, 'transit', 'EWR.H', DATE '2026-11-05', '185376.22-EWR.H-ROC01-010-H', 'by_route'),
        (216, 'transit', 'EWR.H', DATE '2026-11-05', '185375.22-EWR.H-ROC01-01-H', 'by_route'),
        (217, 'transit', 'EWR.H', DATE '2026-11-05', '185374.22-EWR.H-ROC01-008-H', 'by_route'),
        (218, 'transit', 'EWR.H', DATE '2026-11-05', '185641.22-EWR.H-ROC01-007-H', 'by_route'),
        (510, 'transit', 'EWR.H', DATE '2026-11-05', '185570.22-EWR.H-PIT01-007-H', 'by_route'),
        (511, 'transit', 'EWR.H', DATE '2026-11-05', '185300.22-EWR.H-PIT01-006-H', 'by_route'),
        (512, 'transit', 'EWR.H', DATE '2026-11-05', '185299.22-EWR.H-PIT01-004-H', 'by_route'),
        (513, 'transit', 'EWR.H', DATE '2026-11-05', '185298.22-EWR.H-PIT01-003-H', 'by_route'),
        (514, 'transit', 'EWR.H', DATE '2026-11-05', '185297.22-EWR.H-PIT01-002-H', 'by_route'),
        (515, 'transit', 'EWR.H', DATE '2026-11-05', '185296.22-EWR.H-PIT01-001-H', 'by_route'),
        (551, 'transit', 'EWR.H', DATE '2026-11-05', '185314.22-EWR.H-PIT01-28-H', 'by_route'),
        (552, 'transit', 'EWR.H', DATE '2026-11-05', '185637.22-EWR.H-PIT01-27-H', 'by_route'),
        (553, 'transit', 'EWR.H', DATE '2026-11-05', '185313.22-EWR.H-PIT01-26-H', 'by_route'),
        (554, 'transit', 'EWR.H', DATE '2026-11-05', '185312.22-EWR.H-PIT01-25-H', 'by_route'),
        (555, 'transit', 'EWR.H', DATE '2026-11-05', '185311.22-EWR.H-PIT01-24-H', 'by_route'),
        (556, 'transit', 'EWR.H', DATE '2026-11-05', '185310.22-EWR.H-PIT01-023-H', 'by_route'),
        (557, 'transit', 'EWR.H', DATE '2026-11-05', '185309.22-EWR.H-PIT01-022-H', 'by_route'),
        (558, 'transit', 'EWR.H', DATE '2026-11-05', '185308.22-EWR.H-PIT01-021-H', 'by_route'),
        (559, 'transit', 'EWR.H', DATE '2026-11-05', '185307.22-EWR.H-PIT01-020-H', 'by_route'),
        (560, 'transit', 'EWR.H', DATE '2026-11-05', '185306.22-EWR.H-PIT01-015-H', 'by_route'),
        (561, 'transit', 'EWR.H', DATE '2026-11-05', '185305.22-EWR.H-PIT01-014-H', 'by_route'),
        (562, 'transit', 'EWR.H', DATE '2026-11-05', '185304.22-EWR.H-PIT01-012-H', 'by_route'),
        (563, 'transit', 'EWR.H', DATE '2026-11-05', '185303.22-EWR.H-PIT01-011-H', 'by_route'),
        (564, 'transit', 'EWR.H', DATE '2026-11-05', '185302.22-EWR.H-PIT01-010-H', 'by_route'),
        (565, 'transit', 'EWR.H', DATE '2026-11-05', '185301.22-EWR.H-PIT01-009-H', 'by_route'),
        (566, 'transit', 'EWR.H', DATE '2026-11-05', '185571.22-EWR.H-PIT01-008-H', 'by_route'),
        (601, 'transit', 'EWR.H', DATE '2026-11-05', '185596.22-EWR.H-GED01-076-H', 'by_route'),
        (602, 'transit', 'EWR.H', DATE '2026-11-05', '185204.22-EWR.H-GED01-075-H', 'by_route'),
        (603, 'transit', 'EWR.H', DATE '2026-11-05', '185203.22-EWR.H-GED01-074-H', 'by_route'),
        (604, 'transit', 'EWR.H', DATE '2026-11-05', '185202.22-EWR.H-GED01-073-H', 'by_route'),
        (605, 'transit', 'EWR.H', DATE '2026-11-05', '185201.22-EWR.H-GED01-072-H', 'by_route'),
        (606, 'transit', 'EWR.H', DATE '2026-11-05', '185200.22-EWR.H-GED01-071-H', 'by_route'),
        (607, 'transit', 'EWR.H', DATE '2026-11-05', '185595.22-EWR.H-GED01-010-H', 'by_route'),
        (608, 'transit', 'EWR.H', DATE '2026-11-05', '185594.22-EWR.H-GED01-009-H', 'by_route'),
        (609, 'transit', 'EWR.H', DATE '2026-11-05', '185199.22-EWR.H-GED01-008-H', 'by_route'),
        (610, 'transit', 'EWR.H', DATE '2026-11-05', '185198.22-EWR.H-GED01-007-H', 'by_route'),
        (611, 'transit', 'EWR.H', DATE '2026-11-05', '185197.22-EWR.H-GED01-006-H', 'by_route'),
        (612, 'transit', 'EWR.H', DATE '2026-11-05', '185593.22-EWR.H-GED01-005-H', 'by_route'),
        (613, 'transit', 'EWR.H', DATE '2026-11-05', '185196.22-EWR.H-GED01-004-H', 'by_route'),
        (614, 'transit', 'EWR.H', DATE '2026-11-05', '185592.22-EWR.H-GED01-003-H', 'by_route'),
        (615, 'transit', 'EWR.H', DATE '2026-11-05', '185591.22-EWR.H-GED01-002-H', 'by_route'),
        (616, 'transit', 'EWR.H', DATE '2026-11-05', '185195.22-EWR.H-GED01-001-H', 'by_route'),
        (651, 'transit', 'EWR.H', DATE '2026-11-05', '185633.22-EWR.H-MHT01-013-H', 'by_route'),
        (652, 'transit', 'EWR.H', DATE '2026-11-05', '185632.22-EWR.H-MHT01-012-H', 'by_route'),
        (653, 'transit', 'EWR.H', DATE '2026-11-05', '185275.22-EWR.H-MHT01-010-H', 'by_route'),
        (654, 'transit', 'EWR.H', DATE '2026-11-05', '185274.22-EWR.H-MHT01-009-H', 'by_route'),
        (655, 'transit', 'EWR.H', DATE '2026-11-05', '185273.22-EWR.H-MHT01-008-H', 'by_route'),
        (656, 'transit', 'EWR.H', DATE '2026-11-05', '185272.22-EWR.H-MHT01-007-H', 'by_route'),
        (657, 'transit', 'EWR.H', DATE '2026-11-05', '185271.22-EWR.H-MHT01-006-H', 'by_route'),
        (658, 'transit', 'EWR.H', DATE '2026-11-05', '185270.22-EWR.H-MHT01-005-H', 'by_route'),
        (659, 'transit', 'EWR.H', DATE '2026-11-05', '185269.22-EWR.H-MHT01-004-H', 'by_route'),
        (660, 'transit', 'EWR.H', DATE '2026-11-05', '185268.22-EWR.H-MHT01-003-H', 'by_route'),
        (661, 'transit', 'EWR.H', DATE '2026-11-05', '185267.22-EWR.H-MHT01-002-H', 'by_route'),
        (662, 'transit', 'EWR.H', DATE '2026-11-05', '185266.22-EWR.H-MHT01-001-H', 'by_route'),
        (701, 'transit', 'EWR.H', DATE '2026-11-05', '185414.22-EWR.H-SYR01-015-H', 'by_route'),
        (702, 'transit', 'EWR.H', DATE '2026-11-05', '185413.22-EWR.H-SYR01-014-H', 'by_route'),
        (703, 'transit', 'EWR.H', DATE '2026-11-05', '185653.22-EWR.H-SYR01-013-H', 'by_route'),
        (704, 'transit', 'EWR.H', DATE '2026-11-05', '185652.22-EWR.H-SYR01-012-H', 'by_route'),
        (705, 'transit', 'EWR.H', DATE '2026-11-05', '185412.22-EWR.H-SYR01-011-H', 'by_route'),
        (706, 'transit', 'EWR.H', DATE '2026-11-05', '185411.22-EWR.H-SYR01-010-H', 'by_route'),
        (707, 'transit', 'EWR.H', DATE '2026-11-05', '185651.22-EWR.H-SYR01-009-H', 'by_route'),
        (708, 'transit', 'EWR.H', DATE '2026-11-05', '185650.22-EWR.H-SYR01-008-H', 'by_route'),
        (709, 'transit', 'EWR.H', DATE '2026-11-05', '185410.22-EWR.H-SYR01-007-H', 'by_route'),
        (710, 'transit', 'EWR.H', DATE '2026-11-05', '185409.22-EWR.H-SYR01-006-H', 'by_route'),
        (711, 'transit', 'EWR.H', DATE '2026-11-05', '185408.22-EWR.H-SYR01-005-H', 'by_route'),
        (712, 'transit', 'EWR.H', DATE '2026-11-05', '185407.22-EWR.H-SYR01-004-H', 'by_route'),
        (713, 'transit', 'EWR.H', DATE '2026-11-05', '185406.22-EWR.H-SYR01-003-H', 'by_route'),
        (714, 'transit', 'EWR.H', DATE '2026-11-05', '185405.22-EWR.H-SYR01-002-H', 'by_route'),
        (715, 'transit', 'EWR.H', DATE '2026-11-05', '185404.22-EWR.H-SYR01-001-H', 'by_route'),
        (751, 'transit', 'EWR.H', DATE '2026-11-05', '185058.22-EWR.H-ABE01-092-G', 'by_route'),
        (752, 'transit', 'EWR.H', DATE '2026-11-05', '185057.22-EWR.H-ABE01-091-G', 'by_route'),
        (753, 'transit', 'EWR.H', DATE '2026-11-05', '185056.22-EWR.H-ABE01-090-G', 'by_route'),
        (754, 'transit', 'EWR.H', DATE '2026-11-05', '185055.22-EWR.H-ABE01-075-G', 'by_route'),
        (755, 'transit', 'EWR.H', DATE '2026-11-05', '185054.22-EWR.H-ABE01-074-G', 'by_route'),
        (756, 'transit', 'EWR.H', DATE '2026-11-05', '185053.22-EWR.H-ABE01-073-G', 'by_route'),
        (757, 'transit', 'EWR.H', DATE '2026-11-05', '185583.22-EWR.H-ABE01-015-G', 'by_route'),
        (758, 'transit', 'EWR.H', DATE '2026-11-05', '185582.22-EWR.H-ABE01-014-G', 'by_route'),
        (759, 'transit', 'EWR.H', DATE '2026-11-05', '185052.22-EWR.H-ABE01-013-G', 'by_route'),
        (760, 'transit', 'EWR.H', DATE '2026-11-05', '185051.22-EWR.H-ABE01-012-G', 'by_route'),
        (761, 'transit', 'EWR.H', DATE '2026-11-05', '185050.22-EWR.H-ABE01-011-G', 'by_route'),
        (762, 'transit', 'EWR.H', DATE '2026-11-05', '185049.22-EWR.H-ABE01-010-G', 'by_route'),
        (763, 'transit', 'EWR.H', DATE '2026-11-05', '185048.22-EWR.H-ABE01-009-G', 'by_route'),
        (764, 'transit', 'EWR.H', DATE '2026-11-05', '185047.22-EWR.H-ABE01-008-G', 'by_route'),
        (765, 'transit', 'EWR.H', DATE '2026-11-05', '185046.22-EWR.H-ABE01-007-G', 'by_route'),
        (766, 'transit', 'EWR.H', DATE '2026-11-05', '185045.22-EWR.H-ABE01-006-G', 'by_route'),
        (767, 'transit', 'EWR.H', DATE '2026-11-05', '185581.22-EWR.H-ABE01-005-G', 'by_route'),
        (768, 'transit', 'EWR.H', DATE '2026-11-05', '185580.22-EWR.H-ABE01-004-G', 'by_route'),
        (769, 'transit', 'EWR.H', DATE '2026-11-05', '185579.22-EWR.H-ABE01-003-G', 'by_route'),
        (801, 'transit', 'EWR.H', DATE '2026-11-05', '185462.22-EWR.H-TEB01-51-G', 'by_route'),
        (802, 'transit', 'EWR.H', DATE '2026-11-05', '185461.22-EWR.H-TEB01-50-G', 'by_route'),
        (803, 'transit', 'EWR.H', DATE '2026-11-05', '185460.22-EWR.H-TEB01-49-G', 'by_route'),
        (804, 'transit', 'EWR.H', DATE '2026-11-05', '185459.22-EWR.H-TEB01-48-G', 'by_route'),
        (805, 'transit', 'EWR.H', DATE '2026-11-05', '185458.22-EWR.H-TEB01-47-G', 'by_route'),
        (806, 'transit', 'EWR.H', DATE '2026-11-05', '185457.22-EWR.H-TEB01-46-G', 'by_route'),
        (807, 'transit', 'EWR.H', DATE '2026-11-05', '185456.22-EWR.H-TEB01-45-G', 'by_route'),
        (808, 'transit', 'EWR.H', DATE '2026-11-05', '185455.22-EWR.H-TEB01-44-G', 'by_route'),
        (809, 'transit', 'EWR.H', DATE '2026-11-05', '185454.22-EWR.H-TEB01-43-G', 'by_route'),
        (810, 'transit', 'EWR.H', DATE '2026-11-05', '185453.22-EWR.H-TEB01-42-G', 'by_route'),
        (811, 'transit', 'EWR.H', DATE '2026-11-05', '185684.22-EWR.H-ORH01-011-G', 'by_route'),
        (812, 'transit', 'EWR.H', DATE '2026-11-05', '185590.22-EWR.H-ERI01-006-H', 'by_route'),
        (813, 'transit', 'EWR.H', DATE '2026-11-05', '185175.22-EWR.H-ERI01-005-H', 'by_route'),
        (814, 'transit', 'EWR.H', DATE '2026-11-05', '185174.22-EWR.H-ERI01-004-H', 'by_route'),
        (815, 'transit', 'EWR.H', DATE '2026-11-05', '185676.22-EWR.H-ERI01-003-H', 'by_route'),
        (816, 'transit', 'EWR.H', DATE '2026-11-05', '185173.22-EWR.H-ERI01-002-H', 'by_route'),
        (817, 'transit', 'EWR.H', DATE '2026-11-05', '185172.22-EWR.H-ERI01-001-H', 'by_route'),
        (818, 'transit', 'EWR.H', DATE '2026-11-05', '185578.22-EWR.H-ABE01-002-G', 'by_route'),
        (819, 'transit', 'EWR.H', DATE '2026-11-05', '185577.22-EWR.H-ABE01-001-G', 'by_route'),
        (851, 'transit', 'EWR.H', DATE '2026-11-05', '185430.22-EWR.H-TEB01-16-G', 'by_route'),
        (852, 'transit', 'EWR.H', DATE '2026-11-05', '185429.22-EWR.H-TEB01-15-G', 'by_route'),
        (853, 'transit', 'EWR.H', DATE '2026-11-05', '185428.22-EWR.H-TEB01-14-G', 'by_route'),
        (854, 'transit', 'EWR.H', DATE '2026-11-05', '185427.22-EWR.H-TEB01-13-G', 'by_route'),
        (855, 'transit', 'EWR.H', DATE '2026-11-05', '185426.22-EWR.H-TEB01-12-G', 'by_route'),
        (856, 'transit', 'EWR.H', DATE '2026-11-05', '185425.22-EWR.H-TEB01-11-G', 'by_route'),
        (857, 'transit', 'EWR.H', DATE '2026-11-05', '185424.22-EWR.H-TEB01-10-G', 'by_route'),
        (858, 'transit', 'EWR.H', DATE '2026-11-05', '185423.22-EWR.H-TEB01-09-G', 'by_route'),
        (859, 'transit', 'EWR.H', DATE '2026-11-05', '185422.22-EWR.H-TEB01-08-G', 'by_route'),
        (860, 'transit', 'EWR.H', DATE '2026-11-05', '185421.22-EWR.H-TEB01-07-G', 'by_route'),
        (861, 'transit', 'EWR.H', DATE '2026-11-05', '185420.22-EWR.H-TEB01-06-G', 'by_route'),
        (862, 'transit', 'EWR.H', DATE '2026-11-05', '185419.22-EWR.H-TEB01-05-G', 'by_route'),
        (863, 'transit', 'EWR.H', DATE '2026-11-05', '185418.22-EWR.H-TEB01-04-G', 'by_route'),
        (864, 'transit', 'EWR.H', DATE '2026-11-05', '185417.22-EWR.H-TEB01-03-G', 'by_route'),
        (865, 'transit', 'EWR.H', DATE '2026-11-05', '185416.22-EWR.H-TEB01-02-G', 'by_route'),
        (866, 'transit', 'EWR.H', DATE '2026-11-05', '185415.22-EWR.H-TEB01-01-G', 'by_route'),
        (901, 'transit', 'EWR.H', DATE '2026-11-05', '185443.22-EWR.H-TEB01-31-G', 'by_route'),
        (902, 'transit', 'EWR.H', DATE '2026-11-05', '185442.22-EWR.H-TEB01-29-G', 'by_route'),
        (903, 'transit', 'EWR.H', DATE '2026-11-05', '185441.22-EWR.H-TEB01-28-G', 'by_route'),
        (904, 'transit', 'EWR.H', DATE '2026-11-05', '185440.22-EWR.H-TEB01-26-G', 'by_route'),
        (905, 'transit', 'EWR.H', DATE '2026-11-05', '185439.22-EWR.H-TEB01-25-G', 'by_route'),
        (906, 'transit', 'EWR.H', DATE '2026-11-05', '185438.22-EWR.H-TEB01-24-G', 'by_route'),
        (907, 'transit', 'EWR.H', DATE '2026-11-05', '185437.22-EWR.H-TEB01-23-G', 'by_route'),
        (908, 'transit', 'EWR.H', DATE '2026-11-05', '185436.22-EWR.H-TEB01-22-G', 'by_route'),
        (909, 'transit', 'EWR.H', DATE '2026-11-05', '185435.22-EWR.H-TEB01-21-G', 'by_route'),
        (910, 'transit', 'EWR.H', DATE '2026-11-05', '185434.22-EWR.H-TEB01-20-G', 'by_route'),
        (911, 'transit', 'EWR.H', DATE '2026-11-05', '185433.22-EWR.H-TEB01-19-G', 'by_route'),
        (912, 'transit', 'EWR.H', DATE '2026-11-05', '185432.22-EWR.H-TEB01-18-G', 'by_route'),
        (913, 'transit', 'EWR.H', DATE '2026-11-05', '185431.22-EWR.H-TEB01-17-G', 'by_route'),
        (1001, 'transit', 'EWR.H', DATE '2026-11-05', '185217.22-EWR.H-LDJ01-019-G', 'by_route'),
        (1002, 'transit', 'EWR.H', DATE '2026-11-05', '185216.22-EWR.H-LDJ01-017-G', 'by_route'),
        (1003, 'transit', 'EWR.H', DATE '2026-11-05', '185215.22-EWR.H-LDJ01-016-G', 'by_route'),
        (1004, 'transit', 'EWR.H', DATE '2026-11-05', '185214.22-EWR.H-LDJ01-015-G', 'by_route'),
        (1005, 'transit', 'EWR.H', DATE '2026-11-05', '185213.22-EWR.H-LDJ01-014-G', 'by_route'),
        (1006, 'transit', 'EWR.H', DATE '2026-11-05', '185212.22-EWR.H-LDJ01-013-G', 'by_route'),
        (1007, 'transit', 'EWR.H', DATE '2026-11-05', '185452.22-EWR.H-TEB01-41-G', 'by_route'),
        (1008, 'transit', 'EWR.H', DATE '2026-11-05', '185655.22-EWR.H-TEB01-40-G', 'by_route'),
        (1009, 'transit', 'EWR.H', DATE '2026-11-05', '185451.22-EWR.H-TEB01-39-G', 'by_route'),
        (1010, 'transit', 'EWR.H', DATE '2026-11-05', '185450.22-EWR.H-TEB01-38-G', 'by_route'),
        (1011, 'transit', 'EWR.H', DATE '2026-11-05', '185449.22-EWR.H-TEB01-37-G', 'by_route'),
        (1012, 'transit', 'EWR.H', DATE '2026-11-05', '185448.22-EWR.H-TEB01-36-G', 'by_route'),
        (1013, 'transit', 'EWR.H', DATE '2026-11-05', '185447.22-EWR.H-TEB01-35-G', 'by_route'),
        (1014, 'transit', 'EWR.H', DATE '2026-11-05', '185446.22-EWR.H-TEB01-34-G', 'by_route'),
        (1015, 'transit', 'EWR.H', DATE '2026-11-05', '185445.22-EWR.H-TEB01-33-G', 'by_route'),
        (1016, 'transit', 'EWR.H', DATE '2026-11-05', '185444.22-EWR.H-TEB01-32-G', 'by_route'),
        (1053, 'transit', 'EWR.H', DATE '2026-11-05', '185246.22-EWR.H-LDJ01-64-G', 'by_route'),
        (1054, 'transit', 'EWR.H', DATE '2026-11-05', '185244.22-EWR.H-LDJ01-61-G', 'by_route'),
        (1055, 'transit', 'EWR.H', DATE '2026-11-05', '185242.22-EWR.H-LDJ01-56-G', 'by_route'),
        (1056, 'transit', 'EWR.H', DATE '2026-11-05', '185240.22-EWR.H-LDJ01-53-G', 'by_route'),
        (1057, 'transit', 'EWR.H', DATE '2026-11-05', '185238.22-EWR.H-LDJ01-51-G', 'by_route'),
        (1058, 'transit', 'EWR.H', DATE '2026-11-05', '185236.22-EWR.H-LDJ01-49-G', 'by_route'),
        (1059, 'transit', 'EWR.H', DATE '2026-11-05', '185234.22-EWR.H-LDJ01-47-G', 'by_route'),
        (1060, 'transit', 'EWR.H', DATE '2026-11-05', '185232.22-EWR.H-LDJ01-45-G', 'by_route'),
        (1061, 'transit', 'EWR.H', DATE '2026-11-05', '185230.22-EWR.H-LDJ01-43-G', 'by_route'),
        (1062, 'transit', 'EWR.H', DATE '2026-11-05', '185228.22-EWR.H-LDJ01-18-G', 'by_route'),
        (1063, 'transit', 'EWR.H', DATE '2026-11-05', '185226.22-EWR.H-LDJ01-062-G', 'by_route'),
        (1064, 'transit', 'EWR.H', DATE '2026-11-05', '185224.22-EWR.H-LDJ01-03-G', 'by_route'),
        (1065, 'transit', 'EWR.H', DATE '2026-11-05', '185222.22-EWR.H-LDJ01-024-G', 'by_route'),
        (1066, 'transit', 'EWR.H', DATE '2026-11-05', '185220.22-EWR.H-LDJ01-022-G', 'by_route'),
        (1067, 'transit', 'EWR.H', DATE '2026-11-05', '185218.22-EWR.H-LDJ01-020-G', 'by_route'),
        (10101, 'transit', 'EWR.H', DATE '2026-11-05', '185631.22-EWR.H-LGA02-M44-H', 'by_route'),
        (10201, 'transit', 'EWR.H', DATE '2026-11-05', '185629.22-EWR.H-LGA02-M42-H', 'by_route'),
        (10301, 'transit', 'EWR.H', DATE '2026-11-05', '185627.22-EWR.H-LGA02-M40-H', 'by_route'),
        (10401, 'transit', 'EWR.H', DATE '2026-11-05', '185625.22-EWR.H-LGA02-M38-H', 'by_route'),
        (10501, 'transit', 'EWR.H', DATE '2026-11-05', '185623.22-EWR.H-LGA02-M36-H', 'by_route'),
        (10601, 'transit', 'EWR.H', DATE '2026-11-05', '185621.22-EWR.H-LGA02-M34-H', 'by_route'),
        (10701, 'transit', 'EWR.H', DATE '2026-11-05', '185619.22-EWR.H-LGA02-M32-H', 'by_route'),
        (10801, 'transit', 'EWR.H', DATE '2026-11-05', '185617.22-EWR.H-LGA02-M30-H', 'by_route'),
        (10901, 'transit', 'EWR.H', DATE '2026-11-05', '185615.22-EWR.H-LGA02-M19-H', 'by_route'),
        (11001, 'transit', 'EWR.H', DATE '2026-11-05', '185613.22-EWR.H-LGA02-M17-H', 'by_route'),
        (11101, 'transit', 'EWR.H', DATE '2026-11-05', '185611.22-EWR.H-LGA02-M15-H', 'by_route'),
        (11201, 'transit', 'EWR.H', DATE '2026-11-05', '185609.22-EWR.H-LGA02-M13-H', 'by_route'),
        (11301, 'transit', 'EWR.H', DATE '2026-11-05', '185607.22-EWR.H-LGA02-M11-H', 'by_route'),
        (11401, 'transit', 'EWR.H', DATE '2026-11-05', '185605.22-EWR.H-LGA02-M09-H', 'by_route'),
        (11501, 'transit', 'EWR.H', DATE '2026-11-05', '185603.22-EWR.H-LGA02-M07-H', 'by_route'),
        (11601, 'transit', 'EWR.H', DATE '2026-11-05', '185601.22-EWR.H-LGA02-M05-H', 'by_route'),
        (11701, 'transit', 'EWR.H', DATE '2026-11-05', '185599.22-EWR.H-LGA02-M03-H', 'by_route'),
        (11801, 'transit', 'EWR.H', DATE '2026-11-05', '185597.22-EWR.H-LGA02-M01-H', 'by_route'),
        (17001, 'transit', 'EWR.H', DATE '2026-11-05', '185154.22-EWR.H-BUF01-002-H', 'by_route'),
        (22001, 'transit', 'EWR.H', DATE '2026-11-05', '185153.22-EWR.H-BUF01-001-H', 'by_route'),
        (105201, 'transit', 'EWR.H', DATE '2026-11-05', '185248.22-EWR.H-LDJ01-66-G', 'by_route'),
        (105301, 'transit', 'EWR.H', DATE '2026-11-05', '185247.22-EWR.H-LDJ01-65-G', 'by_route'),
        (105401, 'transit', 'EWR.H', DATE '2026-11-05', '185245.22-EWR.H-LDJ01-63-G', 'by_route'),
        (105501, 'transit', 'EWR.H', DATE '2026-11-05', '185243.22-EWR.H-LDJ01-60-G', 'by_route'),
        (105601, 'transit', 'EWR.H', DATE '2026-11-05', '185241.22-EWR.H-LDJ01-55-G', 'by_route'),
        (105701, 'transit', 'EWR.H', DATE '2026-11-05', '185239.22-EWR.H-LDJ01-52-G', 'by_route'),
        (105801, 'transit', 'EWR.H', DATE '2026-11-05', '185237.22-EWR.H-LDJ01-50-G', 'by_route'),
        (105901, 'transit', 'EWR.H', DATE '2026-11-05', '185235.22-EWR.H-LDJ01-48-G', 'by_route'),
        (106001, 'transit', 'EWR.H', DATE '2026-11-05', '185233.22-EWR.H-LDJ01-46-G', 'by_route'),
        (106101, 'transit', 'EWR.H', DATE '2026-11-05', '185231.22-EWR.H-LDJ01-44-G', 'by_route'),
        (106201, 'transit', 'EWR.H', DATE '2026-11-05', '185229.22-EWR.H-LDJ01-42-G', 'by_route'),
        (106301, 'transit', 'EWR.H', DATE '2026-11-05', '185227.22-EWR.H-LDJ01-067-G', 'by_route'),
        (106401, 'transit', 'EWR.H', DATE '2026-11-05', '185225.22-EWR.H-LDJ01-057-G', 'by_route'),
        (106501, 'transit', 'EWR.H', DATE '2026-11-05', '185223.22-EWR.H-LDJ01-025-G', 'by_route'),
        (106601, 'transit', 'EWR.H', DATE '2026-11-05', '185221.22-EWR.H-LDJ01-023-G', 'by_route'),
        (106701, 'transit', 'EWR.H', DATE '2026-11-05', '185219.22-EWR.H-LDJ01-021-G', 'by_route')
) AS v(chute_id, bundle_type, destination_warehouse, effective_date, route, sort_type)
WHERE NOT EXISTS (
    SELECT 1
    FROM public.chute_destination_resort existing
    WHERE existing.chute_id = v.chute_id
      AND existing.effective_date IS NOT DISTINCT FROM v.effective_date
      AND existing.route IS NOT DISTINCT FROM v.route
);
