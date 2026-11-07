import type { Campaign } from '~/types/database'

export type CampaignInput = Pick<Campaign, 'name' | 'kind' | 'discount_percent' | 'starts_at' | 'ends_at'>

export type CampaignStatus = 'active' | 'paused' | 'scheduled' | 'ended'

export const CAMPAIGN_STATUSES: Record<CampaignStatus, { label: string; color: string }> = {
  active: { label: 'Aktivna', color: 'bg-emerald-100 text-emerald-800' },
  paused: { label: 'Pauzirana', color: 'bg-amber-100 text-amber-800' },
  scheduled: { label: 'Zakazana', color: 'bg-primary-200 text-primary-900' },
  ended: { label: 'Završena', color: 'bg-stone-200 text-stone-700' },
}

// Isto pravilo kao campaign_percent u bazi (migracija 0024): sniženje vrijedi samo dok je kampanja aktivna.
export function campaignStatus(campaign: Campaign, now = Date.now()): CampaignStatus {
  if (campaign.is_paused) return 'paused'
  if (campaign.kind === 'permanent') return 'active'
  if (now < new Date(campaign.starts_at!).getTime()) return 'scheduled'
  if (now >= new Date(campaign.ends_at!).getTime()) return 'ended'
  return 'active'
}

// Npr. "Zimsko sniženje · -20 % · Aktivna", za izbornike u formi i skupnim radnjama.
export function campaignOptionLabel(campaign: Campaign) {
  return `${campaign.name} · -${campaign.discount_percent} % · ${CAMPAIGN_STATUSES[campaignStatus(campaign)].label}`
}

export function useCampaigns() {
  const supabase = useSupabase()

  const campaigns = ref<Campaign[]>([])
  // Broj aktivnih (nearhiviranih) proizvoda po kampanji.
  const productCounts = ref<Record<string, number>>({})
  const isLoading = ref(true)
  const loadError = ref('')

  async function load() {
    isLoading.value = true
    loadError.value = ''
    const [campaignResult, productResult] = await Promise.all([
      supabase.from('campaigns').select('*').order('created_at', { ascending: false }),
      supabase.from('products').select('campaign_id').not('campaign_id', 'is', null).is('archived_at', null),
    ])
    isLoading.value = false
    if (campaignResult.error || productResult.error) {
      loadError.value = productErrorMessage(campaignResult.error ?? productResult.error)
      return
    }
    campaigns.value = campaignResult.data
    productCounts.value = productResult.data.reduce<Record<string, number>>((counts, row) => {
      if (row.campaign_id) counts[row.campaign_id] = (counts[row.campaign_id] ?? 0) + 1
      return counts
    }, {})
  }

  async function save(input: CampaignInput, id?: string) {
    const query = id
      ? supabase.from('campaigns').update(input).eq('id', id)
      : supabase.from('campaigns').insert(input)
    const { error } = await query.select('id').single()
    if (error) throw error
    await load()
  }

  async function setPaused(ids: string[], isPaused: boolean) {
    if (!ids.length) return
    const { error } = await supabase.from('campaigns').update({ is_paused: isPaused }).in('id', ids).select('id')
    if (error) throw error
    await load()
  }

  // Proizvodi obrisane kampanje ostaju, samo bez sniženja.
  async function remove(id: string) {
    const { error } = await supabase.from('campaigns').delete().eq('id', id).select('id').single()
    if (error) throw error
    await load()
  }

  return { campaigns, productCounts, isLoading, loadError, load, save, setPaused, remove }
}
