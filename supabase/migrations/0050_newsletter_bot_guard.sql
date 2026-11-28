-- Zaštita newslettera od botova koji upisuju tuđe adrese ("subscription bombing").
-- Isto pravilo ima shared/utils/newsletterGuard.ts (forma i /api/newsletter): bez SMS adresa
-- i bez Gmail adresa s 3 ili više točkica (Gmail ih zanemaruje, pa botovi njima zaobilaze provjeru iste adrese).
-- "not valid": postojeći redovi se ne provjeravaju, pravilo vrijedi za sve nove upise.
begin;

alter table public.newsletter_subscribers
  drop constraint if exists newsletter_email_ok;

alter table public.newsletter_subscribers
  add constraint newsletter_email_ok check (
    email ~* '^[^[:space:]@]+@[^[:space:]@]+\.[a-z]{2,}$'
    and split_part(email, '@', 2) not in (
      'vtext.com', 'vzwpix.com', 'txt.att.net', 'mms.att.net', 'tmomail.net',
      'messaging.sprintpcs.com', 'pm.sprint.com', 'msg.fi.google.com',
      'sms.myboostmobile.com', 'mymetropcs.com', 'email.uscc.net', 'vmobl.com'
    )
    and not (
      split_part(email, '@', 2) in ('gmail.com', 'googlemail.com')
      and length(split_part(split_part(email, '@', 1), '+', 1))
        - length(replace(split_part(split_part(email, '@', 1), '+', 1), '.', '')) >= 3
    )
  ) not valid;

commit;
