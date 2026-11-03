-- Trgovina više nema poslovnu liniju. Kategorija se samo isključuje (ne briše), jer na nju mogu biti vezani proizvodi.
-- Okidač iz 0002 sam isključuje i sve kategorije ispod nje. Upit se smije pokrenuti više puta.
update public.categories
set is_active = false
where slug = 'poslovno' and is_active;

update public.categories
set description = 'Svečane, maturalne i elegantne haljine. Pogledajte modele online ili nas posjetite u Mepas Mallu u Mostaru.'
where slug = 'haljine'
  and description = 'Haljine za posao i posebne prilike. Pogledajte modele online ili nas posjetite u Mepas Mallu u Mostaru.';
