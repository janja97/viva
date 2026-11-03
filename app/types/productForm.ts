import type { SizeType } from '~/types/database'

export type ImageForm = {
  id: string
  path: string
  alt: string
}

export type ColorForm = {
  id: string
  name: string
  hex: string
  slug: string
  // URL prati naziv samo dok boja nije spremljena i dok ga korisnik ne promijeni.
  autoSlug: boolean
  quantities: Record<string, string>
  images: ImageForm[]
}

export type ProductForm = {
  id: string
  sku: string
  name: string
  category_id: string
  extra_category_ids: string[]
  // Interni podatak, kupci ga ne vide.
  brand: string
  description: string
  material: string
  care: string
  size_guide: string
  size_type: SizeType
  price: string
  discount_percent: string
  dress_length: string
  heel_height: string
  weight_grams: string
  is_visible: boolean
  store_only: boolean
  meta_title: string
  meta_description: string
  // Samo za prikaz: arhivirani proizvod se ne uređuje dok se ne vrati iz arhive.
  archived_at: string | null
  sizes: string[]
  colors: ColorForm[]
}
