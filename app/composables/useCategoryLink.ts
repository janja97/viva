import type { ShopNavLink } from '~/config/navigation'

// Dok kategorija ne postoji u bazi, poveznica vodi na kolekciju, a ne na praznu stranicu.
export function useCategoryLink() {
  const { fetchCategories } = useShop()
  const { data } = useAsyncData(
    'site-category-slugs',
    async () => (await fetchCategories()).map((category) => category.slug),
    { default: () => [] as string[] },
  )

  return (slug?: string) => (slug && data.value.includes(slug) ? `/kategorija/${slug}` : '/proizvodi')
}

// Poveznica i oznaka aktivne stavke za izbornik trgovine (zaglavlje i podnožje).
export function useShopNavLink() {
  const route = useRoute()
  const categoryLink = useCategoryLink()

  const to = (link: ShopNavLink) => ({ path: categoryLink(link.slug), query: link.query })

  // Stavka bez postojeće kategorije također vodi na kolekciju, pa se aktivna ne prepoznaje po poveznici.
  // "Novo" i "Popust" vode na isti popis, a razlikuje ih samo filtar sniženja.
  const isActive = (link: ShopNavLink) =>
    route.path === (link.slug ? `/kategorija/${link.slug}` : '/proizvodi')
    && route.query.snizeno === link.query?.snizeno

  return { to, isActive }
}
