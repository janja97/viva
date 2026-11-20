import { FLY_TO_CART } from '~/config/products'

const DURATION_MS = 850
// Veličina slike kad "uleti" u ikonu košarice.
const END_SIZE_PX = 22
// Ako velika slika nije na ekranu (npr. kupac je na mobitelu skrolao do gumba), slika polijeće iznad gumba u ovoj veličini.
const FALLBACK_SIZE_PX = 140

// Animacija dodavanja u košaricu: kopija slike proizvoda leti od velike slike (data-fly-source u ProductGallery)
// do ikone košarice u zaglavlju (data-cart-target), u luku, i usput se smanjuje. Na kraju ikona kratko "poskoči".
// Ne radi ako je FLY_TO_CART isključen ili je u sustavu uključeno smanjenje animacija. Nikad ne baca grešku.
export function useFlyToCart() {
  // Prva vidljiva velika slika (na mobitelu trenutna slika vrtuljka, na računalu glavna).
  function sourceRect(fallback: HTMLElement | null): DOMRect | null {
    const { innerWidth: width, innerHeight: height } = window
    for (const element of document.querySelectorAll<HTMLElement>('[data-fly-source]')) {
      const rect = element.getBoundingClientRect()
      const isVisible = rect.width > 0 && rect.left >= -1 && rect.right <= width + 1 && rect.bottom > 100 && rect.top < height - 100
      if (isVisible) return rect
    }
    if (!fallback) return null
    const button = fallback.getBoundingClientRect()
    return new DOMRect(button.left + button.width / 2 - FALLBACK_SIZE_PX / 2, button.top - FALLBACK_SIZE_PX - 12, FALLBACK_SIZE_PX, FALLBACK_SIZE_PX)
  }

  function bump(target: HTMLElement) {
    target.classList.remove('cart-bump')
    // Ponovno pokretanje CSS animacije ako je kupac brzo dodao dva proizvoda.
    void target.offsetWidth
    target.classList.add('cart-bump')
  }

  async function fly(imageUrl: string | null, fallback: HTMLElement | null = null) {
    if (!FLY_TO_CART || !imageUrl || import.meta.server) return
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return

    const target = [...document.querySelectorAll<HTMLElement>('[data-cart-target]')].find((element) => element.offsetParent)
    const from = sourceRect(fallback)
    if (!target || !from) return
    const to = target.getBoundingClientRect()

    const clone = document.createElement('img')
    clone.src = imageUrl
    clone.alt = ''
    clone.setAttribute('aria-hidden', 'true')
    Object.assign(clone.style, {
      position: 'fixed',
      left: `${from.left}px`,
      top: `${from.top}px`,
      width: `${from.width}px`,
      height: `${from.height}px`,
      objectFit: 'contain',
      zIndex: '70',
      pointerEvents: 'none',
      transformOrigin: 'center center',
      willChange: 'transform, opacity',
    })
    document.body.appendChild(clone)

    // Pomak od sredine slike do sredine ikone. Luk: prvo se diže, a zatim skreće prema košarici.
    const dx = to.left + to.width / 2 - (from.left + from.width / 2)
    const dy = to.top + to.height / 2 - (from.top + from.height / 2)
    const endScale = END_SIZE_PX / Math.max(from.width, from.height)
    const midScale = Math.max(endScale, 0.45)

    try {
      await clone.animate([
        { transform: 'translate(0, 0) scale(1)', opacity: 1 },
        { transform: `translate(${dx * 0.25}px, ${dy * 0.65}px) scale(${midScale})`, opacity: 1, offset: 0.5 },
        { transform: `translate(${dx}px, ${dy}px) scale(${endScale})`, opacity: 0.4 },
      ], { duration: DURATION_MS, easing: 'cubic-bezier(0.5, 0, 0.3, 1)' }).finished
      bump(target)
    } catch {
      // Prekinuta animacija (npr. kupac je otišao sa stranice) nije greška.
    } finally {
      clone.remove()
    }
  }

  return { fly }
}
