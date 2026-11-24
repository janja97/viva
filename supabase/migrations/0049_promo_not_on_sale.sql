-- Promo kod vrijedi samo za artikle koji nisu već sniženi (kampanjom ili akcijskom stranicom).
-- Popust se računa samo na iznos nesniženih artikala. Isto pravilo ima košarica (useCart().promoBase).
begin;

-- Iznos nesniženih artikala narudžbe: cijena koju kupac plaća jednaka je redovnoj cijeni.
create or replace function public.inquiry_promo_base(p_inquiry uuid)
returns numeric
language sql
stable
set search_path = ''
as $$
  select coalesce(sum(unit_price * quantity), 0)
  from public.inquiry_items
  where inquiry_id = p_inquiry and unit_price >= regular_price;
$$;

-- Koriste je samo funkcije narudžbe (security definer), kupci je ne zovu izravno.
revoke all on function public.inquiry_promo_base(uuid) from public, anon, authenticated;

-- Narudžba s weba (obrazac). Isto kao u migraciji 0048, ali promo kod vrijedi samo za artikle koji nisu sniženi.
-- Ako su svi artikli već sniženi, kod se ne sprema ni ne troši.
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
  v_delivery text := coalesce(nullif(p_customer ->> 'delivery_method', ''), 'delivery');
  v_item record;
  v_inquiry_id uuid;
  v_number bigint;
  v_subtotal numeric(10, 2);
  v_shipping numeric(10, 2);
  v_promo_code text := upper(nullif(btrim(coalesce(p_customer ->> 'promo_code', '')), ''));
  v_promo public.promo_codes;
  v_promo_discount numeric(10, 2) := 0;
begin
  perform public.shop_session_expire(p_session);

  if v_delivery not in ('delivery', 'pickup_mostar', 'pickup_sarajevo') then
    raise exception 'Odaberite način preuzimanja.';
  end if;

  if char_length(v_name) not between 2 and 100 then
    raise exception 'Upišite ime i prezime.';
  end if;
  if v_phone !~ '^[0-9 +()/-]{6,30}$' then
    raise exception 'Upišite ispravan broj telefona.';
  end if;
  -- Adresa je potrebna samo za dostavu.
  if v_delivery = 'delivery' then
    if char_length(v_address) not between 3 and 200 then
      raise exception 'Upišite adresu za dostavu.';
    end if;
    if v_postal_code !~ '^[0-9]{5}$' then
      raise exception 'Poštanski broj mora imati 5 znamenki.';
    end if;
    if char_length(v_city) not between 2 and 100 then
      raise exception 'Upišite grad.';
    end if;
  else
    v_address := '';
    v_postal_code := '';
    v_city := '';
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
    select ci.quantity, s.size, s.quantity as stock, c.name as color_name, p.name, p.is_visible and public.category_is_active(p.category_id) as is_visible, p.store_only
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

  -- Promo kod se zaključava, kako isti jednokratni kod ne bi prošao u dvije narudžbe odjednom.
  if v_promo_code is not null then
    select * into v_promo from public.promo_codes where code = v_promo_code for update;
    if not found or not public.promo_code_is_valid(v_promo) then
      raise exception 'Promo kod nije valjan ili je istekao. Uklonite ga i pošaljite narudžbu ponovno.';
    end if;
  end if;

  insert into public.inquiries (customer_name, phone, address, postal_code, city, email, note, session_id, promo_code_id, promo_code, delivery_method)
  values (v_name, v_phone, nullif(v_address, ''), nullif(v_postal_code, ''), nullif(v_city, ''), v_email, v_note, p_session, v_promo.id, v_promo.code, v_delivery)
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

  -- Poštarina se računa prema iznosu prije promo koda, kao i u košarici. Preuzimanje u trgovini je bez poštarine.
  v_shipping := case when v_delivery = 'delivery' then public.shipping_for(v_subtotal) else 0 end;

  if v_promo.id is not null then
    v_promo_discount := round(public.inquiry_promo_base(v_inquiry_id) * v_promo.discount_percent / 100, 2);
    if v_promo_discount > 0 then
      update public.promo_codes set used_count = used_count + 1 where id = v_promo.id;
    else
      update public.inquiries set promo_code_id = null, promo_code = null where id = v_inquiry_id;
    end if;
  end if;

  update public.inquiries
  set subtotal = v_subtotal, shipping = v_shipping, promo_discount = v_promo_discount, total = v_subtotal - v_promo_discount + v_shipping
  where id = v_inquiry_id;

  delete from public.cart_items where session_id = p_session;
  perform public.shop_session_touch(p_session);

  return jsonb_build_object('number', v_number);
end;
$$;

