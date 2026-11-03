-- Košarica, lista želja i upiti kupaca. Kupci se ne prijavljuju: preglednik stvori nasumičan id sesije
-- i čuva ga kod sebe, a tko ga ne zna, ne može vidjeti ni mijenjati tuđu košaricu.
-- Kupci tablicama ne pristupaju izravno, nego samo kroz funkcije shop_*, koje provjeravaju dostupnost i količine.
-- Sesija i sve njezine stavke brišu se nakon 7 dana bez izmjene. Upit ostaje trajno, s kopijom podataka o proizvodu.
begin;

create table public.shop_sessions (
  id uuid primary key,
  created_at timestamptz not null default now(),
  last_active_at timestamptz not null default now()
);

create index shop_sessions_active_idx on public.shop_sessions (last_active_at);

create table public.cart_items (
  session_id uuid not null references public.shop_sessions (id) on delete cascade,
  size_id uuid not null references public.product_sizes (id) on delete cascade,
  quantity integer not null check (quantity between 1 and 20),
  added_at timestamptz not null default now(),
  primary key (session_id, size_id)
);

create index cart_items_size_idx on public.cart_items (size_id);

create table public.wishlist_items (
  session_id uuid not null references public.shop_sessions (id) on delete cascade,
  color_id uuid not null references public.product_colors (id) on delete cascade,
  added_at timestamptz not null default now(),
  primary key (session_id, color_id)
);

create index wishlist_items_color_idx on public.wishlist_items (color_id);

create table public.inquiries (
  id uuid primary key default gen_random_uuid(),
  number bigint generated always as identity unique,
  status text not null default 'new' check (status in ('new', 'in_progress', 'completed', 'cancelled')),
  customer_name text not null check (char_length(btrim(customer_name)) between 2 and 100),
  phone text not null check (char_length(btrim(phone)) between 6 and 30),
  email text check (email is null or char_length(email) <= 200),
  note text check (note is null or char_length(note) <= 2000),
  total numeric(10, 2) not null default 0,
  -- Bez stranog ključa, jer se sesija briše nakon 7 dana, a upit ostaje.
  session_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index inquiries_created_idx on public.inquiries (created_at desc);
create index inquiries_status_idx on public.inquiries (status, created_at desc);
create index inquiries_session_idx on public.inquiries (session_id, created_at desc);

-- Kopija podataka u trenutku upita, kako bi statistika ostala točna i kad se proizvod promijeni ili obriše.
create table public.inquiry_items (
  id uuid primary key default gen_random_uuid(),
  inquiry_id uuid not null references public.inquiries (id) on delete cascade,
  product_id uuid references public.products (id) on delete set null,
  color_id uuid references public.product_colors (id) on delete set null,
  size_id uuid references public.product_sizes (id) on delete set null,
  sku text not null,
  product_name text not null,
  color_name text not null,
  size text not null,
  unit_price numeric(10, 2) not null,
  regular_price numeric(10, 2) not null,
  quantity integer not null check (quantity >= 1)
);

create index inquiry_items_inquiry_idx on public.inquiry_items (inquiry_id);
create index inquiry_items_product_idx on public.inquiry_items (product_id);

-- touch_product samo postavlja updated_at, pa vrijedi i ovdje.
create trigger touch_inquiry
before update on public.inquiries
for each row execute function public.touch_product();

-- POMOĆNE FUNKCIJE (nisu dostupne izvana)

-- Istekla sesija se briše pri prvom sljedećem pristupu, čak i ako dnevno čišćenje ne radi.
create function public.shop_session_expire(p_session uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.shop_sessions
  where id = p_session and last_active_at < now() - interval '7 days';
$$;

create function public.shop_session_touch(p_session uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.shop_sessions (id) values (p_session)
  on conflict (id) do update set last_active_at = now();
$$;

create function public.cleanup_shop_sessions()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_deleted integer;
begin
  delete from public.shop_sessions where last_active_at < now() - interval '7 days';
  get diagnostics v_deleted = row_count;
  return v_deleted;
end;
$$;

-- KOŠARICA

-- Stavke koje se više ne mogu kupiti (skrivene, arhivirane, samo u trgovini) uklanjaju se same.
create function public.shop_cart(p_session uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.shop_session_expire(p_session);

  delete from public.cart_items ci
  using public.product_sizes s, public.product_colors c, public.products p
  where ci.session_id = p_session
    and s.id = ci.size_id and c.id = s.color_id and p.id = c.product_id
    and (not p.is_visible or p.store_only);

  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'sizeId', s.id,
      'size', s.size,
      'quantity', ci.quantity,
      'stock', s.quantity,
      'colorId', c.id,
      'colorName', c.name,
      'hex', c.hex,
      'slug', c.slug,
      'productName', p.name,
      'sku', p.sku,
      'price', coalesce(p.sale_price, p.price),
      'compareAtPrice', case when p.sale_price is not null then p.price end,
      'imagePath', image.path,
      'imageAlt', image.alt
    ) order by ci.added_at)
    from public.cart_items ci
    join public.product_sizes s on s.id = ci.size_id
    join public.product_colors c on c.id = s.color_id
    join public.products p on p.id = c.product_id
    left join lateral (
      select i.path, i.alt from public.product_images i
      where i.color_id = c.id
      order by i.sort_order
      limit 1
    ) image on true
    where ci.session_id = p_session
  ), '[]'::jsonb);
