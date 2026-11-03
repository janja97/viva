-- Uloge administratora i RLS pravila. Korisnik bez retka u user_roles nema pristup adminu.
begin;

create type public.app_role as enum ('super_admin', 'admin', 'viewer');

create table public.user_roles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role public.app_role not null,
  created_at timestamptz not null default now()
);

-- Uloga prijavljenog korisnika. Koristi se i u RLS pravilima budućih tablica.
create function public.current_user_role()
returns public.app_role
language sql
stable
security definer
set search_path = ''
as $$
  select role from public.user_roles where user_id = auth.uid();
$$;

-- Sustav mora uvijek imati barem jednog super admina.
create function public.protect_last_super_admin()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.role = 'super_admin'
    and (tg_op = 'DELETE' or new.role <> 'super_admin')
    and not exists (
      select 1 from public.user_roles
      where role = 'super_admin' and user_id <> old.user_id
    )
  then
    raise exception 'Nije moguće ukloniti zadnjeg super admina.';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create trigger protect_last_super_admin
before update or delete on public.user_roles
for each row execute function public.protect_last_super_admin();

alter table public.user_roles enable row level security;

revoke all on public.user_roles from public, anon;
grant select, insert, update, delete on public.user_roles to authenticated;
grant all on public.user_roles to service_role;

revoke all on function public.current_user_role() from public, anon;
grant execute on function public.current_user_role() to authenticated, service_role;
revoke all on function public.protect_last_super_admin() from public, anon, authenticated;

-- Čitanje: svaki član tima vidi tim, a korisnik uvijek vidi svoju ulogu.
create policy user_roles_select on public.user_roles
for select to authenticated
using (
  user_id = (select auth.uid())
  or (select public.current_user_role()) is not null
);

-- Dodavanje: admin ne smije dodijeliti ulogu super admina.
create policy user_roles_insert on public.user_roles
for insert to authenticated
with check (
  (select public.current_user_role()) = 'super_admin'
  or ((select public.current_user_role()) = 'admin' and role <> 'super_admin')
);

-- Izmjena: admin ne smije dirati super admine ni mijenjati vlastitu ulogu.
create policy user_roles_update on public.user_roles
for update to authenticated
using (
  (select public.current_user_role()) = 'super_admin'
  or (
    (select public.current_user_role()) = 'admin'
    and role <> 'super_admin'
    and user_id <> (select auth.uid())
  )
)
with check (
  (select public.current_user_role()) = 'super_admin'
  or ((select public.current_user_role()) = 'admin' and role <> 'super_admin')
);

-- Brisanje: samo super admin.
create policy user_roles_delete on public.user_roles
for delete to authenticated
using ((select public.current_user_role()) = 'super_admin');

commit;
