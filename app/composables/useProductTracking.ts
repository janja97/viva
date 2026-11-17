import type { ProductEventType } from '~/types/database'

// Praćenje zanimanja za proizvode (migracija 0041): pregled, dodavanje u košaricu i narudžba preko WhatsAppa.
// Radi samo u pregledniku i nikad ne javlja grešku kupcu. Baza broji svako otvaranje, a osvježavanje unutar 10 s jednom (migracija 0042).
export function useProductTracking() {
  const supabase = useSupabase()
  const { sessionId } = useShopSession()

  function track(colorId: string, event: ProductEventType, quantity = 1) {
    if (import.meta.server) return
    supabase
      .rpc('shop_track_event', { p_session: sessionId(), p_color_id: colorId, p_event: event, p_quantity: quantity })
      .then(({ error }) => {
        if (error) console.error(error)
      })
  }

  return { track }
}
