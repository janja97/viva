import { PRODUCT_IMAGES_BUCKET } from '~/config/products'
import type { BulkProductChanges, Database, Product, ProductColor, ProductPayload } from '~/types/database'
import type { ProductForm } from '~/types/productForm'

const PAGE_SIZE = 25

const bySortOrder = <T extends { sort_order: number }>(items: T[]) =>
  [...items].sort((a, b) => a.sort_order - b.sort_order)

export function emptyProductForm(): ProductForm {
  return {
    id: crypto.randomUUID(),
    sku: '',
    name: '',
    category_id: '',
    extra_category_ids: [],
    brand: '',
    description: '',
    material: '',
    care: '',
    size_guide: '',
    size_type: 'clothing',
    price: '',
    campaign_id: '',
    dress_length: '',
    heel_height: '',
    weight_grams: '',
    is_visible: false,
    store_only: false,
    meta_title: '',
    meta_description: '',
    archived_at: null,
    sizes: [],
    colors: [],
  }
}

export function toProductPayload(form: ProductForm): ProductPayload {
  const name = form.name.trim()
  return {
    id: form.id,
    sku: form.sku.trim(),
    name,
    category_id: form.category_id,
    extra_category_ids: form.extra_category_ids.filter((id) => id !== form.category_id),
    brand: form.brand.trim() || null,
    description: form.description.trim() || null,
    material: form.material.trim() || null,
    care: form.care.trim() || null,
    size_guide: form.size_guide.trim() || null,
    size_type: form.size_type,
    price: Number(form.price),
    campaign_id: form.campaign_id || null,
    // Duljina vrijedi samo za odjeću, a peta samo za obuću.
    dress_length: form.size_type === 'clothing' ? form.dress_length || null : null,
    heel_height: form.size_type === 'footwear' ? form.heel_height || null : null,
    weight_grams: form.weight_grams === '' ? null : Number(form.weight_grams),
    is_visible: form.is_visible,
    store_only: form.store_only,
    meta_title: form.meta_title.trim() || null,
    meta_description: form.meta_description.trim() || null,
    colors: form.colors.map((color, colorIndex) => ({
      id: color.id,
      name: color.name.trim(),
      hex: color.hex,
      slug: color.slug,
      sort_order: colorIndex,
      sizes: form.sizes.map((size, sizeIndex) => ({
        size,
        quantity: Number(color.quantities[size] || 0),
        sort_order: sizeIndex,
      })),
      images: color.images.map((image, imageIndex) => ({
        id: image.id,
        path: image.path,
        alt: image.alt.trim() || `${name} ${color.name.trim()}`,
        sort_order: imageIndex,
      })),
    })),
  }
}

