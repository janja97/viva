-- JEDNOKRATNO: SEO tekstovi za sve kategorije, nakon istraživanja ključnih riječi (studeni 2026.).
-- Zamjenjuje tekstove iz seed_category_seo.sql. Kupci su iz Mostara i okolice te iz Dalmacije (Split, Dubrovnik).
-- Ključne riječi su iz Googleovih prijedloga pretrage za BiH i Hrvatsku, bez brojeva pretraga.
-- Upisuje samo u kategorije s tim slugom; ostale preskače. Sve se poslije može mijenjati u adminu.
-- {godina} web mijenja u godinu sljedeće mature. Naslov za Google: web sam dodaje "| Viva" na kraj.
-- Samo potvrđene tvrdnje: veličine do 58 ovisno o modelu, isprobavanje u trgovini, dostava samo u BiH,
-- zamjena 15 dana, nakit od nehrđajućeg čelika, poklon bon u iznosu po izboru, plaćanje KM, karticom ili na rate.
begin;

create temporary table seo (slug text primary key, meta_title text, meta_description text, description text, seo_text text, faq jsonb) on commit drop;

insert into seo values
-- HALJINE
('haljine',
 'Svečane haljine Mostar | Za svadbu, maturu i kumu',
 'Svečane, duge i elegantne haljine za svadbu, maturu, kumu i obiteljske proslave, u veličinama do 58. Isprobajte u Mepas Mallu u Mostaru ili naručite po BiH.',
 'Svečane, maturalne i elegantne haljine za svadbu, kumu, maturu i obiteljske proslave, te ležernije haljine za posao.',
 $t$## Svečane haljine u Mostaru
Tražite haljinu za svadbu, maturu, krštenje ili večer koju ćete pamtiti? U našem butiku u Mepas Mallu u Mostaru čekaju vas duge svečane haljine, kraće koktel haljine i elegantne haljine za svaku priliku.

## Haljina za kumu i haljine za svadbu
Za vjenčanje kao gost, za vjenčanu, krsnu ili krizmanu kumu biramo haljine koje su elegantne, a ugodne za cijelu večer. Imamo i svečane haljine za mame, za pričest, krizmu, krštenje i vjenčanje djece.

## I u većim veličinama
Veličine idu do 58, ovisno o modelu, pa elegantne haljine za svadbu pronađu i punije dame. Dostupne veličine vidite na stranici svakog proizvoda.

## Iz Splita, Dubrovnika i cijele Dalmacije
Mnoge kupce iz Dalmacije rado dočekujemo u Mostaru, osobito u sezoni matura i vjenčanja. Haljine možete isprobati u trgovini, a za kupnju veću od 200 KM moguć je povrat PDV-a. Više na stranici [Kupovina u Mostaru](/kupovina-u-mostaru).$t$,
 jsonb_build_array(
   jsonb_build_object('question', 'Mogu li haljinu isprobati prije kupnje?', 'answer', 'Da, u našoj trgovini u Mepas Mallu u Mostaru možete isprobati više modela prije kupnje.'),
   jsonb_build_object('question', 'Koje veličine imate?', 'answer', 'Veličine idu do 58, ovisno o modelu. Dostupne veličine vidite na stranici svakog proizvoda.'),
   jsonb_build_object('question', 'Imate li haljine za kumu i za mame?', 'answer', 'Da, u ponudi su svečane haljine za kumu i za mame za pričest, krizmu, krštenje i vjenčanje.'),
   jsonb_build_object('question', 'Šaljete li haljine u Hrvatsku?', 'answer', 'Ne, online narudžbe zasad šaljemo samo na adrese u BiH. Iz Hrvatske nas posjetite u Mepas Mallu u Mostaru.'),
   jsonb_build_object('question', 'Mogu li zamijeniti haljinu?', 'answer', 'Da, u roku od 15 dana, ako haljina nema tragova nošenja.')
 )),
