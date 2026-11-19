// Sadržaj naslovne stranice. Slug mora odgovarati kategoriji iz baze (migracija 0009).
// Fotografije idu u public/ (kao WebP), a ovdje se upisuje putanja, npr. '/images/home/naslovna.webp'. Bez slike ostaje obojena podloga.
export const HOME_TOP_BAR = {
  desktop: 'Naruči online · preuzmi u butiku, Mepas Mall',
  mobile: 'Preuzmi u butiku · Mepas Mall',
}

export const HOME_HERO = {
  eyebrow: 'Jesen / Zima 2026',
  eyebrowExtra: ' · Svečana kolekcija',
  text: 'Za maturu, vjenčanje i svaku svečanu večer — haljine, kaputi, cipele i torbice birani s pažnjom u našem butiku u Mepas Mallu.',
  // Original je originals/viva header.jpg (kolaž 2000 × 1390). Računalo dobiva cijeli kolaž smanjen na 1600 px,
  // a mobitel samo lijevu fotografiju, izrezanu 3 : 4 od vrha.
  image: '/images/home/heroj.webp',
  imageMobile: '/images/home/heroj-mobitel.webp',
  imageAlt: 'Ružičasta duga haljina od čipke s biserima, dugim rukavima i prorezom',
  primary: { label: 'Svečane haljine', slug: 'svecane-haljine' },
  secondary: { label: 'Kaputi', slug: 'kaputi' },
}

export const HOME_CATEGORIES = [
  { title: 'Haljine', slug: 'haljine', image: '/images/home/svecana-haljina-kategorija.webp', imageAlt: 'Ružičasta svečana haljina na jedno rame, sa šljokicama, remenom i satenskim šlepom' },
  { title: 'Ženska odijela', slug: 'zenska-odijela', image: '/images/home/kompleti-i-sakoi-kategorija.webp', imageAlt: 'Ženski komplet od sakoa i hlača u bež boji, uz bijelu košulju s naglašenim ovratnikom i torbicu' },
  { title: 'Obuća', slug: 'obuca', image: '/images/home/obuca-kategorija.webp', imageAlt: 'Bež čizme do koljena s ukrasnim vezicama i zlatnim gumbima' },
  { title: 'Torbice', slug: 'torbice', image: '/images/home/torbice-kategorija.webp', imageAlt: 'Srebrna svjetlucava torbica s mašnom uz crnu satensku haljinu' },
  // Modni dodaci su zasad maknuti s naslovne, jer ih još nema u ponudi. Za povratak samo makni komentar.
  // { title: 'Modni dodaci', slug: 'dodaci', image: '/images/home/modni-dodaci-kategorija.webp', imageAlt: 'Bež pismo torbica i cipele na petu uz smeđu satensku haljinu' },
]

// Prva kartica je sezonska, druga stoji cijelu godinu.
// Ljeti zamijeni prvu, npr.:
// { eyebrow: 'Proljeće / Ljeto', title: 'Lagane', accent: 'haljine', text: 'Lagane haljine za tople dane i ljetne večeri.', link: 'Pogledaj haljine', slug: 'haljine', tone: 'white', image: '/images/home/....webp', imageAlt: 'Što je na fotografiji' }
// ili sandale: { ..., title: 'Ljetne', accent: 'sandale', link: 'Pogledaj sandale', slug: 'sandale' }
export const HOME_PANELS = [
  {
    eyebrow: 'Jesen / Zima',
    title: 'Zimski',
    accent: 'kaputi',
    text: 'Kaputi za hladnije dane, koji se lijepo slažu uz svečane i lagane haljine.',
    link: 'Pogledaj kapute',
    slug: 'kaputi',
    tone: 'white',
    image: '/images/home/zimski-kaput.webp',
    imageAlt: 'Smeđi kaput s remenom te raskošnim ovratnikom i manžetama',
  },
  {
    eyebrow: 'Vjenčanja · Mature · Gala',
    title: 'Svečani',
    accent: 'trenuci',
    text: 'Duge večernje haljine, koktel modeli, sandale na petu i torbice-pisma koje zaokružuju izgled.',
    link: 'Istraži kolekciju',
    slug: 'svecane-haljine',
    tone: 'champagne',
    // Smanjena kopija (1080 px) fotografije originals/svecana-haljina-srebrna.jpg, koju koristi i stranica "Uskoro".
    image: '/images/home/svecana-haljina-srebrna-1080.webp',
    imageAlt: 'Crni svečani korzet bez naramenica s ukrasima',
  },
]

