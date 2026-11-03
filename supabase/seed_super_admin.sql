-- Prvo napravi korisnika: Authentication > Users > Add user (uključi Auto Confirm User).
-- Zatim zamijeni e-mail ispod i pokreni ovaj upit.
do $$
declare
  admin_email text := 'TVOJ_EMAIL@primjer.hr';
  admin_id uuid;
begin
  select id into admin_id from auth.users where lower(email) = lower(admin_email);

  if admin_id is null then
    raise exception 'Korisnik % ne postoji u Authentication > Users.', admin_email;
  end if;

  insert into public.user_roles (user_id, role)
  values (admin_id, 'super_admin')
  on conflict (user_id) do update set role = excluded.role;
end;
$$;
