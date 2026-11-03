-- Kategorije za glavne pojmove koje kupci traže. Postojeće se ne mijenjaju.
insert into public.categories (parent_id, name, slug, description, sort_order)
select parent.id, item.name, item.slug, item.description, item.sort_order
from (values
  ('odjeca', 'Svečane haljine', 'svecane-haljine', 'Svečane haljine za posebne prilike. Pogledajte modele online i isprobajte ih u našoj trgovini Viva u Mepas Mallu u Mostaru.', 10),
  ('odjeca', 'Maturalne haljine', 'maturalne-haljine', 'Maturalne haljine za vašu maturu. Pogledajte modele online i isprobajte ih u našoj trgovini Viva u Mepas Mallu u Mostaru.', 11),
  ('odjeca', 'Elegantne haljine', 'elegantne-haljine', 'Elegantne haljine za svaku svečanu priliku. Pogledajte modele online ili nas posjetite u Mepas Mallu u Mostaru.', 12),
  ('odjeca', 'Odijela', 'odijela', 'Svečana odijela za maturu i posebne prilike. Pogledajte ponudu online ili nas posjetite u Mepas Mallu u Mostaru.', 13),
  ('obuca', 'Cipele', 'cipele', 'Svečane cipele uz haljinu ili odijelo. Pogledajte ponudu online ili nas posjetite u Mepas Mallu u Mostaru.', 10)
) as item (parent_slug, name, slug, description, sort_order)
join public.categories parent on parent.slug = item.parent_slug
on conflict (slug) do nothing;

-- Dodaci već postoje kao glavna kategorija, pa dobivaju samo opis ako ga nemaju.
update public.categories
set description = 'Svečani dodaci koji upotpunjuju vaš izgled. Pogledajte ponudu online ili nas posjetite u Mepas Mallu u Mostaru.'
where slug = 'dodaci' and description is null;
