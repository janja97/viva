-- Ista boja više puta na jednom proizvodu, npr. crne cipele od kože i crne od pliša (ista šifra).
-- Boja dobiva neobaveznu oznaku (label, npr. "koža", "pliš"). U product_colors.name ostaje naziv koji kupac vidi
-- ("Crna koža"), pa košarica, lista želja, narudžbe i statistika rade bez izmjena, a postojeće pravilo
-- unique (product_id, name) traži da iste boje imaju različite oznake. Osnovna boja s popisa ("Crna") je u
-- base_color i služi za filtar boja na webu.
begin;

alter table public.product_colors
  add column base_color text check (base_color is null or char_length(btrim(base_color)) between 1 and 50),
  add column label text not null default '' check (char_length(label) <= 30);

update public.product_colors set base_color = name;

-- Spremanje proizvoda: save_product upisuje naziv za kupce (name), a ovdje se dodaju osnovna boja i oznaka.
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

  update public.product_colors pc
  set base_color = coalesce(nullif(btrim(item ->> 'base_color'), ''), pc.name),
      label = coalesce(btrim(item ->> 'label'), '')
  from jsonb_array_elements(payload -> 'colors') item
  where pc.id = (item ->> 'id')::uuid and pc.product_id = v_product_id;

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

-- Filtar boja na webu ide po osnovnoj boji, pa "Crna" nalazi i "Crna pliš". Ostalo je isto kao u migraciji 0038.
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
    where p.is_visible and not p.promo_only and public.category_is_active(p.category_id)
      and (p_category_ids is null or exists (
        select 1 from public.product_categories pc
        where pc.product_id = p.id and pc.category_id = any (p_category_ids)
      ))
      and (p_colors is null or coalesce(c.base_color, c.name) = any (p_colors))
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
    where p.is_visible and not p.promo_only and public.category_is_active(p.category_id)
      and (p_category_ids is null or exists (
        select 1 from public.product_categories pc
        where pc.product_id = p.id and pc.category_id = any (p_category_ids)
      ))
  ),
  colors as (
    select c.id, coalesce(c.base_color, c.name) as name, c.hex
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

commit;
