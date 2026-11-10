// Sadržaj naslovne stranice. Slug mora odgovarati kategoriji iz baze (migracija 0009).
// Fotografije idu u public/, a ovdje se upisuje putanja, npr. '/slike/naslovna.jpg'. Bez slike ostaje obojena podloga.
export const HOME_TOP_BAR = {
  desktop: 'Naruči online · preuzmi u butiku, Mepas Mall',
  mobile: 'Preuzmi u butiku · Mepas Mall',
}

export const HOME_HERO = {
  eyebrow: 'Jesen / Zima 2026',
  eyebrowExtra: ' · Svečana kolekcija',
  text: 'Za maturu, vjenčanje i svaku svečanu večer — haljine, kaputi, cipele i torbice birani s pažnjom u našem butiku u Mepas Mallu.',
  image: '',
  imageAlt: 'Model u dugoj večernjoj haljini',
  primary: { label: 'Svečane haljine', slug: 'svecano' },
  secondary: { label: 'Kaputi', slug: 'kaputi' },
}

export const HOME_CATEGORIES = [
  { title: 'Haljine', slug: 'haljine', image: '/images/home/svecana-haljina-kategorija.jpg', imageAlt: 'Ružičasta svečana haljina na jedno rame, sa šljokicama, remenom i satenskim šlepom' },
  { title: 'Kompleti & sakoi', slug: 'kompleti-i-sakoi', image: '/images/home/kompleti-i-sakoi-kategorija.jpg', imageAlt: 'Ženski komplet od sakoa i hlača u bež boji, uz bijelu košulju s naglašenim ovratnikom i torbicu' },
  { title: 'Obuća', slug: 'obuca', image: '/images/home/obuca-kategorija.jpg', imageAlt: 'Bež čizme do koljena s ukrasnim vezicama i zlatnim gumbima' },
  { title: 'Torbice', slug: 'torbice', image: '/images/home/torbice-kategorija.jpg', imageAlt: 'Srebrna svjetlucava torbica s mašnom uz crnu satensku haljinu' },
  { title: 'Modni dodaci', slug: 'dodaci', image: '/images/home/modni-dodaci-kategorija.jpg', imageAlt: 'Bež pismo torbica i cipele na petu uz smeđu satensku haljinu' },
]

// Prva kartica je sezonska, druga stoji cijelu godinu.
// Ljeti zamijeni prvu, npr.:
// { eyebrow: 'Proljeće / Ljeto', title: 'Lagane', accent: 'haljine', text: 'Lagane haljine za tople dane i ljetne večeri.', link: 'Pogledaj haljine', slug: 'haljine', tone: 'white', image: '/images/home/...jpg', imageAlt: 'Što je na fotografiji' }
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
    image: '/images/home/zimski-kaput.jpg',
    imageAlt: 'Smeđi kaput s remenom te raskošnim ovratnikom i manžetama',
  },
  {
    eyebrow: 'Vjenčanja · Mature · Gala',
    title: 'Svečani',
    accent: 'trenuci',
    text: 'Duge večernje haljine, koktel modeli, sandale na petu i torbice-pisma koje zaokružuju izgled.',
    link: 'Istraži kolekciju',
    slug: 'svecano',
    tone: 'champagne',
    image: '/images/home/svecana-haljina-srebrna.jpg',
    imageAlt: 'Srebrnosiva duga haljina s perlicama i visokim ovratnikom',
  },
]

