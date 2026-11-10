-- Postavke trgovine (/admin/postavke): kontakt, društvene mreže, radno vrijeme, poštarina i obavijest na vrhu weba.
-- Tablica ima samo jedan redak. Čitaju je svi (podaci su javni, prikazuju se na webu),
-- a mijenjaju je samo admin i super admin. Čitatelj je samo vidi. Novi redak i brisanje nisu dopušteni nikome.
begin;

create table public.store_settings (
  id boolean primary key default true check (id),
  phone text not null default '' check (phone = '' or phone ~ '^[0-9 +()/-]{6,30}$'),
  whatsapp text not null default '' check (whatsapp = '' or whatsapp ~ '^[0-9 +()/-]{6,30}$'),
  viber text not null default '' check (viber = '' or viber ~ '^[0-9 +()/-]{6,30}$'),
  email text not null default '' check (email = '' or (char_length(email) <= 200 and email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$')),
  instagram_url text not null default '' check (instagram_url = '' or (char_length(instagram_url) <= 300 and instagram_url ~ '^https://')),
  facebook_url text not null default '' check (facebook_url = '' or (char_length(facebook_url) <= 300 and facebook_url ~ '^https://')),
  tiktok_url text not null default '' check (tiktok_url = '' or (char_length(tiktok_url) <= 300 and tiktok_url ~ '^https://')),
  -- Sedam dana redom od ponedjeljka: [{ "day": "Monday", "closed": false, "opens": "09:00", "closes": "21:00" }, ...]
  opening_hours jsonb not null check (jsonb_typeof(opening_hours) = 'array' and jsonb_array_length(opening_hours) = 7),
  shipping_price numeric(10, 2) not null default 9 check (shipping_price >= 0 and shipping_price <= 1000),
  free_shipping_above numeric(10, 2) not null default 150 check (free_shipping_above >= 0 and free_shipping_above <= 100000),
  announcement_enabled boolean not null default false,
  announcement_text text not null default '' check (char_length(announcement_text) <= 160),
  updated_at timestamptz not null default now(),
  updated_by_email text
);

insert into public.store_settings (opening_hours) values ('[
  { "day": "Monday", "closed": false, "opens": "09:00", "closes": "21:00" },
  { "day": "Tuesday", "closed": false, "opens": "09:00", "closes": "21:00" },
  { "day": "Wednesday", "closed": false, "opens": "09:00", "closes": "21:00" },
  { "day": "Thursday", "closed": false, "opens": "09:00", "closes": "21:00" },
  { "day": "Friday", "closed": false, "opens": "09:00", "closes": "21:00" },
  { "day": "Saturday", "closed": false, "opens": "09:00", "closes": "21:00" },
  { "day": "Sunday", "closed": false, "opens": "12:00", "closes": "20:00" }
]'::jsonb);

-- Uključena obavijest mora imati tekst. Bilježi se tko je zadnji spremio.
create function public.touch_store_settings()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.announcement_enabled and btrim(new.announcement_text) = '' then
    raise exception 'Upišite tekst obavijesti ili je isključite.';
  end if;
  new.updated_at := now();
  new.updated_by_email := auth.jwt() ->> 'email';
  return new;
end;
$$;

create trigger touch_store_settings
before update on public.store_settings
for each row execute function public.touch_store_settings();

alter table public.store_settings enable row level security;

revoke all on public.store_settings from public, anon, authenticated;
grant select on public.store_settings to anon;
grant select, update on public.store_settings to authenticated;
grant all on public.store_settings to service_role;

-- Kupci (anon) i cijeli tim (super_admin, admin, viewer) čitaju.
create policy store_settings_select on public.store_settings
for select to anon, authenticated
using (true);

-- Mijenjaju samo super_admin i admin. Viewer nema pravo izmjene.
create policy store_settings_update on public.store_settings
for update to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'))
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

-- Insert i delete nemaju pravilo, pa ih RLS odbija za sve uloge (tablica ima uvijek točno jedan redak).

-- Poštarina iz postavki. Isto pravilo ima shippingFor u aplikaciji.
create function public.shipping_for(p_subtotal numeric)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select case when p_subtotal > s.free_shipping_above then 0 else s.shipping_price end
  from public.store_settings s
$$;

revoke all on function public.shipping_for(numeric) from public;
grant execute on function public.shipping_for(numeric) to anon, authenticated, service_role;

-- Upit sada poštarinu čita iz postavki umjesto stalnih 9 KM i 150 KM. Ostatak je isti kao u migraciji 0025.
create or replace function public.shop_submit_inquiry(p_session uuid, p_customer jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text := btrim(coalesce(p_customer ->> 'name', ''));
  v_phone text := btrim(coalesce(p_customer ->> 'phone', ''));
  v_address text := btrim(coalesce(p_customer ->> 'address', ''));
  v_postal_code text := btrim(coalesce(p_customer ->> 'postal_code', ''));
  v_city text := btrim(coalesce(p_customer ->> 'city', ''));
  v_email text := nullif(btrim(coalesce(p_customer ->> 'email', '')), '');
  v_note text := nullif(btrim(coalesce(p_customer ->> 'note', '')), '');
  v_item record;
  v_inquiry_id uuid;
  v_number bigint;
  v_subtotal numeric(10, 2);
  v_shipping numeric(10, 2);
  v_promo_code text := upper(nullif(btrim(coalesce(p_customer ->> 'promo_code', '')), ''));
  v_promo public.promo_codes;
  v_promo_discount numeric(10, 2) := 0;
begin
  perform public.shop_session_expire(p_session);

  if char_length(v_name) not between 2 and 100 then
    raise exception 'Upišite ime i prezime.';
  end if;
  if v_phone !~ '^[0-9 +()/-]{6,30}$' then
    raise exception 'Upišite ispravan broj telefona.';
  end if;
  if char_length(v_address) not between 3 and 200 then
    raise exception 'Upišite adresu za dostavu.';
  end if;
  if v_postal_code !~ '^[0-9]{5}$' then
    raise exception 'Poštanski broj mora imati 5 znamenki.';
  end if;
  if char_length(v_city) not between 2 and 100 then
    raise exception 'Upišite grad.';
  end if;
  if v_email is not null and (char_length(v_email) > 200 or v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$') then
    raise exception 'Upišite ispravnu e-mail adresu ili ostavite polje prazno.';
  end if;
  if char_length(coalesce(v_note, '')) > 2000 then
    raise exception 'Napomena može imati najviše 2000 znakova.';
  end if;

  -- Zaštita od višestrukog slanja istog upita.
  if exists (
    select 1 from public.inquiries
    where session_id = p_session and created_at > now() - interval '1 minute'
  ) then
    raise exception 'Narudžba je upravo poslana. Pričekajte minutu prije nove.';
  end if;

  if not exists (select 1 from public.cart_items where session_id = p_session) then
    raise exception 'Košarica je prazna.';
  end if;

  for v_item in
    select ci.quantity, s.size, s.quantity as stock, c.name as color_name, p.name, p.is_visible and public.category_is_active(p.category_id) as is_visible, p.store_only
    from public.cart_items ci
    join public.product_sizes s on s.id = ci.size_id
    join public.product_colors c on c.id = s.color_id
    join public.products p on p.id = c.product_id
    where ci.session_id = p_session
  loop
    if not v_item.is_visible or v_item.store_only then
      raise exception '% (%) više nije moguće naručiti online. Uklonite ga iz košarice.', v_item.name, v_item.color_name;
    end if;
    if v_item.quantity > v_item.stock then
      raise exception 'Za % (%, %) dostupno je još % kom. Promijenite količinu u košarici.',
        v_item.name, v_item.color_name, v_item.size, v_item.stock;
    end if;
  end loop;

  -- Promo kod se zaključava, kako isti jednokratni kod ne bi prošao u dvije narudžbe odjednom.
  if v_promo_code is not null then
    select * into v_promo from public.promo_codes where code = v_promo_code for update;
    if not found or not public.promo_code_is_valid(v_promo) then
      raise exception 'Promo kod nije valjan ili je istekao. Uklonite ga i pošaljite narudžbu ponovno.';
    end if;
  end if;

  insert into public.inquiries (customer_name, phone, address, postal_code, city, email, note, session_id, promo_code_id, promo_code)
  values (v_name, v_phone, v_address, v_postal_code, v_city, v_email, v_note, p_session, v_promo.id, v_promo.code)
  returning id, number into v_inquiry_id, v_number;

  insert into public.inquiry_items (
    inquiry_id, product_id, color_id, size_id, sku, product_name, color_name, size, unit_price, regular_price, quantity
  )
  select
    v_inquiry_id, p.id, c.id, s.id, p.sku, p.name, c.name, s.size,
    coalesce(p.sale_price, p.price), p.price, ci.quantity
  from public.cart_items ci
  join public.product_sizes s on s.id = ci.size_id
  join public.product_colors c on c.id = s.color_id
  join public.products p on p.id = c.product_id
  where ci.session_id = p_session
  order by ci.added_at;

  select sum(unit_price * quantity) into v_subtotal
  from public.inquiry_items
  where inquiry_id = v_inquiry_id;

  -- Poštarina se računa prema iznosu prije promo koda, kao i u košarici.
  v_shipping := public.shipping_for(v_subtotal);

  if v_promo.id is not null then
    v_promo_discount := round(v_subtotal * v_promo.discount_percent / 100, 2);
    update public.promo_codes set used_count = used_count + 1 where id = v_promo.id;
  end if;

  update public.inquiries
  set subtotal = v_subtotal, shipping = v_shipping, promo_discount = v_promo_discount, total = v_subtotal - v_promo_discount + v_shipping
  where id = v_inquiry_id;

  delete from public.cart_items where session_id = p_session;
  perform public.shop_session_touch(p_session);

  return jsonb_build_object('number', v_number);
end;
$$;

commit;