('svecane-haljine',
 'Svečane haljine Mostar | Duge i kratke večernje haljine',
 'Duge i kratke svečane haljine, večernje i elegantne haljine za svadbu, kumu i proslave. Butik u Mepas Mallu u Mostaru, blizu Splita i Dubrovnika.',
 'Duge i kratke svečane haljine za svadbu, kumu, gala večer i obiteljske proslave.',
 $t$## Duge svečane haljine
Duga svečana haljina prvi je izbor za vjenčanje, gala večer ili maturu. U ponudi su modeli s dugim rukavima, s prorezom, sa šljokicama, perlicama i kristalima, u klasičnim i jačim bojama.

## Kratke svečane haljine
Za manje proslave, krštenje ili svadbu ljeti mnoge biraju kratku svečanu haljinu do koljena. Uz nju idu sandale na petu i mala svečana torbica.

## Pogledajte i isprobajte u Mostaru
Sve modele možete isprobati u našoj trgovini u Mepas Mallu u Mostaru. Veličine idu do 58, ovisno o modelu, a online narudžbe šaljemo na adrese u BiH.$t$,
 jsonb_build_array(
   jsonb_build_object('question', 'Imate li duge svečane haljine s rukavima?', 'answer', 'Da, u ponudi su i duge svečane haljine s dugim rukavima. Dostupne modele vidite na ovoj stranici.'),
   jsonb_build_object('question', 'Radite li skraćivanje haljina?', 'answer', 'Ne, skraćivanje i prepravke ne radimo. Zato preporučujemo da u trgovini isprobate više modela.')
 )),
('maturalne-haljine',
 'Maturalne haljine {godina} | Velika i mala matura, Mostar',
 'Maturalne haljine {godina} za veliku i malu maturu: duge i kratke modele isprobajte u Mepas Mallu u Mostaru. Kupci nam dolaze i iz Splita i Dubrovnika.',
 'Maturalne haljine {godina} za veliku i malu maturu, duge i kratke, uz cipele i torbicu.',
 $t$## Maturalne haljine {godina}
Matura je jedna od najvažnijih večeri, zato u ponudi imamo haljine za veliku i malu maturu: duge haljine za svečanu večer i kraće modele za one koje žele nešto lakše. Nova kolekcija stiže često.

## Haljine za malu maturu
Za malu maturu (9. razred) birajte jednostavnije i kraće modele. Dostupne veličine vidite na stranici svakog proizvoda.

## Cipele i torbica uz haljinu
Uz maturalnu haljinu kod nas možete odabrati cipele za maturu, salonke ili sandale na petu, i svečanu torbicu. Ponesite cipele ili ih odaberite kod nas, jer visina pete mijenja duljinu haljine.

## Maturantice iz Dalmacije
Maturalne haljine u Mostaru biraju i maturantice iz Splita, Dubrovnika i Makarske. Dođite isprobati više modela u Mepas Mall, a za kupnju veću od 200 KM moguć je povrat PDV-a. Više na stranici [Kupovina u Mostaru](/kupovina-u-mostaru).$t$,
 jsonb_build_array(
   jsonb_build_object('question', 'Imate li haljine za malu maturu?', 'answer', 'Da, u ponudi su haljine za veliku i za malu maturu.'),
   jsonb_build_object('question', 'Mogu li isprobati maturalnu haljinu?', 'answer', 'Da, u našoj trgovini u Mepas Mallu u Mostaru možete isprobati više modela.'),
   jsonb_build_object('question', 'Kako se plaća u trgovini?', 'answer', 'Gotovinom u KM ili karticom, a moguće je i plaćanje na rate.'),
   jsonb_build_object('question', 'Mogu li rezervirati haljinu?', 'answer', 'Ne, haljine nije moguće rezervirati ni ostaviti sa strane.'),
   jsonb_build_object('question', 'Šaljete li maturalne haljine poštom?', 'answer', 'Da, na adrese u BiH, uz plaćanje pouzećem. Dostava traje 3 do 5 dana. U Hrvatsku zasad ne šaljemo.')
 )),
('haljine-za-svadbu',
 'Haljine za svadbu i haljina za kumu | Mostar',
 'Elegantne haljine za svadbu kao gost, haljina za kumu i svečane haljine za mame, u veličinama do 58. Isprobajte u Mepas Mallu u Mostaru.',
 'Elegantne haljine za vjenčanje kao gost, za kumu i za mame mladenaca.',
 $t$## Haljine za vjenčanje kao gost
Za svadbu birajte haljinu koja je elegantna, a u kojoj se ugodno osjećate cijelu večer. U ponudi su duge i kratke haljine za svadbu, u nježnim i jačim bojama.

## Haljina za kumu
Vjenčana, krsna ili krizmana kuma traži nešto posebno. Pogledajte elegantne haljine za kumu, a uz njih odaberite cipele na petu i svečanu torbicu.

## Haljine za svadbu za mame
Imamo i svečane haljine za mame mladenaca, u veličinama do 58, ovisno o modelu.$t$,
 jsonb_build_array(
   jsonb_build_object('question', 'Imate li haljine za kumu?', 'answer', 'Da, u ponudi su elegantne haljine za vjenčanu, krsnu i krizmanu kumu.'),
   jsonb_build_object('question', 'Imate li haljine za svadbu za punije dame?', 'answer', 'Da, veličine idu do 58, ovisno o modelu.')
 )),
