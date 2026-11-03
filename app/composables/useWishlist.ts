import { PRODUCT_IMAGES_BUCKET } from '~/config/products'
import type { ShopCard } from '~/composables/useShop'
import type { ShopWishlistRow } from '~/types/database'

// Lista želja čuva boje proizvoda, jer svaka boja ima svoju stranicu. Vrijedi 7 dana od zadnje izmjene.
export function useWishlist() {
  const supabase = useSupabase()
  const { sessionId } = useShopSession()

  const cards = useState<ShopCard[]>('wishlist-cards', () => [])
  const isLoaded = useState('wishlist-loaded', () => false)

  const count = computed(() => cards.value.length)
  const has = (colorId: string) => cards.value.some((card) => card.id === colorId)

  function setCards(rows: ShopWishlistRow[]) {
    cards.value = rows.map((row) => ({
      id: row.id,
      slug: row.slug,
      productName: row.productName,
      colorName: row.colorName,
      categoryName: row.categoryName ?? '',
      price: Number(row.price),
      compareAtPrice: row.compareAtPrice === null ? null : Number(row.compareAtPrice),
      image: row.imagePath ? supabase.storage.from(PRODUCT_IMAGES_BUCKET).getPublicUrl(row.imagePath).data.publicUrl : null,
      alt: row.imageAlt ?? `${row.productName} ${row.colorName}`,
      soldOut: row.soldOut,
      storeOnly: row.storeOnly,
      colors: row.colors,
    }))
    isLoaded.value = true
  }

  async function load() {
    const { data, error } = await supabase.rpc('shop_wishlist', { p_session: sessionId() })
    if (error) throw error
    setCards(data)
  }

  async function ensureLoaded() {
    if (!isLoaded.value) await load()
  }

  async function set(colorId: string, on: boolean) {
    const { data, error } = await supabase.rpc('shop_wishlist_set', { p_session: sessionId(), p_color_id: colorId, p_on: on })
    if (error) throw error
    setCards(data)
  }

  const toggle = (colorId: string) => set(colorId, !has(colorId))

  return { cards, isLoaded, count, has, load, ensureLoaded, toggle, remove: (colorId: string) => set(colorId, false) }
}
