-- Prijedlog SEO tekstova za glavne kategorije (traži migraciju 0031).
-- Upisuje samo u kategorije s tim URL nazivom (slug); ostale preskače. Sve se poslije može mijenjati u adminu.
-- {godina} web mijenja u godinu sljedeće mature.
-- Ključne riječi su iz Googleovih prijedloga pretrage za BiH i Hrvatsku (studeni 2026.).
begin;

-- Haljine: svečane haljine, haljine za svadbu, večernje i duge haljine.
update public.categories set
  meta_title = 'Svečane haljine Mostar | Haljine za svadbu i maturu',
  meta_description = 'Svečane, večernje i duge haljine za svadbu, maturu i obiteljske proslave. Pogledajte online ili nas posjetite u Mepas Mallu u Mostaru.',
  seo_text = $t$## Svečane haljine za svaku priliku
Tražite haljinu za svadbu, maturu ili obiteljsku proslavu? U našoj ponudi su svečane i večernje haljine, od dugih modela za velike večeri do kraćih haljina za manje proslave.

## Haljine za svadbu kao gost
Za svadbu biramo haljine koje su elegantne, a ugodne za cijelu večer. Uz haljinu možete odmah odabrati cipele na petu i torbicu.

## Haljine za mame
Imamo i svečane haljine za mame za pričest, krizmu, krštenje i vjenčanje djece.

## Pogledajte uživo u Mostaru
Sve modele možete pogledati i isprobati u našoj trgovini u Mepas Mallu u Mostaru. Online narudžbe šaljemo na adrese u BiH, uz plaćanje pouzećem.$t$,
  faq = jsonb_build_array(
    jsonb_build_object('question', 'Mogu li haljinu isprobati prije kupnje?', 'answer', 'Da, modele možete isprobati u našoj trgovini u Mepas Mallu u Mostaru.'),
    jsonb_build_object('question', 'Imate li haljine za mame za pričest, krizmu i krštenje?', 'answer', 'Da, u ponudi su svečane haljine za mame za obiteljske proslave.'),
    jsonb_build_object('question', 'Kako se plaća online narudžba?', 'answer', 'Pouzećem, kuriru pri preuzimanju paketa. Dostava traje 3 do 5 dana, samo unutar BiH.'),
    jsonb_build_object('question', 'Mogu li zamijeniti haljinu?', 'answer', 'Da, u roku od 15 dana, ako haljina nema tragova nošenja.')
  )
where slug in ('haljine', 'svecane-haljine');

-- Maturalne haljine: velika i mala matura, s godinom.
update public.categories set
  meta_title = 'Maturalne haljine {godina} | Mostar, Mepas Mall',
  meta_description = 'Maturalne haljine {godina} za veliku i malu maturu: duge i kratke svečane haljine. Pogledajte online ili isprobajte u Mepas Mallu u Mostaru.',
  seo_text = $t$## Maturalne haljine {godina}
Matura je jedna od najvažnijih večeri, zato u ponudi imamo maturalne haljine za veliku i malu maturu: duge haljine za svečanu večer i kraće modele za one koje žele nešto lakše.

## Kako odabrati haljinu za maturu
Haljinu je dobro birati na vrijeme, kako bi ostalo dovoljno vremena za cipele i dodatke. Ponesite cipele u kojima ćete biti na maturi ili ih odaberite kod nas, kako biste vidjeli pravu duljinu haljine.

## Cipele i torbica uz haljinu
Uz maturalnu haljinu kod nas možete odabrati cipele na petu ili sandale za maturu i svečanu torbicu.

## Isprobajte u Mostaru
Maturalne haljine možete isprobati u trgovini u Mepas Mallu u Mostaru, a online narudžbe šaljemo na adrese u BiH.$t$,
  faq = jsonb_build_array(
    jsonb_build_object('question', 'Imate li haljine za malu maturu?', 'answer', 'Da, u ponudi su haljine za veliku i za malu maturu.'),
    jsonb_build_object('question', 'Mogu li isprobati maturalnu haljinu?', 'answer', 'Da, u našoj trgovini u Mepas Mallu u Mostaru.'),
    jsonb_build_object('question', 'Kako se plaća u trgovini?', 'answer', 'Gotovinom u KM ili karticom.'),
    jsonb_build_object('question', 'Šaljete li maturalne haljine poštom?', 'answer', 'Da, na adrese u BiH, uz plaćanje pouzećem. Dostava traje 3 do 5 dana.')
  )
where slug = 'maturalne-haljine';