// Haljine po prigodi (HomeOccasions). Slug je podkategorija haljina; isključena kategorija se ne prikazuje.
export const HOME_OCCASIONS = {
  eyebrow: 'Haljine za svaku prigodu',
  title: 'Odaberite po prigodi',
  items: [
    { title: 'Maturalne haljine', slug: 'maturalne-haljine', text: 'Za veliku i malu maturu.' },
    { title: 'Haljine za svadbu', slug: 'haljine-za-svadbu', text: 'Za goste na vjenčanju i obiteljske proslave.' },
    { title: 'Svečane haljine', slug: 'svecane-haljine', text: 'Duge večernje haljine za posebne večeri.' },
    { title: 'Koktel haljine', slug: 'koktel-haljine', text: 'Kraći modeli za proslave i izlaske.' },
    { title: 'Ležerne haljine', slug: 'lezerne-haljine', text: 'Za posao i manje proslave.' },
  ],
}

// Sezonska istaknuta sekcija (HomeFeature). Zimi čizme, a ljeti zamijeni npr. sandalama:
// { eyebrow: 'Proljeće / Ljeto', title: 'Sandale', accent: 'na petu', text: '...', link: 'Pogledaj sandale', slug: 'sandale', image: '/images/home/....webp', imageAlt: 'Što je na fotografiji' }
export const HOME_SEASON = {
  eyebrow: 'Jesen / Zima',
  title: 'Čizme',
  accent: 'za hladnije dane',
  text: 'Ravne čizme i čizme na petu, koje se lijepo slažu uz kapute i haljine.',
  link: 'Pogledaj čizme',
  slug: 'cizme',
  image: '/images/home/obuca-kategorija.webp',
  imageAlt: 'Bež čizme do koljena s ukrasnim vezicama i zlatnim gumbima',
}

// "Novo" na naslovnoj (HomeNew): nasumičan izbor među najnovijim proizvodima, drukčiji pri svakom učitavanju.
export const HOME_NEW = {
  eyebrow: 'Upravo stiglo',
  title: 'Novo u butiku',
  // Koliko se najnovijih proizvoda uzima u obzir i koliko ih se prikaže.
  pool: 24,
  count: 10,
}

// Najava stranice Čišćenje zaliha (HomeFeature), bez proizvoda. Prikazuje se samo dok je ta stranica uključena.
// Fotografija je public/images/home/ciscenje-zaliha.webp (900 × 1125). imagePosition čuva čizme i torbu u kadru.
export const HOME_CLEARANCE = {
  eyebrow: 'Posebna ponuda',
  title: 'Čišćenje',
  accent: 'zaliha',
  text: 'Odabrani modeli po sniženim cijenama, izdvojeni na jednoj stranici.',
  link: 'Pogledaj ponudu',
  image: '/images/home/ciscenje-zaliha.webp',
  imageAlt: 'Bijele čizme do koljena s kopčama i bijela torba uz tamnoljubičastu haljinu s čipkom',
  imagePosition: 'object-[50%_65%]',
}

// Kratke prednosti trgovine (HomeHighlights). Samo tvrdnje koje je potvrdila vlasnica.
export const HOME_HIGHLIGHTS = {
  eyebrow: 'Zašto Viva',
  title: 'Dobro je znati',
  items: [
    { title: 'Veličine od 36 do 58', text: 'Ovisno o modelu. Dostupne veličine vidite na stranici svakog proizvoda.' },
    { title: 'Isprobajte u trgovini', text: 'U trgovini možete isprobati više modela prije nego što se odlučite.' },
    { title: 'Poklon bon', text: 'Poklon bon možete kupiti u iznosu po vašem izboru.' },
  ],
}

