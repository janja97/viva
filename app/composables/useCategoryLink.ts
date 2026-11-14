import { PROMO_PAGE_SLUGS, SHOP_NAV, type ShopNavLink } from '~/config/navigation'

export type SiteCategory = { id: string; name: string; slug: string; parent_id: string | null }

// Aktivne kategorije za izbornik i poveznice, učitane jednom za cijelu stranicu.
export function useSiteCategories() {
  const { fetchCategories } = useShop()
  return useAsyncData(
    'site-categories',
    async (): Promise<SiteCategory[]> =>
      (await fetchCategories()).map(({ id, name, slug, parent_id }) => ({ id, name, slug, parent_id })),
    { default: () => [] as SiteCategory[] },
  )
}

// Dok kategorija ne postoji u bazi, poveznica vodi na kolekciju, a ne na praznu stranicu.
export function useCategoryLink() {
  const { data } = useSiteCategories()
  return (slug?: string) => (slug && data.value.some((category) => category.slug === slug) ? `/kategorija/${slug}` : '/proizvodi')
}

// Poveznica, oznaka aktivne stavke i podkategorije za izbornik trgovine (zaglavlje i podnožje).
export function useShopNavLink() {
  const route = useRoute()
  const categoryLink = useCategoryLink()
  const { data: categories } = useSiteCategories()

  const to = (link: ShopNavLink) => (link.path ? { path: link.path } : { path: categoryLink(link.slug), query: link.query })

  // Stavka bez postojeće kategorije također vodi na kolekciju, pa se aktivna ne prepoznaje po poveznici.
  // "Novo" i "Popust" vode na isti popis, a razlikuje ih samo filtar sniženja.
  const isActive = (link: ShopNavLink) => link.path
    ? route.path === link.path
    : route.path === (link.slug ? `/kategorija/${link.slug}` : '/proizvodi')
    && route.query.snizeno === link.query?.snizeno

  // Izravne podkategorije stavke, redom kao u adminu.
  const subcategories = (link: ShopNavLink) => {
    const parent = link.slug && categories.value.find((category) => category.slug === link.slug)
    return parent ? childrenOf(categories.value, parent.id) : []
  }

  return { to, isActive, subcategories }
}

// Izbornik trgovine. Dok obična akcijska stranica traje, stavka "Popust" vodi na nju pod nazivom iz admina.
export function useShopNav() {
  const pages = PROMO_PAGE_SLUGS.map((slug) => useShopPromoPage(slug).data)
  return computed<ShopNavLink[]>(() => {
    const live = pages.flatMap((page) => (page.value?.state === 'live' ? [page.value] : []))
    const promo = live.find((page) => !page.is_exclusive)
    // Stranica "samo ovdje" (Čišćenje zaliha) ne zamjenjuje "Popust", jer ostali sniženi proizvodi ostaju u trgovini.
    const extra = live.filter((page) => page.is_exclusive)
      .map((page): ShopNavLink => ({ label: page.nav_label || page.title, path: `/${page.slug}`, highlight: true }))
    return [
      ...SHOP_NAV.map((link) => (link.query?.snizeno && promo
        ? { label: promo.nav_label || link.label, path: `/${promo.slug}`, highlight: true }
        : link)),
      ...extra,
    ]
  })
}
