-- Zaliha po veličinama za nadzornu ploču (kartica Zalihe). Bez iznosa, pa je vidi cijeli tim.
-- Vraća zbroj komada po glavnoj kategoriji proizvoda i veličini, a aplikacija zbraja podkategorije.
begin;

create function public.admin_stock_by_size()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if public.current_user_role() is null then
    raise exception 'Nemaš ovlasti za ovu radnju.' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(row_to_json(stock))
    from (
      select p.category_id, s.size, sum(s.quantity)::integer as quantity
      from public.product_sizes s
      join public.product_colors c on c.id = s.color_id
      join public.products p on p.id = c.product_id
      where p.archived_at is null
      group by p.category_id, s.size
    ) stock
  ), '[]'::jsonb);
end;
$$;

revoke all on function public.admin_stock_by_size() from public, anon;
grant execute on function public.admin_stock_by_size() to authenticated, service_role;

commit;
