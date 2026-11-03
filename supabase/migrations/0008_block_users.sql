-- Blokada računa. Podatak je banned_until u auth.users, koji se iz preglednika ne može mijenjati,
-- pa blokadu može postaviti i skinuti samo server ruta, a ona dopušta samo super adminu.
begin;

-- Blokirani korisnik odmah gubi ulogu, a time i sva prava koja provjerava RLS.
create or replace function public.current_user_role()
returns public.app_role
language sql
stable
security definer
set search_path = ''
as $$
  select ur.role
  from public.user_roles ur
  join auth.users u on u.id = ur.user_id
  where ur.user_id = auth.uid()
    and (u.banned_until is null or u.banned_until <= now());
$$;

-- Promjena povratnih stupaca traži brisanje i ponovno stvaranje funkcije.
drop function public.list_team_members();

create function public.list_team_members()
returns table (
  user_id uuid,
  email text,
  role public.app_role,
  created_at timestamptz,
  last_sign_in_at timestamptz,
  is_blocked boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    ur.user_id,
    u.email::text,
    ur.role,
    ur.created_at,
    u.last_sign_in_at,
    coalesce(u.banned_until > now(), false)
  from public.user_roles ur
  join auth.users u on u.id = ur.user_id
  where public.current_user_role() is not null
  order by ur.created_at;
$$;

revoke all on function public.list_team_members() from public, anon;
grant execute on function public.list_team_members() to authenticated, service_role;

commit;
