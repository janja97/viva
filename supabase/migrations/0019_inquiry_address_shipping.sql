-- Adresa za dostavu i poštarina u upitu. Poštarina je besplatna za narudžbe veće od 150 KM, a inače je 9 KM.
-- Iste brojeve koristi aplikacija (SHIPPING u app/config/store.ts), a baza ih sama računa kako kupac ne bi poslao drugi iznos.
begin;

alter table public.inquiries
  add column address text check (address is null or char_length(address) <= 200),
  add column postal_code text check (postal_code is null or char_length(postal_code) <= 10),
  add column city text check (city is null or char_length(city) <= 100),
  add column subtotal numeric(10, 2),
  add column shipping numeric(10, 2) not null default 0;

-- Dosadašnji upiti nisu imali poštarinu, pa je međuzbroj jednak ukupnom iznosu.
update public.inquiries set subtotal = total where subtotal is null;

alter table public.inquiries alter column subtotal set not null;
alter table public.inquiries alter column subtotal set default 0;

create or replace function public.shop_submit_inquiry(p_session uuid, p_customer jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text := btrim(coalesce(p_customer ->> 'name', ''));
  v_phone text := btrim(coalesce(p_customer ->> 'phone', ''));
  v_address text := btrim(coalesce(p_customer ->> 'address', ''));
  v_postal_code text := btrim(coalesce(p_customer ->> 'postal_code', ''));
  v_city text := btrim(coalesce(p_customer ->> 'city', ''));
  v_email text := nullif(btrim(coalesce(p_customer ->> 'email', '')), '');
  v_note text := nullif(btrim(coalesce(p_customer ->> 'note', '')), '');
  v_item record;
  v_inquiry_id uuid;
  v_number bigint;
  v_subtotal numeric(10, 2);
  v_shipping numeric(10, 2);
begin
  perform public.shop_session_expire(p_session);

  if char_length(v_name) not between 2 and 100 then
    raise exception 'Upišite ime i prezime.';
  end if;
  if v_phone !~ '^[0-9 +()/-]{6,30}$' then
    raise exception 'Upišite ispravan broj telefona.';
  end if;
  if char_length(v_address) not between 3 and 200 then
    raise exception 'Upišite adresu za dostavu.';
  end if;
  if v_postal_code !~ '^[0-9]{5}$' then
    raise exception 'Poštanski broj mora imati 5 znamenki.';
  end if;
  if char_length(v_city) not between 2 and 100 then
    raise exception 'Upišite grad.';
  end if;
  if v_email is not null and (char_length(v_email) > 200 or v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$') then
    raise exception 'Upišite ispravnu e-mail adresu ili ostavite polje prazno.';
  end if;
  if char_length(coalesce(v_note, '')) > 2000 then
    raise exception 'Napomena može imati najviše 2000 znakova.';
  end if;

  -- Zaštita od višestrukog slanja istog upita.
  if exists (
    select 1 from public.inquiries
    where session_id = p_session and created_at > now() - interval '1 minute'
  ) then
    raise exception 'Narudžba je upravo poslana. Pričekajte minutu prije nove.';
  end if;

  if not exists (select 1 from public.cart_items where session_id = p_session) then
    raise exception 'Košarica je prazna.';
  end if;

  for v_item in
    select ci.quantity, s.size, s.quantity as stock, c.name as color_name, p.name, p.is_visible, p.store_only
    from public.cart_items ci
    join public.product_sizes s on s.id = ci.size_id
    join public.product_colors c on c.id = s.color_id
    join public.products p on p.id = c.product_id
    where ci.session_id = p_session
  loop
    if not v_item.is_visible or v_item.store_only then
      raise exception '% (%) više nije moguće naručiti online. Uklonite ga iz košarice.', v_item.name, v_item.color_name;
    end if;
    if v_item.quantity > v_item.stock then
      raise exception 'Za % (%, %) dostupno je još % kom. Promijenite količinu u košarici.',
        v_item.name, v_item.color_name, v_item.size, v_item.stock;
    end if;
  end loop;

  insert into public.inquiries (customer_name, phone, address, postal_code, city, email, note, session_id)
  values (v_name, v_phone, v_address, v_postal_code, v_city, v_email, v_note, p_session)
  returning id, number into v_inquiry_id, v_number;

  insert into public.inquiry_items (
    inquiry_id, product_id, color_id, size_id, sku, product_name, color_name, size, unit_price, regular_price, quantity
  )
  select
    v_inquiry_id, p.id, c.id, s.id, p.sku, p.name, c.name, s.size,
    coalesce(p.sale_price, p.price), p.price, ci.quantity
  from public.cart_items ci
  join public.product_sizes s on s.id = ci.size_id
  join public.product_colors c on c.id = s.color_id
  join public.products p on p.id = c.product_id
  where ci.session_id = p_session
  order by ci.added_at;

  select sum(unit_price * quantity) into v_subtotal
  from public.inquiry_items
  where inquiry_id = v_inquiry_id;

  v_shipping := case when v_subtotal > 150 then 0 else 9 end;

  update public.inquiries
  set subtotal = v_subtotal, shipping = v_shipping, total = v_subtotal + v_shipping
  where id = v_inquiry_id;

  delete from public.cart_items where session_id = p_session;
  perform public.shop_session_touch(p_session);

  return jsonb_build_object('number', v_number);
end;
$$;

commit;
