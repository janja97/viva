-- Posjete webu: odakle kupci dolaze (Google, Instagram, Facebook, kampanja), iz koje države i grada, s kojeg uređaja
-- i na koju stranicu prvo dođu. Jedan redak je jedan dolazak (sesija preglednika), a ne svaka otvorena stranica.
-- Upisuje server ruta /api/visit (zna državu i grad iz Netlifyjevih zaglavlja) kroz shop_track_visit.
-- IP adresa se ne sprema. Čita samo super admin (statistika), briše samo super admin.
-- Retci stariji od 2 godine brišu se sami (pg_cron posao "brisanje-posjeta"), kako piše u Politici privatnosti.
begin;

create table public.site_visits (
  id bigint generated always as identity primary key,
  session_id uuid not null,
  created_at timestamptz not null default now(),
  landing_path text not null check (char_length(landing_path) <= 300),
  referrer_host text check (char_length(referrer_host) <= 200),
  -- Izvor (google, instagram, facebook, whatsapp, newsletter, izravno ili domena) i vrsta (organic, social, paid, email, referral, direct).
  source text not null check (char_length(source) <= 100),
  medium text not null check (medium in ('organic', 'social', 'paid', 'email', 'referral', 'direct')),
  utm_source text check (char_length(utm_source) <= 100),
  utm_medium text check (char_length(utm_medium) <= 100),
  utm_campaign text check (char_length(utm_campaign) <= 150),
  country text check (char_length(country) <= 2),
  region text check (char_length(region) <= 100),
  city text check (char_length(city) <= 100),
  device text not null check (device in ('mobile', 'tablet', 'desktop')),
  is_team boolean not null default false
);

create index site_visits_created_idx on public.site_visits (created_at desc);
create index site_visits_session_idx on public.site_visits (session_id, created_at desc);

alter table public.site_visits enable row level security;

revoke all on public.site_visits from public, anon, authenticated;
grant select, delete on public.site_visits to authenticated;
grant all on public.site_visits to service_role;

-- Samo super admin čita i briše (kao i ostalu analitiku). Admin i viewer nemaju pristup.
create policy site_visits_select on public.site_visits
for select to authenticated
using ((select public.current_user_role()) = 'super_admin');

create policy site_visits_delete on public.site_visits
for delete to authenticated
using ((select public.current_user_role()) = 'super_admin');

