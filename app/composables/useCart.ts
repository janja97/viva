import { PRODUCT_IMAGES_BUCKET } from '~/config/products'
import type { DeliveryMethod } from '~/config/store'
import type { InquiryCustomerInput, ShopCartItemRow } from '~/types/database'

export type CartItem = ShopCartItemRow & { image: string | null }

// Promo kod i način preuzimanja ne upisuje kupac u obrazac, nego ih dodaje košarica.
export type InquiryCustomer = Omit<InquiryCustomerInput, 'promo_code' | 'delivery_method'>

// Košarica je zajednička za cijelu stranicu (zaglavlje, stranica proizvoda i košarica).
// Podatke uvijek vraća baza, koja sama provjerava dostupnost i količine.
export function useCart() {
  const supabase = useSupabase()
  const { sessionId } = useShopSession()
  const { shippingFor } = useStoreSettings()

  const items = useState<CartItem[]>('cart-items', () => [])
  const isLoaded = useState('cart-loaded', () => false)

  // Brzi pregled košarice s desne strane.
  const isDrawerOpen = useState('cart-drawer-open', () => false)

  const count = computed(() => items.value.reduce((sum, item) => sum + item.quantity, 0))
  const subtotal = computed(() => items.value.reduce((sum, item) => sum + item.price * item.quantity, 0))
  const savings = computed(() => items.value.reduce((sum, item) => sum + ((item.compareAtPrice ?? item.price) - item.price) * item.quantity, 0))
  // Dostava ili preuzimanje u trgovini (migracija 0048). Kupac bira u košarici, a preuzimanje je bez poštarine.
  const deliveryMethod = useState<DeliveryMethod>('cart-delivery', () => 'delivery')
  const shipping = computed(() => (items.value.length && deliveryMethod.value === 'delivery' ? shippingFor(subtotal.value) : 0))

  // Promo kod iz košarice. Popust je samo na iznos artikala koji nisu već sniženi (migracija 0049),
  // a poštarina se računa prema iznosu prije popusta, isto kao u shop_submit_inquiry.
  const promo = useState<{ code: string; percent: number } | null>('cart-promo', () => null)
  const promoBase = computed(() => items.value
    .filter((item) => item.compareAtPrice === null || item.compareAtPrice <= item.price)
    .reduce((sum, item) => sum + item.price * item.quantity, 0))
  const promoDiscount = computed(() => (promo.value ? Math.round(promoBase.value * promo.value.percent) / 100 : 0))
  // Kod se šalje samo kad stvarno daje popust, inače bi se potrošio bez koristi.
  const promoCodeToSend = computed(() => (promoDiscount.value > 0 ? promo.value?.code ?? null : null))
  const total = computed(() => subtotal.value - promoDiscount.value + shipping.value)

  function setItems(rows: ShopCartItemRow[]) {
    items.value = rows.map((row) => ({
      ...row,
      price: Number(row.price),
      compareAtPrice: row.compareAtPrice === null ? null : Number(row.compareAtPrice),
      image: row.imagePath ? supabase.storage.from(PRODUCT_IMAGES_BUCKET).getPublicUrl(row.imagePath).data.publicUrl : null,
    }))
    isLoaded.value = true
  }

  async function load() {
    const { data, error } = await supabase.rpc('shop_cart', { p_session: sessionId() })
    if (error) throw error
    setItems(data)
  }

  // Učitava samo jednom, a ostale izmjene ionako vraćaju cijelu košaricu.
  async function ensureLoaded() {
    if (!isLoaded.value) await load()
  }

  async function update(sizeId: string, quantity: number, add = false) {
    const { data, error } = await supabase.rpc('shop_cart_update', {
      p_session: sessionId(),
      p_size_id: sizeId,
      p_quantity: quantity,
      p_add: add,
    })
    if (error) throw error
    setItems(data)
  }

  const add = (sizeId: string, quantity = 1) => update(sizeId, quantity, true)
  const setQuantity = (sizeId: string, quantity: number) => update(sizeId, quantity)
  const remove = (sizeId: string) => update(sizeId, 0)

  async function applyPromo(code: string) {
    const { data, error } = await supabase.rpc('shop_check_promo', { p_code: code.trim() })
    if (error) throw error
    promo.value = data
  }

  const clearPromo = () => { promo.value = null }

  // WhatsApp narudžba (migracija 0043): sprema se u admin bez podataka kupca, a košarica ostaje.
  async function submitWhatsappInquiry(note: string) {
    const { error } = await supabase.rpc('shop_submit_whatsapp_inquiry', {
      p_session: sessionId(),
      p_note: note.trim() || null,
      p_promo_code: promoCodeToSend.value,
      p_delivery: deliveryMethod.value,
    })
    if (error) throw error
  }

  async function submitInquiry(customer: InquiryCustomer) {
    const { data, error } = await supabase.rpc('shop_submit_inquiry', {
      p_session: sessionId(),
      p_customer: { ...customer, promo_code: promoCodeToSend.value, delivery_method: deliveryMethod.value },
    })
    if (error) throw error
    items.value = []
    promo.value = null
    return data.number
  }

  return {
    items, isLoaded, isDrawerOpen, count, subtotal, savings, deliveryMethod, shipping, promo, promoBase, promoDiscount, promoCodeToSend, total,
    load, ensureLoaded, add, setQuantity, remove, applyPromo, clearPromo, submitInquiry, submitWhatsappInquiry,
  }
}
