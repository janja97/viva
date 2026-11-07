import type { Inquiry, InquiryAuditEntry, InquiryItem, InquiryStatus } from '~/types/database'

const PAGE_SIZE = 25

export const INQUIRY_STATUSES: { value: InquiryStatus; label: string; color: string }[] = [
  { value: 'new', label: 'Novo', color: 'bg-amber-100 text-amber-800' },
  { value: 'in_progress', label: 'U obradi', color: 'bg-primary-200 text-primary-900' },
  { value: 'sold', label: 'Prodano', color: 'bg-emerald-100 text-emerald-800' },
  { value: 'cancelled', label: 'Otkazano', color: 'bg-stone-200 text-stone-700' },
]

export const inquiryStatusLabel = (status: InquiryStatus | null) =>
  INQUIRY_STATUSES.find((item) => item.value === status)?.label ?? ''

export type InquiryWithItems = Inquiry & { inquiry_items: InquiryItem[] }

// Broj novih narudžbi i onih u obradi, za oznake u izborniku i gornjoj traci. Zajednički je za cijeli admin.
export function useNewInquiries() {
  const supabase = useSupabase()
  const count = useState('new-inquiries', () => 0)
  const inProgressCount = useState('in-progress-inquiries', () => 0)

  async function countByStatus(status: InquiryStatus) {
    const { count: total, error } = await supabase
      .from('inquiries')
      .select('id', { count: 'exact', head: true })
      .eq('status', status)
    if (error) throw error
    return total ?? 0
  }

  async function refresh() {
    try {
      ;[count.value, inProgressCount.value] = await Promise.all([countByStatus('new'), countByStatus('in_progress')])
    } catch (error) {
      console.error(error)
    }
  }

  return { count, inProgressCount, refresh }
}

// Narudžbe kupaca. Upisuje ih samo baza (shop_submit_inquiry), a ovdje se pregledavaju i mijenja im se status.
export function useInquiries() {
  const supabase = useSupabase()

  const rows = ref<InquiryWithItems[]>([])
  const total = ref(0)
  const page = ref(0)
  const status = ref<InquiryStatus | ''>('')
  const isLoading = ref(true)
  const loadError = ref('')

  const pageCount = computed(() => Math.max(1, Math.ceil(total.value / PAGE_SIZE)))

  async function load() {
    isLoading.value = true
    loadError.value = ''
    let query = supabase
      .from('inquiries')
      .select('*, inquiry_items(*)', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(page.value * PAGE_SIZE, (page.value + 1) * PAGE_SIZE - 1)
    if (status.value) query = query.eq('status', status.value)

    const { data, error, count } = await query
    isLoading.value = false
    if (error) {
      loadError.value = productErrorMessage(error)
      return
    }
    rows.value = data
    total.value = count ?? 0
  }

  // Baza upisuje tko je i kada promijenio status, pa se narudžba zamjenjuje svježom.
  async function setStatus(id: string, next: InquiryStatus) {
    const { data, error } = await supabase
      .from('inquiries')
      .update({ status: next })
      .eq('id', id)
      .select('*, inquiry_items(*)')
      .single()
    if (error) throw error
    rows.value = rows.value.map((row) => (row.id === id ? data : row))
  }

  async function remove(id: string) {
    const { error } = await supabase.from('inquiries').delete().eq('id', id).select('id').single()
    if (error) throw error
  }

  // Tko je i kada mijenjao narudžbu, od najnovije promjene.
  async function fetchHistory(id: string): Promise<InquiryAuditEntry[]> {
    const { data, error } = await supabase
      .from('inquiry_audit_log')
      .select('*')
      .eq('inquiry_id', id)
      .order('created_at', { ascending: false })
    if (error) throw error
    return data
  }

  return { rows, total, page, pageCount, status, isLoading, loadError, load, setStatus, remove, fetchHistory }
}
