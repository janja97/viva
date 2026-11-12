-- Akcijske stranice (/admin/akcijske-stranice), prva je /black-friday.
-- Stranica ima stalnu adresu i ne briše se nakon akcije, kako bi je Google iz godine u godinu jačao.
-- Proizvode, datume i postotak daje odabrana kampanja (migracija 0024).
-- Stanje: 'live' dok je kampanja aktivna, 'upcoming' prije početka privremene kampanje, inače 'off'.
-- Kupci tablicu ne čitaju izravno, nego kroz shop_promo_page, koja ne otkriva podatke drugih kampanja.
begin;

create table public.promo_pages (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  -- U tekstovima se može upisati {godina}: godina početka kampanje, a bez nje tekuća godina.
  title text not null check (char_length(btrim(title)) between 2 and 80),
  intro text not null default '' check (char_length(intro) <= 1000),
  -- Naziv stavke "Popust" u izborniku dok je akcija u tijeku.
  nav_label text not null default '' check (char_length(nav_label) <= 30),
  meta_title text check (meta_title is null or char_length(meta_title) between 1 and 70),
  meta_description text check (meta_description is null or char_length(meta_description) between 1 and 170),
  -- Tekst izvan akcije, npr. "Black Friday se vraća u studenom".
  off_text text not null default '' check (char_length(off_text) <= 500),
  faq jsonb not null default '[]'::jsonb check (jsonb_typeof(faq) = 'array' and jsonb_array_length(faq) <= 12),
  campaign_id uuid references public.campaigns (id) on delete set null,
  is_active boolean not null default false,
  updated_at timestamptz not null default now()
);

insert into public.promo_pages (slug, title, intro, nav_label, meta_title, meta_description, off_text, faq) values (
  'black-friday',
  'Black Friday {godina}',
  'Black Friday sniženja na svečane i maturalne haljine, ženska odijela, cipele na petu i torbice. Akcija vrijedi samo do isteka odbrojavanja.',
  'Black Friday',
  'Black Friday {godina} | Svečane haljine Mostar',
  'Black Friday {godina} sniženja na svečane i maturalne haljine, ženska odijela, cipele i torbice. Online s dostavom po BiH ili u Mepas Mallu u Mostaru.',
  'Black Friday se vraća u studenom. Prijavite se na newsletter i prvi saznajte kad akcija počinje.',
  jsonb_build_array(
    jsonb_build_object('question', 'Koliko traje Black Friday?', 'answer', 'Akcija traje do isteka odbrojavanja na ovoj stranici.'),
    jsonb_build_object('question', 'Kako se plaća online narudžba?', 'answer', 'Pouzećem, kuriru pri preuzimanju. Dostava traje 3 do 5 dana, samo unutar BiH.'),
    jsonb_build_object('question', 'Mogu li zamijeniti proizvod kupljen na Black Friday?', 'answer', 'Da, u roku od 15 dana, ako proizvod nema tragova nošenja.')
  )
);

create function public.touch_promo_page()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger touch_promo_page
before update on public.promo_pages
for each row execute function public.touch_promo_page();

alter table public.promo_pages enable row level security;

revoke all on public.promo_pages from public, anon, authenticated;
grant select, insert, update, delete on public.promo_pages to authenticated;
grant all on public.promo_pages to service_role;

-- Cijeli tim (super_admin, admin, viewer) čita. Kupci (anon) nemaju izravan pristup, nego kroz shop_promo_page.
create policy promo_pages_select on public.promo_pages
for select to authenticated
using ((select public.current_user_role()) is not null);

-- Dodaju, mijenjaju i brišu samo super_admin i admin. Viewer samo čita.
create policy promo_pages_insert on public.promo_pages
for insert to authenticated
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy promo_pages_update on public.promo_pages
for update to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'))
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy promo_pages_delete on public.promo_pages
for delete to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'));

-- Javni podaci akcijske stranice. Proizvodi se vraćaju samo dok je akcija u tijeku,
-- i to samo vidljivi proizvodi iz aktivnih kategorija.
create function public.shop_promo_page(p_slug text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_page public.promo_pages;
  v_campaign public.campaigns;
  v_state text := 'off';
  v_product_ids uuid[] := '{}';
begin
  select * into v_page from public.promo_pages where slug = p_slug;
  if not found then
    return null;
  end if;

  if v_page.is_active and v_page.campaign_id is not null then
    select * into v_campaign from public.campaigns where id = v_page.campaign_id and not is_paused;
    if found then
      if v_campaign.kind = 'permanent' or (now() >= v_campaign.starts_at and now() < v_campaign.ends_at) then
        v_state := 'live';
      elsif now() < v_campaign.starts_at then
        v_state := 'upcoming';
      end if;
    end if;
  end if;

  if v_state = 'live' then
    select coalesce(array_agg(p.id order by p.created_at desc), '{}') into v_product_ids
    from (
      select id, created_at from public.products
      where campaign_id = v_campaign.id and is_visible and public.category_is_active(category_id)
      order by created_at desc
      limit 96
    ) p;
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
    'starts_at', case when v_state <> 'off' then v_campaign.starts_at end,
    'ends_at', case when v_state <> 'off' then v_campaign.ends_at end,
    'discount_percent', case when v_state <> 'off' then v_campaign.discount_percent end,
    'product_ids', to_jsonb(v_product_ids)
  );
end;
$$;

revoke all on function public.shop_promo_page(text) from public;
grant execute on function public.shop_promo_page(text) to anon, authenticated, service_role;

commit;
