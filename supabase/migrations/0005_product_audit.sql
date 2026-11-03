-- Povijest proizvoda: tko je i kada upisao, uredio ili obrisao proizvod.
-- Bez stranih ključeva, kako bi zapis ostao i nakon brisanja proizvoda ili korisnika.
begin;

create table public.product_audit_log (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null,
  sku text not null,
  name text not null,
  action text not null check (action in ('created', 'updated', 'deleted')),
  user_id uuid,
  user_email text,
  created_at timestamptz not null default now()
);

create index product_audit_log_product_idx on public.product_audit_log (product_id, created_at desc);
create index product_audit_log_created_idx on public.product_audit_log (created_at desc);

create function public.log_product_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text;
begin
  select email::text into v_email from auth.users where id = auth.uid();

  if tg_op = 'DELETE' then
    insert into public.product_audit_log (product_id, sku, name, action, user_id, user_email)
    values (old.id, old.sku, old.name, 'deleted', auth.uid(), v_email);
  else
    insert into public.product_audit_log (product_id, sku, name, action, user_id, user_email)
    values (
      new.id,
      new.sku,
      new.name,
      case when tg_op = 'INSERT' then 'created' else 'updated' end,
      auth.uid(),
      v_email
    );
  end if;
  return null;
end;
$$;

create trigger log_product_change
after insert or update or delete on public.products
for each row execute function public.log_product_change();

revoke all on function public.log_product_change() from public, anon, authenticated;

alter table public.product_audit_log enable row level security;

revoke all on public.product_audit_log from public, anon, authenticated;
grant select on public.product_audit_log to authenticated;
grant all on public.product_audit_log to service_role;

-- Čitanje: svi članovi tima. Upisuje samo okidač, a mijenjati ili brisati ne može nitko iz aplikacije.
create policy product_audit_log_select on public.product_audit_log
for select to authenticated
using ((select public.current_user_role()) is not null);

commit;
