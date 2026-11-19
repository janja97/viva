-- Isključuje kategorije bez ijednog proizvoda vidljivog na webu, ni u sebi ni u podkategorijama.
-- Proizvod se broji ako mu je to glavna ili dodatna kategorija (product_categories).
-- Jednokratno: kad kategorija dobije proizvode, uključuje se ručno u /admin/kategorije.
-- Kategorije koje su već isključene ostaju isključene.

with recursive tree as (
  -- Svaka kategorija je "predak" sama sebi, pa se penje prema vrhu.
  select id as category_id, id as ancestor_id, parent_id from public.categories
  union all
  select tree.category_id, parent.id, parent.parent_id
  from tree
  join public.categories parent on parent.id = tree.parent_id
),
used as (
  select distinct tree.ancestor_id as id
  from public.products p
  join public.product_categories pc on pc.product_id = p.id
  join tree on tree.category_id = pc.category_id
  where p.is_visible and p.archived_at is null
)
update public.categories c
set is_active = false
where c.is_active
  and not exists (select 1 from used where used.id = c.id)
returning c.slug;