export function useProducts() {
  const supabase = useSupabase()

  async function fetchForm(id: string): Promise<ProductForm | null> {
    const { data, error } = await supabase
      .from('products')
      .select('*, product_internal(brand), product_categories(category_id), product_colors(*, product_sizes(*), product_images(*))')
      .eq('id', id)
      .maybeSingle()
    if (error) throw error
    if (!data) return null

    const colors = bySortOrder(data.product_colors)
    const sizes: string[] = []
    for (const color of colors) {
      for (const { size } of bySortOrder(color.product_sizes)) {
        if (!sizes.includes(size)) sizes.push(size)
      }
    }

    return {
      id: data.id,
      sku: data.sku,
      name: data.name,
      category_id: data.category_id,
      extra_category_ids: data.product_categories
        .map((link) => link.category_id)
        .filter((categoryId) => categoryId !== data.category_id),
      brand: data.product_internal?.brand ?? '',
      description: data.description ?? '',
      material: data.material ?? '',
      care: data.care ?? '',
      size_guide: data.size_guide ?? '',
      size_type: data.size_type,
      price: String(data.price),
      campaign_id: data.campaign_id ?? '',
      dress_length: data.dress_length ?? '',
      heel_height: data.heel_height ?? '',
      weight_grams: data.weight_grams === null ? '' : String(data.weight_grams),
      is_visible: data.is_visible,
      store_only: data.store_only,
      meta_title: data.meta_title ?? '',
      meta_description: data.meta_description ?? '',
      archived_at: data.archived_at,
      sizes,
      colors: colors.map((color) => ({
        id: color.id,
        name: color.name,
        hex: color.hex,
        slug: color.slug,
        autoSlug: false,
        quantities: Object.fromEntries(color.product_sizes.map(({ size, quantity }) => [size, String(quantity)])),
        images: bySortOrder(color.product_images).map(({ id: imageId, path, alt }) => ({ id: imageId, path, alt })),
      })),
    }
  }

  async function save(form: ProductForm) {
    const { error } = await supabase.rpc('save_product_with_categories', { payload: toProductPayload(form) })
    if (error) throw error
  }

  // Sve radnje ispod primaju jedan ili više proizvoda i vraćaju broj promijenjenih.

  // Baza ostavlja prvu sliku i vraća putanje ostalih, koje se brišu iz spremišta tek nakon uspjeha.
  async function archive(ids: string[]) {
    const { data: paths, error } = await supabase.rpc('archive_products', { p_ids: ids })
    if (error) throw error
    if (paths?.length) await supabase.storage.from(PRODUCT_IMAGES_BUCKET).remove(paths)
  }

  // Vraćeni proizvod ostaje skriven dok mu se ne dodaju slike i ne uključi vidljivost.
  async function restore(ids: string[]) {
    const { data, error } = await supabase.from('products').update({ archived_at: null }).in('id', ids).select('id')
    if (error) throw error
    return data.length
  }

  // Trajno brisanje dopušteno je samo za arhivirane proizvode.
  async function remove(ids: string[]) {
    const { data: images } = await supabase
      .from('product_images')
      .select('path, product_colors!inner(product_id)')
      .in('product_colors.product_id', ids)

    const { data, error } = await supabase.from('products').delete().in('id', ids).select('id')
    if (error) throw error
    if (!data.length) throw Object.assign(new Error(''), { code: '42501' })

    const deleted = new Set(data.map((product) => product.id))
    const paths = (images ?? []).filter((image) => deleted.has(image.product_colors.product_id)).map((image) => image.path)
    if (paths.length) await supabase.storage.from(PRODUCT_IMAGES_BUCKET).remove(paths)
    return data.length
  }

  // Objava, skrivanje, "samo u trgovini" i kampanja (sniženje) za više proizvoda odjednom.
  async function bulkUpdate(ids: string[], changes: BulkProductChanges) {
    const { data, error } = await supabase.rpc('bulk_update_products', { p_ids: ids, p_changes: changes })
    if (error) throw error
    return data
  }

  async function fetchStock(id: string) {
    const { data, error } = await supabase
      .from('products')
      .select('product_colors(id, name, hex, sort_order, product_sizes(id, size, quantity, sort_order))')
      .eq('id', id)
      .single()
    if (error) throw error
    return bySortOrder(data.product_colors).map(({ id: colorId, name, hex, product_sizes }) => ({
      id: colorId,
      name,
      hex,
      sizes: bySortOrder(product_sizes),
    }))
  }

  // Šalje razliku, a ne novu količinu, kako istodobna izmjena druge osobe ne bi bila pregažena.
  async function adjustStock(productId: string, changes: { size_id: string; delta: number }[]) {
    const { error } = await supabase.rpc('adjust_product_stock', { p_product_id: productId, p_changes: changes })
    if (error) throw error
  }

  async function fetchBrands() {
    const { data, error } = await supabase.rpc('product_brands')
    if (error) throw error
    return data ?? []
  }

  return { fetchForm, save, archive, restore, remove, bulkUpdate, fetchStock, adjustStock, fetchBrands }
}

export type ProductListRow = {
  id: string
  sku: string
  name: string
  price: number
  salePrice: number | null
  isVisible: boolean
  storeOnly: boolean
  categoryName: string
  brand: string | null
  colors: { id: string; name: string; hex: string }[]
  stock: number
  thumbnail: string | null
}

export type BulkAction = 'publish' | 'hide' | 'store_on' | 'store_off' | 'campaign' | 'archive' | 'restore' | 'delete'

export type ProductFilterOptions = Database['public']['Functions']['admin_product_filter_options']['Returns']

