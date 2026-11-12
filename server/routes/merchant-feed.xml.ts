import { createClient } from '@supabase/supabase-js'

// Feed proizvoda za Google Merchant Center (besplatni prikaz u kartici Google Shopping).
// U Merchant Centeru se dodaje kao "zakazano dohvaćanje" s adresom /merchant-feed.xml.
// Jedan artikl je jedna boja u jednoj veličini, a item_group_id povezuje sve varijante proizvoda.
// Proizvodi "samo u trgovini" i skriveni se ne šalju. Marke nema, pa je identifier_exists = no.
const PRODUCT_IMAGES_BUCKET = 'product-images'
const MAX_DESCRIPTION = 4500

// Googleova kategorija po našoj kategoriji (gleda se najdublja s pravilom). Popis: support.google.com/merchants/answer/6324436
const GOOGLE_CATEGORIES: Record<string, string> = {
  haljine: '2271', // Apparel & Accessories > Clothing > Dresses
  kaputi: '5598', // Apparel & Accessories > Clothing > Outerwear > Coats & Jackets
  'zenska-odijela': '5183', // Apparel & Accessories > Clothing > Suits
  jakne: '5598', // Apparel & Accessories > Clothing > Outerwear > Coats & Jackets
  nakit: '188', // Apparel & Accessories > Jewelry
  bolera: '5598', // Apparel & Accessories > Clothing > Outerwear
  hlace: '204', // Apparel & Accessories > Clothing > Pants
  kosulje: '212', // Apparel & Accessories > Clothing > Shirts & Tops
  salovi: '177', // Apparel & Accessories > Clothing Accessories > Scarves & Shawls
  'koferi-i-putne-torbe': '5181', // Luggage & Bags
  odjeca: '1604', // Apparel & Accessories > Clothing
  obuca: '187', // Apparel & Accessories > Shoes
  torbice: '3032', // Apparel & Accessories > Handbags, Wallets & Cases > Handbags
  dodaci: '167', // Apparel & Accessories > Clothing Accessories
}

const escapeXml = (text: string) => text.replace(/[<>&'"]/g, (char) => `&#${char.charCodeAt(0)};`)
const tag = (name: string, value: string | number | null | undefined) =>
  value === null || value === undefined || value === '' ? '' : `      <g:${name}>${escapeXml(String(value))}</g:${name}>`

type CategoryRow = { id: string; slug: string; name: string; parent_id: string | null }

export default defineEventHandler(async (event) => {
  const { siteUrl, siteName, supabaseUrl, supabasePublishableKey } = useRuntimeConfig(event).public
  const origin = (siteUrl || getRequestURL(event).origin).replace(/\/$/, '')
  const imageUrl = (path: string) => `${supabaseUrl}/storage/v1/object/public/${PRODUCT_IMAGES_BUCKET}/${path}`
  const supabase = createClient(supabaseUrl, supabasePublishableKey, { auth: { persistSession: false } })

  const [productResult, categoryResult, settingsResult] = await Promise.all([
    supabase
      .from('products')
      .select('id, name, description, material, price, sale_price, category_id, categories!products_category_id_fkey!inner(is_active), product_colors(name, slug, sort_order, product_sizes(id, size, quantity), product_images(path, sort_order))')
      .eq('is_visible', true)
      .eq('store_only', false)
      .eq('categories.is_active', true),
    supabase.from('categories').select('id, slug, name, parent_id').eq('is_active', true),
    supabase.from('store_settings').select('shipping_price, free_shipping_above').maybeSingle(),
  ])
  if (productResult.error) {
    console.error(productResult.error)
    throw createError({ statusCode: 500, statusMessage: 'Feed trenutno nije dostupan' })
  }

  const categories = (categoryResult.data ?? []) as CategoryRow[]
  const pathOf = (id: string) => {
    const path: CategoryRow[] = []
    let current = categories.find((item) => item.id === id)
    while (current) {
      path.unshift(current)
      current = categories.find((item) => item.id === current!.parent_id)
    }
    return path
  }
  const shippingPrice = Number(settingsResult.data?.shipping_price ?? 9)
  const freeAbove = Number(settingsResult.data?.free_shipping_above ?? 150)
  const price = (value: number) => `${value.toFixed(2)} BAM`

  const items: string[] = []
  for (const product of productResult.data) {
    const path = pathOf(product.category_id)
    const googleCategory = [...path].reverse().map((item) => GOOGLE_CATEGORIES[item.slug]).find(Boolean)
    const current = Number(product.sale_price ?? product.price)
    const description = [product.description, product.material ? `Materijal: ${product.material}` : '']
      .filter(Boolean).join('\n\n') || `${product.name}. Svečana moda iz Mepas Malla u Mostaru.`

    for (const color of product.product_colors) {
      const images = [...color.product_images].sort((a, b) => a.sort_order - b.sort_order).map((image) => imageUrl(image.path))
      // Google odbija artikle bez slike.
      if (!images.length) continue
      for (const size of color.product_sizes) {
        items.push([
          '    <item>',
          tag('id', size.id),
          tag('item_group_id', product.id),
          tag('title', `${product.name} ${color.name}, vel. ${size.size}`.slice(0, 150)),
          tag('description', description.slice(0, MAX_DESCRIPTION)),
          tag('link', `${origin}/proizvod/${color.slug}`),
          tag('image_link', images[0]),
          ...images.slice(1, 10).map((url) => tag('additional_image_link', url)),
          tag('availability', size.quantity > 0 ? 'in_stock' : 'out_of_stock'),
          tag('price', price(Number(product.price))),
          product.sale_price !== null ? tag('sale_price', price(Number(product.sale_price))) : '',
          tag('condition', 'new'),
          tag('identifier_exists', 'no'),
          tag('brand', siteName),
          tag('gender', 'female'),
          tag('age_group', 'adult'),
          tag('color', color.name),
          tag('size', size.size),
          tag('material', product.material?.slice(0, 200)),
          tag('google_product_category', googleCategory),
          tag('product_type', path.map((item) => item.name).join(' > ')),
          '      <g:shipping>',
          '        <g:country>BA</g:country>',
          `        <g:price>${price(current > freeAbove ? 0 : shippingPrice)}</g:price>`,
          '      </g:shipping>',
          '    </item>',
        ].filter(Boolean).join('\n'))
      }
    }
  }

  setResponseHeader(event, 'Content-Type', 'application/xml; charset=utf-8')
  return `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:g="http://base.google.com/ns/1.0">
  <channel>
    <title>${escapeXml(siteName)}</title>
    <link>${escapeXml(origin)}</link>
    <description>Svečana moda, Mepas Mall Mostar</description>
${items.join('\n')}
  </channel>
</rss>
`
})
