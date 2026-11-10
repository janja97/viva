import type { Countdown, CountdownInput } from '~/types/database'

export type CountdownStatus = 'disabled' | 'upcoming' | 'live' | 'ended'

export const COUNTDOWN_STATUSES: Record<CountdownStatus, { label: string; color: string }> = {
  disabled: { label: 'Isključeno', color: 'bg-stone-200 text-stone-700' },
  upcoming: { label: 'Odbrojava', color: 'bg-amber-100 text-amber-800' },
  live: { label: 'U tijeku', color: 'bg-emerald-100 text-emerald-800' },
  ended: { label: 'Završeno', color: 'bg-stone-200 text-stone-700' },
}

// Isto pravilo kao RLS u migraciji 0032: na webu je samo uključeno i nezavršeno.
export function countdownStatus(countdown: Pick<Countdown, 'is_enabled' | 'starts_at' | 'ends_at'>, now = Date.now()): CountdownStatus {
  if (now >= new Date(countdown.ends_at).getTime()) return 'ended'
  if (!countdown.is_enabled) return 'disabled'
  return now < new Date(countdown.starts_at).getTime() ? 'upcoming' : 'live'
}

// Odbrojavanja u adminu (/admin/odbrojavanja).
export function useCountdowns() {
  const supabase = useSupabase()

  const countdowns = ref<Countdown[]>([])
  const isLoading = ref(true)
  const loadError = ref('')

  async function load() {
    isLoading.value = true
    loadError.value = ''
    const { data, error } = await supabase.from('countdowns').select('*').order('starts_at', { ascending: false })
    isLoading.value = false
    if (error) {
      loadError.value = productErrorMessage(error)
      return
    }
    countdowns.value = data
  }

  async function save(input: CountdownInput, id?: string) {
    const query = id
      ? supabase.from('countdowns').update(input).eq('id', id)
      : supabase.from('countdowns').insert(input)
    const { error } = await query.select('id').single()
    if (error) throw error
    await load()
  }

  async function setEnabled(id: string, isEnabled: boolean) {
    const { error } = await supabase.from('countdowns').update({ is_enabled: isEnabled }).eq('id', id).select('id').single()
    if (error) throw error
    await load()
  }

  async function remove(id: string) {
    const { error } = await supabase.from('countdowns').delete().eq('id', id).select('id').single()
    if (error) throw error
    await load()
  }

  return { countdowns, isLoading, loadError, load, save, setEnabled, remove }
}

// Odbrojavanje za naslovnu: uključeno, nezavršeno, ono koje najranije počinje.
// Učitava se tek u pregledniku, jer se vrijeme ionako računa ondje.
export function useActiveCountdown() {
  const supabase = useSupabase()
  return useAsyncData(
    'active-countdown',
    async () => {
      const { data, error } = await supabase
        .from('countdowns')
        .select('*')
        .eq('is_enabled', true)
        .gt('ends_at', new Date().toISOString())
        .order('starts_at')
        .limit(1)
        .maybeSingle()
      if (error) throw error
      return data
    },
    { server: false, lazy: true, default: () => null },
  )
}
