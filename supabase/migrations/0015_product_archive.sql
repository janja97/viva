-- Arhiva proizvoda. Proizvod se umjesto brisanja arhivira: nestaje s weba i s popisa, ali podaci ostaju za statistiku
-- i buduće narudžbe. Pri arhiviranju ostaje samo prva slika (za prepoznavanje), a ostale se brišu jer zauzimaju najviše mjesta.
-- Trajno se može obrisati samo arhivirani proizvod.
begin;

alter table public.products
  add column archived_at timestamptz,
  add constraint products_archived_hidden_check check (archived_at is null or not is_visible);

create index products_active_created_idx on public.products (created_at desc) where archived_at is null;
create index products_archived_idx on public.products (archived_at desc) where archived_at is not null;

alter table public.product_audit_log
  drop constraint product_audit_log_action_check;

alter table public.product_audit_log
  add constraint product_audit_log_action_check
  check (action in ('created', 'updated', 'deleted', 'stock', 'archived', 'restored'));

-- Arhiviranje i vraćanje iz arhive bilježe se kao zasebne radnje, a ne kao obična izmjena.
create or replace function public.log_product_change()
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
      case
        when tg_op = 'INSERT' then 'created'
        when old.archived_at is null and new.archived_at is not null then 'archived'
        when old.archived_at is not null and new.archived_at is null then 'restored'
        else 'updated'
      end,
      auth.uid(),
      v_email
    );
  end if;
  return null;
end;
$$;

-- Arhivira proizvod i vraća putanje obrisanih slika, koje aplikacija zatim uklanja iz spremišta.
create function public.archive_product(p_product_id uuid)
returns text[]
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_keep_id uuid;
  v_paths text[];
begin
  if coalesce(public.current_user_role()::text, '') not in ('super_admin', 'admin') then
    raise exception 'Nemaš ovlasti za ovu radnju.' using errcode = '42501';
  end if;

  update public.products
  set archived_at = now(), is_visible = false
  where id = p_product_id and archived_at is null;

  if not found then
    raise exception 'Proizvod ne postoji ili je već arhiviran.';
  end if;

  select i.id into v_keep_id
  from public.product_images i
  join public.product_colors c on c.id = i.color_id
  where c.product_id = p_product_id
  order by c.sort_order, i.sort_order
  limit 1;

  with removed as (
    delete from public.product_images i
    using public.product_colors c
    where c.id = i.color_id
      and c.product_id = p_product_id
      and i.id is distinct from v_keep_id
    returning i.path
  )
  select coalesce(array_agg(path), '{}') into v_paths from removed;

  return v_paths;
end;
$$;

revoke all on function public.archive_product(uuid) from public, anon;
grant execute on function public.archive_product(uuid) to authenticated, service_role;

-- Trajno brisanje samo iz arhive, kako se proizvod ne bi obrisao slučajno.
drop policy products_delete on public.products;

create policy products_delete on public.products
for delete to authenticated
using (
  archived_at is not null
  and (select public.current_user_role()) in ('super_admin', 'admin')
);

commit;
