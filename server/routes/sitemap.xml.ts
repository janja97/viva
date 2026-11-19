import { createClient } from '@supabase/supabase-js'

const STATIC_ROUTES = ['/', '/proizvodi', '/o-nama', '/kontakt', '/dostava', '/povrat-i-zamjena', '/ciscenje-zaliha', '/kupovina-u-mostaru', '/poklon-bon', '/blog', '/uvjeti-kupnje', '/politika-privatnosti']
const PRODUCT_IMAGES_BUCKET = 'product-images'
// Google uzima najviše 1000 slika po adresi, a za proizvod je dovoljno nekoliko.
const MAX_IMAGES_PER_URL = 6

type Entry = { path: string; lastmod: string | null; images?: string[] }
type ProductRow = {
  updated_at: string
  product_categories: { categories: { slug: string } | null }[]
  product_colors: { slug: string; product_images: { path: string; sort_order: number }[] }[]
}

const escapeXml = (text: string) => text.replace(/[<>&'"]/g, (char) => `&#${char.charCodeAt(0)};`)

// Svoj zapis dobiva svaka boja proizvoda (sa slikama, za Google pretragu slika), svaka kategorija
// s proizvodima ili tekstom te svaki objavljeni članak bloga. Sve se čita u stranicama po 1000 (fetchAllRows),
// pa sitemap nema gornju granicu broja proizvoda. Netlify ga kešira 1 sat (routeRules u nuxt.config.ts).
export default defineEventHandler(async (event) => {
  const { siteUrl, supabaseUrl, supabasePublishableKey } = useRuntimeConfig(event).public
  const origin = (siteUrl || getRequestURL(event).origin).replace(/\/$/, '')
  const imageUrl = (path: string) => `${supabaseUrl}/storage/v1/object/public/${PRODUCT_IMAGES_BUCKET}/${path}`

  const entries: Entry[] = STATIC_ROUTES.map((path) => ({ path, lastmod: null }))

  const supabase = createClient(supabaseUrl, supabasePublishableKey, { auth: { persistSession: false } })

  try {
    const products = await fetchAllRows<ProductRow>((from, to) => supabase
      .from('products')
      .select('updated_at, categories!products_category_id_fkey!inner(slug, is_active), product_categories(categories(slug)), product_colors(slug, product_images(path, sort_order))')
      .eq('is_visible', true)
      .eq('categories.is_active', true)
      .order('id')
      .range(from, to) as unknown as PromiseLike<{ data: ProductRow[] | null; error: unknown }>)

    const categorySlugs = new Set<string>()
    for (const product of products) {
      for (const link of product.product_categories) {
        if (link.categories) categorySlugs.add(link.categories.slug)
      }
      for (const color of product.product_colors) {
        const images = [...color.product_images]
          .sort((a, b) => a.sort_order - b.sort_order)
          .slice(0, MAX_IMAGES_PER_URL)
          .map((image) => imageUrl(image.path))
        entries.push({ path: `/proizvod/${color.slug}`, lastmod: product.updated_at, images })
      }
    }

    // Aktivne kategorije: one s proizvodima i one s vlastitim tekstom. Isključene se ne čitaju (RLS i filtar).
    const categories = await fetchAllRows<{ slug: string; updated_at: string; description: string | null; seo_text: string | null }>((from, to) => supabase
      .from('categories')
      .select('slug, updated_at, description, seo_text')
      .eq('is_active', true)
      .order('id')
      .range(from, to))
    for (const category of categories) {
      if (categorySlugs.has(category.slug) || category.description || category.seo_text) {
        entries.push({ path: `/kategorija/${category.slug}`, lastmod: category.updated_at })
      }
    }
  } catch (error) {
    console.error(error)
  }

  // Blog (migracija 0037). Bez tablice ili bez članaka samo se preskače.
  const posts = await fetchAllRows<{ slug: string; updated_at: string }>((from, to) => supabase
    .from('blog_posts')
    .select('slug, updated_at')
    .eq('is_published', true)
    .order('id')
    .range(from, to)).catch(() => [])
  for (const post of posts) entries.push({ path: `/blog/${post.slug}`, lastmod: post.updated_at })

  const urls = entries
    .map(({ path, lastmod, images }) => [
      '  <url>',
      `    <loc>${escapeXml(`${origin}${path}`)}</loc>`,
      lastmod ? `    <lastmod>${lastmod}</lastmod>` : '',
      ...(images ?? []).map((url) => `    <image:image><image:loc>${escapeXml(url)}</image:loc></image:image>`),
      '  </url>',
    ].filter(Boolean).join('\n'))
    .join('\n')

  setResponseHeader(event, 'Content-Type', 'application/xml; charset=utf-8')
  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">
${urls}
</urlset>
`
})
