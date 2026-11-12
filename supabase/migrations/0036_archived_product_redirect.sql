-- Preusmjerenje (301) za arhivirane proizvode, da se ne gubi pozicija na Googleu.
-- Kupci ne čitaju arhivirane proizvode, pa ova funkcija vraća samo kamo voditi: slug glavne kategorije
-- (ako je aktivna) ili null za /proizvodi. Za skriven, ali nearhiviran proizvod vraća 'not_archived',
-- jer se on može vratiti, pa ostaje 404 bez preusmjerenja. Za nepoznat slug vraća 'unknown'.
-- Ne otkriva ništa drugo o proizvodu.
begin;

create function public.shop_product_redirect(p_color_slug text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (
      select case
        when p.archived_at is null then jsonb_build_object('status', 'not_archived')
        else jsonb_build_object(
          'status', 'archived',
          'category_slug', (select c.slug from public.categories c where c.id = p.category_id and public.category_is_active(c.id))
        )
      end
      from public.product_colors pc
      join public.products p on p.id = pc.product_id
      where pc.slug = p_color_slug
    ),
    jsonb_build_object('status', 'unknown')
  );
$$;

revoke all on function public.shop_product_redirect(text) from public;
grant execute on function public.shop_product_redirect(text) to anon, authenticated, service_role;

commit;
