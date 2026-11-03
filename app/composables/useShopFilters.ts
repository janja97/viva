import type { ShopFilters, ShopSort } from '~/composables/useShop'

export const SHOP_SORTS: { value: ShopSort; label: string }[] = [
  { value: 'new', label: 'Najnovije' },
  { value: 'price_asc', label: 'Cijena: od najniže' },
  { value: 'price_desc', label: 'Cijena: od najviše' },
  { value: 'name', label: 'Naziv: A - Ž' },
]

const asList = (value: unknown) => (Array.isArray(value) ? value : value ? [value] : []).filter((item): item is string => typeof item === 'string' && item !== '')

function asPrice(value: unknown) {
  const price = typeof value === 'string' && value !== '' ? Number(value) : NaN
  return Number.isFinite(price) && price >= 0 ? price : null
}

// Filtri su u adresi, pa rade povratak u pregledniku i dijeljenje linka.
export function useShopFilters() {
  const route = useRoute()

  const filters = computed<ShopFilters>(() => {
    const sort = route.query.poredaj as ShopSort
    return {
      colors: asList(route.query.boja),
      sizes: asList(route.query.velicina),
      lengths: asList(route.query.duljina),
      heels: asList(route.query.peta),
      minPrice: asPrice(route.query.od),
      maxPrice: asPrice(route.query.do),
      inStock: route.query.dostupno === '1',
      onSale: route.query.snizeno === '1',
      sort: SHOP_SORTS.some((item) => item.value === sort) ? sort : 'new',
    }
  })

  const page = computed(() => Math.max(1, Math.floor(Number(route.query.stranica)) || 1))

  const activeCount = computed(() => filters.value.colors.length
    + filters.value.sizes.length
    + filters.value.lengths.length
    + filters.value.heels.length
    + (filters.value.minPrice !== null ? 1 : 0)
    + (filters.value.maxPrice !== null ? 1 : 0)
    + (filters.value.inStock ? 1 : 0)
    + (filters.value.onSale ? 1 : 0))

  // Ne indeksira se ništa osim osnovnog popisa, jer bi kombinacije filtara stvarale duplikate.
  const isFiltered = computed(() => activeCount.value > 0 || filters.value.sort !== 'new')

  function apply(patch: Partial<ShopFilters>) {
    const next = { ...filters.value, ...patch }
    // Promjena filtra vraća na prvu stranicu.
    return navigateTo({
      query: {
        ...(next.colors.length && { boja: next.colors }),
        ...(next.sizes.length && { velicina: next.sizes }),
        ...(next.lengths.length && { duljina: next.lengths }),
        ...(next.heels.length && { peta: next.heels }),
        ...(next.minPrice !== null && { od: String(next.minPrice) }),
        ...(next.maxPrice !== null && { do: String(next.maxPrice) }),
        ...(next.inStock && { dostupno: '1' }),
        ...(next.onSale && { snizeno: '1' }),
        ...(next.sort !== 'new' && { poredaj: next.sort }),
      },
    }, { replace: true })
  }

  function toggle(key: 'colors' | 'sizes' | 'lengths' | 'heels', value: string) {
    const list = filters.value[key]
    return apply({ [key]: list.includes(value) ? list.filter((item) => item !== value) : [...list, value] })
  }

  const clear = () => apply({ colors: [], sizes: [], lengths: [], heels: [], minPrice: null, maxPrice: null, inStock: false, onSale: false })

  return { filters, page, activeCount, isFiltered, apply, toggle, clear }
}
