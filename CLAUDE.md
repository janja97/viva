# Viva2 – web shop

## Stalna pravila
- Odgovaraj na hrvatskom jeziku.
- Sve mora biti responzivno (mobitel prvo) i SEO optimizirano.
- Radi u malim komponentama, organizirano po zadnjim standardima.
- Vue (Nuxt 4), npm, Supabase kao baza i prijava, kod ide na git, hosting na Netlifyju.
- Svaki SQL i RLS daj korisniku kao gotov upit za zaljepljivanje u Supabase SQL editor i spremi ga u `supabase/migrations/`. Claude nema pristup bazi za pisanje.
- Svaka nova tablica mora imati RLS pravila za sve tri uloge.
- Commit i push samo kad korisnik to zatraži.
- Ovaj projekt ima vlastiti git repozitorij. Git root `C:\Users\janja` (remote `janja97/vibe`) se ne koristi.
- Održavaj ovu datoteku ažurnom nakon svake veće promjene.

## Uloge
| Uloga | Prava |
|---|---|
| `super_admin` | sve |
| `admin` | sve osim brisanja korisnika; ne smije dirati super admine ni dodijeliti tu ulogu |
| `viewer` | samo čitanje |

- Uloge su u tablici `public.user_roles`. Korisnik bez retka (npr. kupac) nema pristup adminu.
- Za RLS novih tablica koristi `public.current_user_role()`.
- Prava provjerava RLS u bazi. `app/config/roles.ts` i `usePermissions().can()` služe samo za prikaz.
- Blokiranje računa smije samo `super_admin`, kroz `server/api/admin/users/[id].patch.ts` (migracija `0008`). Podatak je `banned_until` u `auth.users`, a `current_user_role()` blokiranom vraća `null`, pa odmah gubi prava. `useAuth` ulogu čita tom funkcijom.
- Nitko ne mijenja vlastitu ulogu kroz sučelje ni ne briše ili blokira vlastiti račun. Zadnjeg super admina čuva okidač u bazi.

## Tajni ključ i server rute
- Stvaranje i brisanje računa traže tajni Supabase ključ pa idu kroz `server/api/admin/users/`.
- Ključ je `NUXT_SUPABASE_SECRET_KEY`, u `runtimeConfig.supabaseSecretKey`. Nikad u `public`, git ni chat.
- Tajni ključ zaobilazi RLS. Svaka server ruta mora prvo pozvati `requireRole()` iz `server/utils/adminAuth.ts` i sama provesti pravila uloga.
- Sve što RLS može sam čuvati ide izravno iz preglednika (npr. promjena uloge), ne kroz server.

## Admin stil (uvijek ga se drži)
- Isti stil kao trgovina: bjelokost, bež, šampanjac i zlatna, tamni gumbi, bez zaobljenih kutova, sjena i gradijenata (`--radius-*` i `--shadow-*` u `main.css` su ugašeni; okrugli elementi koriste `rounded-full`).
- Izbornik je `primary-100`, bijele kartice su na `primary-50` podlozi, a linije i rubovi `primary-300`.
- Boje su `primary-*` tokeni u `app/assets/css/main.css`. Za novu boju mijenjaj samo njih. Bijeli tekst ide samo na `primary-600` ili `primary-700`, odnosno `primary-950`.
- Neutralni tekst je `stone`. Dodatne boje: `amber` za upozorenja, `emerald` za uspjeh, `red` za greške i brisanje. Pregled Google rezultata u `ProductSeoCard` ostaje plav jer oponaša Google.
- Boje uloga su u `RoleBadge`: super admin tamna, administrator šampanjac, čitatelj bijela s rubom.
- Kartice `border border-primary-300 bg-white` (`AdminCard`).
- Tekst je Jost (`font-admin`), a naslovi Cormorant Garamond (`font-display`): stranica `text-4xl`, kartica `text-2xl`, oba `font-normal`. Tekst `text-sm`, sporedni tekst `text-stone-500`.
- Ikone iz `@lucide/vue`, `size-4`, `stroke-width="1.75"`.
- Mobitel: dodirne površine najmanje 44px (`min-h-11`, od `sm:` može gušće).
- Svaka admin stranica počinje s `AdminPageHeader`. Forme koriste `Base*` komponente i `form-field`, dijalozi `BaseModal` i `ConfirmDialog`.
- Izbornik: grupe odvojene crtom (`ADMIN_NAV_GROUPS`), a Postavke, Moj račun i Korisnici stoje na dnu (`ADMIN_NAV_BOTTOM`).

