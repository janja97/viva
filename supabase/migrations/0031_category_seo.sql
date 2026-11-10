-- SEO za kategorije: vlastiti naslov i opis za Google, duži tekst ispod proizvoda i česta pitanja (FAQ).
-- Sve je neobavezno. U tekstu se može upisati {godina}, a web ga mijenja u godinu sljedeće mature.
-- RLS ostaje kao u migraciji 0002: kupci i cijeli tim (super_admin, admin, viewer) čitaju,
-- a dodaju, mijenjaju i brišu samo admin i super admin. Nova polja su javna, jer se prikazuju na webu.
begin;

alter table public.categories
  add column meta_title text check (meta_title is null or char_length(meta_title) between 1 and 70),
  add column meta_description text check (meta_description is null or char_length(meta_description) between 1 and 170),
  add column seo_text text check (seo_text is null or char_length(seo_text) between 1 and 6000),
  -- [{ "question": "...", "answer": "..." }], najviše 12 pitanja.
  add column faq jsonb not null default '[]'::jsonb
    check (jsonb_typeof(faq) = 'array' and jsonb_array_length(faq) <= 12);

commit;
