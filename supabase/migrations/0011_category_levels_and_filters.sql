-- Tri razine kategorija i filtri na javnim popisima proizvoda.
begin;

-- Čuva najviše tri razine, sprječava kružne veze i ne dopušta aktivnu kategoriju pod neaktivnom.
create or replace function public.validate_category()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_parent_depth integer;
  v_height integer;
  v_parent_active boolean;
  v_is_cycle boolean;
begin
  if new.parent_id is not null then
    with recursive below as (
      select id, 1 as depth from public.categories where parent_id = new.id
      union all
      select c.id, b.depth + 1 from public.categories c join below b on c.parent_id = b.id where b.depth < 10
    )
    select coalesce(max(depth), 0), coalesce(bool_or(id = new.parent_id), false)
    into v_height, v_is_cycle
    from below;

    if v_is_cycle then
      raise exception 'Kategorija ne može biti unutar vlastite podkategorije.';
    end if;

    with recursive above as (
      select id, parent_id, 1 as depth from public.categories where id = new.parent_id
      union all
      select c.id, c.parent_id, a.depth + 1 from public.categories c join above a on c.id = a.parent_id where a.depth < 10
    )
    select max(depth) into v_parent_depth from above;

    if v_parent_depth + 1 + v_height > 3 then
      raise exception 'Kategorije mogu imati najviše tri razine.';
    end if;

    select is_active into v_parent_active from public.categories where id = new.parent_id;
    if v_parent_active = false then
      new.is_active := false;
    end if;
  end if;

  new.updated_at := now();
  return new;
end;
$$;

-- Jedna kartica po boji. Security invoker, pa RLS vrijedi kao i kod običnog čitanja.
create function public.shop_cards(
  p_category_ids uuid[] default null,
  p_colors text[] default null,
  p_sizes text[] default null,
  p_min_price numeric default null,
  p_max_price numeric default null,
  p_in_stock boolean default false,
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
      p.price,
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
      and (p_min_price is null or p.price >= p_min_price)
      and (p_max_price is null or p.price <= p_max_price)
      and (not p_in_stock or exists (
        select 1 from public.product_sizes s where s.color_id = c.id and s.quantity > 0
      ))
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
create function public.shop_filter_options(p_category_ids uuid[] default null)
returns jsonb
language sql
stable
set search_path = ''
as $$
  with products as (
    select p.id, p.price
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
    'minPrice', (select min(price) from products),
    'maxPrice', (select max(price) from products)
  );
$$;

revoke all on function public.shop_cards(uuid[], text[], text[], numeric, numeric, boolean, text, integer, integer) from public;
revoke all on function public.shop_filter_options(uuid[]) from public;
grant execute on function public.shop_cards(uuid[], text[], text[], numeric, numeric, boolean, text, integer, integer) to anon, authenticated, service_role;
grant execute on function public.shop_filter_options(uuid[]) to anon, authenticated, service_role;

commit;