## Javni stil: luksuzna svečana moda (uvijek ga se drži)
- Trgovina se zove Viva: luksuzna svečana roba u Mepas Mallu u Mostaru. Glavna ciljana skupina su mature; ključni pojmovi su svečane, elegantne i maturalne haljine, odijela i cipele. Proizvodi nemaju marku, pa Product JSON-LD nema `brand`.
- Sadržaj naslovne je u `config/home.ts`, a kategorije za naslovnu u migraciji `0006`.
- Ponuda je samo za žene: svečane i lagane haljine, zimi kaputi, uz cipele, torbice i dodatke. Muških odijela nema, pa se nigdje ne spominju. Kategorija `poslovno` je isključena (migracija `0014`). Izbornik (`SHOP_NAV`): Haljine, Odjeća (sve ostalo, s podkategorijama), Obuća, Torbice, Dodaci, Novo i Popust (`/proizvodi?snizeno=1`); poveznice i aktivnu stavku daje `useShopNavLink`. Na mobitelu nema trake s gumbima, sve je u izborniku ☰. Na heroju su Kaputi (`kaputi`), a prva kartica u `HOME_PANELS` je sezonska (zimi kaputi, ljeti npr. lagane haljine ili sandale, primjer je u komentaru).
- Naslovna ima galeriju svečanih haljina (`HomeLookbook`, `HOME_LOOKBOOK`, 15 fotografija, velike su indeksi u `LOOKBOOK_LARGE` kako bi 4 stupca bila puna) i mjesto za video (`HomeVideo`, `HOME_VIDEO`). Dok se ne upiše putanja slike ili videa, prikazuje se obojena podloga.
- Fotografije za naslovnu: originali su u `public/homePage/`, a stranica koristi smanjene kopije u `public/images/home/` (kategorije 600 × 800, galerija 600 × 800 i 900 × 1200, JPG kvalitete 82, izrez 3 : 4 uz desni rub da logo VIVA ostane cijeli).
- Boje su bež, siva i zlatna, bez roze i bordo: `ivory`, `sand` i `champagne` podloge, `photo` i `photo-dark` iza fotografija, `graphite` za tamne gumbe i traku, `ink` tekst, `gold` i `gold-light` kao detalji, `line` za crte, `muted` za sporedni tekst.
- Dizajn prati PDF predložak VIVA Boutique: bez zaobljenih kutova, sjena i gradijenata (iznimka su okrugli uzorci boja). Naslovna je u `components/site/Home*.vue`, a sav njezin tekst i putanje fotografija u `config/home.ts`. Izbornik je `SHOP_NAV`; `useCategoryLink` vodi na `/proizvodi` dok kategorija ne postoji (migracija `0009`).
- Newsletter ne sprema adrese. Online plaćanja nema: kupac iz košarice šalje upit. Ikona košarice i dodavanje u košaricu otvaraju brzi pregled s desne strane (`CartDrawer`, "Naruči" vodi na `/kosarica`, "Nastavi s kupnjom" samo zatvara). Na `/kosarica` gumb "Naruči" otvara prozor s podacima za dostavu (ime, telefon, adresa, poštanski broj, grad, e-mail, napomena), a zadnji gumb je "Pošalji upit".
- Poštarina je 9 KM, a besplatna za narudžbe veće od 150 KM (`SHIPPING` u `config/store.ts` i isto pravilo u `shop_submit_inquiry`, migracija `0019`). Upit sprema `subtotal`, `shipping` i `total`. Na webu i u adminu oni se zovu "Ukupno", "Poštarina" i "Sveukupno" (ne "Međuzbroj").
- Trgovina nema rezervaciju probe ni termine: kupci mogu doći kad god žele. Ne dodavaj gumbe ni tekstove o rezervaciji.
- Naslovi `font-display` (Cormorant Garamond), tekst `font-body` (Jost). Svaki font mora uredno prikazivati č, ć, đ, š i ž.
- Logo: izvor je `public/logo/logo.png` (crna podloga). `logo/logo-dark.png` je tamnozlatna prozirna verzija za svijetle podloge (navigacija, footer, admin), a `logo/logo-gold.png` za tamne. Ikone (`favicon.ico`, `favicon-*.png`, `apple-touch-icon.png`) i `logo/logo-square.png` nastale su iz njega. Logo je i u footeru i u `AppLogo` (admin i prijava). `logo/og-image.png` je zadana slika za dijeljenje linka u `usePageSeo`, a `server/routes/site.webmanifest.ts` daje ikone za mobitel.
- Puno praznog prostora. Komponente su u `components/site/`.
- Filtri i sortiranje: `ShopListing`, `ShopFilterPanel` (stalno sa strane i sticky na računalu, u modalu na mobitelu) i `ShopActiveFilters` na `/proizvodi` i `/kategorija/[slug]`, RPC `shop_cards` i `shop_filter_options` (migracije `0011` i `0012`). Stanje je u adresi (`useShopFilters`), a filtrirane stranice imaju noindex. Kategorija prikazuje proizvode iz svih razina ispod sebe.
- Pretraga: `/pretraga?q=`, `useShop().searchCards` traži po slugu pa radi i bez naših slova. Stranica ima noindex.
- Podaci o trgovini su u `config/store.ts`. Ne izmišljaj telefon, radno vrijeme ni tvrdnje o proizvodima. Radno vrijeme je i u `STORE.openingHours` (za ClothingStore JSON-LD), pa ga mijenjaj zajedno s `hours`.
- Canonical (`usePageSeo`) je putanja bez parametara, osim `?stranica=N` na popisima. Product JSON-LD ima `shippingDetails` po pravilu `shippingFor`, osim za `store_only`. Putanja (breadcrumbs) na stranici proizvoda ista je kao u JSON-LD-u.
- Sekcija "Posjetite nas" (`HomeVisit`) prikazuje Google kartu (`STORE.mapEmbedUrl`, bez API ključa, prigušene boje), na računalu lijevo od adrese, a na mobitelu ispod nje.