('koktel-haljine',
 'Kratke svečane i koktel haljine | Mostar',
 'Kratke svečane i koktel haljine do koljena za proslave, izlaske i svadbu ljeti. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Kratke svečane i koktel haljine za proslave, izlaske i ljetne svadbe.',
 $t$## Kratke svečane haljine
Koktel haljina do koljena ili kraća idealna je za rođendan, krštenje, ljetnu svadbu ili večernji izlazak. Uz nju idu sandale na petu ili salonke i mala clutch torbica.$t$,
 '[]'::jsonb),
('lezerne-haljine',
 'Ležerne haljine i haljine za posao | Mostar',
 'Ležerne haljine za svaki dan, haljine za posao i manje proslave. Pogledajte online ili u našem butiku u Mepas Mallu u Mostaru.',
 'Ležerne haljine za svaki dan, posao i manje proslave.',
 $t$## Haljine za posao
Klasične haljine za posao trebaju biti elegantne, a udobne za cijeli dan. Uz njih odlično idu sako, mokasine ili salonke na nisku petu.

## Ležerne haljine za svaki dan
Ležerne haljine nosite na kavi, putovanju ili manjoj proslavi, a uz cipele na petu postaju i svečanije.$t$,
 '[]'::jsonb),

-- ODJEĆA
('odjeca',
 'Ženska odjeća Mostar | Odijela, kaputi i jakne',
 'Ženska odijela za posao i svečane prilike, kaputi, jakne, bolera, hlače i košulje. Butik ženske mode u Mepas Mallu u Mostaru.',
 'Ženska odijela, kaputi, jakne, bolera, hlače i košulje, za posao i svečane prilike.',
 $t$## Ženska odjeća za posao i svečane prilike
Uz haljine u našem butiku pronaći ćete ženska odijela, sakoe, hlače i košulje za posao, kao i kapute, jakne i bolera koja se nose preko svečane haljine.

Sve možete isprobati u trgovini u Mepas Mallu u Mostaru, a online narudžbe šaljemo na adrese u BiH.$t$,
 '[]'::jsonb),
('zenska-odijela',
 'Ženska odijela | Poslovna i svečana odijela, Mostar',
 'Poslovna i svečana ženska odijela, sakoi i kompleti za posao, svadbu i vjenčanje. Isprobajte u Mepas Mallu u Mostaru.',
 'Poslovna i svečana ženska odijela, sakoi i kompleti.',
 $t$## Poslovna odijela za žene
Žensko odijelo od sakoa i hlača siguran je izbor za posao, sastanak ili važan dan. Sako se može nositi i zasebno, uz haljinu ili traperice.

## Svečano žensko odijelo za svadbu
Za vjenčanje ili svečanu priliku žensko odijelo elegantna je zamjena za haljinu. Uz njega birajte salonke ili sandale na petu.$t$,
 jsonb_build_array(
   jsonb_build_object('question', 'Imate li ženska odijela za vjenčanje?', 'answer', 'Da, u ponudi su i svečana ženska odijela za vjenčanje i druge svečane prilike.')
 )),
('kaputi',
 'Ženski kaputi | Dugi i kratki kaputi, Mostar',
 'Ženski kaputi, dugi i kratki, elegantni za svaki dan i preko svečane haljine. Pogledajte online ili isprobajte u Mepas Mallu u Mostaru.',
 'Elegantni ženski kaputi, dugi i kratki, za svaki dan i preko svečane haljine.',
 $t$## Elegantni ženski kaputi
Zimi je kaput dio svakog izgleda. U ponudi su dugi i kratki ženski kaputi koji se nose uz svakodnevnu odjeću i preko svečane haljine.

Kapute možete isprobati u našoj trgovini u Mepas Mallu u Mostaru, a online narudžbe šaljemo na adrese u BiH.$t$,
 '[]'::jsonb),
('jakne',
 'Ženske jakne | Kožne jakne i jakne za jesen, Mostar',
 'Ženske jakne za jesen i zimu i kožne jakne. Pogledajte online ili u našem butiku u Mepas Mallu u Mostaru.',
 'Ženske jakne za jesen i zimu, uključujući kožne jakne.',
 $t$## Ženske jakne
Jakna je praktičan izbor za svaki dan, a dobro odabrana ide i uz haljinu. U ponudi su ženske jakne za jesen i zimu te kožne jakne.$t$,
 '[]'::jsonb),
