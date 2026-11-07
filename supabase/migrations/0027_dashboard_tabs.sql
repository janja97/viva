-- Nadzorna ploča po karticama: broj novih upita po razdoblju (svi statusi) i popis rasprodanih boja.
-- Zamjenjuje funkcije iz 0026.
begin;

-- Osnovni pregled, bez iznosa: narudžbe koje čekaju, stanje proizvoda i zaliha, pretplatnici.
create or replace function public.admin_dashboard_basic()
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

  return jsonb_build_object(
    'orders', (
      select jsonb_build_object(
        'new', count(*) filter (where status = 'new'),
        'in_progress', count(*) filter (where status = 'in_progress'),
        'today', count(*) filter (where created_at >= date_trunc('day', now() at time zone 'Europe/Sarajevo') at time zone 'Europe/Sarajevo')
      )
      from public.inquiries
    ),
    'products', (
      select jsonb_build_object(
        'visible', count(*) filter (where archived_at is null and is_visible),
        'hidden', count(*) filter (where archived_at is null and not is_visible),
        'archived', count(*) filter (where archived_at is not null),
        'on_sale', count(*) filter (where archived_at is null and sale_price is not null)
      )
      from public.products
    ),
    -- Boje kojima su sve veličine na nuli.
    'sold_out_colors', (
      select count(*)
      from public.product_colors c
      join public.products p on p.id = c.product_id
      where p.archived_at is null
        and not exists (select 1 from public.product_sizes s where s.color_id = c.id and s.quantity > 0)
    ),
    'sold_out', coalesce((
      select jsonb_agg(row_to_json(gone) order by gone.name, gone.color)
      from (
        select p.id as product_id, p.name, p.sku, c.name as color
        from public.product_colors c
        join public.products p on p.id = c.product_id
        where p.archived_at is null
          and not exists (select 1 from public.product_sizes s where s.color_id = c.id and s.quantity > 0)
        order by p.name, c.name
        limit 30
      ) gone
    ), '[]'::jsonb),
    -- Veličine kojih je ostalo jedan ili dva komada.
    'low_stock', coalesce((
      select jsonb_agg(row_to_json(low) order by low.quantity, low.name)
      from (
        select p.id as product_id, p.name, p.sku, c.name as color, s.size, s.quantity
        from public.product_sizes s
        join public.product_colors c on c.id = s.color_id
        join public.products p on p.id = c.product_id
        where p.archived_at is null and s.quantity between 1 and 2
        order by s.quantity, p.name
        limit 12
      ) low
    ), '[]'::jsonb),
    'low_stock_total', (
      select count(*)
      from public.product_sizes s
      join public.product_colors c on c.id = s.color_id
      join public.products p on p.id = c.product_id
      where p.archived_at is null and s.quantity between 1 and 2
    ),
    'subscribers', (select count(*) from public.newsletter_subscribers)
  );
end;
$$;

revoke all on function public.admin_dashboard_basic() from public, anon;
grant execute on function public.admin_dashboard_basic() to authenticated, service_role;

