// Isti izračun koristi forma za pregled i javna stranica proizvoda, kako bi prikaz bio točan.
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
}

// Boja je u naslovu i kod ručnog unosa, jer svaka boja ima svoju stranicu.
export function productSeoTitle({ name, colorName, categoryName, metaTitle }: ProductSeoInput) {
  const base = `${metaTitle.trim() || name.trim()} ${colorName.trim()}`.trim()
  if (metaTitle.trim() || !categoryName) return truncate(base, MAX_TITLE)
  const withCategory = `${base} - ${categoryName}`
  return withCategory.length <= MAX_TITLE ? withCategory : truncate(base, MAX_TITLE)
}

// Bez ručnog opisa: naziv i boja, opis proizvoda ili kategorija i cijena, pa kako se kupuje.
// Mostar i dostava po BiH su na kraju jer se po njima traži, a otpadaju prvi kad tekst ne stane.
export function productSeoDescription(input: ProductSeoInput) {
  if (input.metaDescription.trim()) return truncate(input.metaDescription, MAX_DESCRIPTION)

  const intro = `${input.name.trim()} u boji ${input.colorName.trim().toLowerCase()}.`
  const where = input.storeOnly
    ? 'Dostupno u trgovini u Mepas Mallu u Mostaru.'
    : 'Dostava po BiH, plaćanje pouzećem ili isprobajte u Mepas Mallu u Mostaru.'
  if (input.description.trim()) return truncate(`${intro} ${input.description} ${where}`, MAX_DESCRIPTION)

  const category = input.categoryName ? ` ${input.categoryName}.` : ''
  const price = input.price ? ` Cijena ${formatPrice(Number(input.price))}.` : ''
  return truncate(`${intro}${category}${price} ${where}`, MAX_DESCRIPTION)
}
