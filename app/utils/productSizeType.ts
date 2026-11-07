import { CATEGORY_SIZE_TYPES, DRESS_CATEGORY_SLUG, SIZE_PRESETS } from '~/config/products'
import type { Category, SizeType } from '~/types/database'
import type { ProductForm } from '~/types/productForm'

// Vrsta veličina iz najbliže kategorije s pravilom, od odabrane prema gore. Bez pravila vraća null.
export function sizeTypeForCategory(categories: Category[], categoryId: string): SizeType | null {
  const path = categoryPath(categories, categoryId)
  for (const category of [...path].reverse()) {
    const type = CATEGORY_SIZE_TYPES[category.slug]
    if (type) return type
  }
  return null
}

export function isDressCategory(categories: Category[], categoryId: string) {
  return categoryPath(categories, categoryId).some((category) => category.slug === DRESS_CATEGORY_SLUG)
}

// Promjena vrste briše odabrane veličine, jer se veličine različitih vrsta ne poklapaju.
export function applySizeType(form: ProductForm, type: SizeType) {
  form.size_type = type
  form.sizes = type === 'universal' ? [...SIZE_PRESETS.universal] : []
}
