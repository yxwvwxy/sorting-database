-- Keep only CLT as a written exclusive hub city; clear the other 8.

UPDATE public.chute_destination_gofo
SET hub_city = NULL
WHERE sort_type = 'uni_hub'
  AND end_date IS NULL
  AND hub_city IS NOT NULL
  AND hub_city <> 'CLT';
