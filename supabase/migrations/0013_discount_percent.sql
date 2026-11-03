-- Sniženje se upisuje u postotku, a baza sama računa cijenu kupca.
-- sale_price ostaje stupac, pa filtri, sortiranje i povijest cijena rade kao i prije.
begin;

drop trigger record_product_price on public.products;

alter table public.products
  add column discount_percent integer,
  add constraint products_discount_percent_check check (discount_percent is null or discount_percent between 1 and 99);

-- Postojeća snižena cijena pretvara se u najbliži postotak.
update public.products
set discount_percent = greatest(1, least(99, round((1 - sale_price / price) * 100)))::integer
where sale_price is not null and price > 0;

alter table public.products
  drop constraint products_sale_price_check,
  drop column sale_price;

alter table public.products
  add column sale_price numeric(10, 2)
  generated always as (round(price * (100 - discount_percent) / 100, 2)) stored;

create index products_sale_idx on public.products (sale_price) where sale_price is not null;

create trigger record_product_price
after insert or update of price, discount_percent on public.products
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
    price, discount_percent, dress_length, heel_height,
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
    (payload ->> 'discount_percent')::integer,
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
    discount_percent = excluded.discount_percent,
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

commit;