-- Obuća: svečane cipele, salonke na petu, cipele i sandale za maturu.
update public.categories set
  meta_title = 'Svečane cipele ženske | Salonke na petu, Mostar',
  meta_description = 'Svečane ženske cipele, salonke na petu i sandale za maturu i svadbu. Pogledajte online ili nas posjetite u Mepas Mallu u Mostaru.',
  seo_text = $t$## Svečane cipele i salonke na petu
Uz svečanu haljinu najčešće se biraju salonke na petu ili elegantne sandale. U ponudi su modeli s visokom, srednjom i niskom petom, pa svaka može naći udobnu visinu za cijelu večer.

## Cipele i sandale za maturu i svadbu
Ako cipele birate uz haljinu, dođite s haljinom ili je odaberite kod nas, jer visina pete mijenja duljinu haljine.

Online narudžbe šaljemo na adrese u BiH, a zamjena je moguća u roku od 15 dana za obuću bez tragova nošenja.$t$,
  faq = jsonb_build_array(
    jsonb_build_object('question', 'Kako odabrati visinu pete?', 'answer', 'U filteru možete birati ravne, niske, srednje i visoke pete. Za cijelu večer mnoge biraju srednju petu.'),
    jsonb_build_object('question', 'Mogu li zamijeniti cipele ako mi ne odgovara broj?', 'answer', 'Da, u roku od 15 dana, ako cipele nemaju tragova nošenja.')
  )
where slug = 'obuca';

-- Torbice: svečane torbice i clutch torbice.
update public.categories set
  meta_title = 'Svečane torbice i clutch torbice | Mostar',
  meta_description = 'Svečane torbice i clutch torbice uz haljinu za svadbu, maturu i večernje izlaske. Pogledajte online ili u Mepas Mallu u Mostaru.',
  seo_text = $t$## Svečane torbice uz haljinu
Mala svečana torbica ili clutch zaokružuje izgled uz večernju i maturalnu haljinu. Birajte torbicu u boji cipela ili kao naglasak, a za večer stane sve što treba: mobitel, ključevi i ruž.

Torbice možete pogledati online ili u našoj trgovini u Mepas Mallu u Mostaru, zajedno s haljinom i cipelama.$t$,
  faq = jsonb_build_array(
    jsonb_build_object('question', 'Kako odabrati torbicu uz haljinu?', 'answer', 'Najsigurnije je uskladiti je s cipelama ili odabrati zlatnu, srebrnu ili crnu torbicu koja ide uz više haljina.')
  )
where slug = 'torbice';

-- Dodaci: nakit od nehrđajućeg čelika.
update public.categories set
  meta_title = 'Nakit od nehrđajućeg čelika i dodaci | Mostar',
  meta_description = 'Nakit od nehrđajućeg čelika i modni dodaci uz svečanu haljinu. Pogledajte online ili u Mepas Mallu u Mostaru.',
  seo_text = $t$## Nakit od nehrđajućeg čelika
Naš nakit izrađen je od nehrđajućeg čelika. Uz svečanu haljinu birajte naušnice ili ogrlicu koje prate izrez i boju haljine.

Dodatke možete pogledati online ili u trgovini u Mepas Mallu u Mostaru i odmah ih isprobati uz haljinu.$t$,
  faq = jsonb_build_array(
    jsonb_build_object('question', 'Od čega je nakit?', 'answer', 'Nakit u našoj ponudi izrađen je od nehrđajućeg čelika.')
  )
where slug = 'dodaci';

-- Kaputi i jakne.
update public.categories set
  meta_title = 'Elegantni kaputi za žene | Mostar',
  meta_description = 'Elegantni ženski kaputi i jakne, i preko svečane haljine. Pogledajte online ili u Mepas Mallu u Mostaru.',
  seo_text = $t$## Elegantni kaputi za žene
Zimi je kaput dio svečanog izgleda. U ponudi su elegantni ženski kaputi i jakne koji se nose i uz svakodnevnu odjeću i preko svečane haljine.

Kapute možete isprobati u našoj trgovini u Mepas Mallu u Mostaru, a online narudžbe šaljemo na adrese u BiH.$t$
where slug = 'kaputi';

-- Kompleti i sakoi: ženska odijela.
update public.categories set
  meta_title = 'Ženska odijela i sakoi | Svečano i za posao, Mostar',
  meta_description = 'Ženska odijela, sakoi i kompleti za posao, svadbu i svečane prilike. Pogledajte online ili u Mepas Mallu u Mostaru.',
  seo_text = $t$## Ženska odijela i sakoi
Žensko odijelo elegantna je zamjena za haljinu, za svadbu, svečanu priliku ili posao. U ponudi su kompleti od sakoa i hlača te sakoi koji se mogu nositi i zasebno.

Odijela možete isprobati u našoj trgovini u Mepas Mallu u Mostaru.$t$
where slug = 'kompleti-i-sakoi';

commit;