end;
$$;

-- Dodaje (p_add) ili postavlja količinu. Količina 0 uklanja stavku. Vraća cijelu košaricu.
create function public.shop_cart_update(p_session uuid, p_size_id uuid, p_quantity integer, p_add boolean default false)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_stock integer;
  v_current integer;
  v_quantity integer;
begin
  perform public.shop_session_expire(p_session);

  select ci.quantity into v_current
  from public.cart_items ci
  where ci.session_id = p_session and ci.size_id = p_size_id;

  v_quantity := case when p_add then coalesce(v_current, 0) + p_quantity else p_quantity end;

  if v_quantity <= 0 then
    delete from public.cart_items where session_id = p_session and size_id = p_size_id;
    perform public.shop_session_touch(p_session);
    return public.shop_cart(p_session);
  end if;

  select s.quantity into v_stock
  from public.product_sizes s
  join public.product_colors c on c.id = s.color_id
  join public.products p on p.id = c.product_id
  where s.id = p_size_id and p.is_visible and not p.store_only;

  if not found then
    raise exception 'Ovaj proizvod trenutno nije moguće naručiti online.';
  end if;
  if v_stock = 0 then
    raise exception 'Ova veličina je rasprodana.';
  end if;
  if v_current is null and (select count(*) from public.cart_items where session_id = p_session) >= 30 then
    raise exception 'Košarica može imati najviše 30 različitih proizvoda.';
  end if;

  perform public.shop_session_touch(p_session);

  insert into public.cart_items (session_id, size_id, quantity)
  values (p_session, p_size_id, least(v_quantity, v_stock, 20))
  on conflict (session_id, size_id) do update set quantity = excluded.quantity;

  return public.shop_cart(p_session);
end;
$$;

-- LISTA ŽELJA

-- Skriveni proizvodi se ne prikazuju, ali ostaju na listi ako se vrate na web.
create function public.shop_wishlist(p_session uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.shop_session_expire(p_session);

  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', c.id,
      'slug', c.slug,
      'productName', p.name,
      'colorName', c.name,
      'categoryName', (select cat.name from public.categories cat where cat.id = p.category_id),
      'price', coalesce(p.sale_price, p.price),
      'compareAtPrice', case when p.sale_price is not null then p.price end,
      'imagePath', image.path,
      'imageAlt', image.alt,
      'soldOut', not exists (select 1 from public.product_sizes s where s.color_id = c.id and s.quantity > 0),
      'storeOnly', p.store_only,
      'colors', (
        select jsonb_agg(jsonb_build_object('id', o.id, 'name', o.name, 'hex', o.hex) order by o.sort_order)
        from public.product_colors o
        where o.product_id = p.id
      )
    ) order by w.added_at desc)
    from public.wishlist_items w
    join public.product_colors c on c.id = w.color_id
    join public.products p on p.id = c.product_id
    left join lateral (
      select i.path, i.alt from public.product_images i
      where i.color_id = c.id
      order by i.sort_order
      limit 1
    ) image on true
    where w.session_id = p_session and p.is_visible
  ), '[]'::jsonb);
end;
$$;

create function public.shop_wishlist_set(p_session uuid, p_color_id uuid, p_on boolean)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.shop_session_expire(p_session);

  if not p_on then
    delete from public.wishlist_items where session_id = p_session and color_id = p_color_id;
    perform public.shop_session_touch(p_session);
  else
    if not exists (
      select 1 from public.product_colors c
      join public.products p on p.id = c.product_id
      where c.id = p_color_id and p.is_visible
    ) then
      raise exception 'Ovaj proizvod više nije dostupan.';
    end if;
    if (select count(*) from public.wishlist_items where session_id = p_session) >= 100 then
      raise exception 'Lista želja može imati najviše 100 proizvoda.';
    end if;
    perform public.shop_session_touch(p_session);
    insert into public.wishlist_items (session_id, color_id)
    values (p_session, p_color_id)
    on conflict do nothing;
  end if;

  return public.shop_wishlist(p_session);
end;
$$;

-- UPIT

