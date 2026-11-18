import type { ShopCard } from '~/composables/useShop'

// Filtri i poredak akcijske stranice (npr. /ciscenje-zaliha): glavna kategorija, popust, boja, cijena od-do.
// Proizvoda je malo (do 96 po popustu), pa se filtrira i slaže u pregledniku. Stanje je u adresi.
export type PromoSort = 'new' | 'price_asc' | 'price_desc' | 'discount' | 'name'

export const PROMO_SORTS: { value: PromoSort; label: string }[] = [
  { value: 'new', label: 'Najnovije' },
  { value: 'price_asc', label: 'Cijena: od najniže' },
  { value: 'price_desc', label: 'Cijena: od najviše' },
  { value: 'discount', label: 'Najveći popust' },
  { value: 'name', label: 'Naziv: A - Ž' },
]

export type PromoFilters = {
  category: string
  colors: string[]
  discounts: number[]
  minPrice: number | null
  maxPrice: number | null
  sort: PromoSort
}

// Kartica s podacima za filtriranje: glavna kategorija (Haljine, Obuća...) i popust njezina odjeljka.
export type PromoCard = ShopCard & { mainCategory: { slug: string; name: string } | null; discount: number }

const asList = (value: unknown) => (Array.isArray(value) ? value : value ? [value] : []).filter((item): item is string => typeof item === 'string' && item !== '')
function asPrice(value: unknown) {
  const price = typeof value === 'string' && value !== '' ? Number(value) : NaN
  return Number.isFinite(price) && price >= 0 ? price : null
}

// Ponuđene vrijednosti: samo one koje postoje među proizvodima stranice.
export function promoFilterOptions(cards: PromoCard[]) {
  const categoryMap = new Map<string, string>()
  const colorMap = new Map<string, string>()
  for (const card of cards) {
    if (card.mainCategory) categoryMap.set(card.mainCategory.slug, card.mainCategory.name)
    const name = card.baseColor ?? card.colorName
    if (!colorMap.has(name)) colorMap.set(name, card.colors.find((color) => color.id === card.id)?.hex ?? '#ffffff')
  }
  const prices = cards.map((card) => card.price)
  const byName = (a: { name: string }, b: { name: string }) => a.name.localeCompare(b.name, 'hr')
  return {
    categories: [...categoryMap].map(([slug, name]) => ({ slug, name })).sort(byName),
    colors: [...colorMap].map(([name, hex]) => ({ name, hex })).sort(byName),
    discounts: [...new Set(cards.map((card) => card.discount))].sort((a, b) => b - a),
    price: prices.length ? { min: Math.floor(Math.min(...prices)), max: Math.ceil(Math.max(...prices)) } : null,
  }
}

export function usePromoFilters() {
  const route = useRoute()

  const filters = computed<PromoFilters>(() => {
    const sort = route.query.poredaj as PromoSort
    return {
      category: typeof route.query.kategorija === 'string' ? route.query.kategorija : '',
      colors: asList(route.query.boja),
      discounts: asList(route.query.popust).map(Number).filter((value) => Number.isInteger(value) && value >= 0),
      minPrice: asPrice(route.query.od),
      maxPrice: asPrice(route.query.do),
      sort: PROMO_SORTS.some((item) => item.value === sort) ? sort : 'new',
    }
  })

  // Poredak se ne broji kao filtar.
  const activeCount = computed(() => (filters.value.category ? 1 : 0) + filters.value.colors.length + filters.value.discounts.length
    + (filters.value.minPrice !== null ? 1 : 0) + (filters.value.maxPrice !== null ? 1 : 0))
  // Za Google: stranica s filtrom ili drugim poretkom je duplikat.
  const isFiltered = computed(() => activeCount.value > 0 || filters.value.sort !== 'new')

  function apply(patch: Partial<PromoFilters>) {
    const next = { ...filters.value, ...patch }
    return navigateTo({
      query: {
        ...(next.category && { kategorija: next.category }),
        ...(next.colors.length && { boja: next.colors }),
        ...(next.discounts.length && { popust: next.discounts.map(String) }),
        ...(next.minPrice !== null && { od: String(next.minPrice) }),
        ...(next.maxPrice !== null && { do: String(next.maxPrice) }),
        ...(next.sort !== 'new' && { poredaj: next.sort }),
      },
    }, { replace: true })
  }

  function toggleColor(name: string) {
    const list = filters.value.colors
    return apply({ colors: list.includes(name) ? list.filter((item) => item !== name) : [...list, name] })
  }

  function toggleDiscount(percent: number) {
    const list = filters.value.discounts
    return apply({ discounts: list.includes(percent) ? list.filter((item) => item !== percent) : [...list, percent] })
  }

  // Poredak ostaje.
  const clear = () => apply({ category: '', colors: [], discounts: [], minPrice: null, maxPrice: null })

  function matches(card: PromoCard) {
    const value = filters.value
    if (value.category && card.mainCategory?.slug !== value.category) return false
    if (value.colors.length && !value.colors.includes(card.baseColor ?? card.colorName)) return false
    if (value.discounts.length && !value.discounts.includes(card.discount)) return false
    if (value.minPrice !== null && card.price < value.minPrice) return false
    if (value.maxPrice !== null && card.price > value.maxPrice) return false
    return true
  }

  // Najnovije je redoslijed iz baze, pa se tada ne slaže.
  function sortCards(cards: PromoCard[]) {
    const sort = filters.value.sort
    if (sort === 'new') return cards
    const sorted = [...cards]
    if (sort === 'price_asc') sorted.sort((a, b) => a.price - b.price)
    if (sort === 'price_desc') sorted.sort((a, b) => b.price - a.price)
    if (sort === 'discount') sorted.sort((a, b) => b.discount - a.discount || a.price - b.price)
    if (sort === 'name') sorted.sort((a, b) => `${a.productName} ${a.colorName}`.localeCompare(`${b.productName} ${b.colorName}`, 'hr'))
    return sorted
  }

  return { filters, activeCount, isFiltered, apply, toggleColor, toggleDiscount, clear, matches, sortCards }
}
