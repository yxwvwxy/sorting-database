-- Exclusive uni_hub route hub cities (never appear on a mixed *.H chute).
-- CLT already set on 870/918/919; fill the other 8.

UPDATE public.chute_destination_gofo SET hub_city = 'CNO'
WHERE chute_id = 869 AND sort_type = 'uni_hub' AND end_date IS NULL;

UPDATE public.chute_destination_gofo SET hub_city = 'DEN'
WHERE chute_id = 370 AND sort_type = 'uni_hub' AND end_date IS NULL;

UPDATE public.chute_destination_gofo SET hub_city = 'DFW'
WHERE chute_id IN (468, 518) AND sort_type = 'uni_hub' AND end_date IS NULL;

UPDATE public.chute_destination_gofo SET hub_city = 'IAH'
WHERE chute_id IN (569, 618) AND sort_type = 'uni_hub' AND end_date IS NULL;

UPDATE public.chute_destination_gofo SET hub_city = 'IND'
WHERE chute_id IN (620, 670) AND sort_type = 'uni_hub' AND end_date IS NULL;

UPDATE public.chute_destination_gofo SET hub_city = 'ORD'
WHERE chute_id IN (420, 470, 520) AND sort_type = 'uni_hub' AND end_date IS NULL;

UPDATE public.chute_destination_gofo SET hub_city = 'SEA'
WHERE chute_id = 570 AND sort_type = 'uni_hub' AND end_date IS NULL;

UPDATE public.chute_destination_gofo SET hub_city = 'SFO'
WHERE chute_id = 720 AND sort_type = 'uni_hub' AND end_date IS NULL;
