import type { AnalyticsBucket, DashboardBasic, SalesAnalytics, StockBySizeRow } from '~/types/database'

export type AnalyticsPeriod = 'month' | '3m' | '6m' | '9m' | '12m' | 'all'

// months: 0 je od početka ovog mjeseca, null je cijela povijest. Dulja razdoblja grupiraju se po tjednima i mjesecima.
export const ANALYTICS_PERIODS: { value: AnalyticsPeriod; label: string; months: number | null; bucket: AnalyticsBucket }[] = [
  { value: 'month', label: 'Ovaj mjesec', months: 0, bucket: 'day' },
  { value: '3m', label: 'Zadnja 3 mj.', months: 3, bucket: 'week' },
  { value: '6m', label: '6 mj.', months: 6, bucket: 'month' },
  { value: '9m', label: '9 mj.', months: 9, bucket: 'month' },
  { value: '12m', label: '12 mj.', months: 12, bucket: 'month' },
  { value: 'all', label: 'Sve', months: null, bucket: 'month' },
]

export const DEFAULT_ANALYTICS_PERIOD: AnalyticsPeriod = '3m'

// Tablica je po mjesecima, osim za ovaj mjesec, koji je po danima.
export const tableBucket = (period: AnalyticsPeriod): AnalyticsBucket => (period === 'month' ? 'day' : 'month')

function periodStart(months: number | null) {
  if (months === null) return null
  const now = new Date()
  if (months === 0) return new Date(now.getFullYear(), now.getMonth(), 1)
  const start = new Date(now)
  start.setMonth(start.getMonth() - months)
  return start
}

const dayFormat = new Intl.DateTimeFormat('hr-HR', { day: 'numeric', month: 'numeric' })
const monthFormat = new Intl.DateTimeFormat('hr-HR', { month: 'short', year: 'numeric' })

// Baza vraća početak razdoblja u vremenu Mostara, bez zone.
// Kratka oznaka (ispod osi grafa) kod tjedna piše samo datum početka.
export function analyticsBucketLabel(bucket: string, size: AnalyticsBucket, short = false) {
  const date = new Date(bucket)
  if (size === 'month') return monthFormat.format(date)
  if (size === 'week') return short ? dayFormat.format(date) : `tjedan od ${dayFormat.format(date)}`
  return dayFormat.format(date)
}

export function useDashboard() {
  const supabase = useSupabase()

  // Osnovni pregled za cijeli tim, bez iznosa.
  async function fetchBasic(): Promise<DashboardBasic> {
    const { data, error } = await supabase.rpc('admin_dashboard_basic')
    if (error) throw error
    return data
  }

  // Analitika prodaje. Baza je dopušta samo super adminu.
  // bucket mijenja grupiranje razdoblja, npr. tablica je po mjesecima i kad je graf po tjednima.
  async function fetchAnalytics(period: AnalyticsPeriod, bucket?: AnalyticsBucket): Promise<SalesAnalytics> {
    const option = ANALYTICS_PERIODS.find((item) => item.value === period)!
    const from = periodStart(option.months)?.toISOString() ?? null
    const { data, error } = await supabase.rpc('admin_sales_analytics', { p_from: from, p_to: null, p_bucket: bucket ?? option.bucket })
    if (error) throw error
    return data
  }

  // Zaliha po veličinama, bez iznosa (cijeli tim).
  async function fetchStockBySize(): Promise<StockBySizeRow[]> {
    const { data, error } = await supabase.rpc('admin_stock_by_size')
    if (error) throw error
    return data
  }

  return { fetchBasic, fetchAnalytics, fetchStockBySize }
}
