import { createClient } from '@supabase/supabase-js'

const STATIC_ROUTES = ['/', '/proizvodi', '/o-nama', '/kontakt', '/dostava', '/povrat-i-zamjena', '/black-friday']

// Svoj zapis dobiva svaka boja proizvoda te svaka kategorija s proizvodima ili opisom.
export default defineEventHandler(async (event) => {
  const { siteUrl, supabaseUrl, supabasePublishableKey } = useRuntimeConfig(event).public
  const origin = (siteUrl || getRequestURL(event).origin).replace(/\/$/, '')

  const entries = STATIC_ROUTES.map((path) => ({ path, lastmod: null as string | null }))

  const supabase = createClient(supabaseUrl, supabasePublishableKey, { auth: { persistSession: false } })
  const { data, error } = await supabase
    .from('products')
    .select('updated_at, categories!products_category_id_fkey!inner(slug, is_active), product_categories(categories(slug)), product_colors(slug)')
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
        entries.push({ path: `/proizvod/${color.slug}`, lastmod: product.updated_at })
      }
    }
    const { data: described } = await supabase
      .from('categories')
      .select('slug')
      .eq('is_active', true)
      .not('description', 'is', null)
    for (const category of described ?? []) categorySlugs.add(category.slug)
    for (const slug of categorySlugs) entries.push({ path: `/kategorija/${slug}`, lastmod: null })
  }

  const urls = entries
    .map(({ path, lastmod }) => `  <url><loc>${origin}${path}</loc>${lastmod ? `<lastmod>${lastmod}</lastmod>` : ''}</url>`)
    .join('\n')

  setResponseHeader(event, 'Content-Type', 'application/xml; charset=utf-8')
  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls}
</urlset>
`
})
