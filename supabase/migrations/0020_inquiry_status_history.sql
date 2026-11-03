-- Statusi narudžbi su Novo, U obradi, Prodano i Otkazano, a baza bilježi tko je i kada promijenio status.
-- Povijest (inquiry_audit_log) puni okidač, nema stranih ključeva i ostaje i nakon brisanja narudžbe.
begin;

alter table public.inquiries drop constraint inquiries_status_check;

update public.inquiries set status = 'sold' where status = 'completed';

alter table public.inquiries
  add constraint inquiries_status_check check (status in ('new', 'in_progress', 'sold', 'cancelled')),
  add column status_changed_at timestamptz,
  add column status_changed_by uuid,
  add column status_changed_by_email text;

create table public.inquiry_audit_log (
  id uuid primary key default gen_random_uuid(),
  inquiry_id uuid not null,
  inquiry_number bigint not null,
  action text not null check (action in ('created', 'status', 'deleted')),
  from_status text,
  to_status text,
  user_id uuid,
  user_email text,
  created_at timestamptz not null default now()
);

create index inquiry_audit_log_inquiry_idx on public.inquiry_audit_log (inquiry_id, created_at desc);
create index inquiry_audit_log_created_idx on public.inquiry_audit_log (created_at desc);

-- Zadnja promjena statusa upisuje se i na samu narudžbu, za brzi prikaz na popisu.
create function public.track_inquiry_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status is distinct from old.status then
    new.status_changed_at := now();
    new.status_changed_by := auth.uid();
    select email::text into new.status_changed_by_email from auth.users where id = auth.uid();
  end if;
  return new;
end;
$$;

create trigger track_inquiry_status
before update of status on public.inquiries
for each row execute function public.track_inquiry_status();

-- Narudžbu stvara kupac (bez korisnika), a promjene statusa i brisanje članovi tima.
create function public.log_inquiry_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text;
begin
  select email::text into v_email from auth.users where id = auth.uid();

  if tg_op = 'INSERT' then
    insert into public.inquiry_audit_log (inquiry_id, inquiry_number, action, to_status, user_id, user_email)
    values (new.id, new.number, 'created', new.status, auth.uid(), v_email);
  elsif tg_op = 'UPDATE' then
    if new.status is distinct from old.status then
      insert into public.inquiry_audit_log (inquiry_id, inquiry_number, action, from_status, to_status, user_id, user_email)
      values (new.id, new.number, 'status', old.status, new.status, auth.uid(), v_email);
    end if;
  else
    insert into public.inquiry_audit_log (inquiry_id, inquiry_number, action, from_status, user_id, user_email)
    values (old.id, old.number, 'deleted', old.status, auth.uid(), v_email);
  end if;
  return null;
end;
$$;

create trigger log_inquiry_change
after insert or update of status or delete on public.inquiries
for each row execute function public.log_inquiry_change();

-- Postojeće narudžbe dobivaju zapis o nastanku, kako povijest ne bi bila prazna.
insert into public.inquiry_audit_log (inquiry_id, inquiry_number, action, to_status, created_at)
select id, number, 'created', 'new', created_at from public.inquiries;

revoke all on function public.track_inquiry_status() from public, anon, authenticated;
revoke all on function public.log_inquiry_change() from public, anon, authenticated;

alter table public.inquiry_audit_log enable row level security;

revoke all on public.inquiry_audit_log from public, anon, authenticated;
grant select on public.inquiry_audit_log to authenticated;
grant all on public.inquiry_audit_log to service_role;

-- Čitanje: svi članovi tima. Upisuje samo okidač, a mijenjati ili brisati ne može nitko iz aplikacije.
create policy inquiry_audit_log_select on public.inquiry_audit_log
for select to authenticated
using ((select public.current_user_role()) is not null);

commit;
