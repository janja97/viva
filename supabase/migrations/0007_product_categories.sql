-- Proizvod može biti u više kategorija, npr. svečane i maturalne haljine.
-- products.category_id ostaje glavna kategorija, a ova tablica sadrži glavnu i sve dodatne.
begin;

create table public.product_categories (
  product_id uuid not null references public.products (id) on delete cascade,
  category_id uuid not null references public.categories (id) on delete cascade,
  primary key (product_id, category_id)
);

create index product_categories_category_idx on public.product_categories (category_id);

insert into public.product_categories (product_id, category_id)
select id, category_id from public.products;

-- Glavna kategorija se uvijek nalazi i u ovoj tablici.
create function public.sync_main_category()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.product_categories (product_id, category_id)
  values (new.id, new.category_id)
  on conflict do nothing;
  return null;
end;
$$;

create trigger sync_main_category
after insert or update of category_id on public.products
for each row execute function public.sync_main_category();

-- Sprema proizvod i njegove dodatne kategorije u jednoj transakciji.
create function public.save_product_with_categories(payload jsonb)
returns uuid
language plpgsql
set search_path = ''
as $$
declare
  v_product_id uuid;
  v_main_id uuid := (payload ->> 'category_id')::uuid;
  v_extra_ids jsonb := coalesce(payload -> 'extra_category_ids', '[]'::jsonb);
begin
  v_product_id := public.save_product(payload);

  delete from public.product_categories pc
  where pc.product_id = v_product_id
    and pc.category_id <> v_main_id
    and pc.category_id not in (
      select value::uuid from jsonb_array_elements_text(v_extra_ids)
    );

  insert into public.product_categories (product_id, category_id)
  select v_product_id, value::uuid from jsonb_array_elements_text(v_extra_ids)
  on conflict do nothing;

  return v_product_id;
end;
$$;

revoke all on function public.sync_main_category() from public, anon, authenticated;
revoke all on function public.save_product_with_categories(jsonb) from public, anon;
grant execute on function public.save_product_with_categories(jsonb) to authenticated, service_role;

alter table public.product_categories enable row level security;

revoke all on public.product_categories from public, anon, authenticated;
grant select on public.product_categories to anon, authenticated;
grant insert, update, delete on public.product_categories to authenticated;
grant all on public.product_categories to service_role;

-- Veza se vidi samo ako je vidljiv i proizvod (RLS proizvoda vrijedi i ovdje).
create policy product_categories_select on public.product_categories
for select to anon, authenticated
using (exists (select 1 from public.products p where p.id = product_id));

create policy product_categories_insert on public.product_categories
for insert to authenticated
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy product_categories_update on public.product_categories
for update to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'))
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy product_categories_delete on public.product_categories
for delete to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'));

commit;
