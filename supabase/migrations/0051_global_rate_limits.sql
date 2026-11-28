-- Ukupna ograničenja za cijelu trgovinu, protiv skripti koje šalju lažne narudžbe i prijave na newsletter.
-- Postojeća ograničenja broje po sesiji, a skripta svaki put izmisli novu, pa ovdje broji baza ukupno.
-- Granice su daleko iznad stvarnog prometa butika. Poruka (P0001) ide kupcu kroz shopErrorMessage i /api/newsletter.
begin;

-- Narudžbe (web i WhatsApp): najviše 20 novih u 10 minuta. Osvježavanje iste WhatsApp narudžbe nije nova narudžba.
create or replace function public.inquiries_global_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select count(*) from public.inquiries where created_at > now() - interval '10 minutes') >= 20 then
    raise exception 'Trenutno primamo previše narudžbi. Pokušajte ponovno za nekoliko minuta ili nam se javite telefonom.';
  end if;
  return new;
end;
$$;

revoke all on function public.inquiries_global_limit() from public, anon, authenticated;

drop trigger if exists inquiries_global_limit on public.inquiries;
create trigger inquiries_global_limit
before insert on public.inquiries
for each row execute function public.inquiries_global_limit();

-- Newsletter: najviše 30 novih pretplatnika na sat, pa bot ne može potrošiti kvotu e-mailova.
-- Ponovna prijava odjavljenog nije novi upis i ne broji se.
create or replace function public.newsletter_global_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select count(*) from public.newsletter_subscribers where created_at > now() - interval '1 hour') >= 30 then
    raise exception 'Trenutno je previše prijava. Pokušajte ponovno za sat vremena.';
  end if;
  return new;
end;
$$;

revoke all on function public.newsletter_global_limit() from public, anon, authenticated;

drop trigger if exists newsletter_global_limit on public.newsletter_subscribers;
create trigger newsletter_global_limit
before insert on public.newsletter_subscribers
for each row execute function public.newsletter_global_limit();

commit;