-- Provjerava košaricu, sprema upit s kopijom stavki i prazni košaricu. Količine na stanju se ne mijenjaju,
-- jer upit nije kupnja: trgovina ga potvrđuje i sama ažurira stanje.
create function public.shop_submit_inquiry(p_session uuid, p_customer jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text := btrim(coalesce(p_customer ->> 'name', ''));
  v_phone text := btrim(coalesce(p_customer ->> 'phone', ''));
  v_email text := nullif(btrim(coalesce(p_customer ->> 'email', '')), '');
  v_note text := nullif(btrim(coalesce(p_customer ->> 'note', '')), '');
  v_item record;
  v_inquiry_id uuid;
  v_number bigint;
begin
  perform public.shop_session_expire(p_session);

  if char_length(v_name) not between 2 and 100 then
    raise exception 'Upišite ime i prezime.';
  end if;
  if v_phone !~ '^[0-9 +()/-]{6,30}$' then
    raise exception 'Upišite ispravan broj telefona.';
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
    raise exception 'Upit je upravo poslan. Pričekajte minutu prije novog.';
  end if;

  if not exists (select 1 from public.cart_items where session_id = p_session) then
    raise exception 'Košarica je prazna.';
  end if;

  for v_item in
    select ci.quantity, s.size, s.quantity as stock, c.name as color_name, p.name, p.is_visible, p.store_only
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

  insert into public.inquiries (customer_name, phone, email, note, session_id)
  values (v_name, v_phone, v_email, v_note, p_session)
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

  update public.inquiries
  set total = (select sum(unit_price * quantity) from public.inquiry_items where inquiry_id = v_inquiry_id)
  where id = v_inquiry_id;

  delete from public.cart_items where session_id = p_session;
  perform public.shop_session_touch(p_session);

  return jsonb_build_object('number', v_number);
end;
$$;

-- PRAVA NA FUNKCIJE
revoke all on function public.shop_session_expire(uuid) from public, anon, authenticated;
revoke all on function public.shop_session_touch(uuid) from public, anon, authenticated;
revoke all on function public.cleanup_shop_sessions() from public, anon, authenticated;
revoke all on function public.shop_cart(uuid) from public;
revoke all on function public.shop_cart_update(uuid, uuid, integer, boolean) from public;
revoke all on function public.shop_wishlist(uuid) from public;
revoke all on function public.shop_wishlist_set(uuid, uuid, boolean) from public;
revoke all on function public.shop_submit_inquiry(uuid, jsonb) from public;
grant execute on function public.shop_cart(uuid) to anon, authenticated, service_role;
grant execute on function public.shop_cart_update(uuid, uuid, integer, boolean) to anon, authenticated, service_role;
grant execute on function public.shop_wishlist(uuid) to anon, authenticated, service_role;
grant execute on function public.shop_wishlist_set(uuid, uuid, boolean) to anon, authenticated, service_role;
grant execute on function public.shop_submit_inquiry(uuid, jsonb) to anon, authenticated, service_role;
grant execute on function public.cleanup_shop_sessions() to service_role;

-- RLS
alter table public.shop_sessions enable row level security;
alter table public.cart_items enable row level security;
alter table public.wishlist_items enable row level security;
alter table public.inquiries enable row level security;
alter table public.inquiry_items enable row level security;

revoke all on public.shop_sessions, public.cart_items, public.wishlist_items, public.inquiries, public.inquiry_items
  from public, anon, authenticated;
grant select on public.shop_sessions, public.cart_items, public.wishlist_items, public.inquiries, public.inquiry_items
  to authenticated;
-- Iz aplikacije se mijenja samo status, a podaci kupca i stavke ostaju kakve je kupac poslao.
grant update (status) on public.inquiries to authenticated;
grant delete on public.inquiries to authenticated;
grant all on public.shop_sessions, public.cart_items, public.wishlist_items, public.inquiries, public.inquiry_items
  to service_role;

-- Sesije, košarice i liste želja: tim ih smije samo čitati (npr. za statistiku). Pišu ih samo funkcije shop_*.
create policy shop_sessions_select on public.shop_sessions
for select to authenticated
using ((select public.current_user_role()) is not null);

create policy cart_items_select on public.cart_items
for select to authenticated
using ((select public.current_user_role()) is not null);

create policy wishlist_items_select on public.wishlist_items
for select to authenticated
using ((select public.current_user_role()) is not null);

-- Upiti: svi članovi tima čitaju, super admin i admin mijenjaju status i brišu. Upisuje ih samo shop_submit_inquiry.
create policy inquiries_select on public.inquiries
for select to authenticated
using ((select public.current_user_role()) is not null);

create policy inquiries_update on public.inquiries
for update to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'))
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy inquiries_delete on public.inquiries
for delete to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy inquiry_items_select on public.inquiry_items
for select to authenticated
using ((select public.current_user_role()) is not null);

commit;

-- DNEVNO ČIŠĆENJE (izvan transakcije, kako greška ovdje ne bi poništila tablice iznad)
-- Svaki dan u 3:00 (UTC) briše sesije bez izmjene dulje od 7 dana, zajedno s košaricom i listom želja.
create extension if not exists pg_cron with schema pg_catalog;

select cron.schedule('ciscenje-kosarica', '0 3 * * *', 'select public.cleanup_shop_sessions()');
