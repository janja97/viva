-- Snižena cijena, duljina haljine i visina pete, zajedno s filtrima za njih.
begin;

alter table public.products
  add column sale_price numeric(10, 2),
  add column dress_length text,
  add column heel_height text,
  add constraint products_sale_price_check check (sale_price is null or (sale_price >= 0 and sale_price < price)),
  add constraint products_dress_length_check check (dress_length is null or dress_length in ('mini', 'knee', 'midi', 'maxi')),
  add constraint products_heel_height_check check (heel_height is null or heel_height in ('flat', 'low', 'medium', 'high'));

create index products_sale_idx on public.products (sale_price) where sale_price is not null;

-- Povijest pamti cijenu koju je kupac stvarno plaćao, za najnižu cijenu iz zadnjih 30 dana.
create or replace function public.record_product_price()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' or coalesce(new.sale_price, new.price) <> coalesce(old.sale_price, old.price) then
    insert into public.product_price_history (product_id, price)
    values (new.id, coalesce(new.sale_price, new.price));
  end if;
  return null;
end;
$$;

drop trigger record_product_price on public.products;

create trigger record_product_price
after insert or update of price, sale_price on public.products
for each row execute function public.record_product_price();

create or replace function public.save_product(payload jsonb)
returns uuid
language plpgsql
set search_path = ''
as $$
declare
  v_product_id uuid := (payload ->> 'id')::uuid;
  color jsonb;
  v_color_id uuid;
begin
  if jsonb_array_length(coalesce(payload -> 'colors', '[]'::jsonb)) = 0 then
    raise exception 'Proizvod mora imati barem jednu boju.';
  end if;

  insert into public.products (
    id, sku, name, category_id, description, material, care, size_guide, size_type,
    price, sale_price, dress_length, heel_height,
    weight_grams, is_visible, store_only, meta_title, meta_description
  )
  values (
    v_product_id,
    btrim(payload ->> 'sku'),
    btrim(payload ->> 'name'),
    (payload ->> 'category_id')::uuid,
    payload ->> 'description',
    payload ->> 'material',
    payload ->> 'care',
    payload ->> 'size_guide',
    payload ->> 'size_type',
    (payload ->> 'price')::numeric,
    (payload ->> 'sale_price')::numeric,
    payload ->> 'dress_length',
    payload ->> 'heel_height',
    (payload ->> 'weight_grams')::integer,
    (payload ->> 'is_visible')::boolean,
    (payload ->> 'store_only')::boolean,
    payload ->> 'meta_title',
    payload ->> 'meta_description'
  )
  on conflict (id) do update set
    sku = excluded.sku,
    name = excluded.name,
    category_id = excluded.category_id,
    description = excluded.description,
    material = excluded.material,
    care = excluded.care,
    size_guide = excluded.size_guide,
    size_type = excluded.size_type,
    price = excluded.price,
    sale_price = excluded.sale_price,
    dress_length = excluded.dress_length,
    heel_height = excluded.heel_height,
    weight_grams = excluded.weight_grams,
    is_visible = excluded.is_visible,
    store_only = excluded.store_only,
    meta_title = excluded.meta_title,
    meta_description = excluded.meta_description;

  delete from public.product_colors pc
  where pc.product_id = v_product_id
    and pc.id not in (
      select (item ->> 'id')::uuid from jsonb_array_elements(payload -> 'colors') item
    );

  for color in select * from jsonb_array_elements(payload -> 'colors') loop
    v_color_id := (color ->> 'id')::uuid;

    insert into public.product_colors (id, product_id, name, hex, slug, sort_order)
    values (
      v_color_id,
      v_product_id,
      btrim(color ->> 'name'),
      color ->> 'hex',
      color ->> 'slug',
      (color ->> 'sort_order')::integer
    )
    on conflict (id) do update set
      name = excluded.name,
      hex = excluded.hex,
      slug = excluded.slug,
      sort_order = excluded.sort_order;

    delete from public.product_sizes ps
    where ps.color_id = v_color_id
      and ps.size not in (
        select item ->> 'size' from jsonb_array_elements(color -> 'sizes') item
      );

    insert into public.product_sizes (color_id, size, quantity, sort_order)
    select
      v_color_id,
      item ->> 'size',
      (item ->> 'quantity')::integer,
      (item ->> 'sort_order')::integer
    from jsonb_array_elements(color -> 'sizes') item
    on conflict on constraint product_sizes_color_id_size_key do update set
      quantity = excluded.quantity,
      sort_order = excluded.sort_order;

    delete from public.product_images pi
    where pi.color_id = v_color_id
      and pi.id not in (
        select (item ->> 'id')::uuid from jsonb_array_elements(color -> 'images') item
      );

    insert into public.product_images (id, color_id, path, alt, sort_order)
    select
      (item ->> 'id')::uuid,
      v_color_id,
      item ->> 'path',
      item ->> 'alt',
      (item ->> 'sort_order')::integer
    from jsonb_array_elements(color -> 'images') item
    on conflict (id) do update set
      alt = excluded.alt,
      sort_order = excluded.sort_order;
  end loop;

  return v_product_id;
end;
$$;

-- Promjena parametara traži brisanje i ponovno stvaranje funkcije.
drop function public.shop_cards(uuid[], text[], text[], numeric, numeric, boolean, text, integer, integer);

create function public.shop_cards(
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
    where p.is_visible
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

-- Vrijednosti koje se stvarno mogu odabrati na tom popisu.
create or replace function public.shop_filter_options(p_category_ids uuid[] default null)
returns jsonb
language sql
stable
set search_path = ''
as $$
  with products as (
    select p.id, coalesce(p.sale_price, p.price) as price, p.sale_price, p.dress_length, p.heel_height
    from public.products p
    where p.is_visible
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

revoke all on function public.shop_cards(uuid[], text[], text[], numeric, numeric, boolean, boolean, text[], text[], text, integer, integer) from public;
grant execute on function public.shop_cards(uuid[], text[], text[], numeric, numeric, boolean, boolean, text[], text[], text, integer, integer) to anon, authenticated, service_role;

commit;
