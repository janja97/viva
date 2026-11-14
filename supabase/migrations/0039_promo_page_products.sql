-- Čišćenje zaliha: proizvodi se na stranicu dodaju pojedinačno (products.promo_page_id), a ne preko kampanje.
-- Kampanja i dalje daje samo sniženje. Proizvod dodan na uključenu stranicu "samo ovdje" (promo_pages.is_exclusive)
-- prikazuje se samo na njoj (products.promo_only), a ostali proizvodi iste kampanje ostaju u trgovini.
-- Takva stranica je u tijeku čim je uključena, bez obzira na kampanje. Zamjenjuje pravilo iz migracije 0038.
begin;

alter table public.products
  add column promo_page_id uuid references public.promo_pages (id) on delete set null;

create index products_promo_page_idx on public.products (promo_page_id) where promo_page_id is not null;

-- Skriva li stranica svoje proizvode iz ostatka trgovine: samo dok je uključena i "samo ovdje".
create function public.promo_page_hides_products(p_page_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select is_active and is_exclusive from public.promo_pages where id = p_page_id), false);
$$;

revoke all on function public.promo_page_hides_products(uuid) from public;
grant execute on function public.promo_page_hides_products(uuid) to authenticated, service_role;

-- Sniženje prati kampanju, a "samo na akcijskoj stranici" stranicu na koju je proizvod dodan. Ručni upis se zanemaruje.
create or replace function public.apply_campaign_discount()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.discount_percent := public.campaign_percent(new.campaign_id);
  new.promo_only := public.promo_page_hides_products(new.promo_page_id);
  return new;
end;
$$;

-- Usklađuje cijene i promo_only. Vrijednosti upisuje okidač apply_campaign_discount.
-- Poziva ga pg_cron posao kampanje-cijene svake minute te promjena kampanje ili akcijske stranice.
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
    or p.promo_only is distinct from public.promo_page_hides_products(p.promo_page_id);
  get diagnostics v_updated = row_count;
  return v_updated;
end;
$$;

revoke all on function public.refresh_campaign_prices() from public, anon, authenticated;

-- Pravilo iz migracije 0038 (svi proizvodi kampanje) više ne vrijedi.
drop trigger promo_page_campaigns_changed on public.promo_page_campaigns;
drop function public.campaign_is_exclusive(uuid);

-- Dodaje proizvode na stranicu "samo ovdje" ili ih s nje miče. Vraća broj promijenjenih.
-- Radi s pravima prijavljenog korisnika, pa i RLS dopušta samo adminu i super adminu.
create function public.set_promo_page_products(p_slug text, p_ids uuid[], p_on boolean)
returns integer
language plpgsql
set search_path = ''
as $$
declare
  v_page_id uuid;
  v_updated integer;
begin
  if coalesce(public.current_user_role()::text, '') not in ('super_admin', 'admin') then
    raise exception 'Nemaš ovlasti za ovu radnju.' using errcode = '42501';
  end if;

  select id into v_page_id from public.promo_pages where slug = p_slug and is_exclusive;
  if not found then
    raise exception 'Akcijska stranica ne postoji.';
  end if;

  if p_on then
    update public.products
    set promo_page_id = v_page_id
    where id = any (p_ids) and archived_at is null and promo_page_id is distinct from v_page_id;
  else
    update public.products
    set promo_page_id = null
    where id = any (p_ids) and promo_page_id = v_page_id;
  end if;
  get diagnostics v_updated = row_count;
  return v_updated;
end;
$$;

revoke all on function public.set_promo_page_products(text, uuid[], boolean) from public, anon;
grant execute on function public.set_promo_page_products(text, uuid[], boolean) to authenticated, service_role;

-- Javni podaci akcijske stranice. Stranica "samo ovdje" prikazuje pojedinačno dodane proizvode čim je uključena,
-- po trenutnom postotku sniženja (0 = bez sniženja). Ostale stranice rade kao u migraciji 0034.
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

  if v_page.is_active and v_page.is_exclusive then
    v_state := 'live';
    select coalesce(jsonb_agg(jsonb_build_object('discount_percent', g.percent, 'product_ids', g.ids) order by g.percent desc), '[]'::jsonb)
    into v_groups
    from (
      select coalesce(p.discount_percent, 0) as percent,
        to_jsonb((array_agg(p.id order by p.created_at desc))[1:96]) as ids
      from public.products p
      where p.promo_page_id = v_page.id and p.is_visible and public.category_is_active(p.category_id)
      group by coalesce(p.discount_percent, 0)
    ) g;
  elsif v_page.is_active then
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

-- Proizvodi skriveni po starom pravilu (kampanja) odmah se vraćaju u trgovinu.
select public.refresh_campaign_prices();

commit;
