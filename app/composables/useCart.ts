import { PRODUCT_IMAGES_BUCKET } from '~/config/products'
import { SHIPPING, shippingFor } from '~/config/store'
import type { InquiryCustomerInput, ShopCartItemRow } from '~/types/database'

export type CartItem = ShopCartItemRow & { image: string | null }

export type InquiryCustomer = InquiryCustomerInput

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
  const total = computed(() => subtotal.value + shipping.value)
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

  async function submitInquiry(customer: InquiryCustomer) {
    const { data, error } = await supabase.rpc('shop_submit_inquiry', { p_session: sessionId(), p_customer: customer })
    if (error) throw error
    items.value = []
    return data.number
  }

  return {
    items, isLoaded, isDrawerOpen, count, subtotal, savings, shipping, total, missingForFreeShipping,
    load, ensureLoaded, add, setQuantity, remove, submitInquiry,
  }
}
