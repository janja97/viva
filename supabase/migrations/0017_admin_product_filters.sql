-- Filtri, sortiranje i skupne radnje na admin popisu proizvoda.
-- Funkcije rade s pravima pozivatelja, pa vrijede RLS pravila tablica, a provjera uloge daje jasnu poruku.
begin;

-- Vraća samo id-eve proizvoda za traženu stranicu, redom, i ukupan broj. Ostale podatke aplikacija dohvaća sama.
-- Količina se zbraja samo za odabrane boje i veličine, pa se može tražiti npr. "crna 38 je rasprodana".
create function public.admin_products(
  p_filters jsonb default '{}'::jsonb,
  p_sort text default 'new',
  p_limit integer default 25,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
set search_path = ''
as $$
declare
  v_archived boolean := coalesce((p_filters ->> 'archived')::boolean, false);
  v_search text := lower(nullif(btrim(p_filters ->> 'search'), ''));
  v_category_ids uuid[] := array(select value::uuid from jsonb_array_elements_text(p_filters -> 'category_ids'));
  v_size_types text[] := array(select jsonb_array_elements_text(p_filters -> 'size_types'));
  v_brand text := nullif(p_filters ->> 'brand', '');
  v_no_brand boolean := coalesce((p_filters ->> 'no_brand')::boolean, false);
  v_colors text[] := array(select jsonb_array_elements_text(p_filters -> 'colors'));
  v_sizes text[] := array(select jsonb_array_elements_text(p_filters -> 'sizes'));
  v_min_price numeric := (p_filters ->> 'min_price')::numeric;
  v_max_price numeric := (p_filters ->> 'max_price')::numeric;
  v_min_qty integer := (p_filters ->> 'min_qty')::integer;
  v_max_qty integer := (p_filters ->> 'max_qty')::integer;
  v_visible boolean := (p_filters ->> 'visible')::boolean;
  v_store_only boolean := (p_filters ->> 'store_only')::boolean;
  v_on_sale boolean := (p_filters ->> 'on_sale')::boolean;
  v_missing_images boolean := coalesce((p_filters ->> 'missing_images')::boolean, false);
  v_result jsonb;
begin
  if public.current_user_role() is null then
    raise exception 'Nemaš ovlasti za ovu radnju.' using errcode = '42501';
  end if;

  with base as (
    select
      p.id,
      p.name,
      p.created_at,
      p.archived_at,
      coalesce(p.sale_price, p.price) as price,
      (
        select coalesce(sum(s.quantity), 0)
        from public.product_sizes s
        join public.product_colors c on c.id = s.color_id
        where c.product_id = p.id
          and (cardinality(v_colors) = 0 or c.name = any (v_colors))
          and (cardinality(v_sizes) = 0 or s.size = any (v_sizes))
      ) as quantity
    from public.products p
    left join public.product_internal pi on pi.product_id = p.id
    where (p.archived_at is not null) = v_archived
      and (v_search is null
        or strpos(lower(p.sku), v_search) > 0
        or strpos(lower(p.name), v_search) > 0
        or strpos(lower(coalesce(pi.brand, '')), v_search) > 0)
      and (cardinality(v_category_ids) = 0 or exists (
        select 1 from public.product_categories pc
        where pc.product_id = p.id and pc.category_id = any (v_category_ids)
      ))
      and (cardinality(v_size_types) = 0 or p.size_type = any (v_size_types))
      and (v_brand is null or pi.brand = v_brand)
      and (not v_no_brand or pi.brand is null)
      and (v_min_price is null or coalesce(p.sale_price, p.price) >= v_min_price)
      and (v_max_price is null or coalesce(p.sale_price, p.price) <= v_max_price)
      and (v_visible is null or p.is_visible = v_visible)
      and (v_store_only is null or p.store_only = v_store_only)
      and (v_on_sale is null or (p.sale_price is not null) = v_on_sale)
      and (cardinality(v_colors) = 0 or exists (
        select 1 from public.product_colors c
        where c.product_id = p.id and c.name = any (v_colors)
      ))
      and (cardinality(v_sizes) = 0 or exists (
        select 1 from public.product_sizes s
        join public.product_colors c on c.id = s.color_id
        where c.product_id = p.id
          and s.size = any (v_sizes)
          and (cardinality(v_colors) = 0 or c.name = any (v_colors))
      ))
      and (not v_missing_images or exists (
        select 1 from public.product_colors c
        where c.product_id = p.id
          and not exists (select 1 from public.product_images i where i.color_id = c.id)
      ))
  ),
  filtered as (
    select * from base
    where (v_min_qty is null or quantity >= v_min_qty)
      and (v_max_qty is null or quantity <= v_max_qty)
  ),
  page as (
    select id, row_number() over (
      order by
        case when p_sort = 'price_asc' then price end asc nulls last,
        case when p_sort = 'price_desc' then price end desc nulls last,
        case when p_sort = 'qty_asc' then quantity end asc nulls last,
        case when p_sort = 'qty_desc' then quantity end desc nulls last,
        case when p_sort = 'name' then name end asc nulls last,
        case when p_sort = 'old' then created_at end asc nulls last,
        case when p_sort = 'archived' then archived_at end desc nulls last,
        created_at desc,
        id
    ) as position
    from filtered
    order by position
    limit greatest(p_limit, 0)
    offset greatest(p_offset, 0)
  )
  select jsonb_build_object(
    'total', (select count(*) from filtered),
    'ids', coalesce((select jsonb_agg(id order by position) from page), '[]'::jsonb)
  )
  into v_result;

  return v_result;
end;
$$;

-- Ponuđene vrijednosti filtara. Ovise o arhivi, kategoriji i vrsti proizvoda,
-- pa se kod obuće nude samo brojevi obuće, a kod odjeće samo veličine odjeće.
create function public.admin_product_filter_options(p_filters jsonb default '{}'::jsonb)
returns jsonb
language plpgsql
stable
set search_path = ''
as $$
declare
  v_archived boolean := coalesce((p_filters ->> 'archived')::boolean, false);
  v_category_ids uuid[] := array(select value::uuid from jsonb_array_elements_text(p_filters -> 'category_ids'));
  v_size_types text[] := array(select jsonb_array_elements_text(p_filters -> 'size_types'));
  v_result jsonb;
begin
  if public.current_user_role() is null then
    raise exception 'Nemaš ovlasti za ovu radnju.' using errcode = '42501';
  end if;

  with products as (
    select p.id, p.size_type, coalesce(p.sale_price, p.price) as price
    from public.products p
    where (p.archived_at is not null) = v_archived
      and (cardinality(v_category_ids) = 0 or exists (
        select 1 from public.product_categories pc
        where pc.product_id = p.id and pc.category_id = any (v_category_ids)
      ))
      and (cardinality(v_size_types) = 0 or p.size_type = any (v_size_types))
  ),
  colors as (
    select c.id, c.name, c.hex
    from public.product_colors c
    join products p on p.id = c.product_id
  )
  select jsonb_build_object(
    'brands', coalesce((
      select jsonb_agg(distinct pi.brand)
      from public.product_internal pi
      join products p on p.id = pi.product_id
      where pi.brand is not null
    ), '[]'::jsonb),
    'colors', coalesce((
      select jsonb_agg(item order by item ->> 'name')
      from (select distinct on (name) jsonb_build_object('name', name, 'hex', hex) as item from colors order by name) named
    ), '[]'::jsonb),
    'sizes', coalesce((
      select jsonb_agg(distinct s.size)
      from public.product_sizes s
      join colors c on c.id = s.color_id
    ), '[]'::jsonb),
    'sizeTypes', coalesce((select jsonb_agg(distinct size_type) from products), '[]'::jsonb),
    'minPrice', (select min(price) from products),
    'maxPrice', (select max(price) from products)
  )
  into v_result;

  return v_result;
end;
$$;

-- Skupna izmjena: objava ili skrivanje, "samo u trgovini" i sniženje. Šalje se jedna izmjena po pozivu.
-- Na web idu samo aktivni proizvodi kojima svaka boja ima barem jednu sliku, a ostali se preskaču.
create function public.bulk_update_products(p_ids uuid[], p_changes jsonb)
returns jsonb
language plpgsql
set search_path = ''
as $$
declare
  v_updated integer := 0;
  v_skipped integer := 0;
  v_discount integer;
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

  elsif p_changes ? 'discount_percent' then
    v_discount := (p_changes ->> 'discount_percent')::integer;
    if v_discount is not null and v_discount not between 1 and 99 then
      raise exception 'Sniženje mora biti cijeli broj od 1 do 99.';
    end if;

    update public.products
    set discount_percent = v_discount
    where id = any (p_ids) and discount_percent is distinct from v_discount;
    get diagnostics v_updated = row_count;

  else
    raise exception 'Nepoznata izmjena.';
  end if;

  return jsonb_build_object('updated', v_updated, 'skipped', v_skipped);
end;
$$;

-- Skupno arhiviranje. Vraća putanje obrisanih slika, kao i archive_product.
create function public.archive_products(p_ids uuid[])
returns text[]
language plpgsql
set search_path = ''
as $$
declare
  v_id uuid;
  v_paths text[] := '{}';
begin
  for v_id in
    select id from public.products where id = any (p_ids) and archived_at is null
  loop
    v_paths := v_paths || public.archive_product(v_id);
  end loop;
  return v_paths;
end;
$$;

revoke all on function public.admin_products(jsonb, text, integer, integer) from public, anon;
revoke all on function public.admin_product_filter_options(jsonb) from public, anon;
revoke all on function public.bulk_update_products(uuid[], jsonb) from public, anon;
revoke all on function public.archive_products(uuid[]) from public, anon;
grant execute on function public.admin_products(jsonb, text, integer, integer) to authenticated, service_role;
grant execute on function public.admin_product_filter_options(jsonb) to authenticated, service_role;
grant execute on function public.bulk_update_products(uuid[], jsonb) to authenticated, service_role;
grant execute on function public.archive_products(uuid[]) to authenticated, service_role;

commit;