// Odabir "svih rezultata" ide do ove granice, kako jedna radnja ne bi zahvatila previše proizvoda.
export const MAX_BULK_SELECTION = 1000

// Filtriranje i redoslijed radi baza (admin_products), a ovdje se dohvaćaju podaci za prikaz.
export function useProductList() {
  const supabase = useSupabase()
  const storage = supabase.storage.from(PRODUCT_IMAGES_BUCKET)

  const rows = ref<ProductListRow[]>([])
  const total = ref(0)
  const options = ref<ProductFilterOptions | null>(null)
  const isLoading = ref(true)
  const loadError = ref('')

  const pageCount = computed(() => Math.max(1, Math.ceil(total.value / PAGE_SIZE)))

  // Odgovor starijeg zahtjeva ne smije prebrisati noviji kad se filtri brzo mijenjaju.
  let request = 0

  async function load(filters: Record<string, unknown>, sort: string, page: number) {
    const current = ++request
    isLoading.value = true
    loadError.value = ''

    try {
      const { data: result, error } = await supabase.rpc('admin_products', {
        p_filters: filters,
        p_sort: sort,
        p_limit: PAGE_SIZE,
        p_offset: page * PAGE_SIZE,
      })
      if (error) throw error

      let data: ProductRowData[] = []
      if (result.ids.length) {
        const response = await supabase
          .from('products')
          .select('id, sku, name, price, sale_price, is_visible, store_only, categories!products_category_id_fkey(name), product_internal(brand), product_colors(id, name, hex, sort_order, product_sizes(quantity), product_images(path, sort_order))')
          .in('id', result.ids)
        if (response.error) throw response.error
        data = response.data
      }
      if (current !== request) return

      const byId = new Map(data.map((product) => [product.id, toRow(product)]))
      rows.value = result.ids.flatMap((id) => byId.get(id) ?? [])
      total.value = result.total
    } catch (error) {
      if (current === request) loadError.value = productErrorMessage(error)
    } finally {
      if (current === request) isLoading.value = false
    }
  }

  // Ponuđene vrijednosti ovise samo o arhivi, kategoriji i vrsti, pa se ne učitavaju pri svakoj promjeni.
  async function loadOptions(filters: Record<string, unknown>) {
    const { data, error } = await supabase.rpc('admin_product_filter_options', { p_filters: filters })
    if (error) console.error(error)
    else options.value = data
  }

  async function fetchAllIds(filters: Record<string, unknown>, sort: string) {
    const { data, error } = await supabase.rpc('admin_products', {
      p_filters: filters,
      p_sort: sort,
      p_limit: MAX_BULK_SELECTION,
      p_offset: 0,
    })
    if (error) throw error
    return data.ids
  }

  function toRow(product: ProductRowData): ProductListRow {
    const colors = bySortOrder(product.product_colors)
    const firstImage = colors.flatMap((color) => bySortOrder(color.product_images))[0]
    return {
      id: product.id,
      sku: product.sku,
      name: product.name,
      price: Number(product.price),
      salePrice: product.sale_price === null || product.sale_price === undefined ? null : Number(product.sale_price),
      isVisible: product.is_visible,
      storeOnly: product.store_only,
      categoryName: product.categories?.name ?? '',
      brand: product.product_internal?.brand ?? null,
      colors: colors.map(({ id, name, hex }) => ({ id, name, hex })),
      stock: colors.flatMap((color) => color.product_sizes).reduce((sum, size) => sum + size.quantity, 0),
      thumbnail: firstImage ? storage.getPublicUrl(firstImage.path).data.publicUrl : null,
    }
  }

  return { rows, total, pageCount, options, isLoading, loadError, load, loadOptions, fetchAllIds }
}

type ProductRowData = Pick<Product, 'id' | 'sku' | 'name' | 'price' | 'sale_price' | 'is_visible' | 'store_only'> & {
  categories: { name: string } | null
  product_internal: { brand: string | null } | null
  product_colors: (Pick<ProductColor, 'id' | 'name' | 'hex' | 'sort_order'> & {
    product_sizes: { quantity: number }[]
    product_images: { path: string; sort_order: number }[]
  })[]
}
