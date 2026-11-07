-- Narudžbe smije brisati samo super admin. Administrator i dalje mijenja status.
begin;

drop policy inquiries_delete on public.inquiries;

create policy inquiries_delete on public.inquiries
for delete to authenticated
using ((select public.current_user_role()) = 'super_admin');

commit;
