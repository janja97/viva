-- Narudžba preko WhatsAppa sada se sprema i kao narudžba u adminu (/admin/narudzbe), sa stavkama iz košarice.
-- Ime, telefon i adresu kupac javlja u WhatsApp poruci, pa ih ovdje nema (channel = 'whatsapp').
-- Košarica ostaje, jer kupac poruku možda ne pošalje. Ponovni klik istog kupca unutar 30 minuta ne stvara
-- novu narudžbu, nego postojeću (dok je još Novo) osvježi sadržajem košarice.
-- Usput se prestaje bilježiti dodavanje u košaricu (product_events.event = 'cart_add').
begin;

alter table public.inquiries
  add column channel text not null default 'web' check (channel in ('web', 'whatsapp'));

alter table public.inquiries alter column customer_name drop not null;
alter table public.inquiries alter column phone drop not null;

-- Narudžba s weba i dalje mora imati ime i telefon.
alter table public.inquiries
  add constraint inquiries_web_contact_check check (channel = 'whatsapp' or (customer_name is not null and phone is not null));

create function public.shop_submit_whatsapp_inquiry(p_session uuid, p_note text default null, p_promo_code text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_note text := nullif(btrim(coalesce(p_note, '')), '');
  v_promo_code text := upper(nullif(btrim(coalesce(p_promo_code, '')), ''));
  v_promo public.promo_codes;
  v_inquiry public.inquiries;
  v_subtotal numeric(10, 2);
  v_shipping numeric(10, 2);
  v_promo_discount numeric(10, 2) := 0;
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

    insert into public.inquiries (channel, note, session_id, promo_code_id, promo_code)
    values ('whatsapp', v_note, p_session, v_promo.id, v_promo.code)
    returning * into v_inquiry;

    if v_promo.id is not null then
      update public.promo_codes set used_count = used_count + 1 where id = v_promo.id;
    end if;
  else
    update public.inquiries set note = v_note where id = v_inquiry.id;
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
  v_shipping := public.shipping_for(v_subtotal);
  if v_promo.id is not null then
    v_promo_discount := round(v_subtotal * v_promo.discount_percent / 100, 2);
  end if;

  update public.inquiries
  set subtotal = v_subtotal, shipping = v_shipping, promo_discount = v_promo_discount, total = v_subtotal - v_promo_discount + v_shipping
  where id = v_inquiry.id;

  perform public.shop_session_touch(p_session);
  return jsonb_build_object('number', v_inquiry.number);
end;
$$;

revoke all on function public.shop_submit_whatsapp_inquiry(uuid, text, text) from public;
grant execute on function public.shop_submit_whatsapp_inquiry(uuid, text, text) to anon, authenticated, service_role;

-- Dodavanje u košaricu se više ne bilježi. Dosad zapisani retci se brišu.
delete from public.product_events where event = 'cart_add';

commit;
