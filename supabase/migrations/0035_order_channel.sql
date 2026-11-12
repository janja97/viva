-- Način narudžbe (/admin/postavke, kartica Narudžbe):
--   'whatsapp': gumb u košarici otvara WhatsApp s gotovom porukom (proizvodi, veličine, poveznice, napomena)
--               na broj iz store_settings.whatsapp. Upit se tada ne sprema u bazu.
--   'web':      dosadašnji obrazac i upit (shop_submit_inquiry, /admin/narudzbe).
-- Zadano je WhatsApp, jer se zasad tako naručuje. Bez upisanog WhatsApp broja web sam koristi obrazac.
-- RLS ostaje kao u migraciji 0029: svi čitaju, mijenjaju samo super_admin i admin.
begin;

alter table public.store_settings
  add column order_channel text not null default 'whatsapp' check (order_channel in ('whatsapp', 'web'));

commit;
