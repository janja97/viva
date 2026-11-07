import type { PromoCode } from '~/types/database'

export type PromoCodeStatus = 'active' | 'paused' | 'scheduled' | 'ended' | 'used'

export const PROMO_CODE_STATUSES: Record<PromoCodeStatus, { label: string; color: string }> = {
  active: { label: 'Aktivan', color: 'bg-emerald-100 text-emerald-800' },
  paused: { label: 'Pauziran', color: 'bg-amber-100 text-amber-800' },
  scheduled: { label: 'Zakazan', color: 'bg-primary-200 text-primary-900' },
  ended: { label: 'Istekao', color: 'bg-stone-200 text-stone-700' },
  used: { label: 'Iskorišten', color: 'bg-stone-200 text-stone-700' },
}

// Isto pravilo kao promo_code_is_valid u bazi (migracija 0025).
export function promoCodeStatus(code: PromoCode, now = Date.now()): PromoCodeStatus {
  if (code.max_uses !== null && code.used_count >= code.max_uses) return 'used'
  if (!code.is_active) return 'paused'
  if (now < new Date(code.starts_at).getTime()) return 'scheduled'
  if (now >= new Date(code.ends_at).getTime()) return 'ended'
  return 'active'
}

export type PromoCodeInput = Pick<PromoCode, 'code' | 'name' | 'discount_percent' | 'starts_at' | 'ends_at'>

// Vlastiti kodovi (npr. za Dan drame). Vrijede više puta, od početka do kraja.
export function usePromoCodes() {
  const supabase = useSupabase()

  const codes = ref<PromoCode[]>([])
  const isLoading = ref(true)
  const loadError = ref('')

  async function load() {
    isLoading.value = true
    loadError.value = ''
    const { data, error } = await supabase
      .from('promo_codes')
      .select('*')
      .eq('kind', 'manual')
      .order('created_at', { ascending: false })
    isLoading.value = false
    if (error) loadError.value = productErrorMessage(error)
    else codes.value = data
  }

  async function save(input: PromoCodeInput, id?: string) {
    const query = id
      ? supabase.from('promo_codes').update(input).eq('id', id)
      : supabase.from('promo_codes').insert({ ...input, kind: 'manual' })
    const { error } = await query.select('id').single()
    if (error) throw error
    await load()
  }

  async function setActive(id: string, isActive: boolean) {
    const { error } = await supabase.from('promo_codes').update({ is_active: isActive }).eq('id', id).select('id').single()
    if (error) throw error
    await load()
  }

  // Narudžbe s ovim kodom zadržavaju upisani kod i iznos popusta.
  async function remove(id: string) {
    const { error } = await supabase.from('promo_codes').delete().eq('id', id).select('id').single()
    if (error) throw error
    await load()
  }

  return { codes, isLoading, loadError, load, save, setActive, remove }
}