## Gdje je što
- `nuxt.config.ts`: SSR pravila (`/admin/**` bez SSR-a i uz noindex).
- `app/config/navigation.ts`: javna i admin navigacija, popis admin ruta bez prijave.
- `app/config/roles.ts`: uloge, opisi, ovlasti i koje uloge tko smije dodijeliti.
- `app/middleware/admin.global.ts`: štiti sve pod `/admin` automatski.
- `app/composables/`: `useAuth`, `usePermissions`, `usePageSeo`, `useSupabase`, `useCategories`, `useTeamMembers`.
- `app/layouts/`: `default` (javni), `admin`, `auth` (prijava).
- `app/components/`: `ui/`, `site/`, `auth/`, `admin/` (s podmapama `categories/`, `users/`, `account/`). Komponente se koriste samo po imenu datoteke.
- `app/types/database.ts`: tipovi baze, proširi ih uz svaku novu tablicu. Koristi `type`, ne `interface`, inače Supabase tipovi postanu `never`.
- `server/routes/`: `sitemap.xml`, `robots.txt`. `server/api/admin/`: rute s tajnim ključem.
- `supabase/`: SQL migracije i `seed_super_admin.sql`.

## Pravila za novu stranicu
1. Dodaj datoteku u `app/pages/` i pozovi `usePageSeo({ title, description })`.
2. Dodaj je u `app/config/navigation.ts` ako treba biti u izborniku.
3. Javna stranica sa sadržajem ide u `ROUTES` u `server/routes/sitemap.xml.ts`.
4. Stranice "u izradi" imaju `noindex` i nisu u sitemapu. Makni `noindex` kad dobiju sadržaj.

## Env varijable
Javne imaju prefiks `NUXT_PUBLIC_`, ne `NEXT_PUBLIC_`. Popis je u `.env.example`. Iste moraju biti i na Netlifyju.

