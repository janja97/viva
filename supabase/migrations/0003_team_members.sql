-- Popis članova tima s e-mailom. Tablica auth.users nije dostupna iz preglednika,
-- pa je čita ova funkcija i vraća retke samo prijavljenim članovima tima.
create function public.list_team_members()
returns table (
  user_id uuid,
  email text,
  role public.app_role,
  created_at timestamptz,
  last_sign_in_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select ur.user_id, u.email::text, ur.role, ur.created_at, u.last_sign_in_at
  from public.user_roles ur
  join auth.users u on u.id = ur.user_id
  where public.current_user_role() is not null
  order by ur.created_at;
$$;

revoke all on function public.list_team_members() from public, anon;
grant execute on function public.list_team_members() to authenticated, service_role;