('kozne-jakne',
 'Kožne jakne ženske | Mostar',
 'Ženske kožne jakne, crne i u drugim bojama, uz traperice ili haljinu. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Ženske kožne jakne za svaki dan.',
 $t$## Ženske kožne jakne
Kožna jakna ide uz traperice, hlače i haljinu. Dostupne boje i veličine vidite na stranici svakog proizvoda.$t$,
 '[]'::jsonb),
('bolera',
 'Bolera i jaknice za svečanu haljinu | Mostar',
 'Bolera i kratke jaknice preko svečane i maturalne haljine. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Bolera i kratke jaknice preko svečane haljine.',
 $t$## Bolero preko svečane haljine
Bolero pokriva ramena na crkvenom obredu ili u hladnijoj večeri, a ne skriva haljinu. Odaberite ga zajedno s haljinom u našoj trgovini.$t$,
 '[]'::jsonb),
('kompleti',
 'Ženski kompleti | Svečani i za svaki dan, Mostar',
 'Ženski kompleti od dva dijela, svečani i za svaki dan, za posao, proslave i izlaske. Pogledajte online ili isprobajte u Mepas Mallu u Mostaru.',
 'Ženski kompleti od dva dijela, svečani i za svaki dan.',
 $t$## Ženski kompleti
Komplet od dva dijela jednostavan je način da izgledate usklađeno bez puno razmišljanja. Svečaniji kompleti idu na proslave i svadbe, a ležerniji na posao i za svaki dan.

Komplete možete isprobati u našoj trgovini u Mepas Mallu u Mostaru, a online narudžbe šaljemo na adrese u BiH.$t$,
 '[]'::jsonb),
('hlace',
 'Ženske elegantne hlače | Za posao, Mostar',
 'Elegantne ženske hlače za posao i svečane prilike. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Elegantne ženske hlače za posao i svečane prilike.',
 null, '[]'::jsonb),
('kosulje',
 'Ženske košulje i bluze | Mostar',
 'Ženske košulje i bluze uz odijelo, hlače ili suknju. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Ženske košulje i bluze uz odijelo, hlače ili suknju.',
 null, '[]'::jsonb),

-- OBUĆA
('obuca',
 'Ženska obuća Mostar | Štikle, salonke, sandale i čizme',
 'Štikle, salonke, sandale na petu, čizme na petu i ravne čizme, za svadbu, maturu i svaki dan. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Štikle i salonke, sandale na petu, čizme na petu i ravne čizme, mokasine i baletanke.',
 $t$## Štikle i salonke za svečane prilike
Uz svečanu haljinu najčešće se biraju salonke na petu ili elegantne sandale. U ponudi su modeli s visokom, srednjom i niskom petom, pa svaka može naći udobnu visinu za cijelu večer.

## Cipele za maturu i svadbu
Ako cipele birate uz haljinu, dođite s haljinom ili je odaberite kod nas, jer visina pete mijenja duljinu haljine.

## Čizme za jesen i zimu
Ravne čizme i čizme na petu, do koljena i niže, nose se uz kaput, haljinu ili hlače.$t$,
 jsonb_build_array(
   jsonb_build_object('question', 'Kako odabrati visinu pete?', 'answer', 'U filteru možete birati ravne, niske, srednje i visoke pete. Za cijelu večer mnoge biraju srednju petu.'),
   jsonb_build_object('question', 'Mogu li zamijeniti cipele ako mi ne odgovara broj?', 'answer', 'Da, u roku od 15 dana, ako cipele nemaju tragova nošenja.')
 )),
('salonke',
 'Salonke na petu i štikle | Za svadbu i maturu, Mostar',
 'Salonke na petu, crne, bež i svečane štikle za svadbu, maturu i posao. Pogledajte online ili isprobajte u Mepas Mallu u Mostaru.',
 'Salonke na petu i štikle za svadbu, maturu i posao.',
 $t$## Salonke na petu
Salonke su klasika koja ide uz svečanu haljinu, odijelo i poslovnu haljinu. Bež salonke produljuju nogu i idu uz gotovo svaku boju, a crne su sigurna klasika.

## Štikle za svadbu i maturu
Za cijelu večer plesa birajte visinu pete u kojoj se ugodno osjećate. Cipele možete isprobati u trgovini zajedno s haljinom.$t$,
 '[]'::jsonb),
