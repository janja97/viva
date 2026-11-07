import type { NewsletterSubscriber, PromoCode } from '~/types/database'

export type SubscriberRow = NewsletterSubscriber & {
  code: PromoCode | null
  // Brojevi narudžbi u kojima je kod iskorišten.
  orderNumbers: number[]
}

// Pretplatnici na newsletter s njihovim kodom za 10 %. Upisuje ih samo /api/newsletter.
export function useNewsletter() {
  const supabase = useSupabase()

  const subscribers = ref<SubscriberRow[]>([])
  const isLoading = ref(true)
  const loadError = ref('')

  async function load() {
    isLoading.value = true
    loadError.value = ''
    const [subscriberResult, orderResult] = await Promise.all([
      supabase
        .from('newsletter_subscribers')
        .select('id, email, created_at, promo_codes(*)')
        .order('created_at', { ascending: false }),
      supabase.from('inquiries').select('number, promo_code_id').not('promo_code_id', 'is', null),
    ])
    isLoading.value = false
    if (subscriberResult.error || orderResult.error) {
      loadError.value = productErrorMessage(subscriberResult.error ?? orderResult.error)
      return
    }

    const ordersByCode = new Map<string, number[]>()
    for (const order of orderResult.data) {
      if (!order.promo_code_id) continue
      ordersByCode.set(order.promo_code_id, [...(ordersByCode.get(order.promo_code_id) ?? []), order.number])
    }

    subscribers.value = subscriberResult.data.map(({ promo_codes: codes, ...subscriber }) => {
      const code = codes[0] ?? null
      return { ...subscriber, code, orderNumbers: code ? ordersByCode.get(code.id) ?? [] : [] }
    })
  }

  // Briše i njegov kod. Narudžbe zadržavaju upisani kod i iznos popusta.
  async function remove(id: string) {
    const { error } = await supabase.from('newsletter_subscribers').delete().eq('id', id).select('id').single()
    if (error) throw error
    await load()
  }

  return { subscribers, isLoading, loadError, load, remove }
}
