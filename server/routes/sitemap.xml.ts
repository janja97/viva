import { createClient } from '@supabase/supabase-js'

const STATIC_ROUTES = ['/', '/proizvodi', '/o-nama', '/kontakt', '/dostava', '/povrat-i-zamjena', '/ciscenje-zaliha','/blog']
const PRODUCT_IMAGES_BUCKET = 'product-images'
// Google uzima najviše 1000 slika po adresi, a za proizvod je dovoljno nekoliko.
const MAX_IMAGES_PER_URL = 6

type Entry = { path: string; lastmod: string | null; images?: string[] }

const escapeXml = (text: string) => text.replace(/[<>&'"]/g, (char) => `&#${char.charCodeAt(0)};`)

// Svoj zapis dobiva svaka boja proizvoda (sa slikama, za Google pretragu slika), svaka kategorija
// s proizvodima ili tekstom te svaki objavljeni članak bloga.
export default defineEventHandler(async (event) => {
  const { siteUrl, supabaseUrl, supabasePublishableKey } = useRuntimeConfig(event).public
  const origin = (siteUrl || getRequestURL(event).origin).replace(/\/$/, '')
  const imageUrl = (path: string) => `${supabaseUrl}/storage/v1/object/public/${PRODUCT_IMAGES_BUCKET}/${path}`

  const entries: Entry[] = STATIC_ROUTES.map((path) => ({ path, lastmod: null }))

  const supabase = createClient(supabaseUrl, supabasePublishableKey, { auth: { persistSession: false } })
  const { data, error } = await supabase
    .from('products')
    .select('updated_at, categories!products_category_id_fkey!inner(slug, is_active), product_categories(categories(slug)), product_colors(slug, product_images(path, sort_order))')
    .eq('is_visible', true)
    .eq('categories.is_active', true)

  if (error) {
    console.error(error)
  } else {
    const categorySlugs = new Set<string>()
    for (const product of data) {
      const links = product.product_categories as unknown as { categories: { slug: string } | null }[]
      for (const link of links) {
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
    const { data: described } = await supabase
      .from('categories')
      .select('slug')
      .eq('is_active', true)
      .or('description.not.is.null,seo_text.not.is.null')
    for (const category of described ?? []) categorySlugs.add(category.slug)
    for (const slug of categorySlugs) entries.push({ path: `/kategorija/${slug}`, lastmod: null })
  }

  // Blog (migracija 0037). Bez tablice ili bez članaka samo se preskače.
  const { data: posts } = await supabase.from('blog_posts').select('slug, updated_at').eq('is_published', true)
  for (const post of posts ?? []) entries.push({ path: `/blog/${post.slug}`, lastmod: post.updated_at })

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
