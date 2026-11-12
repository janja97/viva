import { PRODUCT_PATH } from '~/config/products'

type OrderLine = { productName: string; colorName: string; size: string; quantity: number; price: number; slug: string }

// Tekst narudžbe za WhatsApp: proizvodi s crticom, bez iznosa (ukupno, poštarina i sveukupno se ne pišu).
// Uz svaki proizvod ide poveznica, od koje WhatsApp sam napravi pregled sa slikom.
export function whatsappOrderMessage({ items, promoCode, note, origin }: {
  items: OrderLine[]
  promoCode: string | null
  note: string
  origin: string
}) {
  const lines = items.map((item) => [
    `- ${item.productName}, ${item.colorName}, vel. ${item.size}, ${item.quantity} kom, ${formatPrice(item.price * item.quantity)}`,
    `  ${origin}${PRODUCT_PATH}/${item.slug}`,
  ].join('\n'))

  return [
    'Pozdrav, želim naručiti:',
    '',
    lines.join('\n'),
    promoCode ? `\nPromo kod: ${promoCode}` : '',
    note.trim() ? `\nNapomena: ${note.trim()}` : '',
  ].filter((line) => line !== '').join('\n')
}

// wa.me prima broj samo sa znamenkama, s pozivnim brojem države (npr. 38763123456).
export function whatsappUrl(phone: string, text: string) {
  return `https://wa.me/${phone.replace(/\D/g, '')}?text=${encodeURIComponent(text)}`
}
