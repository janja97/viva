-- Praćenje (migracija 0041) sada broji svako otvaranje proizvoda, i kad je kupac prijavljen kao član tima.
-- Dok je web na stranici "Uskoro", proizvode vide samo prijavljeni članovi tima, pa se inače ništa ne bi brojalo.
-- Isti pregled istog preglednika unutar 10 sekundi (osvježavanje, dvostruki klik) i dalje se broji jednom.
-- Članovi tima su označeni (is_team), pa ih se kasnije može izostaviti iz statistike.
begin;

alter table public.product_events
  add column is_team boolean not null default false;

create or replace function public.shop_track_event(p_session uuid, p_color_id uuid, p_event text, p_quantity integer default 1)
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

  select c.product_id into v_product_id
  from public.product_colors c
  join public.products p on p.id = c.product_id
  where c.id = p_color_id and p.archived_at is null;
  if v_product_id is null then
    return;
  end if;

  -- Isti preglednik, ista boja i isti događaj unutar 10 sekundi broje se jednom (osvježavanje, dvostruki klik).
  if exists (
    select 1 from public.product_events e
    where e.session_id = p_session and e.color_id = p_color_id and e.event = p_event
      and e.created_at > now() - interval '10 seconds'
  ) then
    return;
  end if;

  -- Zaštita od preplavljivanja: najviše 300 događaja po pregledniku na sat.
  if (select count(*) from public.product_events e where e.session_id = p_session and e.created_at > now() - interval '1 hour') >= 300 then
    return;
  end if;

  insert into public.product_events (product_id, color_id, event, quantity, session_id, is_team)
  values (
    v_product_id, p_color_id, p_event, greatest(1, least(coalesce(p_quantity, 1), 99)), p_session,
    public.current_user_role() is not null
  );
end;
$$;

revoke all on function public.shop_track_event(uuid, uuid, text, integer) from public;
grant execute on function public.shop_track_event(uuid, uuid, text, integer) to anon, authenticated, service_role;

commit;
