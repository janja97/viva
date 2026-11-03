// Sadržaj naslovne stranice. Slug mora odgovarati kategoriji iz baze (migracija 0009).
// Fotografije idu u public/, a ovdje se upisuje putanja, npr. '/slike/naslovna.jpg'. Bez slike ostaje obojena podloga.
export const HOME_TOP_BAR = {
  desktop: 'Naruči online · preuzmi u butiku, Mepas Mall',
  mobile: 'Preuzmi u butiku · Mepas Mall',
}

export const HOME_HERO = {
  eyebrow: 'Jesen / Zima 2026',
  eyebrowExtra: ' · Svečana kolekcija',
  text: 'Za maturu, vjenčanje i svaku svečanu večer — haljine, odijela, cipele i torbice birani s pažnjom u našem butiku u Mepas Mallu.',
  image: '',
  imageAlt: 'Model u dugoj večernjoj haljini',
  primary: { label: 'Svečane haljine', slug: 'svecano' },
  secondary: { label: 'Odijela', slug: 'odijela' },
}

export const HOME_CATEGORIES = [
  { title: 'Haljine', slug: 'haljine', image: '' },
  { title: 'Kompleti & sakoi', slug: 'kompleti-i-sakoi', image: '' },
  { title: 'Obuća', slug: 'obuca', image: '' },
  { title: 'Torbice', slug: 'torbice', image: '' },
  { title: 'Modni dodaci', slug: 'dodaci', image: '' },
]

export const HOME_PANELS = [
  {
    eyebrow: 'Mature · Posebne prilike',
    title: 'Svečana',
    accent: 'odijela',
    text: 'Odijela za maturu i posebne prilike, uz cipele i dodatke koji zaokružuju izgled.',
    link: 'Pogledaj odijela',
    slug: 'odijela',
    tone: 'white',
  },
  {
    eyebrow: 'Vjenčanja · Mature · Gala',
    title: 'Svečani',
    accent: 'trenuci',
    text: 'Duge večernje haljine, koktel modeli, sandale na petu i torbice-pisma koje zaokružuju izgled.',
    link: 'Istraži kolekciju',
    slug: 'svecano',
    tone: 'champagne',
  },
]

// Galerija svečanih haljina. Prva slika je veća. Opis (alt) neka kaže što je na fotografiji, zbog Googlea i čitača zaslona.
export const HOME_LOOKBOOK = {
  eyebrow: 'Mature · Vjenčanja · Gala',
  title: 'Svečane haljine',
  text: 'Maturalne, večernje i elegantne haljine za večer koju ćete pamtiti. Pogledajte izbor i dođite ih isprobati u Mepas Mall.',
  link: { label: 'Pogledaj haljine', slug: 'haljine' },
  images: [
    { src: '', alt: 'Duga maturalna haljina' },
    { src: '', alt: 'Večernja haljina s detaljima' },
    { src: '', alt: 'Elegantna koktel haljina' },
    { src: '', alt: 'Svečana haljina za vjenčanje' },
    { src: '', alt: 'Maturalna haljina u pokretu' },
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

export const HOME_VISIT_IMAGE = ''

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
    question: 'Imate li i odijela za maturu?',
    answer: 'Da, osim haljina u ponudi su i odijela, cipele i svečani dodaci.',
  },
  {
    question: 'Mogu li isprobati model prije kupnje?',
    answer: 'Da, odabrane modele možete isprobati kod nas u trgovini u Mepas Mallu.',
  },
]