-- Upis dolaska. Isti preglednik unutar 30 minuta je isti dolazak. Nikad ne javlja grešku (ne smije smetati kupcu).
create function public.shop_track_visit(
  p_session uuid,
  p_landing_path text,
  p_referrer_host text,
  p_source text,
  p_medium text,
  p_utm_source text,
  p_utm_medium text,
  p_utm_campaign text,
  p_country text,
  p_region text,
  p_city text,
  p_device text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_session is null or p_landing_path is null or p_source is null then
    return;
  end if;

  if exists (
    select 1 from public.site_visits v
    where v.session_id = p_session and v.created_at > now() - interval '30 minutes'
  ) then
    return;
  end if;

  -- Zaštita od preplavljivanja: najviše 20 dolazaka po pregledniku na dan.
  if (select count(*) from public.site_visits v where v.session_id = p_session and v.created_at > now() - interval '1 day') >= 20 then
    return;
  end if;

  insert into public.site_visits (
    session_id, landing_path, referrer_host, source, medium, utm_source, utm_medium, utm_campaign,
    country, region, city, device, is_team
  )
  values (
    p_session,
    left(p_landing_path, 300),
    nullif(left(p_referrer_host, 200), ''),
    left(p_source, 100),
    case when p_medium in ('organic', 'social', 'paid', 'email', 'referral', 'direct') then p_medium else 'referral' end,
    nullif(left(p_utm_source, 100), ''),
    nullif(left(p_utm_medium, 100), ''),
    nullif(left(p_utm_campaign, 150), ''),
    nullif(upper(left(p_country, 2)), ''),
    nullif(left(p_region, 100), ''),
    nullif(left(p_city, 100), ''),
    case when p_device in ('mobile', 'tablet', 'desktop') then p_device else 'desktop' end,
    public.current_user_role() is not null
  );
end;
$$;

revoke all on function public.shop_track_visit(uuid, text, text, text, text, text, text, text, text, text, text, text) from public;
grant execute on function public.shop_track_visit(uuid, text, text, text, text, text, text, text, text, text, text, text) to anon, authenticated, service_role;

-- Pregled posjeta za nadzornu ploču (samo super admin). Članovi tima nisu u brojkama, nego se samo navode.
create function public.admin_visit_analytics(p_from timestamptz, p_to timestamptz, p_bucket text default 'day')
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_zone constant text := 'Europe/Sarajevo';
  v_to timestamptz := coalesce(p_to, now());
  v_from timestamptz;
  v_bucket text := case when p_bucket in ('day', 'week', 'month') then p_bucket else 'day' end;
begin
  if public.current_user_role() is distinct from 'super_admin' then
    raise exception 'Nemaš ovlasti za ovu radnju.' using errcode = '42501';
  end if;

  v_from := coalesce(p_from, (select min(created_at) from public.site_visits), v_to - interval '30 days');

  return (
    with visits as (
      select * from public.site_visits
      where created_at >= v_from and created_at < v_to and not is_team
    ),
    buckets as (
      select generate_series(
        date_trunc(v_bucket, v_from at time zone v_zone),
        date_trunc(v_bucket, (v_to - interval '1 second') at time zone v_zone),
        ('1 ' || v_bucket)::interval
      ) as bucket
    )
    select jsonb_build_object(
      'from', v_from,
      'to', v_to,
      'bucket', v_bucket,
      'totals', jsonb_build_object(
        'visits', (select count(*) from visits),
        'visitors', (select count(distinct session_id) from visits),
        'mobile', (select count(*) from visits where device = 'mobile'),
        'team', (select count(*) from public.site_visits where created_at >= v_from and created_at < v_to and is_team)
      ),
      'series', coalesce((
        select jsonb_agg(jsonb_build_object('bucket', b.bucket, 'visits', coalesce(x.visits, 0)) order by b.bucket)
        from buckets b
        left join (
          select date_trunc(v_bucket, created_at at time zone v_zone) as bucket, count(*) as visits
          from visits group by 1
        ) x on x.bucket = b.bucket
      ), '[]'::jsonb),
      'sources', coalesce((select jsonb_agg(row_to_json(x)) from (
        select source as name, medium, count(*) as visits from visits group by source, medium order by count(*) desc limit 20
      ) x), '[]'::jsonb),
      'mediums', coalesce((select jsonb_agg(row_to_json(x)) from (
        select medium as name, count(*) as visits from visits group by medium order by count(*) desc
      ) x), '[]'::jsonb),
      'countries', coalesce((select jsonb_agg(row_to_json(x)) from (
        select coalesce(country, '') as name, count(*) as visits from visits group by country order by count(*) desc limit 20
      ) x), '[]'::jsonb),
      'cities', coalesce((select jsonb_agg(row_to_json(x)) from (
        select city as name, country, count(*) as visits from visits where city is not null
        group by city, country order by count(*) desc limit 30
      ) x), '[]'::jsonb),
      'devices', coalesce((select jsonb_agg(row_to_json(x)) from (
        select device as name, count(*) as visits from visits group by device order by count(*) desc
      ) x), '[]'::jsonb),
      'landings', coalesce((select jsonb_agg(row_to_json(x)) from (
        select landing_path as name, count(*) as visits from visits group by landing_path order by count(*) desc limit 20
      ) x), '[]'::jsonb),
      'campaigns', coalesce((select jsonb_agg(row_to_json(x)) from (
        select utm_campaign as name, coalesce(utm_source, source) as source, count(*) as visits from visits
        where utm_campaign is not null group by utm_campaign, coalesce(utm_source, source) order by count(*) desc limit 20
      ) x), '[]'::jsonb)
    )
  );
end;
$$;

revoke all on function public.admin_visit_analytics(timestamptz, timestamptz, text) from public, anon;
grant execute on function public.admin_visit_analytics(timestamptz, timestamptz, text) to authenticated, service_role;

-- Brisanje posjeta i pregleda proizvoda (product_events) starijih od 2 godine, svaku noć.
create function public.cleanup_site_visits()
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.site_visits where created_at < now() - interval '2 years';
  delete from public.product_events where created_at < now() - interval '2 years';
$$;

revoke all on function public.cleanup_site_visits() from public, anon, authenticated;

select cron.schedule('brisanje-posjeta', '30 3 * * *', 'select public.cleanup_site_visits()');

commit;
