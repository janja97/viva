import type { ProductAuditEntry } from '~/types/database'

const PAGE_SIZE = 50

// Bez `productId` učitava povijest svih proizvoda, zajedno s obrisanima.
export function useProductAudit(productId?: string) {
  const supabase = useSupabase()

  const entries = ref<ProductAuditEntry[]>([])
  const total = ref(0)
  const page = ref(0)
  const isLoading = ref(true)
  const loadError = ref('')

  const pageCount = computed(() => Math.max(1, Math.ceil(total.value / PAGE_SIZE)))

  async function load() {
    isLoading.value = true
    loadError.value = ''

    let query = supabase
      .from('product_audit_log')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(page.value * PAGE_SIZE, (page.value + 1) * PAGE_SIZE - 1)
    if (productId) query = query.eq('product_id', productId)

    const { data, error, count } = await query
    isLoading.value = false
    if (error) {
      loadError.value = productErrorMessage(error)
      return
    }
    entries.value = data
    total.value = count ?? 0
  }

  return { entries, total, page, pageCount, isLoading, loadError, load }
}
