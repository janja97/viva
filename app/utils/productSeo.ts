// Isti izračun koristi forma za pregled i javna stranica proizvoda, kako bi prikaz bio točan.
import { DRESS_LENGTHS, HEEL_HEIGHTS } from '~/config/products'

const MAX_TITLE = 60
const MAX_DESCRIPTION = 155

function truncate(text: string, max: number) {
  const clean = text.replace(/\s+/g, ' ').trim()
  if (clean.length <= max) return clean
  const cut = clean.slice(0, max - 1)
  const lastSpace = cut.lastIndexOf(' ')
  return `${(lastSpace > 0 ? cut.slice(0, lastSpace) : cut).replace(/[\s,.;:-]+$/, '')}…`
}

interface ProductSeoInput {
  name: string
  colorName: string
  categoryName: string
  description: string
  price: string
  storeOnly: boolean
  metaTitle: string
  metaDescription: string
  // Šifra razlikuje modele istog naziva i boje (npr. više "Čizme Crna"), pa je u naslovu i opisu.
  sku?: string
  dressLength?: string | null
  heelHeight?: string | null
}

// Duljina haljine i visina pete, kao dodatna razlika među sličnim modelima u opisu.
function details({ dressLength, heelHeight }: ProductSeoInput) {
  const length = DRESS_LENGTHS.find((item) => item.value === dressLength)?.label
  const heel = HEEL_HEIGHTS.find((item) => item.value === heelHeight)?.label
  return [length && `Duljina: ${length.toLowerCase()}.`, heel && `Peta: ${heel.toLowerCase()}.`].filter(Boolean).join(' ')
}

// Boja je u naslovu i kod ručnog unosa, jer svaka boja ima svoju stranicu.
// Šifra ide uz naziv i boju (osim ako je već upisana u ručni naslov), jer se modeli istog naziva razlikuju samo po njoj.
export function productSeoTitle({ name, colorName, categoryName, metaTitle, sku = '' }: ProductSeoInput) {
  const manual = metaTitle.trim()
  const code = sku.trim()
  const head = `${manual || name.trim()} ${colorName.trim()}`.trim()
  const base = code && !head.toLowerCase().includes(code.toLowerCase()) ? `${head} ${code}` : head
  if (manual || !categoryName) return truncate(base, MAX_TITLE)
  const withCategory = `${base} - ${categoryName}`
  return withCategory.length <= MAX_TITLE ? withCategory : truncate(base, MAX_TITLE)
}

// Bez ručnog opisa: naziv, boja i šifra, opis proizvoda ili kategorija, duljina ili peta i cijena, pa kako se kupuje.
// Mostar i dostava po BiH su na kraju jer se po njima traži, a otpadaju prvi kad tekst ne stane.
export function productSeoDescription(input: ProductSeoInput) {
  if (input.metaDescription.trim()) return truncate(input.metaDescription, MAX_DESCRIPTION)

  const code = input.sku?.trim() ? `, šifra ${input.sku.trim()}` : ''
  const intro = `${input.name.trim()} u boji ${input.colorName.trim().toLowerCase()}${code}.`
  const where = input.storeOnly
    ? 'Dostupno u trgovini u Mepas Mallu u Mostaru.'
    : 'Dostava po BiH, plaćanje pouzećem ili isprobajte u Mepas Mallu u Mostaru.'
  if (input.description.trim()) return truncate(`${intro} ${input.description} ${where}`, MAX_DESCRIPTION)

  const category = input.categoryName ? ` ${input.categoryName}.` : ''
  const extra = details(input)
  const price = input.price ? ` Cijena ${formatPrice(Number(input.price))}.` : ''
  return truncate(`${intro}${category}${extra ? ` ${extra}` : ''}${price} ${where}`, MAX_DESCRIPTION)
}
