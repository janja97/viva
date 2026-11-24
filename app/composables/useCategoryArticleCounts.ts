import type { Category } from '~/types/database'

// Broj artikala po kategoriji za /admin/kategorije. Artikl je jedna boja proizvoda
// (haljina u dvije boje su dva artikla). Broje se svi nearhivirani proizvodi, i skriveni,
// u kategoriji i svim njezinim podkategorijama, kao glavna ili dodatna kategorija (product_categories),
// isto kao što ih prikazuje web. Proizvod se u istoj kategoriji broji samo jednom.
type ProductRow = { id: string; product_colors: { id: string }[] }
type LinkRow = { product_id: string; category_id: string }

export function useCategoryArticleCounts(categories: Ref<Category[]>) {
  const supabase = useSupabase()
  const colorsByProduct = ref(new Map<string, number>())
  const productsByCategory = ref(new Map<string, string[]>())
  const isLoaded = ref(false)

  async function loadCounts() {
    try {
      const [products, links] = await Promise.all([
        fetchAllRows<ProductRow>((from, to) => supabase
          .from('products')
          .select('id, product_colors(id)')
          .is('archived_at', null)
          .order('id')
          .range(from, to) as unknown as PromiseLike<{ data: ProductRow[] | null; error: unknown }>),
        fetchAllRows<LinkRow>((from, to) => supabase
          .from('product_categories')
          .select('product_id, category_id')
          .order('product_id')
          .order('category_id')
          .range(from, to)),
      ])
      colorsByProduct.value = new Map(products.map((product) => [product.id, product.product_colors.length]))
      const grouped = new Map<string, string[]>()
      for (const link of links) grouped.set(link.category_id, [...(grouped.get(link.category_id) ?? []), link.product_id])
      productsByCategory.value = grouped
      isLoaded.value = true
    } catch {
      // Broj je samo pomoćni podatak, pa greška ne smeta radu s kategorijama.
      isLoaded.value = false
    }
  }

  const counts = computed(() => {
    const result = new Map<string, number>()
    if (!isLoaded.value) return result
    const childrenOf = (id: string) => categories.value.filter((category) => category.parent_id === id)
    const subtree = (id: string): string[] => [id, ...childrenOf(id).flatMap((child) => subtree(child.id))]
    for (const category of categories.value) {
      const productIds = new Set(subtree(category.id).flatMap((id) => productsByCategory.value.get(id) ?? []))
      let total = 0
      for (const productId of productIds) total += colorsByProduct.value.get(productId) ?? 0
      result.set(category.id, total)
    }
    return result
  })

  return { counts, loadCounts }
}