// Galerija svečanih haljina. Prva slika je veća. Opis (alt) neka kaže što je na fotografiji, zbog Googlea i čitača zaslona.
export const HOME_LOOKBOOK = {
  eyebrow: 'Mature · Vjenčanja · Gala',
  title: 'Svečane haljine',
  text: 'Maturalne, večernje i elegantne haljine za večer koju ćete pamtiti. Pogledajte izbor i dođite ih isprobati u Mepas Mall.',
  link: { label: 'Pogledaj haljine', slug: 'haljine' },
  // Redoslijed je namjeran: slične haljine i fotografije iste haljine nisu jedna do druge.
  // Velike fotografije su u LOOKBOOK_LARGE (komponenta HomeLookbook).
  images: [
    { src: '/images/home/galerija/svecana-haljina-01.jpg', alt: 'Maslinastozelena duga haljina s volanima i remenom' },
    { src: '/images/home/galerija/svecana-haljina-02.jpg', alt: 'Crna duga haljina s otvorenim ramenima' },
    { src: '/images/home/galerija/svecana-haljina-03.jpg', alt: 'Detalj ružičaste svjetlucave haljine sa šlepom i ukrasnom kopčom na remenu' },
    { src: '/images/home/galerija/svecana-haljina-04.jpg', alt: 'Crvena kratka haljina bez naramenica s cvijetom oko vrata' },
    { src: '/images/home/galerija/svecana-haljina-05.jpg', alt: 'Tamnosmeđa uska duga haljina na jedno rame s velikim cvijetom' },
    { src: '/images/home/galerija/svecana-haljina-06.jpg', alt: 'Detalj bež korzeta s čipkom i dugim rukavima' },
    { src: '/images/home/galerija/svecana-haljina-07.jpg', alt: 'Bordo duga haljina na tanke naramenice s prorezom' },
    { src: '/images/home/galerija/svecana-haljina-08.jpg', alt: 'Ružičasta svečana haljina na jedno rame, sa šljokicama, remenom i satenskim šlepom' },
    { src: '/images/home/galerija/svecana-haljina-09.jpg', alt: 'Tamnosmeđa uska duga haljina s mašnom i volanima na ramenima' },
    { src: '/images/home/galerija/svecana-haljina-10.jpg', alt: 'Crna čipkasta duga haljina s dugim rukavima i prorezom' },
    { src: '/images/home/galerija/svecana-haljina-11.jpg', alt: 'Srebrnosiva duga haljina s perlicama i visokim ovratnikom' },
    { src: '/images/home/galerija/svecana-haljina-12.jpg', alt: 'Detalj srebrnosive haljine s perlicama i prozirnim rukavima' },
    { src: '/images/home/galerija/svecana-haljina-13.jpg', alt: 'Detalj crvenog cvijeta oko vrata uz svečanu haljinu' },
    { src: '/images/home/galerija/svecana-haljina-14.jpg', alt: 'Crna duga haljina s crvenom podlogom, prorezom i svjetlucavim ukrasom' },
    { src: '/images/home/galerija/svecana-haljina-15.jpg', alt: 'Detalj ružičaste svjetlucave haljine na jedno rame' },
  ],
}

// Video, npr. '/video/kolekcija.mp4' (MP4, H.264, bez zvuka, do ~10 MB). Poster je slika dok se video ne učita.
export const HOME_VIDEO = {
  eyebrow: 'Kolekcija u pokretu',
  title: 'Svečana kolekcija',
  src: '',
  poster: '',
  label: 'Video svečane kolekcije haljina',
}

export const HOME_SERVICES = [
  // {prag} zamjenjuje iznos iz postavki trgovine (besplatna poštarina).
  { title: 'Besplatna dostava', text: 'Za narudžbe veće od {prag} poštarina je besplatna.' },
  { title: 'Preuzimanje u trgovini', text: 'Naručite online i preuzmite u našoj trgovini u Mostaru, a moguće i u Sarajevu.' },
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
    answer: 'Veličine idu do 58, ovisno o modelu. Nije svaki model dostupan u svim veličinama, a dostupne veličine vidite na stranici proizvoda.',
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
    answer: 'Da, online narudžbu možete preuzeti u našoj trgovini u Mostaru, a moguće i u Sarajevu. Napišite to u napomeni uz narudžbu.',
  },
  {
    question: 'Imate li poklon bon?',
    answer: 'Da, poklon bon možete kupiti u iznosu po vašem izboru.',
  },
  {
    // Prag i postupak su iz Instrukcije UIO-a (Službeni glasnik BiH 48/25, od 6. 8. 2025.). Provjeriti ako se propis promijeni.
    question: 'Dolazite iz Hrvatske? Možete li dobiti povrat PDV-a?',
    answer: 'Mnoge kupce iz Splita i Dubrovnika rado dočekujemo u Mepas Mallu, osobito u sezoni matura i vjenčanja. Kupci bez prebivališta u BiH mogu ostvariti povrat PDV-a za kupnju veću od 200 KM: na blagajni zatražite obrazac PDV-SL-2, ovjerite ga na granici pri izlasku iz BiH u roku od 3 mjeseca, a ovjereni obrazac vratite nama. PDV vraćamo u KM, gotovinom ili na vaš račun.',
  },
]
