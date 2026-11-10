-- Odbrojavanja (/admin/odbrojavanja): oblačić na webu koji odbrojava do početka akcije (npr. "Dan drame"),
-- a od početka do kraja javlja da je u tijeku i odbrojava do kraja. Nakon kraja nestaje.
-- Samo prikaz: stvarno sniženje i dalje daju kampanje ili promo kodovi.
-- Na webu je istodobno jedno: uključeno, nezavršeno, ono koje najranije počinje.
begin;

create table public.countdowns (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(btrim(title)) between 2 and 60),
  -- Kratki tekst ispod naslova, npr. "-20 % na sve haljine".
  message text not null default '' check (char_length(message) <= 120),
  -- Neobavezna poveznica: putanja na webu (/proizvodi?snizeno=1) ili puna adresa (https://...).
  link text check (link is null or (char_length(link) <= 300 and (link ~ '^/' or link ~ '^https://'))),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  is_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint countdowns_dates_check check (ends_at > starts_at)
);

create index countdowns_active_idx on public.countdowns (starts_at) where is_enabled;

create function public.touch_countdown()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger touch_countdown
before update on public.countdowns
for each row execute function public.touch_countdown();

alter table public.countdowns enable row level security;

revoke all on public.countdowns from public, anon, authenticated;
grant select on public.countdowns to anon;
grant select, insert, update, delete on public.countdowns to authenticated;
grant all on public.countdowns to service_role;

-- Kupci vide samo uključena odbrojavanja koja još nisu završila.
create policy countdowns_select_public on public.countdowns
for select to anon
using (is_enabled and ends_at > now());

-- Cijeli tim (super_admin, admin, viewer) vidi sva, a prijavljeni bez uloge kao kupci.
create policy countdowns_select_authenticated on public.countdowns
for select to authenticated
using ((is_enabled and ends_at > now()) or (select public.current_user_role()) is not null);

-- Dodaju, mijenjaju, pale, gase i brišu samo super_admin i admin. Viewer samo čita.
create policy countdowns_insert on public.countdowns
for insert to authenticated
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy countdowns_update on public.countdowns
for update to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'))
with check ((select public.current_user_role()) in ('super_admin', 'admin'));

create policy countdowns_delete on public.countdowns
for delete to authenticated
using ((select public.current_user_role()) in ('super_admin', 'admin'));

commit;
