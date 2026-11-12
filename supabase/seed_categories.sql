-- JEDNOKRATNO: nove kategorije nakon reset_catalog.sql. Što bude višak, obriši u /admin/kategorije.
-- Adrese (slug) su birane prema onome što ljudi traže na Googleu i koriste ih postavke weba,
-- pa ih ne mijenjaj bez potrebe: haljine, odjeca, obuca i torbice određuju vrstu veličina,
-- haljine i sve ispod nudi duljinu haljine, obuca visinu pete, a izbornik vodi na glavne.
-- Nakon ovoga pokreni seed_category_seo.sql za tekstove i pitanja.
-- Ako kategorija s istom adresom već postoji, preskače se.
begin;

with tops as (
  insert into public.categories (name, slug, description, sort_order) values
    ('Haljine', 'haljine', 'Svečane, maturalne i elegantne haljine za maturu, svadbu i obiteljske proslave, te ležernije haljine za posao.', 1),
    ('Odjeća', 'odjeca', 'Ženska odijela, sakoi, kaputi i jakne, za svečane prilike i svaki dan.', 2),
    ('Obuća', 'obuca', 'Svečane cipele na petu, salonke, sandale i čizme.', 3),
    ('Torbice', 'torbice', 'Svečane torbice i clutch torbice uz haljinu.', 4),
    ('Dodaci', 'dodaci', 'Nakit od nehrđajućeg čelika i modni dodaci uz svečanu haljinu.', 5)
  on conflict (slug) do nothing
  returning id, slug
)
insert into public.categories (parent_id, name, slug, description, sort_order)
select tops.id, child.name, child.slug, child.description, child.sort_order
from tops
join (values
  ('haljine', 'Svečane haljine', 'svecane-haljine', 'Svečane i večernje haljine za posebne prilike.', 1),
  ('haljine', 'Maturalne haljine', 'maturalne-haljine', 'Maturalne haljine za veliku i malu maturu, duge i kratke.', 2),
  ('haljine', 'Haljine za svadbu', 'haljine-za-svadbu', 'Haljine za svadbu kao gošća i za mame mladenaca.', 3),
  ('haljine', 'Koktel haljine', 'koktel-haljine', 'Kraće elegantne haljine za koktele, rođendane i manje proslave.', 4),
  ('haljine', 'Ležerne haljine', 'lezerne-haljine', 'Ležernije haljine za posao i svaki dan.', 5),
  ('odjeca', 'Ženska odijela', 'zenska-odijela', 'Ženska odijela, kompleti i sakoi za posao, svadbu i svečane prilike.', 1),
  ('odjeca', 'Kaputi', 'kaputi', 'Elegantni ženski kaputi, i preko svečane haljine.', 2),
  ('odjeca', 'Jakne', 'jakne', 'Ženske jakne za prijelazno i zimsko vrijeme.', 3),
  ('obuca', 'Salonke', 'salonke', 'Salonke na petu uz svečanu haljinu i odijelo.', 1),
  ('obuca', 'Sandale', 'sandale', 'Svečane sandale za maturu, svadbu i ljetne prilike.', 2),
  ('obuca', 'Čizme', 'cizme', 'Elegantne ženske čizme.', 3),
  ('torbice', 'Clutch torbice', 'clutch-torbice', 'Male clutch torbice uz večernju i maturalnu haljinu.', 1),
  ('torbice', 'Večernje torbice', 'vecernje-torbice', 'Svečane večernje torbice na lančić ili s ručkom.', 2),
  ('dodaci', 'Nakit', 'nakit', 'Nakit od nehrđajućeg čelika: naušnice, ogrlice i narukvice.', 1)
) as child (parent_slug, name, slug, description, sort_order) on child.parent_slug = tops.slug
on conflict (slug) do nothing;

commit;

-- Provjera: popis kategorija s nadređenom.
select coalesce(p.name || ' / ', '') || c.name as kategorija, c.slug
from public.categories c
left join public.categories p on p.id = c.parent_id
order by coalesce(p.sort_order, c.sort_order), c.parent_id nulls first, c.sort_order;
