-- Čišćenje zaliha (/ciscenje-zaliha): akcijska stranica čiji se proizvodi prikazuju samo na njoj.
-- Stranica dobiva prekidač promo_pages.is_exclusive. Dok je takva stranica uključena i kampanja traje,
-- baza proizvodima te kampanje upisuje products.promo_only = true, pa ih nema u kolekciji, kategorijama,
-- filtrima, pretrazi, na naslovnoj ni u preporukama. Stranica proizvoda, košarica i lista želja rade kao i prije.
-- Kad kampanja završi, pauzira se ili se stranica isključi, proizvodi se sami vraćaju u trgovinu.
begin;

alter table public.promo_pages
  add column is_exclusive boolean not null default false;

-- Upisuje ga samo baza (okidač apply_campaign_discount), kao i discount_percent.
alter table public.products
  add column promo_only boolean not null default false;

create index products_promo_only_idx on public.products (promo_only) where promo_only;

-- Je li kampanja trenutno aktivna i na uključenoj stranici "samo ovdje".
create function public.campaign_is_exclusive(p_campaign_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(public.campaign_percent(p_campaign_id) is not null and exists (
    select 1
    from public.promo_page_campaigns pc
    join public.promo_pages pg on pg.id = pc.page_id
    where pc.campaign_id = p_campaign_id and pg.is_active and pg.is_exclusive
  ), false);
$$;

revoke all on function public.campaign_is_exclusive(uuid) from public;
grant execute on function public.campaign_is_exclusive(uuid) to authenticated, service_role;

-- Sniženje i "samo na akcijskoj stranici" uvijek prate kampanju. Ručno upisane vrijednosti se zanemaruju.
create or replace function public.apply_campaign_discount()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.discount_percent := public.campaign_percent(new.campaign_id);
  new.promo_only := public.campaign_is_exclusive(new.campaign_id);
  return new;
end;
$$;

-- Usklađuje cijene i promo_only sa stanjem kampanja i stranica. Mijenja samo proizvode kojima se nešto stvarno mijenja.
-- Vrijednosti upisuje okidač apply_campaign_discount. Poziva ga i pg_cron posao kampanje-cijene svake minute.
create or replace function public.refresh_campaign_prices()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_updated integer;
begin
  update public.products p
  set discount_percent = public.campaign_percent(p.campaign_id)
  where p.discount_percent is distinct from public.campaign_percent(p.campaign_id)
    or p.promo_only is distinct from public.campaign_is_exclusive(p.campaign_id);
  get diagnostics v_updated = row_count;
  return v_updated;
end;
$$;

revoke all on function public.refresh_campaign_prices() from public, anon, authenticated;

-- Promjena stranice ili njezinih kampanja odmah skriva ili vraća proizvode.
create trigger promo_page_changed
after insert or update or delete on public.promo_pages
for each statement execute function public.campaign_changed();

create trigger promo_page_campaigns_changed
after insert or delete on public.promo_page_campaigns
for each statement execute function public.campaign_changed();

insert into public.promo_pages (slug, title, intro, nav_label, meta_title, meta_description, off_text, is_exclusive, faq) values (
  'ciscenje-zaliha',
  'Čišćenje zaliha',
  'Odabrani modeli svečanih haljina, ženskih odijela, cipela i torbica po sniženim cijenama. Ovi modeli dostupni su samo na ovoj stranici.',
  'Čišćenje zaliha',
  'Čišćenje zaliha | Svečane haljine Mostar',
  'Čišćenje zaliha: sniženja svečanih i maturalnih haljina, ženskih odijela, cipela i torbica. Online s dostavom po BiH ili u Mepas Mallu u Mostaru.',
  'Čišćenje zaliha trenutno ne traje. Prijavite se na newsletter i prvi saznajte kad počinje.',
  true,
  jsonb_build_array(
    jsonb_build_object('question', 'Gdje mogu vidjeti modele s čišćenja zaliha?', 'answer', 'Samo na ovoj stranici. Tih modela nema u ostatku ponude na webu.'),
    jsonb_build_object('question', 'Kako se plaća online narudžba?', 'answer', 'Pouzećem, kuriru pri preuzimanju. Dostava traje 3 do 5 dana, samo unutar BiH.')
  )
);

-- Spremanje stranice sprema i prekidač "samo ovdje".
create or replace function public.save_promo_page(p_id uuid, p_page jsonb, p_campaign_ids uuid[])
returns void
language plpgsql
set search_path = ''
as $$
begin
  update public.promo_pages set
    title = p_page ->> 'title',
    intro = coalesce(p_page ->> 'intro', ''),
    nav_label = coalesce(p_page ->> 'nav_label', ''),
    meta_title = nullif(p_page ->> 'meta_title', ''),
    meta_description = nullif(p_page ->> 'meta_description', ''),
    off_text = coalesce(p_page ->> 'off_text', ''),
    faq = coalesce(p_page -> 'faq', '[]'::jsonb),
    is_active = coalesce((p_page ->> 'is_active')::boolean, false),
    is_exclusive = coalesce((p_page ->> 'is_exclusive')::boolean, false)
  where id = p_id;

  if not found then
    raise exception 'Akcijska stranica ne postoji ili je nemaš pravo mijenjati.';
  end if;

  delete from public.promo_page_campaigns where page_id = p_id;
  insert into public.promo_page_campaigns (page_id, campaign_id)
  select p_id, campaign_id from unnest(coalesce(p_campaign_ids, '{}')) as campaign_id;
end;
$$;

-- Javni podaci akcijske stranice, sada i s is_exclusive. Ostalo je isto kao u migraciji 0034.
create or replace function public.shop_promo_page(p_slug text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_page public.promo_pages;
  v_state text := 'off';
  v_starts_at timestamptz;
  v_ends_at timestamptz;
  v_groups jsonb := '[]'::jsonb;
begin
  select * into v_page from public.promo_pages where slug = p_slug;
  if not found then
    return null;
  end if;

  if v_page.is_active then
    -- Aktivne kampanje stranice. Trajna nema kraja, pa tada ni odbrojavanja.
    if exists (
      select 1 from public.promo_page_campaigns pc
      join public.campaigns c on c.id = pc.campaign_id
      where pc.page_id = v_page.id and not c.is_paused
        and (c.kind = 'permanent' or (now() >= c.starts_at and now() < c.ends_at))
    ) then
      v_state := 'live';
      select case when bool_or(c.kind = 'permanent') then null else max(c.ends_at) end into v_ends_at
      from public.promo_page_campaigns pc
      join public.campaigns c on c.id = pc.campaign_id
      where pc.page_id = v_page.id and not c.is_paused
        and (c.kind = 'permanent' or (now() >= c.starts_at and now() < c.ends_at));

      select coalesce(jsonb_agg(jsonb_build_object('discount_percent', g.percent, 'product_ids', g.ids) order by g.percent desc), '[]'::jsonb)
      into v_groups
      from (
        select c.discount_percent as percent,
          (select coalesce(jsonb_agg(x.id order by x.created_at desc), '[]'::jsonb) from (
            select p.id, p.created_at from public.products p
            join public.promo_page_campaigns pc2 on pc2.campaign_id = p.campaign_id and pc2.page_id = v_page.id
            join public.campaigns c2 on c2.id = p.campaign_id
            where c2.discount_percent = c.discount_percent and not c2.is_paused
              and (c2.kind = 'permanent' or (now() >= c2.starts_at and now() < c2.ends_at))
              and p.is_visible and public.category_is_active(p.category_id)
            order by p.created_at desc
            limit 96
          ) x) as ids
        from public.promo_page_campaigns pc
        join public.campaigns c on c.id = pc.campaign_id
        where pc.page_id = v_page.id and not c.is_paused
          and (c.kind = 'permanent' or (now() >= c.starts_at and now() < c.ends_at))
        group by c.discount_percent
      ) g
      where jsonb_array_length(g.ids) > 0;
    else
      select min(c.starts_at) into v_starts_at
      from public.promo_page_campaigns pc
      join public.campaigns c on c.id = pc.campaign_id
      where pc.page_id = v_page.id and not c.is_paused and c.kind = 'temporary' and c.starts_at > now();
      if v_starts_at is not null then
        v_state := 'upcoming';
      end if;
    end if;
  end if;

  return jsonb_build_object(
    'slug', v_page.slug,
    'title', v_page.title,
    'intro', v_page.intro,
    'nav_label', v_page.nav_label,
    'meta_title', v_page.meta_title,
    'meta_description', v_page.meta_description,
    'off_text', v_page.off_text,
    'faq', v_page.faq,
    'is_exclusive', v_page.is_exclusive,
    'state', v_state,
    'starts_at', v_starts_at,
    'ends_at', v_ends_at,
    -- Postoci s proizvodima, od najvećeg: [{ "discount_percent": 50, "product_ids": [...] }, ...]
    'groups', v_groups
  );
end;
$$;

-- Popisi trgovine preskaču proizvode koji su samo na akcijskoj stranici. Ostalo je isto kao u migraciji 0021.
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
    where p.is_visible and not p.promo_only and public.category_is_active(p.category_id)
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

commit;
