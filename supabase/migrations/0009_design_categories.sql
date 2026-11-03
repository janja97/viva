-- Kategorije iz izbornika novog dizajna. Postojeće se ne mijenjaju, pa se upit smije pokrenuti više puta.
insert into public.categories (parent_id, name, slug, description, sort_order)
select parent.id, item.name, item.slug, item.description, item.sort_order
from (values
  ('odjeca', 'Haljine', 'haljine', 'Haljine za posao i posebne prilike. Pogledajte modele online ili nas posjetite u Mepas Mallu u Mostaru.', 20),
  ('odjeca', 'Poslovno', 'poslovno', 'Poslovna ženska moda: sakoi, kompleti i haljine. Pogledajte modele online ili nas posjetite u Mepas Mallu u Mostaru.', 21),
  ('odjeca', 'Svečano', 'svecano', 'Svečana ženska moda za vjenčanja, mature i gala večeri. Pogledajte modele online ili nas posjetite u Mepas Mallu u Mostaru.', 22),
  ('odjeca', 'Kompleti i sakoi', 'kompleti-i-sakoi', 'Krojeni kompleti i sakoi. Pogledajte modele online ili nas posjetite u Mepas Mallu u Mostaru.', 23)
) as item (parent_slug, name, slug, description, sort_order)
join public.categories parent on parent.slug = item.parent_slug
on conflict (slug) do nothing;

insert into public.categories (name, slug, description, sort_order)
values ('Torbice', 'torbice', 'Elegantne torbice i clutch modeli. Pogledajte ponudu online ili nas posjetite u Mepas Mallu u Mostaru.', 30)
on conflict (slug) do nothing;
