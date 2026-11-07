-- Newsletter i promo kodovi.
-- Pretplatnik dobiva osobni kod: 10 %, vrijedi 15 dana i samo za jednu narudžbu.
-- Tim stvara i vlastite kodove (npr. za Dan drame) s trajanjem od-do, koji vrijede više puta.
-- Kod se upisuje u košarici, a popust na iznos proizvoda računa shop_submit_inquiry.
begin;

create table public.newsletter_subscribers (
  id uuid primary key default gen_random_uuid(),
  email text not null unique check (email = lower(email) and char_length(email) between 5 and 200),
  created_at timestamptz not null default now()
);

create index newsletter_subscribers_created_idx on public.newsletter_subscribers (created_at desc);

create table public.promo_codes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^[A-Z0-9-]{3,30}$'),
  kind text not null check (kind in ('newsletter', 'manual')),
  -- Interni naziv vlastitog koda, npr. "Dan drame". Kupci ga ne vide.
  name text check (name is null or char_length(btrim(name)) between 1 and 80),
  discount_percent integer not null check (discount_percent between 1 and 99),
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  -- Null znači bez ograničenja. Kod pretplatnika je 1.
  max_uses integer check (max_uses is null or max_uses > 0),
  used_count integer not null default 0 check (used_count >= 0),
  is_active boolean not null default true,
  subscriber_id uuid references public.newsletter_subscribers (id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint promo_codes_dates_check check (ends_at > starts_at),
  constraint promo_codes_subscriber_check check ((kind = 'newsletter') = (subscriber_id is not null))
);

create index promo_codes_kind_idx on public.promo_codes (kind, created_at desc);
create index promo_codes_subscriber_idx on public.promo_codes (subscriber_id) where subscriber_id is not null;

-- Narudžba čuva upisani kod i iznos popusta, i ako se kod kasnije obriše.
alter table public.inquiries
  add column promo_code_id uuid references public.promo_codes (id) on delete set null,
  add column promo_code text,
  add column promo_discount numeric(10, 2) not null default 0 check (promo_discount >= 0);

create index inquiries_promo_code_idx on public.inquiries (promo_code_id) where promo_code_id is not null;

create function public.promo_code_is_valid(p_code public.promo_codes)
returns boolean
language sql
stable
set search_path = ''
as $$
  select p_code.is_active
    and now() >= p_code.starts_at
    and now() < p_code.ends_at
    and (p_code.max_uses is null or p_code.used_count < p_code.max_uses);
$$;

-- Provjera koda u košarici. Vraća samo postotak, bez ostalih podataka o kodu.
create function public.shop_check_promo(p_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_promo public.promo_codes;
begin
  select * into v_promo from public.promo_codes where code = upper(btrim(coalesce(p_code, '')));
  if not found or not public.promo_code_is_valid(v_promo) then
    raise exception 'Promo kod nije valjan ili je istekao.';
  end if;
  return jsonb_build_object('code', v_promo.code, 'percent', v_promo.discount_percent);
end;
$$;

revoke all on function public.shop_check_promo(text) from public;
grant execute on function public.shop_check_promo(text) to anon, authenticated, service_role;

-- Prijava na newsletter. Zove je samo server (/api/newsletter), koji kod šalje e-mailom,
-- pa ga posjetitelj ne može dobiti bez pristupa upisanoj adresi.
create function public.newsletter_subscribe(p_email text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_subscriber_id uuid;
  v_code text;
  v_ends_at timestamptz := now() + interval '15 days';
begin
  if char_length(v_email) > 200 or v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'Upišite ispravnu e-mail adresu.';
  end if;

  -- Ista adresa ne dobiva novi kod.
  insert into public.newsletter_subscribers (email)
  values (v_email)
  on conflict (email) do nothing
  returning id into v_subscriber_id;

  if v_subscriber_id is null then
    return jsonb_build_object('is_new', false);
  end if;

  loop
    v_code := 'VIVA-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));
    exit when not exists (select 1 from public.promo_codes where code = v_code);
  end loop;

  insert into public.promo_codes (code, kind, discount_percent, ends_at, max_uses, subscriber_id)
  values (v_code, 'newsletter', 10, v_ends_at, 1, v_subscriber_id);

  return jsonb_build_object('is_new', true, 'code', v_code, 'percent', 10, 'expires_at', v_ends_at);
end;
$$;

revoke all on function public.newsletter_subscribe(text) from public, anon, authenticated;
grant execute on function public.newsletter_subscribe(text) to service_role;

-- Narudžba prima promo kod u p_customer.promo_code.
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
  v_shipping := case when v_subtotal > 150 then 0 else 9 end;

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

-- RLS: tim vidi pretplatnike i kodove. Admin i super admin brišu pretplatnike i uređuju kodove.
alter table public.newsletter_subscribers enable row level security;
alter table public.promo_codes enable row level security;

revoke all on public.newsletter_subscribers, public.promo_codes from public, anon, authenticated;
grant select, delete on public.newsletter_subscribers to authenticated;
grant select, insert, update, delete on public.promo_codes to authenticated;
grant all on public.newsletter_subscribers, public.promo_codes to service_role;

create policy newsletter_subscribers_select on public.newsletter_subscribers
for select to authenticated
using ((select public.current_user_role()) is not null);

create policy newsletter_subscribers_delete on public.newsletter_subscribers
for delete to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy promo_codes_select on public.promo_codes
for select to authenticated
using ((select public.current_user_role()) is not null);

-- Iz aplikacije se stvaraju samo vlastiti kodovi. Kodove pretplatnika stvara newsletter_subscribe.
create policy promo_codes_insert on public.promo_codes
for insert to authenticated
with check ((select public.current_user_role()) in ('super_admin', 'admin') and kind = 'manual');

create policy promo_codes_update on public.promo_codes
for update to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'))
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy promo_codes_delete on public.promo_codes
for delete to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin') and kind = 'manual');

commit;
