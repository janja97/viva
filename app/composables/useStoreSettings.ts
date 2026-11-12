import { DEFAULT_STORE_SETTINGS, WEEK_DAYS, shippingFor as shippingForSettings } from '~/config/store'
import type { OpeningHoursDay, StoreSettings, StoreSettingsInput } from '~/types/database'

// Postavke trgovine (tablica store_settings) za web i admin. Učitavaju se jednom za cijelu stranicu (SSR).
// Ako baza ne odgovori, web radi sa zadanim vrijednostima iz config/store.ts.
export function useStoreSettings() {
  const supabase = useSupabase()

  const asyncData = useAsyncData(
    'store-settings',
    async (): Promise<StoreSettings> => {
      const { data: row, error } = await supabase.from('store_settings').select('*').maybeSingle()
      if (error) throw error
      return row ?? DEFAULT_STORE_SETTINGS
    },
    { default: () => DEFAULT_STORE_SETTINGS },
  )
  const { data, refresh } = asyncData
  // Stranice koje postavke koriste u JSON-LD-u čekaju ih prije useHead.
  const ready = async () => { await asyncData }

  const settings = computed(() => data.value ?? DEFAULT_STORE_SETTINGS)

  // Npr. "Pon – Sub 09:00 – 21:00 · Ned 12:00 – 20:00": uzastopni dani s istim vremenom spajaju se.
  const hoursText = computed(() => groupHours(settings.value.opening_hours)
    .map(({ from, to, hours }) => `${from === to ? from : `${from} – ${to}`} ${hours}`)
    .join(' · '))

  const socialLinks = computed(() => [
    { label: 'Instagram', url: settings.value.instagram_url },
    { label: 'Facebook', url: settings.value.facebook_url },
  ].filter((item) => item.url))

  const shippingFor = (subtotal: number) => shippingForSettings(subtotal, settings.value)

  async function save(input: StoreSettingsInput) {
    const { error } = await supabase.from('store_settings').update(input).eq('id', true)
    if (error) throw error
    await refresh()
  }

  return { settings, hoursText, socialLinks, shippingFor, save, refresh, ready }
}

function groupHours(days: OpeningHoursDay[]) {
  const label = (day: OpeningHoursDay) => (day.closed ? 'zatvoreno' : `${day.opens} – ${day.closes}`)
  const short = (day: OpeningHoursDay) => WEEK_DAYS.find((item) => item.value === day.day)?.short ?? day.day
  const groups: { from: string; to: string; hours: string }[] = []
  for (const day of days) {
    const last = groups.at(-1)
    if (last && last.hours === label(day)) last.to = short(day)
    else groups.push({ from: short(day), to: short(day), hours: label(day) })
  }
  return groups
}

// Broj telefona za poveznice tel:, WhatsApp i Viber (samo znamenke, uz + na početku).
export const phoneDigits = (phone: string) => phone.replace(/[^\d+]/g, '')
