-- Odjava s newslettera (/odjava).
-- Pretplatnik se ne briše, nego dobiva unsubscribed_at, pa ista adresa ponovnom prijavom ne dobiva novi kod.
-- Odjava ide poveznicom iz e-maila (osobni unsubscribe_token) ili upisom adrese na /odjava (za e-mailove slane kroz BCC).
-- Obje funkcije uvijek vraćaju isto, da se ne može provjeriti tko je prijavljen.
begin;

alter table public.newsletter_subscribers
  add column unsubscribe_token uuid not null default gen_random_uuid() unique,
  add column unsubscribed_at timestamptz;

-- Ponovna prijava odjavljene adrese vraća je na popis, ali bez novog koda.
-- Novi pretplatnik dobiva i token za poveznicu za odjavu u e-mailu.
create or replace function public.newsletter_subscribe(p_email text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text := lower(btrim(coalesce(p_email, '')));
  v_subscriber_id uuid;
  v_token uuid;
  v_code text;
  v_ends_at timestamptz := now() + interval '15 days';
begin
  if char_length(v_email) > 200 or v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'Upišite ispravnu e-mail adresu.';
  end if;

  insert into public.newsletter_subscribers (email)
  values (v_email)
  on conflict (email) do nothing
  returning id, unsubscribe_token into v_subscriber_id, v_token;

  if v_subscriber_id is null then
    update public.newsletter_subscribers set unsubscribed_at = null where email = v_email;
    return jsonb_build_object('is_new', false);
  end if;

  loop
    v_code := 'VIVA-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));
    exit when not exists (select 1 from public.promo_codes where code = v_code);
  end loop;

  insert into public.promo_codes (code, kind, discount_percent, ends_at, max_uses, subscriber_id)
  values (v_code, 'newsletter', 10, v_ends_at, 1, v_subscriber_id);

  return jsonb_build_object('is_new', true, 'code', v_code, 'percent', 10, 'expires_at', v_ends_at, 'unsubscribe_token', v_token);
end;
$$;

revoke all on function public.newsletter_subscribe(text) from public, anon, authenticated;
grant execute on function public.newsletter_subscribe(text) to service_role;

-- Odjava poveznicom iz e-maila. Neispravan ili nepoznat token se tiho zanemaruje.
create function public.newsletter_unsubscribe(p_token text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.newsletter_subscribers
  set unsubscribed_at = coalesce(unsubscribed_at, now())
  where unsubscribe_token::text = lower(btrim(coalesce(p_token, '')));
end;
$$;

-- Odjava upisom adrese. Nepoznata adresa se tiho zanemaruje.
create function public.newsletter_unsubscribe_email(p_email text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.newsletter_subscribers
  set unsubscribed_at = coalesce(unsubscribed_at, now())
  where email = lower(btrim(coalesce(p_email, '')));
end;
$$;

revoke all on function public.newsletter_unsubscribe(text), public.newsletter_unsubscribe_email(text) from public;
grant execute on function public.newsletter_unsubscribe(text), public.newsletter_unsubscribe_email(text) to anon, authenticated, service_role;

-- RLS tablice ostaje kao u migraciji 0025: cijeli tim (super_admin, admin, viewer) čita,
-- admin i super admin brišu, a kupci tablici ne pristupaju izravno, nego samo kroz funkcije iznad.

commit;
