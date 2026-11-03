-- Proizvod je na webu samo ako mu je glavna kategorija uključena.
-- Tako se cijela sezona (npr. Čizme) skriva isključivanjem kategorije, a "Objavljeno" na proizvodima ostaje kako je bilo.
-- Isključena nadređena kategorija gasi sve ispod sebe (validate_category), pa je dovoljno provjeriti glavnu kategoriju.
-- Dodatna kategorija ne skriva proizvod, nego se samo ne prikazuje.
begin;

create function public.category_is_active(p_category_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select is_active from public.categories where id = p_category_id), false);
$$;

revoke all on function public.category_is_active(uuid) from public;
grant execute on function public.category_is_active(uuid) to anon, authenticated, service_role;

create or replace function public.shop_cards(
  p_category_ids uuid[] default null,
  p_colors text[] default null,
  p_sizes text[] default null,
  p_min_price numeric default null,
  p_max_price numeric default null,
  p_in_stock boolean default false,
  p_on_sale boolean default false,
  p_lengths text[] default null,
  p_heels text[] default null,
  p_sort text default 'new',
  p_limit integer default 24,
  p_offset integer default 0
)
returns jsonb
language sql
stable
set search_path = ''
as $$
  with filtered as (
    select
      c.id,
      c.slug,
      c.name as color_name,
      c.sort_order,
      c.product_id,
      p.name as product_name,
      p.category_id,
      coalesce(p.sale_price, p.price) as price,
      case when p.sale_price is not null then p.price end as compare_at_price,
      p.store_only,
      p.created_at
    from public.product_colors c
    join public.products p on p.id = c.product_id
    where p.is_visible and public.category_is_active(p.category_id)
      and (p_category_ids is null or exists (
        select 1 from public.product_categories pc
        where pc.product_id = p.id and pc.category_id = any (p_category_ids)
      ))
      and (p_colors is null or c.name = any (p_colors))
      -- Veličina se nalazi samo ako je ima na stanju, jer rasprodana kupcu ne koristi.
      and (p_sizes is null or exists (
        select 1 from public.product_sizes s
        where s.color_id = c.id and s.size = any (p_sizes) and s.quantity > 0
      ))
      and (p_min_price is null or coalesce(p.sale_price, p.price) >= p_min_price)
      and (p_max_price is null or coalesce(p.sale_price, p.price) <= p_max_price)
      and (not p_in_stock or exists (
        select 1 from public.product_sizes s where s.color_id = c.id and s.quantity > 0
      ))
      and (not p_on_sale or p.sale_price is not null)
      and (p_lengths is null or p.dress_length = any (p_lengths))
      and (p_heels is null or p.heel_height = any (p_heels))
  ),
  ranked as (
    select f.*, row_number() over (
      order by
        case when p_sort = 'price_asc' then f.price end asc nulls last,
        case when p_sort = 'price_desc' then f.price end desc nulls last,
        case when p_sort = 'name' then f.product_name end asc nulls last,
        f.created_at desc,
        f.product_id,
        f.sort_order
    ) as position
    from filtered f
  ),
  page as (
    select * from ranked
    order by position
    limit greatest(p_limit, 0)
    offset greatest(p_offset, 0)
  )
  select jsonb_build_object(
    'total', (select count(*) from filtered),
    'cards', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', page.id,
        'slug', page.slug,
        'productName', page.product_name,
        'colorName', page.color_name,
        'categoryName', (select cat.name from public.categories cat where cat.id = page.category_id),
        'price', page.price,
        'compareAtPrice', page.compare_at_price,
        'imagePath', image.path,
        'imageAlt', image.alt,
        'soldOut', not exists (select 1 from public.product_sizes s where s.color_id = page.id and s.quantity > 0),
        'storeOnly', page.store_only,
        'colors', (
          select jsonb_agg(jsonb_build_object('id', o.id, 'name', o.name, 'hex', o.hex) order by o.sort_order)
          from public.product_colors o
          where o.product_id = page.product_id
        )
      ) order by page.position)
      from page
      left join lateral (
        select i.path, i.alt from public.product_images i
        where i.color_id = page.id
        order by i.sort_order
        limit 1
      ) image on true
    ), '[]'::jsonb)
  );
$$;

create or replace function public.shop_filter_options(p_category_ids uuid[] default null)
returns jsonb
language sql
stable
set search_path = ''
as $$
  with products as (
    select p.id, coalesce(p.sale_price, p.price) as price, p.sale_price, p.dress_length, p.heel_height
    from public.products p
    where p.is_visible and public.category_is_active(p.category_id)
      and (p_category_ids is null or exists (
        select 1 from public.product_categories pc
        where pc.product_id = p.id and pc.category_id = any (p_category_ids)
      ))
  ),
  colors as (
    select c.id, c.name, c.hex
    from public.product_colors c
    join products p on p.id = c.product_id
  )
  select jsonb_build_object(
    'colors', coalesce((
      select jsonb_agg(item order by item ->> 'name')
      from (select distinct on (name) jsonb_build_object('name', name, 'hex', hex) as item from colors order by name) named
    ), '[]'::jsonb),
    'sizes', coalesce((
      select jsonb_agg(distinct s.size)
      from public.product_sizes s
      join colors c on c.id = s.color_id
      where s.quantity > 0
    ), '[]'::jsonb),
    'lengths', coalesce((select jsonb_agg(distinct dress_length) from products where dress_length is not null), '[]'::jsonb),
    'heels', coalesce((select jsonb_agg(distinct heel_height) from products where heel_height is not null), '[]'::jsonb),
    'hasSale', exists (select 1 from products where sale_price is not null),
    'minPrice', (select min(price) from products),
    'maxPrice', (select max(price) from products)
  );
$$;

-- Košarica uklanja i stavke iz isključenih kategorija, kao i skrivene proizvode.
create or replace function public.shop_cart(p_session uuid)
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
    and (not p.is_visible or p.store_only or not public.category_is_active(p.category_id));

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

create or replace function public.shop_cart_update(p_session uuid, p_size_id uuid, p_quantity integer, p_add boolean default false)
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
  where s.id = p_size_id and p.is_visible and not p.store_only and public.category_is_active(p.category_id);

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

-- Proizvodi iz isključene kategorije ostaju na listi želja i vrate se kad se kategorija uključi.
create or replace function public.shop_wishlist(p_session uuid)
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
    where w.session_id = p_session and p.is_visible and public.category_is_active(p.category_id)
  ), '[]'::jsonb);
end;
$$;

create or replace function public.shop_wishlist_set(p_session uuid, p_color_id uuid, p_on boolean)
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
      where c.id = p_color_id and p.is_visible and public.category_is_active(p.category_id)
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

  insert into public.inquiries (customer_name, phone, address, postal_code, city, email, note, session_id)
  values (v_name, v_phone, v_address, v_postal_code, v_city, v_email, v_note, p_session)
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

  v_shipping := case when v_subtotal > 150 then 0 else 9 end;

  update public.inquiries
  set subtotal = v_subtotal, shipping = v_shipping, total = v_subtotal + v_shipping
  where id = v_inquiry_id;

  delete from public.cart_items where session_id = p_session;
  perform public.shop_session_touch(p_session);

  return jsonb_build_object('number', v_number);
end;
$$;

commit;
