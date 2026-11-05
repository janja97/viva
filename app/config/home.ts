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
  { title: 'Besplatna dostava', text: 'Za narudžbe veće od 150 KM poštarina je besplatna.' },
  { title: 'Preuzimanje u butiku', text: 'Naručite online i probajte u Mepas Mallu prije plaćanja.' },
  { title: 'Dostava po BiH', text: 'Dostava na vašu adresu, s mogućnošću povrata i zamjene.' },
  { title: 'Poklon pakiranje', text: 'Elegantna kutija sa zlatnim detaljem i čestitka na zahtjev.' },
]

export const HOME_FAQ = [
  {
    question: 'Gdje se nalazi trgovina Viva?',
    answer: 'Nalazimo se u Mepas Mallu u Mostaru, Kneza Branimira 2b.',
  },
  {
    question: 'Imate li maturalne haljine?',
    answer: 'Da, maturalne haljine su važan dio naše ponude. Modele možete pogledati online ili u trgovini.',
  },
  {
    question: 'Prodajete li i muška odijela?',
    answer: 'Ne, ponuda je samo za žene: svečane i lagane haljine, zimi i kaputi, uz cipele, torbice i dodatke.',
  },
  {
    question: 'Mogu li isprobati model prije kupnje?',
    answer: 'Da, odabrane modele možete isprobati kod nas u trgovini u Mepas Mallu.',
  },
]
