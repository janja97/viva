import { PRODUCT_IMAGES_BUCKET } from '~/config/products'
import { SHIPPING, shippingFor } from '~/config/store'
import type { InquiryCustomerInput, ShopCartItemRow } from '~/types/database'

export type CartItem = ShopCartItemRow & { image: string | null }

// Promo kod ne upisuje kupac u obrazac, nego ga dodaje košarica.
export type InquiryCustomer = Omit<InquiryCustomerInput, 'promo_code'>

// Košarica je zajednička za cijelu stranicu (zaglavlje, stranica proizvoda i košarica).
// Podatke uvijek vraća baza, koja sama provjerava dostupnost i količine.
export function useCart() {
  const supabase = useSupabase()
  const { sessionId } = useShopSession()

  const items = useState<CartItem[]>('cart-items', () => [])
  const isLoaded = useState('cart-loaded', () => false)

  // Brzi pregled košarice s desne strane.
  const isDrawerOpen = useState('cart-drawer-open', () => false)

  const count = computed(() => items.value.reduce((sum, item) => sum + item.quantity, 0))
  const subtotal = computed(() => items.value.reduce((sum, item) => sum + item.price * item.quantity, 0))
  const savings = computed(() => items.value.reduce((sum, item) => sum + ((item.compareAtPrice ?? item.price) - item.price) * item.quantity, 0))
  const shipping = computed(() => (items.value.length ? shippingFor(subtotal.value) : 0))

  // Promo kod iz košarice. Popust je na iznos proizvoda, a poštarina se računa prema iznosu prije popusta,
  // isto kao u shop_submit_inquiry.
  const promo = useState<{ code: string; percent: number } | null>('cart-promo', () => null)
  const promoDiscount = computed(() => (promo.value ? Math.round(subtotal.value * promo.value.percent) / 100 : 0))
  const total = computed(() => subtotal.value - promoDiscount.value + shipping.value)
  // Koliko još nedostaje do besplatne poštarine.
  const missingForFreeShipping = computed(() => (shipping.value > 0 ? Math.max(0, SHIPPING.freeAbove - subtotal.value) : 0))

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

  async function submitInquiry(customer: InquiryCustomer) {
    const { data, error } = await supabase.rpc('shop_submit_inquiry', {
      p_session: sessionId(),
      p_customer: { ...customer, promo_code: promo.value?.code ?? null },
    })
    if (error) throw error
    items.value = []
    promo.value = null
    return data.number
  }

  return {
    items, isLoaded, isDrawerOpen, count, subtotal, savings, shipping, promo, promoDiscount, total, missingForFreeShipping,
    load, ensureLoaded, add, setQuantity, remove, applyPromo, clearPromo, submitInquiry,
  }
}