## Trenutno stanje (2026-11-02)
- Gotovo: početna (prazna), navigacija, footer, admin prijava, zaboravljena i nova lozinka, dashboard, zaštita ruta, SEO osnove, Netlify konfiguracija.
- Kategorije: `/admin/kategorije`, migracija `0002`. Najviše tri razine (`parent_id`, migracija `0011`), globalno jedinstven `slug`, redoslijed strelicama. Baza čuva pravilo tri razine i gasi sve ispod isključene kategorije. Pomoćne funkcije su u `utils/categoryTree.ts`. Uključivanje glavne ne uključuje podkategorije natrag.
- Korisnici: `/admin/korisnici`, migracija `0003` (`list_team_members`). Administrator zadaje privremenu lozinku i prosljeđuje je ručno, jer Supabaseov zadani e-mail ne šalje tuđim adresama bez vlastitog SMTP-a. Promjena lozinke se zasad ne iznuđuje pri prvoj prijavi.
- Moj račun: `/admin/moj-racun`, promjena lozinke uz provjeru trenutne.
- Proizvodi (admin gotov): `/admin/proizvodi`, `novi`, `[id]`, migracija `0004`, `components/admin/products/`, `useProducts`, `useProductImages`. Model: proizvod (šifra, cijena) > boja (slike, `slug`) > veličina (količina). Spremanje ide kroz RPC `save_product` u jednoj transakciji. Slike su u javnom spremištu `product-images` (5 MB) i brišu se tek nakon uspješnog spremanja.
- Boje se biraju samo s popisa `PRODUCT_COLORS` (`config/products.ts`), bez birača nijanse. "Šareno" je multicolor i prikazuje se kroz `ColorSwatch`, koji treba koristiti i u javnom dijelu.
- Proizvod može biti u više kategorija (migracija `0007`). `products.category_id` je najdublja odabrana kategorija (`ProductCategoryPicker`: izbornici redom po razinama, putanja, SEO), a proizvod se sam prikazuje i na nadređenim stranicama. Dodatne kategorije su u zatvorenom dijelu forme (`ProductExtraCategories`). Tablica `product_categories` sadrži glavnu i dodatne i koristi se za filtriranje. Spremanje ide kroz RPC `save_product_with_categories`. Glavnu kategoriju u upitu uvijek dohvaćaj kao `categories!products_category_id_fkey(...)`, jer samo `categories(...)` baza odbija (PGRST201).
- Slug boje je `naziv-boja-sifra` i sam se stvara dok ga korisnik ne promijeni. Spremljeni slugovi se ne mijenjaju sami.
- Shop je iz Mostara, tržište je BiH, a tekstovi su na hrvatskom. Oznaka jezika je `hr-BA` (`og:locale` je `hr_BA`).
- Valuta je KM (`formatPrice`, za Google `CURRENCY_CODE` = BAM). Nikad ne prikazuj cijene u eurima.
- Količine se mogu mijenjati i s popisa proizvoda (`ProductStockModal`, RPC `adjust_product_stock`, migracija `0010`). RPC prima razliku, a ne novu količinu, i upisuje u povijest akciju `stock` s detaljima po boji i veličini.
- Arhiva proizvoda (migracija `0015`): proizvod se ne briše nego arhivira (`products.archived_at`, RPC `archive_product`). Arhiviran je skriven s weba (baza ne dopušta `is_visible`), nije na popisu "Aktivni" i ne uređuje se; ostaje samo prva slika, a RPC vraća putanje ostalih koje aplikacija briše iz spremišta. Vraćanje iz arhive ostavlja proizvod skrivenim. Trajno brisanje dopušta RLS samo za arhivirane. Stavke upita čuvaju vlastitu kopiju naziva, šifre, boje, veličine i cijene, pa statistika ne ovisi o proizvodu.
- Admin popis proizvoda (migracija `0017`): filtriranje i redoslijed radi RPC `admin_products` (vraća id-eve stranice i ukupan broj), a ponuđene vrijednosti `admin_product_filter_options`. Veličine i boje nude se samo za odabranu arhivu, kategoriju (s podkategorijama) i vrstu, pa obuća ne nudi veličine odjeće. Filtri su u adresi (`useAdminProductFilters`), komponenta `ProductFilters`. Količina se zbraja samo za odabrane boje i veličine.
- Skupne radnje: odabir kvačicama (i "svi rezultati" do `MAX_BULK_SELECTION`), traka `ProductBulkBar`. Objava, skrivanje, "samo u trgovini" i sniženje idu kroz RPC `bulk_update_products` (objavljuje samo proizvode sa slikom za svaku boju), arhiviranje kroz `archive_products`, a vraćanje i trajno brisanje izravno kroz RLS.
- Povijest proizvoda: migracija `0005`, `product_audit_log` puni okidač pri upisu, izmjeni i brisanju, zapis ostaje i nakon brisanja. Prikaz na stranici proizvoda i na `/admin/proizvodi/povijest`.
- SEO proizvoda: naslov i opis stvaraju se po boji u `utils/productSeo.ts`. Javna stranica mora koristiti iste funkcije. `meta_*` stupci su neobavezni ručni unos.
- Javni dio (prva verzija): početna, `/proizvodi`, `/kategorija/[slug]`, `/proizvod/[slug]`, kontakt, o nama, sitemap iz baze. Podaci kroz `useShop` (SSR). Slike još nisu prilagođene veličini.
- Dogovor za javni dio shopa: svaka boja je zasebna kartica i ima svoj URL `/proizvod/{slug}`; na stranici se boja može promijeniti; rasprodana veličina je prekrižena; potpuno rasprodana boja ostaje vidljiva s oznakom "Rasprodano"; `store_only` prikazuje "Dostupno samo u poslovnicama" i ne može se kupiti; `is_visible=false` kupci ne vide; prikazati sastav materijala. Kod sniženja se prikazuju samo stara prekrižena i nova istaknuta cijena, a najniža cijena iz 30 dana se po želji korisnika ne prikazuje. Treba paziti i na neaktivne kategorije. Dodati Product JSON-LD, sitemap po boji, prilagođene slike.
- Sniženje se upisuje kao postotak `products.discount_percent` (1 do 99, migracija `0013`). `sale_price` je stupac koji računa baza i ne upisuje se. `product_price_history` pamti cijenu koju kupac plaća, ali se ne prikazuje. Duljina haljine i visina pete su `dress_length` i `heel_height`, popisi u `config/products.ts`; duljina se sprema samo za odjeću, a peta samo za obuću.
- Isključena kategorija skriva s weba sve proizvode kojima je glavna (migracija `0021`, `category_is_active()` u svim `shop_*` funkcijama, `categories.is_active` u `useShop` i sitemapu). Tako se skriva sezona, a `is_visible` proizvoda se ne dira. Dodatna kategorija ne skriva proizvod. Lista želja ih čuva, a košarica ih uklanja.
- Stranica Popusti je i dalje prazna. Sniženje se upisuje na samom proizvodu.
- Barkod je zasad namjerno izostavljen.
- Brend je interni i neobavezan podatak (migracija `0016`). Nalazi se u tablici `product_internal`, koju vide samo članovi tima, a ne u `products`, jer bi ga kupci inače mogli pročitati preko API-ja. Sprema se kroz `save_product_with_categories`, prijedlozi dolaze iz RPC-a `product_brands`. Nikad ga ne prikazuj u javnom dijelu ni u JSON-LD-u. Tu tablicu koristi i za buduće interne podatke (npr. nabavna cijena, dobavljač).
- U izradi (prazno): popusti, postavke.
- Dashboard kartice prikazuju "—" dok ne nastanu tablice.
- Naziv "Viva" je privremen (`NUXT_PUBLIC_SITE_NAME`).
- Lokalni Node je 22.18.0, a Nuxt traži 22.22.3+ ili 24.15+. Netlify koristi Node 24.
- Košarica, lista želja i upiti (migracija `0018`): kupci se ne prijavljuju. `useShopSession` stvara nasumičan id sesije u `localStorage`, a tablicama `shop_sessions`, `cart_items` i `wishlist_items` kupci pristupaju samo kroz `security definer` funkcije `shop_cart`, `shop_cart_update`, `shop_wishlist`, `shop_wishlist_set` i `shop_submit_inquiry`, koje same provjeravaju vidljivost, `store_only` i količine. Sesija se briše nakon 7 dana bez izmjene (pg_cron posao `ciscenje-kosarica` i provjera pri svakom pristupu). Upit (`inquiries`, `inquiry_items`) ostaje trajno, s kopijom stavki, i ne mijenja zalihu. Tim ih vidi kao narudžbe na `/admin/narudzbe`, a status mijenjaju i brišu ih samo admin i super admin (kroz aplikaciju se smije mijenjati samo stupac `status`).
- Javne stranice `/kosarica` i `/lista-zelja` imaju noindex i nisu u sitemapu. Kupnja na stranici proizvoda je u `ProductPurchase`, a ikone s brojem stavki u `SiteHeader`. Poruke grešaka za kupce idu kroz `shopErrorMessage`.
- Statusi narudžbe (migracija `0020`): Novo (`new`), U obradi (`in_progress`), Prodano (`sold`) i Otkazano (`cancelled`), nazivi u `INQUIRY_STATUSES`. Svaku promjenu statusa i brisanje bilježi okidač u `inquiry_audit_log` (tko i kada, ostaje i nakon brisanja), a zadnja promjena je i na samoj narudžbi (`status_changed_at`, `status_changed_by_email`). Povijest se prikazuje u `InquiryHistory`.
- Broj novih narudžbi (`useNewInquiries`) admin osvježava pri promjeni stranice i svake minute. Prikazuje se kao crveni broj uz "Narudžbe" u izborniku (`badge` u `ADMIN_NAV_GROUPS`) i kao crveni oblačić `NewOrdersAlert` u gornjem lijevom kutu trake.
