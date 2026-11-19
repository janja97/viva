import { PRODUCT_PATH } from '~/config/products'
import { deliveryMethodLabel, type DeliveryMethod } from '~/config/store'

type OrderLine = { productName: string; colorName: string; size: string; quantity: number; price: number; slug: string }

// Tekst narudžbe za WhatsApp: proizvodi s crticom, bez iznosa (ukupno, poštarina i sveukupno se ne pišu),
// a zatim način preuzimanja (dostava ili preuzimanje u trgovini, migracija 0048).
// Uz svaki proizvod ide poveznica, od koje WhatsApp sam napravi pregled sa slikom.
export function whatsappOrderMessage({ items, promoCode, note, origin, delivery = 'delivery' }: {
  items: OrderLine[]
  delivery?: DeliveryMethod
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
    delivery === 'delivery' ? '\nDostava na adresu (ime, adresu i telefon šaljem u nastavku).' : `\n${deliveryMethodLabel(delivery)}.`,
    promoCode ? `\nPromo kod: ${promoCode}` : '',
    note.trim() ? `\nNapomena: ${note.trim()}` : '',
  ].filter((line) => line !== '').join('\n')
}

// wa.me prima broj samo sa znamenkama, s pozivnim brojem države (npr. 38763123456).
export function whatsappUrl(phone: string, text: string) {
  return `https://wa.me/${phone.replace(/\D/g, '')}?text=${encodeURIComponent(text)}`
}
