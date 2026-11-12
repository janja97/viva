-- Akcijska stranica s više popusta: umjesto jedne kampanje (promo_pages.campaign_id) stranica ima popis
-- kampanja, npr. -20 %, -30 % i -50 %. Na webu je svaki postotak zaseban odjeljak s proizvodima.
-- Stanje: 'live' dok je barem jedna kampanja aktivna (odbrojava do kraja zadnje), 'upcoming' dok nijedna
-- ne traje, a neka privremena tek počinje (odbrojava do prve), inače 'off'.
begin;

create table public.promo_page_campaigns (
  page_id uuid not null references public.promo_pages (id) on delete cascade,
  campaign_id uuid not null references public.campaigns (id) on delete cascade,
  primary key (page_id, campaign_id)
);

create index promo_page_campaigns_campaign_idx on public.promo_page_campaigns (campaign_id);

-- Dosad odabrana kampanja prelazi u popis.
insert into public.promo_page_campaigns (page_id, campaign_id)
select id, campaign_id from public.promo_pages where campaign_id is not null;

alter table public.promo_pages drop column campaign_id;

alter table public.promo_page_campaigns enable row level security;

revoke all on public.promo_page_campaigns from public, anon, authenticated;
grant select, insert, delete on public.promo_page_campaigns to authenticated;
grant all on public.promo_page_campaigns to service_role;

-- Cijeli tim (super_admin, admin, viewer) čita. Kupci (anon) nemaju izravan pristup, nego kroz shop_promo_page.
create policy promo_page_campaigns_select on public.promo_page_campaigns
for select to authenticated
using ((select public.current_user_role()) is not null);

-- Dodaju i uklanjaju samo super_admin i admin. Viewer samo čita. Izmjene retka nema (samo dodavanje i brisanje).
create policy promo_page_campaigns_insert on public.promo_page_campaigns
for insert to authenticated
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy promo_page_campaigns_delete on public.promo_page_campaigns
for delete to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'));

-- Spremanje stranice i njezinih kampanja u jednoj transakciji. Radi s pravima prijavljenog korisnika,
-- pa RLS i dalje dopušta samo adminu i super adminu.
create function public.save_promo_page(p_id uuid, p_page jsonb, p_campaign_ids uuid[])
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
    is_active = coalesce((p_page ->> 'is_active')::boolean, false)
  where id = p_id;

  if not found then
    raise exception 'Akcijska stranica ne postoji ili je nemaš pravo mijenjati.';
  end if;

  delete from public.promo_page_campaigns where page_id = p_id;
  insert into public.promo_page_campaigns (page_id, campaign_id)
  select p_id, campaign_id from unnest(coalesce(p_campaign_ids, '{}')) as campaign_id;
end;
$$;

revoke all on function public.save_promo_page(uuid, jsonb, uuid[]) from public, anon;
grant execute on function public.save_promo_page(uuid, jsonb, uuid[]) to authenticated, service_role;

-- Javni podaci akcijske stranice. Proizvodi se vraćaju samo dok je akcija u tijeku, po postotku
-- (od najvećeg), i to samo vidljivi proizvodi iz aktivnih kategorija. Nazivi kampanja se ne otkrivaju.
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
    'state', v_state,
    'starts_at', v_starts_at,
    'ends_at', v_ends_at,
    -- Postoci s proizvodima, od najvećeg: [{ "discount_percent": 50, "product_ids": [...] }, ...]
    'groups', v_groups
  );
end;
$$;

revoke all on function public.shop_promo_page(text) from public;
grant execute on function public.shop_promo_page(text) to anon, authenticated, service_role;

commit;
