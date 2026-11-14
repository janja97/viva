import { PROMO_PAGE_SLUGS } from '~/config/navigation'
import type { PromoPageInput, PromoPageWithCampaigns, ShopPromoPage } from '~/types/database'

// {godina} u tekstu akcijske stranice: godina početka kampanje, a bez nje tekuća godina.
export function fillPromoYear(text: string, page: Pick<ShopPromoPage, 'starts_at'> | null) {
  const year = page?.starts_at ? new Date(page.starts_at).getFullYear() : new Date().getFullYear()
  return text.replaceAll('{godina}', String(year))
}

// Javna akcijska stranica (npr. /ciscenje-zaliha) kroz shop_promo_page (migracija 0033).
// Isti ključ koristi i izbornik, pa se podaci učitavaju jednom.
export function useShopPromoPage(slug: string) {
  const supabase = useSupabase()
  return useAsyncData(
    `promo-page-${slug}`,
    async () => {
      const { data, error } = await supabase.rpc('shop_promo_page', { p_slug: slug })
      if (error) throw error
      return data
    },
    { default: () => null },
  )
}

// Akcijske stranice u adminu (/admin/akcijske-stranice). Stranice se ne stvaraju ni brišu iz sučelja,
// jer svaka treba i svoju datoteku u app/pages.
export function usePromoPages() {
  const supabase = useSupabase()

  const pages = ref<PromoPageWithCampaigns[]>([])
  const isLoading = ref(true)
  const loadError = ref('')

  async function load() {
    isLoading.value = true
    loadError.value = ''
    const [pageResult, linkResult] = await Promise.all([
      // Samo stranice koje imaju datoteku u app/pages, inače bi poveznica vodila na 404.
      supabase.from('promo_pages').select('*').in('slug', PROMO_PAGE_SLUGS).order('slug'),
      supabase.from('promo_page_campaigns').select('page_id, campaign_id'),
    ])
    isLoading.value = false
    if (pageResult.error || linkResult.error) {
      loadError.value = productErrorMessage(pageResult.error ?? linkResult.error)
      return
    }
    pages.value = pageResult.data.map((page) => ({
      ...page,
      campaign_ids: linkResult.data.filter((link) => link.page_id === page.id).map((link) => link.campaign_id),
    }))
  }

  // Stranica i njezine kampanje spremaju se zajedno (RPC save_promo_page, migracija 0034).
  async function save(id: string, input: PromoPageInput, campaignIds: string[]) {
    const { error } = await supabase.rpc('save_promo_page', { p_id: id, p_page: input, p_campaign_ids: campaignIds })
    if (error) throw error
    await load()
  }

  return { pages, isLoading, loadError, load, save }
}
