import { PRODUCT_IMAGES_BUCKET } from '~/config/products'
import type { Category } from '~/types/database'

export const SHOP_PAGE_SIZE = 24
const SEARCH_LIMIT = 60

export type ShopCard = {
  id: string
  slug: string
  productName: string
  colorName: string
  categoryName: string
  // Cijena koju kupac plaća. Redovna je u `compareAtPrice`, samo kad je proizvod snižen.
  price: number
  compareAtPrice: number | null
  image: string | null
  alt: string
  soldOut: boolean
  storeOnly: boolean
  colors: { id: string; name: string; hex: string }[]
}

export type ShopSort = 'new' | 'price_asc' | 'price_desc' | 'name'

export type ShopFilters = {
  colors: string[]
  sizes: string[]
  lengths: string[]
  heels: string[]
  minPrice: number | null
  maxPrice: number | null
  inStock: boolean
  onSale: boolean
  sort: ShopSort
}

const bySortOrder = <T extends { sort_order: number }>(items: T[]) =>
  [...items].sort((a, b) => a.sort_order - b.sort_order)

// Podaci za javne stranice. Skriveni proizvodi filtriraju se i za prijavljene članove tima.
export function useShop() {
  const supabase = useSupabase()
  const imageUrl = (path: string) =>
    supabase.storage.from(PRODUCT_IMAGES_BUCKET).getPublicUrl(path).data.publicUrl

  async function fetchCategories(): Promise<Category[]> {
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .eq('is_active', true)
      .order('sort_order')
    if (error) throw error
    return data
  }

  // Svaka boja je zasebna kartica.
  async function fetchCards({ page = 0, pageSize = SHOP_PAGE_SIZE, categoryIds, productIds }: {
    page?: number
    pageSize?: number
    categoryIds?: string[]
    productIds?: string[]
  } = {}) {
    let query = supabase
      .from('products')
      .select(
        'id, name, price, sale_price, store_only, categories!products_category_id_fkey!inner(name, is_active), product_categories!inner(category_id), product_colors(id, name, hex, slug, sort_order, product_sizes(quantity), product_images(path, alt, sort_order))',
        { count: 'exact' },
      )
      .eq('is_visible', true)
      // Proizvod iz isključene glavne kategorije nije na webu, ni za prijavljene članove tima.
      .eq('categories.is_active', true)
      .order('created_at', { ascending: false })
      .range(page * pageSize, (page + 1) * pageSize - 1)
    // Vrijedi za glavnu i dodatne kategorije, jer su obje u ovoj tablici.
    if (categoryIds) query = query.in('product_categories.category_id', categoryIds)
    if (productIds) query = query.in('id', productIds)

    const { data, error, count } = await query
    if (error) throw error

    const cards: ShopCard[] = data.flatMap((product) => {
      const colors = bySortOrder(product.product_colors)
      return colors.map((color) => {
        const image = bySortOrder(color.product_images)[0]
        return {
          id: color.id,
          slug: color.slug,
          productName: product.name,
          colorName: color.name,
          categoryName: product.categories?.name ?? '',
          price: Number(product.sale_price ?? product.price),
          compareAtPrice: product.sale_price === null || product.sale_price === undefined ? null : Number(product.price),
          image: image ? imageUrl(image.path) : null,
          alt: image?.alt ?? `${product.name} ${color.name}`,
          soldOut: color.product_sizes.every((size) => size.quantity === 0),
          storeOnly: product.store_only,
          colors: colors.map(({ id, name, hex }) => ({ id, name, hex })),
        }
      })
    })

    return { cards, total: count ?? 0 }
  }

  // Traži po slugu, koji sadrži naziv, boju i šifru bez naših slova. Zato "sareno" nalazi "Šareno".
  // Zadnje slovo duljih riječi se zanemaruje, pa "haljine" nalazi i "haljina".
  async function searchCards(text: string) {
    const words = slugify(text)
      .split('-')
      .filter(Boolean)
      .map((word) => (word.length >= 5 ? word.slice(0, -1) : word))
    if (!words.length) return { cards: [], categories: [] }

    let colorQuery = supabase.from('product_colors').select('id, product_id').limit(SEARCH_LIMIT)
    for (const word of words) colorQuery = colorQuery.ilike('slug', `%${word}%`)
    const { data: colors, error } = await colorQuery
    if (error) throw error

    const allCategories = await fetchCategories()
    const categories = allCategories.filter((category) => words.every((word) => category.slug.includes(word)))

    const colorIds = new Set(colors.map((color) => color.id))
    const byColor = colors.length
      ? await fetchCards({ productIds: [...new Set(colors.map((color) => color.product_id))], pageSize: SEARCH_LIMIT })
      : { cards: [] }
    const byCategory = categories.length
      ? await fetchCards({ categoryIds: categories.map((category) => category.id), pageSize: SEARCH_LIMIT })
      : { cards: [] }

    const cards = new Map<string, ShopCard>()
    for (const card of byColor.cards) {
      if (colorIds.has(card.id)) cards.set(card.id, card)
    }
    for (const card of byCategory.cards) cards.set(card.id, card)

    return { cards: [...cards.values()], categories }
  }

  // Popisi s filtrima. Filtrira baza, kako bi straničenje i ukupan broj bili točni.
  async function filterCards(filters: ShopFilters, { page = 0, categoryIds }: { page?: number; categoryIds?: string[] } = {}) {
    const { data, error } = await supabase.rpc('shop_cards', {
      p_category_ids: categoryIds ?? null,
      p_colors: filters.colors.length ? filters.colors : null,
      p_sizes: filters.sizes.length ? filters.sizes : null,
      p_lengths: filters.lengths.length ? filters.lengths : null,
      p_heels: filters.heels.length ? filters.heels : null,
      p_min_price: filters.minPrice,
      p_max_price: filters.maxPrice,
      p_in_stock: filters.inStock,
      p_on_sale: filters.onSale,
      p_sort: filters.sort,
      p_limit: SHOP_PAGE_SIZE,
      p_offset: page * SHOP_PAGE_SIZE,
    })
    if (error) throw error

    const cards: ShopCard[] = data.cards.map(({ imagePath, imageAlt, ...card }) => ({
      ...card,
      categoryName: card.categoryName ?? '',
      price: Number(card.price),
      compareAtPrice: card.compareAtPrice === null ? null : Number(card.compareAtPrice),
      image: imagePath ? imageUrl(imagePath) : null,
      alt: imageAlt ?? `${card.productName} ${card.colorName}`,
    }))
    return { cards, total: data.total }
  }

  async function fetchFilterOptions(categoryIds?: string[]) {
    const { data, error } = await supabase.rpc('shop_filter_options', { p_category_ids: categoryIds ?? null })
    if (error) throw error
    return data
  }

  async function fetchProduct(slug: string) {
    const { data: match, error: matchError } = await supabase
      .from('product_colors')
      .select('product_id')
      .eq('slug', slug)
      .maybeSingle()
    if (matchError) throw matchError
    if (!match) return null

    const { data: product, error } = await supabase
      .from('products')
      .select('*, categories!products_category_id_fkey!inner(name, slug, is_active), product_colors(*, product_sizes(*), product_images(*))')
      .eq('id', match.product_id)
      .eq('categories.is_active', true)
      .eq('is_visible', true)
      .maybeSingle()
    if (error) throw error
    if (!product) return null

    const colors = bySortOrder(product.product_colors).map((color) => ({
      ...color,
      sizes: bySortOrder(color.product_sizes),
      images: bySortOrder(color.product_images).map((image) => ({ ...image, url: imageUrl(image.path) })),
    }))
    const color = colors.find((item) => item.slug === slug)
    return color ? { product, colors, color } : null
  }

  return { fetchCategories, fetchCards, filterCards, fetchFilterOptions, searchCards, fetchProduct }
}
