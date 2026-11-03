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

export function productSeoDescription(input: ProductSeoInput) {
  if (input.metaDescription.trim()) return truncate(input.metaDescription, MAX_DESCRIPTION)

  const intro = `${input.name.trim()} u boji ${input.colorName.trim().toLowerCase()}.`
  if (input.description.trim()) return truncate(`${intro} ${input.description}`, MAX_DESCRIPTION)

  const price = input.price ? ` Cijena ${formatPrice(Number(input.price))}.` : ''
  const availability = input.storeOnly ? ' Dostupno u poslovnicama.' : ' Pogledajte dostupne veličine.'
  return truncate(`${intro}${input.categoryName ? ` ${input.categoryName}.` : ''}${price}${availability}`, MAX_DESCRIPTION)
}