('polusalonke',
 'Polusalonke na petu | Mostar',
 'Polusalonke na petu, otvorene na peti ili sa strane, uz haljinu i odijelo. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Polusalonke na petu, otvorene na peti ili sa strane.',
 null, '[]'::jsonb),
('sandale',
 'Sandale na petu | Svečane sandale, Mostar',
 'Svečane sandale na petu, zlatne, srebrne, bež i crne, za svadbu, maturu i ljetne večeri. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Svečane sandale na petu za svadbu, maturu i ljetne večeri.',
 $t$## Svečane sandale na petu
Sandale na petu uz dugu haljinu daju lagan i elegantan izgled, osobito ljeti. Zlatne i srebrne sandale idu uz svečane haljine, a bež i crne uz gotovo svaku boju.$t$,
 '[]'::jsonb),
('cizme',
 'Ženske čizme | Čizme na petu i ravne čizme, Mostar',
 'Ženske čizme na petu i ravne čizme, do koljena i niže, za jesen i zimu. Pogledajte online ili isprobajte u Mepas Mallu u Mostaru.',
 'Ženske čizme na petu i ravne čizme za jesen i zimu.',
 $t$## Ženske čizme
Čizme do koljena nose se uz haljinu, suknju i kaput, a niže čizme uz hlače. U ponudi su čizme na petu i ravne čizme, od brušene kože, velura i glatkih materijala.

Dostupne brojeve vidite na stranici svakog proizvoda, a zamjena je moguća u roku od 15 dana.$t$,
 '[]'::jsonb),
('cizme-na-petu',
 'Čizme na petu | Do koljena i niske, Mostar',
 'Ženske čizme na petu, do koljena i niske, uz haljinu, suknju ili kaput. Pogledajte online ili isprobajte u Mepas Mallu u Mostaru.',
 'Ženske čizme na petu, do koljena i niske.',
 $t$## Čizme na petu
Čizme na petu do koljena idu uz haljinu i kaput, a niske uz hlače i odijelo. Isprobajte ih u trgovini i odaberite visinu pete u kojoj se ugodno osjećate.$t$,
 '[]'::jsonb),
('ravne-cizme',
 'Ravne čizme | Ženske čizme do koljena, Mostar',
 'Ravne ženske čizme do koljena i niže, udobne za svaki dan. Pogledajte online ili isprobajte u Mepas Mallu u Mostaru.',
 'Ravne ženske čizme, udobne za svaki dan.',
 $t$## Ravne čizme
Ravne čizme do koljena udoban su izbor za cijeli dan, uz traperice, suknju ili haljinu.$t$,
 '[]'::jsonb),
('mokasine',
 'Ženske mokasine | Mostar',
 'Ženske mokasine za posao i svaki dan. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Ženske mokasine za posao i svaki dan.',
 null, '[]'::jsonb),
('baletanke',
 'Baletanke | Ravne cipele za svaki dan, Mostar',
 'Ravne baletanke, udobne uz haljinu i hlače. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Ravne baletanke, udobne uz haljinu i hlače.',
 null, '[]'::jsonb),

-- TORBICE
('torbice',
 'Ženske torbe i torbice | Svečane i za svaki dan, Mostar',
 'Svečane torbice i clutch torbice, te male, srednje i velike ženske torbe za svaki dan. Idealne i za poklon. Mepas Mall, Mostar.',
 'Svečane i clutch torbice, te male, srednje i velike ženske torbe za svaki dan.',
 $t$## Svečane torbice
Mala svečana torbica ili clutch zaokružuje izgled uz večernju i maturalnu haljinu. Zlatna, srebrna, bež ili crna torbica ide uz više haljina.

## Ženske torbe za svaki dan
Za posao, kupovinu i putovanja u ponudi su mini, midi i maxi torbe, a imamo i kofere i putne torbe.

## Torba kao poklon
Torba je jedan od najdražih poklona za nju. Ako niste sigurni što odabrati, tu je i [poklon bon](/poklon-bon) u iznosu po vašem izboru.$t$,
 jsonb_build_array(
   jsonb_build_object('question', 'Kako odabrati torbicu uz haljinu?', 'answer', 'Najsigurnije je uskladiti je s cipelama ili odabrati zlatnu, srebrnu ili crnu torbicu koja ide uz više haljina.')
 )),
