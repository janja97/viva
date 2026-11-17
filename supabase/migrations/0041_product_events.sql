-- Praćenje zanimanja za proizvode: pregled stranice proizvoda, dodavanje u košaricu i narudžba preko WhatsAppa.
-- Svaki događaj je jedan redak (po boji proizvoda), pa se može gledati po razdoblju i po kategoriji.
-- Kupci pišu samo kroz shop_track_event, koja odbacuje ponovljene klikove, preglede istog kupca u 30 minuta
-- i događaje prijavljenih članova tima, da ne kvare brojke. Čitaju samo članovi tima.
begin;

create table public.product_events (
  id bigint generated always as identity primary key,
  product_id uuid not null references public.products (id) on delete cascade,
  color_id uuid references public.product_colors (id) on delete set null,
  event text not null check (event in ('view', 'cart_add', 'whatsapp_order')),
  quantity integer not null default 1 check (quantity between 1 and 99),
  session_id uuid,
  created_at timestamptz not null default now()
);

create index product_events_created_idx on public.product_events (created_at desc);
create index product_events_product_idx on public.product_events (product_id, event);
create index product_events_session_idx on public.product_events (session_id, color_id, event, created_at desc);

alter table public.product_events enable row level security;

revoke all on public.product_events from public, anon, authenticated;
grant select, delete on public.product_events to authenticated;
grant all on public.product_events to service_role;

-- Cijeli tim (super_admin, admin, viewer) čita. Upis ide samo kroz shop_track_event.
create policy product_events_select on public.product_events
for select to authenticated
using ((select public.current_user_role()) is not null);

-- Brisati (npr. čišćenje testnih podataka) smije samo super_admin. Admin i viewer ne mogu.
create policy product_events_delete on public.product_events
for delete to authenticated
using ((select public.current_user_role()) = 'super_admin');

-- Upis događaja s weba. Vraća ništa i nikad ne javlja grešku kupcu (praćenje ne smije smetati kupnji).
create function public.shop_track_event(p_session uuid, p_color_id uuid, p_event text, p_quantity integer default 1)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_product_id uuid;
begin
  if p_event not in ('view', 'cart_add', 'whatsapp_order') or p_session is null then
    return;
  end if;

  -- Članovi tima (prijavljeni u admin) ne ulaze u statistiku.
  if public.current_user_role() is not null then
    return;
  end if;

  select c.product_id into v_product_id
  from public.product_colors c
  join public.products p on p.id = c.product_id
  where c.id = p_color_id and p.is_visible and p.archived_at is null;
  if v_product_id is null then
    return;
  end if;

  -- Isti kupac i ista boja: pregled se broji jednom u 30 minuta, a ostalo jednom u 10 sekundi (dvostruki klik).
  if exists (
    select 1 from public.product_events e
    where e.session_id = p_session and e.color_id = p_color_id and e.event = p_event
      and e.created_at > now() - case when p_event = 'view' then interval '30 minutes' else interval '10 seconds' end
  ) then
    return;
  end if;

  -- Zaštita od preplavljivanja: najviše 300 događaja po sesiji na sat.
  if (select count(*) from public.product_events e where e.session_id = p_session and e.created_at > now() - interval '1 hour') >= 300 then
    return;
  end if;

  insert into public.product_events (product_id, color_id, event, quantity, session_id)
  values (v_product_id, p_color_id, p_event, greatest(1, least(coalesce(p_quantity, 1), 99)), p_session);
end;
$$;

revoke all on function public.shop_track_event(uuid, uuid, text, integer) from public;
grant execute on function public.shop_track_event(uuid, uuid, text, integer) to anon, authenticated, service_role;

-- Pregled za nadzornu ploču: ukupno, po glavnoj kategoriji i po proizvodu (boji), od najgledanijeg.
-- p_category_ids ograničava proizvode na kategoriju (s podkategorijama), a null su svi.
create function public.admin_product_engagement(p_from timestamptz, p_to timestamptz, p_category_ids uuid[] default null, p_limit integer default 30)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if public.current_user_role() is null then
    raise exception 'Nemaš ovlasti za ovu radnju.' using errcode = '42501';
  end if;

  return (
    with events as (
      select e.*, p.name as product_name, p.sku, p.category_id,
        coalesce(g.id, pa.id, c.id) as main_category_id
      from public.product_events e
      join public.products p on p.id = e.product_id
      left join public.categories c on c.id = p.category_id
      left join public.categories pa on pa.id = c.parent_id
      left join public.categories g on g.id = pa.parent_id
      where (p_from is null or e.created_at >= p_from)
        and (p_to is null or e.created_at < p_to)
        and (p_category_ids is null or exists (
          select 1 from public.product_categories pc
          where pc.product_id = p.id and pc.category_id = any (p_category_ids)
        ))
    )
    select jsonb_build_object(
      'totals', jsonb_build_object(
        'views', count(*) filter (where event = 'view'),
        'cart_adds', count(*) filter (where event = 'cart_add'),
        'whatsapp_orders', count(*) filter (where event = 'whatsapp_order')
      ),
      'categories', coalesce((
        select jsonb_agg(row_to_json(x) order by x.views desc)
        from (
          select cat.name,
            count(*) filter (where ev.event = 'view') as views,
            count(*) filter (where ev.event = 'cart_add') as cart_adds,
            count(*) filter (where ev.event = 'whatsapp_order') as whatsapp_orders
          from events ev
          join public.categories cat on cat.id = ev.main_category_id
          group by cat.name
        ) x
      ), '[]'::jsonb),
      'products', coalesce((
        select jsonb_agg(row_to_json(x) order by x.views desc, x.cart_adds desc)
        from (
          select ev.product_id, ev.product_name || coalesce(' ' || col.name, '') as name, ev.sku, col.slug,
            count(*) filter (where ev.event = 'view') as views,
            count(*) filter (where ev.event = 'cart_add') as cart_adds,
            count(*) filter (where ev.event = 'whatsapp_order') as whatsapp_orders
          from events ev
          left join public.product_colors col on col.id = ev.color_id
          group by ev.product_id, ev.product_name, ev.sku, col.name, col.slug
          order by count(*) filter (where ev.event = 'view') desc, count(*) filter (where ev.event = 'cart_add') desc
          limit greatest(1, least(p_limit, 100))
        ) x
      ), '[]'::jsonb)
    )
    from events
  );
end;
$$;

revoke all on function public.admin_product_engagement(timestamptz, timestamptz, uuid[], integer) from public, anon;
grant execute on function public.admin_product_engagement(timestamptz, timestamptz, uuid[], integer) to authenticated, service_role;

-- Brojke uz svaki proizvod na popisu u adminu (ukupno, od početka praćenja).
create function public.admin_product_event_counts(p_ids uuid[])
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if public.current_user_role() is null then
    raise exception 'Nemaš ovlasti za ovu radnju.' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(row_to_json(x))
    from (
      select e.product_id,
        count(*) filter (where e.event = 'view') as views,
        count(*) filter (where e.event = 'cart_add') as cart_adds,
        count(*) filter (where e.event = 'whatsapp_order') as whatsapp_orders
      from public.product_events e
      where e.product_id = any (p_ids)
      group by e.product_id
    ) x
  ), '[]'::jsonb);
end;
$$;

revoke all on function public.admin_product_event_counts(uuid[]) from public, anon;
grant execute on function public.admin_product_event_counts(uuid[]) to authenticated, service_role;

commit;
