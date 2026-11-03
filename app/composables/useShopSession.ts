const STORAGE_KEY = 'viva-sesija'
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

// Kupci se ne prijavljuju. Preglednik stvori nasumičan id i čuva ga, a baza po njemu nalazi košaricu i listu želja.
// Tko ne zna id, ne može vidjeti tuđu košaricu. Baza briše sesiju nakon 7 dana bez izmjene.
export function useShopSession() {
  // Ako preglednik ne dopušta spremanje, id vrijedi dok je stranica otvorena.
  const fallback = useState<string | null>('shop-session', () => null)

  function sessionId() {
    if (import.meta.server) throw new Error('Sesija kupca postoji samo u pregledniku.')
    try {
      const stored = localStorage.getItem(STORAGE_KEY)
      if (stored && UUID.test(stored)) return stored
      const created = crypto.randomUUID()
      localStorage.setItem(STORAGE_KEY, created)
      return created
    } catch {
      fallback.value ??= crypto.randomUUID()
      return fallback.value
    }
  }

  return { sessionId }
}
