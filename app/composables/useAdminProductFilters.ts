import type { LocationQueryRaw } from 'vue-router'
import type { SizeType } from '~/types/database'

export type AdminProductSort = 'new' | 'old' | 'price_asc' | 'price_desc' | 'qty_asc' | 'qty_desc' | 'name' | 'archived'

export const ADMIN_PRODUCT_SORTS: { value: AdminProductSort; label: string }[] = [
  { value: 'new', label: 'Najnovije' },
  { value: 'old', label: 'Najstarije' },
  { value: 'price_asc', label: 'Cijena: od najniže' },
  { value: 'price_desc', label: 'Cijena: od najviše' },
  { value: 'qty_asc', label: 'Količina: od najmanje' },
  { value: 'qty_desc', label: 'Količina: od najveće' },
  { value: 'name', label: 'Naziv: A - Ž' },
  { value: 'archived', label: 'Zadnje arhivirano' },
]

// Vrijednost filtra brenda za proizvode bez upisanog brenda.
export const NO_BRAND = '__bez'

export type AdminProductFilters = {
  archived: boolean
  search: string
  categoryId: string
  sizeType: SizeType | ''
  brand: string
  colors: string[]
  sizes: string[]
  minPrice: number | null
  maxPrice: number | null
  minQty: number | null
  maxQty: number | null
  visible: boolean | null
  storeOnly: boolean | null
  onSale: boolean | null
  missingImages: boolean
  sort: AdminProductSort
}

const SIZE_TYPE_VALUES: SizeType[] = ['clothing', 'footwear', 'bags', 'universal']

const asText = (value: unknown) => (typeof value === 'string' ? value : '')
const asList = (value: unknown) => (Array.isArray(value) ? value : value ? [value] : []).filter((item): item is string => typeof item === 'string' && item !== '')
const asYesNo = (value: unknown) => (value === 'da' ? true : value === 'ne' ? false : null)
const yesNo = (value: boolean | null) => (value === null ? undefined : value ? 'da' : 'ne')

function asNumber(value: unknown) {
  const number = typeof value === 'string' && value !== '' ? Number(value) : NaN
  return Number.isFinite(number) && number >= 0 ? number : null
}

// Filtri su u adresi, pa ostaju nakon povratka s uređivanja proizvoda.
export function useAdminProductFilters() {
  const route = useRoute()

  const filters = computed<AdminProductFilters>(() => {
    const { query } = route
    const archived = query.arhiva === '1'
    const sort = query.poredaj as AdminProductSort
    const sizeType = query.vrsta as SizeType
    return {
      archived,
      search: asText(query.q),
      categoryId: asText(query.kategorija),
      sizeType: SIZE_TYPE_VALUES.includes(sizeType) ? sizeType : '',
      brand: asText(query.brend),
      colors: asList(query.boja),
      sizes: asList(query.velicina),
      minPrice: asNumber(query.od),
      maxPrice: asNumber(query.do),
      minQty: asNumber(query.kolicina_od),
      maxQty: asNumber(query.kolicina_do),
      visible: asYesNo(query.web),
      storeOnly: asYesNo(query.trgovina),
      onSale: asYesNo(query.snizeno),
      missingImages: query.bez_slike === '1',
      sort: ADMIN_PRODUCT_SORTS.some((item) => item.value === sort) ? sort : archived ? 'archived' : 'new',
    }
  })

  const page = computed(() => Math.max(0, Math.floor(Number(route.query.stranica) - 1) || 0))

  // Arhiva, pretraga i redoslijed se ne broje kao filtri.
  const activeCount = computed(() => {
    const value = filters.value
    return [
      value.categoryId, value.sizeType, value.brand, value.missingImages,
      value.minPrice !== null, value.maxPrice !== null, value.minQty !== null, value.maxQty !== null,
      value.visible !== null, value.storeOnly !== null, value.onSale !== null,
    ].filter(Boolean).length + value.colors.length + value.sizes.length
  })

  function toQuery(value: AdminProductFilters, targetPage = 0): LocationQueryRaw {
    const defaultSort = value.archived ? 'archived' : 'new'
    return {
      ...(value.archived && { arhiva: '1' }),
      ...(value.search && { q: value.search }),
      ...(value.categoryId && { kategorija: value.categoryId }),
      ...(value.sizeType && { vrsta: value.sizeType }),
      ...(value.brand && { brend: value.brand }),
      ...(value.colors.length && { boja: value.colors }),
      ...(value.sizes.length && { velicina: value.sizes }),
      ...(value.minPrice !== null && { od: String(value.minPrice) }),
      ...(value.maxPrice !== null && { do: String(value.maxPrice) }),
      ...(value.minQty !== null && { kolicina_od: String(value.minQty) }),
      ...(value.maxQty !== null && { kolicina_do: String(value.maxQty) }),
      web: yesNo(value.visible),
      trgovina: yesNo(value.storeOnly),
      snizeno: yesNo(value.onSale),
      ...(value.missingImages && { bez_slike: '1' }),
      ...(value.sort !== defaultSort && { poredaj: value.sort }),
      ...(targetPage > 0 && { stranica: String(targetPage + 1) }),
    }
  }

  // Svaka promjena filtra vraća na prvu stranicu.
  function apply(patch: Partial<AdminProductFilters>) {
    const next = { ...filters.value, ...patch }
    // Druga kategorija ili vrsta nudi druge veličine, pa se stare poništavaju.
    if (('categoryId' in patch || 'sizeType' in patch) && !('sizes' in patch)) next.sizes = []
    return navigateTo({ query: toQuery(next) }, { replace: true })
  }

  function toggle(key: 'colors' | 'sizes', value: string) {
    const list = filters.value[key]
    return apply({ [key]: list.includes(value) ? list.filter((item) => item !== value) : [...list, value] })
  }

  const goToPage = (target: number) => navigateTo({ query: toQuery(filters.value, target) })

  // Arhiva ima svoje filtre, pa prelazak briše postojeće.
  const showArchived = (archived: boolean) => navigateTo({ query: archived ? { arhiva: '1' } : {} })

  const clear = () => navigateTo({
    query: toQuery({
      ...filters.value,
      categoryId: '', sizeType: '', brand: '', colors: [], sizes: [],
      minPrice: null, maxPrice: null, minQty: null, maxQty: null,
      visible: null, storeOnly: null, onSale: null, missingImages: false,
    }),
  }, { replace: true })

  // Oblik koji očekuje baza. Kategorija uključuje i sve podkategorije.
  function toRpcFilters(value: AdminProductFilters, categoryIds: string[]) {
    return {
      archived: value.archived,
      search: value.search,
      category_ids: categoryIds,
      size_types: value.sizeType ? [value.sizeType] : [],
      brand: value.brand === NO_BRAND ? null : value.brand || null,
      no_brand: value.brand === NO_BRAND,
      colors: value.colors,
      sizes: value.sizes,
      min_price: value.minPrice,
      max_price: value.maxPrice,
      min_qty: value.minQty,
      max_qty: value.maxQty,
      visible: value.visible,
      store_only: value.storeOnly,
      on_sale: value.onSale,
      missing_images: value.missingImages,
    }
  }

  return { filters, page, activeCount, apply, toggle, goToPage, showArchived, clear, toRpcFilters }
}