// Galerija svečanih haljina. Prva slika je veća. Opis (alt) neka kaže što je na fotografiji, zbog Googlea i čitača zaslona.
export const HOME_LOOKBOOK = {
  eyebrow: 'Mature · Vjenčanja · Gala',
  title: 'Svečane haljine',
  text: 'Maturalne, večernje i elegantne haljine za večer koju ćete pamtiti. Pogledajte izbor i dođite ih isprobati u Mepas Mall.',
  link: { label: 'Pogledaj haljine', slug: 'haljine' },
  // Redoslijed je namjeran: slične haljine i fotografije iste haljine nisu jedna do druge.
  // Velike fotografije su u LOOKBOOK_LARGE (komponenta HomeLookbook).
  images: [
    { src: '/images/home/galerija/svecana-haljina-03.webp', alt: 'Crna duga haljina s crvenom podlogom, prorezom i svjetlucavim ukrasom' },
    { src: '/images/home/galerija/svecana-haljina-01.webp', alt: 'Detalj ružičaste haljine sa šljokicama i biserima na jedno rame' },
    { src: '/images/home/galerija/svecana-haljina-06.webp', alt: 'Detalj bež korzeta s čipkom i dugim rukavima' },
    { src: '/images/home/galerija/svecana-haljina-14.webp', alt: 'Crvena kratka haljina bez naramenica s cvijetom oko vrata' },
    { src: '/images/home/galerija/svecana-haljina-09.webp', alt: 'Crna duga haljina s volanima na ramenima' },
    { src: '/images/home/galerija/svecana-haljina-12.webp', alt: 'Detalj srebrnosive haljine s perlicama i prozirnim rukavima' },
    { src: '/images/home/galerija/svecana-haljina-02.webp', alt: 'Ružičasta svjetlucava haljina s remenom, ukrasnom kopčom i satenskim šlepom' },
    { src: '/images/home/galerija/svecana-haljina-10.webp', alt: 'Crna čipkasta duga haljina s dugim rukavima i prorezom' },
    { src: '/images/home/galerija/svecana-haljina-13.webp', alt: 'Detalj crvenog cvijeta oko vrata uz svečanu haljinu' },
    { src: '/images/home/galerija/svecana-haljina-05.webp', alt: 'Tamnosmeđa uska duga haljina na jedno rame s velikim cvijetom' },
    { src: '/images/home/galerija/svecana-haljina-07.webp', alt: 'Bordo duga haljina na tanke naramenice s prorezom' },
  ],
}

// Video, npr. '/video/kolekcija.mp4' (MP4, H.264, bez zvuka, do ~10 MB). Poster je slika dok se video ne učita.
// Dok nema videa, prikazuje se kolaž fotografija različitih veličina, spojenih bez razmaka kao jedna slika (HomeVideo).
// Fotografije su 900 × 1125 (4 : 5) u public/images/home/kolekcija/.
export const HOME_VIDEO = {
  eyebrow: 'Kolekcija u pokretu',
  title: 'Svečana kolekcija',
  src: '',
  poster: '',
  label: 'Video svečane kolekcije haljina',
  link: { label: 'Pogledaj svečane haljine', slug: 'svecane-haljine' },
  images: [
    { src: '/images/home/kolekcija/svecana-kolekcija-1.webp', alt: 'Bež duga haljina s kristalima i ljubičastim satenskim rukavima' },
    { src: '/images/home/kolekcija/svecana-kolekcija-2.webp', alt: 'Bež duga haljina s kristalima, pogled sa strane' },
    { src: '/images/home/kolekcija/svecana-kolekcija-3.webp', alt: 'Bež haljina s dubokim izrezom, kristalima i ljubičastim satenskim rukavima' },
    { src: '/images/home/kolekcija/svecana-kolekcija-4.webp', alt: 'Detalj izreza bež haljine s ljubičastim kristalima' },
    { src: '/images/home/kolekcija/svecana-kolekcija-5.webp', alt: 'Detalj korzeta bež haljine s perlicama i ljubičastim kristalima' },
    { src: '/images/home/kolekcija/svecana-kolekcija-6.webp', alt: 'Bež cipela na petu sa svjetlucavom petom uz rub bež haljine' },
  ],
  // Koja fotografija (indeks u images) ide na koje mjesto kolaža, redom: velika, visoka, visoka, mala, mala, široka.
  // Za veliko i visoka mjesta najbolje su cijele figure, a za široko i mala detalji (vidi HomeVideo).
  order: [2, 0, 1, 3, 5, 4],
}

export const HOME_SERVICES = [
  // {prag} zamjenjuje iznos iz postavki trgovine (besplatna poštarina).
  { title: 'Besplatna dostava', text: 'Za narudžbe veće od {prag} poštarina je besplatna.' },
  { title: 'Preuzimanje u trgovini', text: 'Naručite online i preuzmite bez poštarine, u našoj trgovini u Mostaru ili u Sarajevu.' },
  { title: 'Dostava po BiH', text: 'Dostava na vašu adresu za 3 do 5 dana, plaćanje pouzećem i zamjena u 15 dana.' },
]

