-- Jednokratna provjera i čišćenje bot prijava na newsletter (namjerno nije u migrations/).
-- Pokreći dio po dio u Supabase SQL editoru. Prvo 1 i 2, tek onda 3.

-- 1. Prijave po danu: nagli skok = botovi.
select (created_at at time zone 'Europe/Sarajevo')::date as dan, count(*)
from public.newsletter_subscribers
group by 1 order by 1 desc limit 60;

-- 2. Sumnjive adrese (isto pravilo kao migracija 0050) i je li im kod iskorišten u narudžbi.
select s.email, s.created_at, pc.code, pc.used_count
from public.newsletter_subscribers s
left join public.promo_codes pc on pc.subscriber_id = s.id
where split_part(s.email, '@', 2) in (
    'vtext.com', 'vzwpix.com', 'txt.att.net', 'mms.att.net', 'tmomail.net',
    'messaging.sprintpcs.com', 'pm.sprint.com', 'msg.fi.google.com',
    'sms.myboostmobile.com', 'mymetropcs.com', 'email.uscc.net', 'vmobl.com'
  )
  or (
    split_part(s.email, '@', 2) in ('gmail.com', 'googlemail.com')
    and length(split_part(split_part(s.email, '@', 1), '+', 1))
      - length(replace(split_part(split_part(s.email, '@', 1), '+', 1), '.', '')) >= 3
  )
order by s.created_at desc;

-- 3. Brisanje istih adresa. Njihovi neiskorišteni kodovi brišu se sami (on delete cascade),
--    a narudžba s već iskorištenim kodom ostaje i pamti kod i popust.
-- delete from public.newsletter_subscribers s
-- where split_part(s.email, '@', 2) in (
--     'vtext.com', 'vzwpix.com', 'txt.att.net', 'mms.att.net', 'tmomail.net',
--     'messaging.sprintpcs.com', 'pm.sprint.com', 'msg.fi.google.com',
--     'sms.myboostmobile.com', 'mymetropcs.com', 'email.uscc.net', 'vmobl.com'
--   )
--   or (
--     split_part(s.email, '@', 2) in ('gmail.com', 'googlemail.com')
--     and length(split_part(split_part(s.email, '@', 1), '+', 1))
--       - length(replace(split_part(split_part(s.email, '@', 1), '+', 1), '.', '')) >= 3
--   );
