-- Kampanje sniženja. Trajna traje dok se ne pauzira, a privremena samo od početka do kraja.
-- Proizvod dobiva kampanju (products.campaign_id), a baza sama upisuje products.discount_percent:
-- postotak kampanje dok je aktivna, inače ništa. Zato sale_price, filtri, košarica i povijest cijena rade kao i prije.
begin;

create table public.campaigns (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 80),
  kind text not null check (kind in ('permanent', 'temporary')),
  discount_percent integer not null check (discount_percent between 1 and 99),
  starts_at timestamptz,
  ends_at timestamptz,
  is_paused boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint campaigns_dates_check check (
    (kind = 'permanent' and starts_at is null and ends_at is null)
    or (kind = 'temporary' and starts_at is not null and ends_at is not null and ends_at > starts_at)
  )
);

create index campaigns_created_idx on public.campaigns (created_at desc);

alter table public.products
  add column campaign_id uuid references public.campaigns (id) on delete set null;

create index products_campaign_idx on public.products (campaign_id) where campaign_id is not null;

-- Dosadašnja sniženja upisana na proizvodu postaju trajne kampanje, po jedna za svaki postotak.
-- Ide prije okidača ispod, kako se postojeća sniženja ne bi obrisala prije povezivanja s kampanjom.
insert into public.campaigns (name, kind, discount_percent)
select 'Sniženje ' || discount_percent || ' %', 'permanent', discount_percent
from (select distinct discount_percent from public.products where discount_percent is not null) existing;

update public.products p
set campaign_id = c.id
from public.campaigns c
where p.discount_percent is not null
  and c.kind = 'permanent'
  and c.discount_percent = p.discount_percent;

-- Postotak koji kampanja trenutno daje, ili null ako je pauzirana, još nije počela ili je završila.
create function public.campaign_percent(p_campaign_id uuid)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select c.discount_percent
  from public.campaigns c
  where c.id = p_campaign_id
    and not c.is_paused
    and (c.kind = 'permanent' or now() >= c.starts_at and now() < c.ends_at);
$$;

revoke all on function public.campaign_percent(uuid) from public;
grant execute on function public.campaign_percent(uuid) to authenticated, service_role;

-- Sniženje proizvoda uvijek prati kampanju. Ručno upisan postotak se zanemaruje.
create function public.apply_campaign_discount()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.discount_percent := public.campaign_percent(new.campaign_id);
  return new;
end;
$$;

create trigger apply_campaign_discount
before insert or update on public.products
for each row execute function public.apply_campaign_discount();

-- Usklađuje cijene sa stanjem kampanja. Mijenja samo proizvode kojima se sniženje stvarno mijenja.
create function public.refresh_campaign_prices()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_updated integer;
begin
  update public.products p
  set discount_percent = public.campaign_percent(p.campaign_id)
  where p.discount_percent is distinct from public.campaign_percent(p.campaign_id);
  get diagnostics v_updated = row_count;
  return v_updated;
end;
$$;

revoke all on function public.refresh_campaign_prices() from public, anon, authenticated;

create function public.touch_campaign()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger touch_campaign
before update on public.campaigns
for each row execute function public.touch_campaign();

-- Promjena postotka, datuma ili pauze odmah mijenja cijene. Brisanje kampanje
-- proizvodima postavlja campaign_id na null, a okidač proizvoda tada sam miče sniženje.
create function public.campaign_changed()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.refresh_campaign_prices();
  return null;
end;
$$;

revoke all on function public.campaign_changed() from public, anon, authenticated;

create trigger campaign_changed
after insert or update on public.campaigns
for each statement execute function public.campaign_changed();

-- Privremene kampanje počinju i završavaju same, pa se cijene provjeravaju svake minute.
select cron.schedule('kampanje-cijene', '* * * * *', 'select public.refresh_campaign_prices()');

-- Spremanje proizvoda sprema i kampanju.
create or replace function public.save_product_with_categories(payload jsonb)
returns uuid
language plpgsql
set search_path = ''
as $$
declare
  v_product_id uuid;
  v_main_id uuid := (payload ->> 'category_id')::uuid;
  v_extra_ids jsonb := coalesce(payload -> 'extra_category_ids', '[]'::jsonb);
  v_campaign_id uuid := nullif(payload ->> 'campaign_id', '')::uuid;
begin
  v_product_id := public.save_product(payload);

  update public.products
  set campaign_id = v_campaign_id
  where id = v_product_id and campaign_id is distinct from v_campaign_id;

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

-- Skupne izmjene: sniženje se sada dodjeljuje kampanjom (campaign_id, null je bez kampanje).
create or replace function public.bulk_update_products(p_ids uuid[], p_changes jsonb)
returns jsonb
language plpgsql
set search_path = ''
as $$
declare
  v_updated integer := 0;
  v_skipped integer := 0;
  v_campaign_id uuid;
begin
  if coalesce(public.current_user_role()::text, '') not in ('super_admin', 'admin') then
    raise exception 'Nemaš ovlasti za ovu radnju.' using errcode = '42501';
  end if;

  if p_changes ? 'is_visible' and (p_changes ->> 'is_visible')::boolean then
    update public.products p
    set is_visible = true
    where p.id = any (p_ids)
      and not p.is_visible
      and p.archived_at is null
      and exists (select 1 from public.product_colors c where c.product_id = p.id)
      and not exists (
        select 1 from public.product_colors c
        where c.product_id = p.id
          and not exists (select 1 from public.product_images i where i.color_id = c.id)
      );
    get diagnostics v_updated = row_count;

    select count(*) into v_skipped
    from public.products p
    where p.id = any (p_ids) and not p.is_visible;

  elsif p_changes ? 'is_visible' then
    update public.products
    set is_visible = false
    where id = any (p_ids) and is_visible;
    get diagnostics v_updated = row_count;

  elsif p_changes ? 'store_only' then
    update public.products
    set store_only = (p_changes ->> 'store_only')::boolean
    where id = any (p_ids) and store_only <> (p_changes ->> 'store_only')::boolean;
    get diagnostics v_updated = row_count;

  elsif p_changes ? 'campaign_id' then
    v_campaign_id := nullif(p_changes ->> 'campaign_id', '')::uuid;
    if v_campaign_id is not null and not exists (select 1 from public.campaigns where id = v_campaign_id) then
      raise exception 'Kampanja više ne postoji.';
    end if;

    update public.products
    set campaign_id = v_campaign_id
    where id = any (p_ids) and campaign_id is distinct from v_campaign_id;
    get diagnostics v_updated = row_count;

  else
    raise exception 'Nepoznata izmjena.';
  end if;

  return jsonb_build_object('updated', v_updated, 'skipped', v_skipped);
end;
$$;

-- RLS: tim vidi kampanje, a dodaju, mijenjaju i brišu ih admin i super admin. Kupci ih ne čitaju.
alter table public.campaigns enable row level security;

revoke all on public.campaigns from public, anon, authenticated;
grant select, insert, update, delete on public.campaigns to authenticated;
grant all on public.campaigns to service_role;

create policy campaigns_select on public.campaigns
for select to authenticated
using ((select public.current_user_role()) is not null);

create policy campaigns_insert on public.campaigns
for insert to authenticated
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy campaigns_update on public.campaigns
for update to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'))
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy campaigns_delete on public.campaigns
for delete to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'));

commit;
