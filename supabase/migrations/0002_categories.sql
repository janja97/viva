-- Kategorije u dvije razine: glavna (parent_id je null) i podkategorija.
begin;

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.categories (id) on delete restrict,
  name text not null check (char_length(btrim(name)) between 1 and 80),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  description text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (parent_id is null or parent_id <> id)
);

create index categories_parent_sort_idx on public.categories (parent_id, sort_order);

-- Čuva dvije razine i ne dopušta aktivnu podkategoriju pod neaktivnom glavnom.
create function public.validate_category()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  grandparent_id uuid;
  parent_active boolean;
begin
  if new.parent_id is not null then
    select parent_id, is_active into grandparent_id, parent_active
    from public.categories
    where id = new.parent_id;

    if grandparent_id is not null then
      raise exception 'Podkategorija ne može imati svoju podkategoriju.';
    end if;

    if exists (select 1 from public.categories where parent_id = new.id) then
      raise exception 'Kategorija koja ima podkategorije ne može postati podkategorija.';
    end if;

    if parent_active = false then
      new.is_active := false;
    end if;
  end if;

  new.updated_at := now();
  return new;
end;
$$;

create trigger validate_category
before insert or update on public.categories
for each row execute function public.validate_category();

-- Isključivanje glavne kategorije isključuje i njezine podkategorije.
create function public.deactivate_subcategories()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.categories set is_active = false
  where parent_id = new.id and is_active;
  return null;
end;
$$;

create trigger deactivate_subcategories
after update of is_active on public.categories
for each row
when (old.is_active and not new.is_active)
execute function public.deactivate_subcategories();

revoke all on function public.validate_category() from public, anon, authenticated;
revoke all on function public.deactivate_subcategories() from public, anon, authenticated;

alter table public.categories enable row level security;

revoke all on public.categories from public, anon, authenticated;
grant select on public.categories to anon;
grant select, insert, update, delete on public.categories to authenticated;
grant all on public.categories to service_role;

-- Čitanje: posjetitelji i kupci vide aktivne, a članovi tima sve.
create policy categories_select_public on public.categories
for select to anon
using (is_active);

create policy categories_select_authenticated on public.categories
for select to authenticated
using (is_active or (select public.current_user_role()) is not null);

-- Pisanje: super admin i admin. Viewer samo čita.
create policy categories_insert on public.categories
for insert to authenticated
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy categories_update on public.categories
for update to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'))
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy categories_delete on public.categories
for delete to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'));

-- Početne kategorije.
insert into public.categories (name, slug, sort_order) values
  ('Odjeća', 'odjeca', 1),
  ('Obuća', 'obuca', 2),
  ('Dodaci', 'dodaci', 3);

insert into public.categories (parent_id, name, slug, sort_order)
select parent.id, child.name, child.slug, child.sort_order
from (values
  ('odjeca', 'Haljine', 'haljine', 1),
  ('odjeca', 'Majice', 'majice', 2),
  ('obuca', 'Čizme', 'cizme', 1),
  ('obuca', 'Sandale', 'sandale', 2)
) as child (parent_slug, name, slug, sort_order)
join public.categories parent on parent.slug = child.parent_slug;

commit;
