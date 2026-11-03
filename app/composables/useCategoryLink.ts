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
