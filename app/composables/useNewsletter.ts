import type { NewsletterSubscriber, PromoCode } from '~/types/database'

export type SubscriberRow = Omit<NewsletterSubscriber, 'unsubscribe_token'> & {
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
    // Svi pretplatnici i narudžbe s kodom, u stranicama po 1000 (fetchAllRows), jer ih može biti više od 1000.
    const subscriberQuery = (from: number, to: number) => supabase
      .from('newsletter_subscribers')
      .select('id, email, created_at, unsubscribed_at, promo_codes(*)')
      .order('created_at', { ascending: false })
      .order('id')
      .range(from, to)
    type SubscriberData = NonNullable<Awaited<ReturnType<typeof subscriberQuery>>['data']>[number]
    let subscriberRows: SubscriberData[]
    let orderRows: { number: number; promo_code_id: string | null }[]
    try {
      [subscriberRows, orderRows] = await Promise.all([
        fetchAllRows<SubscriberData>(subscriberQuery),
        fetchAllRows<{ number: number; promo_code_id: string | null }>((from, to) => supabase
          .from('inquiries')
          .select('number, promo_code_id')
          .not('promo_code_id', 'is', null)
          .order('id')
          .range(from, to)),
      ])
    } catch (error) {
      loadError.value = productErrorMessage(error)
      return
    } finally {
      isLoading.value = false
    }
    const subscriberResult = { data: subscriberRows }

    const ordersByCode = new Map<string, number[]>()
    for (const order of orderRows) {
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
