import type { SizeType } from '~/types/database'

export const PRODUCT_IMAGES_BUCKET = 'product-images'
export const MAX_IMAGE_BYTES = 5 * 1024 * 1024

// Vrste datoteka moraju odgovarati onima dopuštenima u spremištu (migracija 0004).
export const IMAGE_EXTENSIONS: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
  'image/avif': 'avif',
}

export const MULTICOLOR = 'Šareno'

// Popis boja u formi. Nijansa se koristi za kružić, a Šareno se prikazuje duginim prijelazom.
export const PRODUCT_COLORS: { name: string; hex: string }[] = [
  { name: 'Crna', hex: '#000000' },
  { name: 'Bijela', hex: '#ffffff' },
  { name: 'Siva', hex: '#9ca3af' },
  { name: 'Srebrna', hex: '#c0c0c0' },
  { name: 'Bež', hex: '#d6c3a5' },
  { name: 'Krem', hex: '#f5efdc' },
  { name: 'Smeđa', hex: '#6f4e37' },
  { name: 'Crvena', hex: '#dc2626' },
  { name: 'Bordo', hex: '#7f1d2d' },
  { name: 'Roza', hex: '#f472b6' },
  { name: 'Ljubičasta', hex: '#7e22ce' },
  { name: 'Plava', hex: '#2563eb' },
  { name: 'Teget', hex: '#1e2a4a' },
  { name: 'Tirkizna', hex: '#14b8a6' },
  { name: 'Zelena', hex: '#16a34a' },
  { name: 'Maslinasta', hex: '#6b7a3a' },
  { name: 'Žuta', hex: '#facc15' },
  { name: 'Narančasta', hex: '#f97316' },
  { name: 'Zlatna', hex: '#d4af37' },
  { name: MULTICOLOR, hex: '#ffffff' },
]

// Vrijednosti moraju odgovarati provjerama u bazi (migracija 0012).
export const DRESS_LENGTHS = [
  { value: 'mini', label: 'Mini' },
  { value: 'knee', label: 'Do koljena' },
  { value: 'midi', label: 'Midi' },
  { value: 'maxi', label: 'Duga' },
]

export const HEEL_HEIGHTS = [
  { value: 'flat', label: 'Ravna, bez pete' },
  { value: 'low', label: 'Niska, do 5 cm' },
  { value: 'medium', label: 'Srednja, 5 do 8 cm' },
  { value: 'high', label: 'Visoka, preko 8 cm' },
]

export const CURRENCY_CODE = 'BAM'
export const PRODUCT_PATH = '/proizvod'

export const UNIVERSAL_SIZE = 'Univerzalna'

export const SIZE_TYPES: { value: SizeType; label: string }[] = [
  { value: 'footwear', label: 'Obuća (brojevi)' },
  { value: 'clothing', label: 'Odjeća (oznake i brojevi)' },
  { value: 'bags', label: 'Torbice' },
  { value: 'universal', label: 'Univerzalna veličina' },
]

export const BAG_SIZES = ['Mini', 'Mala', 'Srednja', 'Velika']

// Veličine ponuđene kvačicama. Ostale se mogu upisati ručno.
export const SIZE_PRESETS: Record<SizeType, string[]> = {
  footwear: ['35', '36', '37', '38', '39', '40', '41', '42'],
  clothing: [
    'S', 'M', 'L', 'XL', 'XXL',
    ...Array.from({ length: 12 }, (_, index) => String(36 + index * 2)),
  ],
  bags: BAG_SIZES,
  universal: [UNIVERSAL_SIZE],
}

// Kategorija (ili bilo koja iznad nje) sama određuje vrstu veličina pri unosu proizvoda.
// Za ostale kategorije (npr. dodaci) vrsta se bira ručno.
export const CATEGORY_SIZE_TYPES: Record<string, SizeType> = {
  obuca: 'footwear',
  odjeca: 'clothing',
  haljine: 'clothing',
  torbice: 'bags',
}

// Duljina haljine nudi se samo za proizvode u ovoj kategoriji ili ispod nje.
export const DRESS_CATEGORY_SLUG = 'haljine'

// Skupine na nadzornoj ploči (Zalihe, "Zaliha po veličinama"). Svaka uključuje i svoje podkategorije.
// Kategorija koje nema u bazi se preskače, a ostale se mogu pogledati izbornikom.
export const STOCK_GROUP_SLUGS = ['haljine', 'kompleti-i-sakoi', 'kaputi', 'obuca', 'torbice', 'dodaci']
