-- Proizvod (šifra) > boja (svoje slike i URL) > veličina (svoja količina).
begin;

create table public.products (
  id uuid primary key default gen_random_uuid(),
  sku text not null unique check (char_length(btrim(sku)) between 1 and 50),
  name text not null check (char_length(btrim(name)) between 1 and 150),
  category_id uuid not null references public.categories (id) on delete restrict,
  description text,
  material text,
  care text,
  size_guide text,
  size_type text not null default 'clothing' check (size_type in ('footwear', 'clothing', 'universal')),
  price numeric(10, 2) not null check (price >= 0),
  weight_grams integer check (weight_grams is null or weight_grams >= 0),
  is_visible boolean not null default false,
  store_only boolean not null default false,
  meta_title text,
  meta_description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index products_category_idx on public.products (category_id);
create index products_created_idx on public.products (created_at desc);

create table public.product_colors (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 50),
  hex text not null check (hex ~ '^#[0-9a-fA-F]{6}$'),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  sort_order integer not null default 0,
  unique (product_id, name)
);

create index product_colors_product_idx on public.product_colors (product_id, sort_order);

create table public.product_sizes (
  id uuid primary key default gen_random_uuid(),
  color_id uuid not null references public.product_colors (id) on delete cascade,
  size text not null check (char_length(btrim(size)) between 1 and 20),
  quantity integer not null default 0 check (quantity >= 0),
  sort_order integer not null default 0,
  unique (color_id, size)
);

create table public.product_images (
  id uuid primary key default gen_random_uuid(),
  color_id uuid not null references public.product_colors (id) on delete cascade,
  path text not null,
  alt text not null,
  sort_order integer not null default 0
);

create index product_images_color_idx on public.product_images (color_id, sort_order);

-- Povijest cijena, za prikaz najniže cijene iz zadnjih 30 dana kod sniženja.
create table public.product_price_history (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  price numeric(10, 2) not null,
  valid_from timestamptz not null default now()
);

create index product_price_history_idx on public.product_price_history (product_id, valid_from desc);

create function public.touch_product()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger touch_product
before update on public.products
for each row execute function public.touch_product();

create function public.record_product_price()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' or new.price <> old.price then
    insert into public.product_price_history (product_id, price)
    values (new.id, new.price);
  end if;
  return null;
end;
$$;

create trigger record_product_price
after insert or update of price on public.products
for each row execute function public.record_product_price();

-- Sprema proizvod s bojama, veličinama i slikama u jednoj transakciji.
-- Radi s pravima pozivatelja, pa za svaku tablicu vrijede njezina RLS pravila.
create function public.save_product(payload jsonb)
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
    price, weight_grams, is_visible, store_only, meta_title, meta_description
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

revoke all on function public.touch_product() from public, anon, authenticated;
revoke all on function public.record_product_price() from public, anon, authenticated;
revoke all on function public.save_product(jsonb) from public, anon;
grant execute on function public.save_product(jsonb) to authenticated, service_role;

alter table public.products enable row level security;
alter table public.product_colors enable row level security;
alter table public.product_sizes enable row level security;
alter table public.product_images enable row level security;
alter table public.product_price_history enable row level security;

revoke all on public.products, public.product_colors, public.product_sizes, public.product_images, public.product_price_history
  from public, anon, authenticated;
grant select on public.products, public.product_colors, public.product_sizes, public.product_images, public.product_price_history
  to anon, authenticated;
grant insert, update, delete on public.products, public.product_colors, public.product_sizes, public.product_images
  to authenticated;
grant all on public.products, public.product_colors, public.product_sizes, public.product_images, public.product_price_history
  to service_role;

-- PROIZVODI
-- Čitanje: posjetitelji i kupci vide vidljive, a članovi tima sve.
create policy products_select_public on public.products
for select to anon
using (is_visible);

create policy products_select_authenticated on public.products
for select to authenticated
using (is_visible or (select public.current_user_role()) is not null);

create policy products_insert on public.products
for insert to authenticated
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy products_update on public.products
for update to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'))
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy products_delete on public.products
for delete to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'));

-- BOJE
-- Podaci se vide samo ako je vidljiv i proizvod kojem pripadaju (RLS proizvoda vrijedi i ovdje).
create policy product_colors_select on public.product_colors
for select to anon, authenticated
using (exists (select 1 from public.products p where p.id = product_id));

create policy product_colors_insert on public.product_colors
for insert to authenticated
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy product_colors_update on public.product_colors
for update to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'))
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy product_colors_delete on public.product_colors
for delete to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'));

-- VELIČINE
create policy product_sizes_select on public.product_sizes
for select to anon, authenticated
using (exists (select 1 from public.product_colors c where c.id = color_id));

create policy product_sizes_insert on public.product_sizes
for insert to authenticated
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy product_sizes_update on public.product_sizes
for update to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'))
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy product_sizes_delete on public.product_sizes
for delete to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'));

-- SLIKE
create policy product_images_select on public.product_images
for select to anon, authenticated
using (exists (select 1 from public.product_colors c where c.id = color_id));

create policy product_images_insert on public.product_images
for insert to authenticated
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy product_images_update on public.product_images
for update to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'))
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy product_images_delete on public.product_images
for delete to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'));

-- POVIJEST CIJENA: samo čitanje, a upisuje je okidač.
create policy product_price_history_select on public.product_price_history
for select to anon, authenticated
using (exists (select 1 from public.products p where p.id = product_id));

-- SPREMIŠTE SLIKA: javno čitanje, a pisanje samo za super admina i admina.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-images',
  'product-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/avif']
);

create policy product_images_storage_select on storage.objects
for select to authenticated
using (
  bucket_id = 'product-images'
  and (select public.current_user_role()) in ('super_admin', 'admin')
);

create policy product_images_storage_insert on storage.objects
for insert to authenticated
with check (
  bucket_id = 'product-images'
  and (select public.current_user_role()) in ('super_admin', 'admin')
);

create policy product_images_storage_delete on storage.objects
for delete to authenticated
using (
  bucket_id = 'product-images'
  and (select public.current_user_role()) in ('super_admin', 'admin')
);

commit;