-- Narudžba preko WhatsAppa. Isto kao u migraciji 0048, ali promo kod vrijedi samo za artikle koji nisu sniženi.
-- Kod se troši tek kad stvarno daje popust.
create or replace function public.shop_submit_whatsapp_inquiry(p_session uuid, p_note text default null, p_promo_code text default null, p_delivery text default 'delivery')
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_note text := nullif(btrim(coalesce(p_note, '')), '');
  v_promo_code text := upper(nullif(btrim(coalesce(p_promo_code, '')), ''));
  v_delivery text := case when p_delivery in ('delivery', 'pickup_mostar', 'pickup_sarajevo') then p_delivery else 'delivery' end;
  v_promo public.promo_codes;
  v_inquiry public.inquiries;
  v_subtotal numeric(10, 2);
  v_shipping numeric(10, 2);
  v_promo_discount numeric(10, 2) := 0;
  v_is_new boolean := false;
begin
  if p_session is null then
    raise exception 'Košarica je prazna.';
  end if;
  perform public.shop_session_expire(p_session);

  -- Samo proizvodi koji se smiju naručiti online.
  if not exists (
    select 1 from public.cart_items ci
    join public.product_sizes s on s.id = ci.size_id
    join public.product_colors c on c.id = s.color_id
    join public.products p on p.id = c.product_id
    where ci.session_id = p_session and p.is_visible and not p.store_only and public.category_is_active(p.category_id)
  ) then
    raise exception 'Košarica je prazna.';
  end if;

  if char_length(coalesce(v_note, '')) > 2000 then
    v_note := left(v_note, 2000);
  end if;

  -- Isti kupac je upravo otvorio WhatsApp: osvježava se ista narudžba, dok je još Novo.
  select * into v_inquiry from public.inquiries
  where session_id = p_session and channel = 'whatsapp' and status = 'new' and created_at > now() - interval '30 minutes'
  order by created_at desc
  limit 1
  for update;

  if v_inquiry.id is null then
    -- Promo kod se troši samo jednom po narudžbi. Nevažeći kod se preskače, jer je narudžba ionako u poruci.
    if v_promo_code is not null then
      select * into v_promo from public.promo_codes where code = v_promo_code for update;
      if not found or not public.promo_code_is_valid(v_promo) then
        v_promo := null;
      end if;
    end if;

    insert into public.inquiries (channel, note, session_id, promo_code_id, promo_code, delivery_method)
    values ('whatsapp', v_note, p_session, v_promo.id, v_promo.code, v_delivery)
    returning * into v_inquiry;
    v_is_new := true;
  else
    update public.inquiries set note = v_note, delivery_method = v_delivery where id = v_inquiry.id;
    delete from public.inquiry_items where inquiry_id = v_inquiry.id;
    if v_inquiry.promo_code_id is not null then
      select * into v_promo from public.promo_codes where id = v_inquiry.promo_code_id;
    end if;
  end if;

  insert into public.inquiry_items (
    inquiry_id, product_id, color_id, size_id, sku, product_name, color_name, size, unit_price, regular_price, quantity
  )
  select
    v_inquiry.id, p.id, c.id, s.id, p.sku, p.name, c.name, s.size,
    coalesce(p.sale_price, p.price), p.price, ci.quantity
  from public.cart_items ci
  join public.product_sizes s on s.id = ci.size_id
  join public.product_colors c on c.id = s.color_id
  join public.products p on p.id = c.product_id
  where ci.session_id = p_session and p.is_visible and not p.store_only and public.category_is_active(p.category_id)
  order by ci.added_at;

  select sum(unit_price * quantity) into v_subtotal from public.inquiry_items where inquiry_id = v_inquiry.id;
  v_shipping := case when v_delivery = 'delivery' then public.shipping_for(v_subtotal) else 0 end;
  if v_promo.id is not null then
    v_promo_discount := round(public.inquiry_promo_base(v_inquiry.id) * v_promo.discount_percent / 100, 2);
    if v_is_new and v_promo_discount > 0 then
      update public.promo_codes set used_count = used_count + 1 where id = v_promo.id;
    elsif v_is_new then
      update public.inquiries set promo_code_id = null, promo_code = null where id = v_inquiry.id;
    end if;
  end if;

  update public.inquiries
  set subtotal = v_subtotal, shipping = v_shipping, promo_discount = v_promo_discount, total = v_subtotal - v_promo_discount + v_shipping
  where id = v_inquiry.id;

  perform public.shop_session_touch(p_session);
  return jsonb_build_object('number', v_inquiry.number);
end;
$$;

revoke all on function public.shop_submit_whatsapp_inquiry(uuid, text, text, text) from public;
grant execute on function public.shop_submit_whatsapp_inquiry(uuid, text, text, text) to anon, authenticated, service_role;

commit;
