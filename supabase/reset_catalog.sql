-- JEDNOKRATNO: briše SVE proizvode i SVE kategorije, da se katalog unese ispočetka ručno.
-- Ne pokretati na objavljenom webu s pravim proizvodima. Ovo nije migracija i ne smije u supabase/migrations.
--
-- Što ostaje: narudžbe (stavke čuvaju vlastitu kopiju naziva, boje, veličine i cijene, a veza na proizvod
-- postaje prazna), kampanje, promo kodovi, newsletter, postavke, akcijske stranice, odbrojavanja i blog.
-- Što nestaje uz proizvode: boje, veličine, zapisi slika, dodatne kategorije, interni podaci (brend),
-- povijest cijena te stavke košarica i lista želja.
-- Same datoteke slika u spremištu product-images ne brišu se ovim upitom: Supabase to dopušta samo kroz
-- Storage (Dashboard > Storage > product-images). Zasad u spremištu nema slika proizvoda.
begin;

delete from public.products;

-- Kategorije od najdublje razine prema glavnima (najviše tri razine), jer baza ne dopušta
-- brisanje kategorije koja još ima podkategorije.
delete from public.categories c where not exists (select 1 from public.categories child where child.parent_id = c.id);
delete from public.categories c where not exists (select 1 from public.categories child where child.parent_id = c.id);
delete from public.categories;

-- Po želji obriši i povijest izmjena testnih proizvoda (makni "--" ispred retka):
-- delete from public.product_audit_log;

commit;

-- Provjera: oba broja moraju biti 0.
select (select count(*) from public.products) as proizvoda, (select count(*) from public.categories) as kategorija;
