// Smanjene slike za kartice proizvoda (ProductCard), preko Supabaseovih transformacija slika
// (/storage/v1/render/image). Original ostaje netaknut u spremištu, a Supabase sam šalje WebP pregledniku koji ga podržava.
//
// UVEDENO PROBNO (studeni 2026.). Transformacije se naplaćuju po broju različitih originalnih slika mjesečno
// (Pro plan ima 100 uključenih, zatim se plaća po 1000). Za POVRATAK na originalne slike postavi
// CARD_IMAGE_RESIZE = false: kartica tada koristi originalnu adresu i nema srcset. Ništa drugo ne treba mijenjati.
export const CARD_IMAGE_RESIZE = true

// Širine za srcset: mobitel (2 stupca), tablet i računalo (4 stupca), uz zaslone veće gustoće.
const CARD_WIDTHS = [300, 450, 600, 800]
const QUALITY = 75

const OBJECT_PATH = '/storage/v1/object/public/'
const RENDER_PATH = '/storage/v1/render/image/public/'

// Adresa smanjene slike zadane širine. Slike izvan Supabaseova spremišta i isključeno smanjivanje vraćaju original.
export function cardImageUrl(url: string, width: number) {
  if (!CARD_IMAGE_RESIZE || !url.includes(OBJECT_PATH)) return url
  return `${url.replace(OBJECT_PATH, RENDER_PATH)}?width=${width}&resize=contain&quality=${QUALITY}`
}

export function cardImageSrcset(url: string) {
  if (!CARD_IMAGE_RESIZE || !url.includes(OBJECT_PATH)) return undefined
  return CARD_WIDTHS.map((width) => `${cardImageUrl(url, width)} ${width}w`).join(', ')
}

// Kartica je pola širine do lg, a zatim trećina ili četvrtina (ProductGrid; uz filtre je i stupac uži).
export const CARD_IMAGE_SIZES = '(min-width: 1024px) 25vw, 50vw'
