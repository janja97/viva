-- Izmjena količina s popisa proizvoda. Promjena se šalje kao razlika, kako istodobna izmjena
-- druge osobe ne bi bila pregažena, a svaka izmjena ostaje zapisana u povijesti proizvoda.
begin;

alter table public.product_audit_log
  add column details jsonb;

alter table public.product_audit_log
  drop constraint product_audit_log_action_check;

alter table public.product_audit_log
  add constraint product_audit_log_action_check
  check (action in ('created', 'updated', 'deleted', 'stock'));

create function public.adjust_product_stock(p_product_id uuid, p_changes jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_product record;
  v_change jsonb;
  v_size record;
  v_delta integer;
  v_quantity integer;
  v_details jsonb := '[]'::jsonb;
begin
  if coalesce(public.current_user_role()::text, '') not in ('super_admin', 'admin') then
    raise exception 'Nemaš ovlasti za ovu radnju.' using errcode = '42501';
  end if;

  select id, sku, name into v_product
  from public.products
  where id = p_product_id
  for update;

  if not found then
    raise exception 'Proizvod više ne postoji.';
  end if;

  for v_change in select value from jsonb_array_elements(p_changes) loop
    v_delta := (v_change ->> 'delta')::integer;
    continue when v_delta = 0;

    select s.id, s.size, s.quantity, c.name as color_name into v_size
    from public.product_sizes s
    join public.product_colors c on c.id = s.color_id
    where s.id = (v_change ->> 'size_id')::uuid
      and c.product_id = p_product_id
    for update of s;

    if not found then
      raise exception 'Veličina više ne postoji. Otvori količine ponovno.';
    end if;

    v_quantity := v_size.quantity + v_delta;
    if v_quantity < 0 then
      raise exception 'Količina za % % ne može biti manja od nule. Trenutno je %.',
        v_size.color_name, v_size.size, v_size.quantity;
    end if;

    update public.product_sizes set quantity = v_quantity where id = v_size.id;

    v_details := v_details || jsonb_build_object(
      'color', v_size.color_name,
      'size', v_size.size,
      'from', v_size.quantity,
      'to', v_quantity
    );
  end loop;

  if jsonb_array_length(v_details) = 0 then
    return;
  end if;

  insert into public.product_audit_log (product_id, sku, name, action, user_id, user_email, details)
  select v_product.id, v_product.sku, v_product.name, 'stock', auth.uid(), u.email::text, v_details
  from (select 1) as one
  left join auth.users u on u.id = auth.uid();
end;
$$;

revoke all on function public.adjust_product_stock(uuid, jsonb) from public, anon;
grant execute on function public.adjust_product_stock(uuid, jsonb) to authenticated, service_role;

commit;
