-- Ops day 2026-10-29 mid-day switch at 12:10 ET.
-- Scrapes before 12:10 keep the prior plan. Scrapes at/after 12:10 stay on
-- ops day 2026-10-29 but use plan 458隔口配置. Close every still-open
-- prior row on 2026-10-29 so the morning window remains covered.

UPDATE public.chute_destination_gofo
SET end_date = DATE '2026-10-29'
WHERE end_date IS NULL
  AND (effective_date IS NULL OR effective_date <= DATE '2026-10-29');
