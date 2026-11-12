-- JEDNOKRATNO, nakon seed_categories.sql: dodatne kategorije koje je tražila vlasnica (studeni 2026.).
-- Postojeće se ne mijenjaju, osim što Clutch i Večernje torbice prelaze ispod Svečanih torbica,
-- a Čizme dobivaju podkategorije Ravne čizme i Čizme na petu. Ako adresa već postoji, preskače se.
-- Najviše tri razine: npr. Obuća / Čizme / Ravne čizme.
begin;

-- Druga razina, ispod glavnih kategorija.
insert into public.categories (parent_id, name, slug, description, sort_order)
select parent.id, child.name, child.slug, child.description, child.sort_order
from (values
  ('odjeca', 'Bolera', 'bolera', 'Bolera i kratke jaknice preko svečane haljine.', 4),
  ('odjeca', 'Hlače', 'hlace', 'Elegantne ženske hlače za posao i svečane prilike.', 5),
  ('odjeca', 'Košulje', 'kosulje', 'Ženske košulje i bluze, uz odijelo, hlače ili suknju.', 6),
  ('obuca', 'Polusalonke', 'polusalonke', 'Polusalonke na petu, otvorene na peti ili sa strane.', 2),
  ('obuca', 'Mokasine', 'mokasine', 'Ženske mokasine za posao i svaki dan.', 5),
  ('obuca', 'Baletanke', 'baletanke', 'Ravne baletanke, udobne uz haljinu i hlače.', 6),
  ('torbice', 'Svečane torbice', 'svecane-torbice', 'Svečane torbice uz večernju i maturalnu haljinu.', 1),
  ('torbice', 'Mini torbice', 'mini-torbice', 'Male torbice za izlaske i svaki dan.', 2),
  ('torbice', 'Midi torbice', 'midi-torbice', 'Torbice srednje veličine za posao i svaki dan.', 3),
  ('torbice', 'Maxi torbe', 'maxi-torbe', 'Velike torbe za posao i putovanja.', 4),
  ('torbice', 'Koferi i putne torbe', 'koferi-i-putne-torbe', 'Koferi i putne torbe.', 5),
  ('dodaci', 'Šalovi', 'salovi', 'Šalovi i marame uz kaput ili svečanu haljinu.', 2)
) as child (parent_slug, name, slug, description, sort_order)
join public.categories parent on parent.slug = child.parent_slug
on conflict (slug) do nothing;

-- Treća razina.
insert into public.categories (parent_id, name, slug, description, sort_order)
select parent.id, child.name, child.slug, child.description, child.sort_order
from (values
  ('jakne', 'Kožne jakne', 'kozne-jakne', 'Ženske kožne jakne.', 1),
  ('cizme', 'Ravne čizme', 'ravne-cizme', 'Ženske čizme bez pete ili s niskom petom.', 1),
  ('cizme', 'Čizme na petu', 'cizme-na-petu', 'Elegantne ženske čizme na petu.', 2)
) as child (parent_slug, name, slug, description, sort_order)
join public.categories parent on parent.slug = child.parent_slug
on conflict (slug) do nothing;

-- Clutch i Večernje torbice ispod Svečanih torbica.
update public.categories c
set parent_id = (select id from public.categories where slug = 'svecane-torbice')
where c.slug in ('clutch-torbice', 'vecernje-torbice');

-- Redoslijed unutar Obuće: Salonke, Polusalonke, Sandale, Čizme, Mokasine, Baletanke.
update public.categories set sort_order = 3 where slug = 'sandale';
update public.categories set sort_order = 4 where slug = 'cizme';

commit;

-- Provjera: cijelo stablo kategorija.
with recursive tree as (
  select id, name, slug, sort_order, 1 as level, lpad(sort_order::text, 3, '0') as path
  from public.categories where parent_id is null
  union all
  select c.id, c.name, c.slug, c.sort_order, t.level + 1, t.path || '.' || lpad(c.sort_order::text, 3, '0')
  from public.categories c join tree t on c.parent_id = t.id
)
select repeat('    ', level - 1) || name as kategorija, slug from tree order by path;
