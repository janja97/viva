-- Interni podaci proizvoda koje vidi samo tim, npr. brend. Kupci ih ne vide ni kroz API,
-- zato su u zasebnoj tablici, a ne u products (koju posjetitelji smiju čitati).
begin;

create table public.product_internal (
  product_id uuid primary key references public.products (id) on delete cascade,
  brand text check (brand is null or char_length(btrim(brand)) between 1 and 80)
);

create index product_internal_brand_idx on public.product_internal (brand) where brand is not null;

-- Postojeća funkcija sprema i brend. Radi s pravima pozivatelja, pa vrijede RLS pravila tablice.
create or replace function public.save_product_with_categories(payload jsonb)
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

  insert into public.product_internal (product_id, brand)
  values (v_product_id, nullif(btrim(payload ->> 'brand'), ''))
  on conflict (product_id) do update set brand = excluded.brand;

  return v_product_id;
end;
$$;

-- Popis upisanih brendova za prijedloge pri unosu.
create function public.product_brands()
returns setof text
language sql
stable
set search_path = ''
as $$
  select distinct brand from public.product_internal where brand is not null order by brand;
$$;

revoke all on function public.product_brands() from public, anon;
grant execute on function public.product_brands() to authenticated, service_role;

alter table public.product_internal enable row level security;

revoke all on public.product_internal from public, anon, authenticated;
grant select, insert, update, delete on public.product_internal to authenticated;
grant all on public.product_internal to service_role;

-- Čitanje: svi članovi tima (i čitatelj). Kupci i posjetitelji nemaju pristup.
create policy product_internal_select on public.product_internal
for select to authenticated
using ((select public.current_user_role()) is not null);

-- Pisanje: super admin i admin.
create policy product_internal_insert on public.product_internal
for insert to authenticated
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy product_internal_update on public.product_internal
for update to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'))
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy product_internal_delete on public.product_internal
for delete to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'));

commit;
