-- Ops day 2026-11-11 regular-plan cutover (1110 → 1111) starts when B opens.
-- Scraper PC rebooted overnight; B discovery was missed until 14:10 ET.
-- UniMap Batch No NJSUB-202611110649 encodes B open at 06:49 ET — use that
-- as switch_at so A scrapes before B stay on 1110 and later A/C use 1111.

INSERT INTO public.gofo_plan_switch (ops_date, switch_at, note)
VALUES (
  DATE '2026-11-11',
  (DATE '2026-11-11' + TIME '06:49') AT TIME ZONE 'America/New_York',
  '第一次分拣模版1110 → 1111 (B segment open NJSUB-202611110649; scrape missed, Batch No clock)'
)
ON CONFLICT (ops_date) DO UPDATE
SET
  switch_at = EXCLUDED.switch_at,
  note = EXCLUDED.note,
  recorded_at = now();