// Sve tvrdnje potvrdila je vlasnica (studeni 2026.). Adresa poslovnice u Sarajevu još nije poznata.
export const HOME_FAQ = [
  {
    question: 'Gdje se nalazi trgovina Viva?',
    answer: 'U Mepas Mallu u Mostaru, Kneza Branimira 2b. Imamo i poslovnicu u Sarajevu. Parking je u garaži Mepas Malla i naplaćuje se.',
  },
  {
    question: 'Imate li maturalne haljine?',
    answer: 'Da, maturalne haljine su važan dio naše ponude, za veliku i za malu maturu. Nova kolekcija stiže nam često, po najnovijoj modi.',
  },
  {
    question: 'Imate li haljine za svadbu, pričest, krizmu ili krštenje?',
    answer: 'Da, u ponudi su svečane haljine za svadbe i obiteljske proslave, uključujući modele za mame za pričest, krizmu i krštenje, uz cipele na petu i torbice.',
  },
  {
    question: 'Što još imate osim haljina?',
    answer: 'Ženska odijela, ležernije haljine za posao i manje proslave, jakne i kapute, cipele na petu, torbice i nakit od nehrđajućeg čelika.',
  },
  {
    question: 'Koje veličine imate?',
    answer: 'Veličine idu od 36 do 58, ovisno o modelu. Nije svaki model dostupan u svim veličinama, a dostupne veličine vidite na stranici proizvoda.',
  },
  {
    question: 'Mogu li isprobati haljinu prije kupnje?',
    answer: 'Da, u trgovini možete isprobati više modela prije nego što se odlučite.',
  },
  {
    question: 'Kako se plaća?',
    answer: 'U trgovini plaćate gotovinom u KM ili karticom, a moguće je i plaćanje na rate. Online narudžbe plaćate pouzećem, kuriru pri preuzimanju.',
  },
  {
    question: 'Mogu li online narudžbu preuzeti u trgovini?',
    answer: 'Da, online narudžbu možete preuzeti bez poštarine, u našoj trgovini u Mostaru ili u poslovnici u Sarajevu. Preuzimanje odaberite u košarici.',
  },
  {
    question: 'Radite li skraćivanje ili prepravke haljina?',
    answer: 'Ne, skraćivanje i prepravke ne radimo. Zato preporučujemo da u trgovini isprobate više modela i veličina.',
  },
  {
    question: 'Mogu li rezervirati haljinu ili je ostaviti sa strane?',
    answer: 'Ne, haljine ne rezerviramo i ne ostavljamo sa strane.',
  },
  {
    question: 'Koliko traje dostava i kamo dostavljate?',
    answer: 'Dostavljamo samo unutar Bosne i Hercegovine. Dostava traje 3 do 5 dana, a plaćate pouzećem, kuriru pri preuzimanju.',
  },
  {
    question: 'Mogu li zamijeniti proizvod?',
    answer: 'Da, proizvod možete zamijeniti u roku od 15 dana, ako nema tragova nošenja. Ako proizvod ima grešku, javite nam se i riješit ćemo to.',
  },
  {
    question: 'Od čega je vaš nakit?',
    answer: 'Nakit u našoj ponudi je od nehrđajućeg čelika.',
  },
  {
    question: 'Imate li poklon bon?',
    answer: 'Da, poklon bon možete kupiti u iznosu po vašem izboru.',
  },
  {
    // Prag i postupak su iz Instrukcije UIO-a (Službeni glasnik BiH 48/25, od 6. 8. 2025.). Provjeriti ako se propis promijeni.
    question: 'Dolazite iz Hrvatske? Možete li dobiti povrat PDV-a?',
    answer: 'Kupce iz cijele Hrvatske rado dočekujemo u Mepas Mallu, osobito u sezoni matura i vjenčanja. Kupci bez prebivališta u BiH mogu ostvariti povrat PDV-a za kupnju veću od 200 KM: na blagajni zatražite obrazac PDV-SL-2, ovjerite ga na granici pri izlasku iz BiH u roku od 3 mjeseca, a ovjereni obrazac vratite nama. PDV vraćamo u KM, gotovinom ili na vaš račun.',
  },
]