('svecane-torbice',
 'Svečane torbice | Clutch i večernje torbice, Mostar',
 'Svečane torbice, clutch i večernje torbice, zlatne, srebrne, bež i crne, uz haljinu za svadbu i maturu. Pogledajte u Mepas Mallu u Mostaru.',
 'Svečane, clutch i večernje torbice uz haljinu za svadbu i maturu.',
 $t$## Svečane torbice uz haljinu
Uz večernju i maturalnu haljinu najbolje ide mala torbica u koju stanu mobitel, ključevi i ruž. Birajte je u boji cipela ili kao naglasak.$t$,
 '[]'::jsonb),
('clutch-torbice',
 'Clutch torbice | Zlatne, srebrne i crne, Mostar',
 'Clutch torbice, zlatne, srebrne, bijele i crne, uz svečanu i maturalnu haljinu. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Clutch torbice uz svečanu i maturalnu haljinu.',
 null, '[]'::jsonb),
('vecernje-torbice',
 'Večernje torbice | Mostar',
 'Večernje torbice uz svečanu haljinu, za svadbu, maturu i gala večer. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Večernje torbice za svadbu, maturu i gala večer.',
 null, '[]'::jsonb),
('mini-torbice',
 'Mini torbice | Male ženske torbice, Mostar',
 'Male ženske torbice za izlaske i svaki dan. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Male ženske torbice za izlaske i svaki dan.',
 null, '[]'::jsonb),
('midi-torbice',
 'Ženske torbe srednje veličine | Mostar',
 'Ženske torbe srednje veličine za posao i svaki dan. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Ženske torbe srednje veličine za posao i svaki dan.',
 null, '[]'::jsonb),
('maxi-torbe',
 'Velike ženske torbe | Za posao i putovanja, Mostar',
 'Velike ženske torbe za posao, kupovinu i putovanja. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Velike ženske torbe za posao i putovanja.',
 null, '[]'::jsonb),
('koferi-i-putne-torbe',
 'Koferi i putne torbe | Mostar',
 'Koferi i putne torbe za putovanja. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Koferi i putne torbe.',
 null, '[]'::jsonb),

-- DODACI
('dodaci',
 'Nakit od nehrđajućeg čelika i dodaci | Mostar',
 'Nakit od nehrđajućeg čelika, šalovi i modni dodaci, idealni za poklon. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Nakit od nehrđajućeg čelika, šalovi i modni dodaci, idealni i za poklon.',
 $t$## Nakit od nehrđajućeg čelika
Naš nakit izrađen je od nehrđajućeg čelika. Uz svečanu haljinu birajte naušnice ili ogrlicu koje prate izrez i boju haljine.

## Poklon za nju
Nakit je jedan od najljepših poklona za rođendan, Božić ili Valentinovo. Ako niste sigurni što odabrati, tu je i [poklon bon](/poklon-bon) u iznosu po vašem izboru.$t$,
 jsonb_build_array(
   jsonb_build_object('question', 'Od čega je nakit?', 'answer', 'Nakit u našoj ponudi izrađen je od nehrđajućeg čelika.'),
   jsonb_build_object('question', 'Imate li poklon bon?', 'answer', 'Da, poklon bon možete kupiti u iznosu po vašem izboru.')
 )),
('nakit',
 'Nakit od nehrđajućeg čelika | Poklon za nju, Mostar',
 'Nakit od nehrđajućeg čelika: ogrlice, naušnice i narukvice, idealne za poklon. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Nakit od nehrđajućeg čelika, idealan i za poklon.',
 $t$## Nakit od nehrđajućeg čelika
Nakit od nehrđajućeg čelika nosi se svaki dan i uz svečanu haljinu. Idealan je poklon za nju, za rođendan, Božić ili Valentinovo.$t$,
 jsonb_build_array(
   jsonb_build_object('question', 'Od čega je nakit?', 'answer', 'Nakit u našoj ponudi izrađen je od nehrđajućeg čelika.')
 )),
('salovi',
 'Šalovi i marame | Mostar',
 'Šalovi i marame uz kaput ili svečanu haljinu. Pogledajte online ili u Mepas Mallu u Mostaru.',
 'Šalovi i marame uz kaput ili svečanu haljinu.',
 null, '[]'::jsonb);

update public.categories c set
  meta_title = s.meta_title,
  meta_description = s.meta_description,
  description = s.description,
  seo_text = coalesce(s.seo_text, c.seo_text),
  faq = case when jsonb_array_length(s.faq) > 0 then s.faq else c.faq end
from seo s
where c.slug = s.slug;

-- Provjera: koje kategorije još nemaju naslov za Google.
select slug, name from public.categories where meta_title is null order by slug;

commit;