-- Analitika prodaje za razdoblje [p_from, p_to). Bez p_from od prve narudžbe. p_bucket: day, week ili month.
create or replace function public.admin_sales_analytics(p_from timestamptz, p_to timestamptz, p_bucket text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_zone constant text := 'Europe/Sarajevo';
  v_to timestamptz := coalesce(p_to, now());
  v_from timestamptz;
  v_previous_from timestamptz;
  v_bucket text := case when p_bucket in ('day', 'week', 'month') then p_bucket else 'day' end;
  v_result jsonb;
begin
  if public.current_user_role() is distinct from 'super_admin' then
    raise exception 'Nemaš ovlasti za ovu radnju.' using errcode = '42501';
  end if;

  v_from := coalesce(p_from, (select min(created_at) from public.inquiries), v_to - interval '30 days');
  v_previous_from := v_from - (v_to - v_from);

  with sold as (
    select * from public.inquiries
    where status = 'sold' and created_at >= v_from and created_at < v_to
  ),
  previous_sold as (
    select * from public.inquiries
    where status = 'sold' and created_at >= v_previous_from and created_at < v_from
  ),
  -- Svi upiti (narudžbe) u razdoblju, bez obzira na status.
  received as (
    select * from public.inquiries
    where created_at >= v_from and created_at < v_to
  ),
  items as (
    select ii.*
    from public.inquiry_items ii
    join sold on sold.id = ii.inquiry_id
  ),
  buckets as (
    select generate_series(
      date_trunc(v_bucket, v_from at time zone v_zone),
      date_trunc(v_bucket, (v_to - interval '1 second') at time zone v_zone),
      ('1 ' || v_bucket)::interval
    ) as bucket
  )
  select jsonb_build_object(
    'from', v_from,
    'to', v_to,
    'bucket', v_bucket,
    'kpi', (
      select jsonb_build_object(
        'revenue', coalesce(sum(total), 0),
        'orders', count(*),
        'average_order', coalesce(round(avg(total), 2), 0),
        'shipping', coalesce(sum(shipping), 0),
        'promo_discount', coalesce(sum(promo_discount), 0),
        'items', (select coalesce(sum(quantity), 0) from items),
        -- Razlika između redovne i snižene cijene (kampanje).
        'sale_savings', (select coalesce(sum((regular_price - unit_price) * quantity), 0) from items),
        'sale_revenue', (select coalesce(sum(unit_price * quantity), 0) from items where unit_price < regular_price),
        'goods_revenue', (select coalesce(sum(unit_price * quantity), 0) from items)
      )
      from sold
    ),
    'previous', (
      select jsonb_build_object(
        'revenue', coalesce(sum(total), 0),
        'orders', count(*),
        'inquiries', (select count(*) from public.inquiries where created_at >= v_previous_from and created_at < v_from)
      )
      from previous_sold
    ),
    -- Sve narudžbe u razdoblju po statusu, za stopu otkazivanja.
    'statuses', (
      select coalesce(jsonb_object_agg(status, total), '{}'::jsonb)
      from (
        select status, count(*) as total
        from public.inquiries
        where created_at >= v_from and created_at < v_to
        group by status
      ) by_status
    ),
    'trend', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'bucket', b.bucket,
        'revenue', coalesce(t.revenue, 0),
        'orders', coalesce(t.orders, 0),
        'inquiries', coalesce(r.inquiries, 0)
      ) order by b.bucket), '[]'::jsonb)
      from buckets b
      left join (
        select date_trunc(v_bucket, created_at at time zone v_zone) as bucket, sum(total) as revenue, count(*) as orders
        from sold
        group by 1
      ) t on t.bucket = b.bucket
      left join (
        select date_trunc(v_bucket, created_at at time zone v_zone) as bucket, count(*) as inquiries
        from received
        group by 1
      ) r on r.bucket = b.bucket
    ),
    'products', (
      select coalesce(jsonb_agg(row_to_json(top)), '[]'::jsonb)
      from (
        select product_name as name, sku, sum(quantity) as quantity, sum(unit_price * quantity) as revenue
        from items
        group by product_name, sku
        order by sum(quantity) desc, sum(unit_price * quantity) desc
        limit 10
      ) top
    ),
    'colors', (
      select coalesce(jsonb_agg(row_to_json(top)), '[]'::jsonb)
      from (
        select color_name as name, sum(quantity) as quantity, sum(unit_price * quantity) as revenue
        from items
        group by color_name
        order by sum(quantity) desc
        limit 10
      ) top
    ),
    'sizes', (
      select coalesce(jsonb_agg(row_to_json(top)), '[]'::jsonb)
      from (
        select size as name, sum(quantity) as quantity, sum(unit_price * quantity) as revenue
        from items
        group by size
        order by sum(quantity) desc
        limit 12
      ) top
    ),
    -- Glavna kategorija proizvoda kakva je danas. Obrisani proizvodi nemaju kategoriju.
    'categories', (
      select coalesce(jsonb_agg(row_to_json(top)), '[]'::jsonb)
      from (
        select coalesce(c.name, 'Bez kategorije') as name, sum(i.quantity) as quantity, sum(i.unit_price * i.quantity) as revenue
        from items i
        left join public.products p on p.id = i.product_id
        left join public.categories c on c.id = p.category_id
        group by coalesce(c.name, 'Bez kategorije')
        order by sum(i.quantity) desc
        limit 10
      ) top
    ),
    'promo_codes', (
      select coalesce(jsonb_agg(row_to_json(top)), '[]'::jsonb)
      from (
        select
          sold.promo_code as code,
          coalesce(pc.kind, 'manual') as kind,
          count(*) as orders,
          sum(sold.promo_discount) as discount
        from sold
        left join public.promo_codes pc on pc.id = sold.promo_code_id
        where sold.promo_code is not null
        group by sold.promo_code, coalesce(pc.kind, 'manual')
        order by count(*) desc
        limit 10
      ) top
    ),
    'newsletter', jsonb_build_object(
      'total', (select count(*) from public.newsletter_subscribers),
      'new', (select count(*) from public.newsletter_subscribers where created_at >= v_from and created_at < v_to),
      'codes_used', (select count(*) from sold join public.promo_codes pc on pc.id = sold.promo_code_id where pc.kind = 'newsletter')
    )
  ) into v_result;

  return v_result;
end;
$$;

revoke all on function public.admin_sales_analytics(timestamptz, timestamptz, text) from public, anon;
grant execute on function public.admin_sales_analytics(timestamptz, timestamptz, text) to authenticated, service_role;

commit;
