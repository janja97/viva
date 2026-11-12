// Arhivirani proizvod trajno (301) vodi na svoju kategoriju, ili na /proizvodi ako ona nije aktivna,
// kako se ne bi gubila pozicija na Googleu (RPC shop_product_redirect, migracija 0036).
// Vidljivi, skriveni i nepoznati proizvodi prolaze dalje, pa stranica proizvoda sama vraća 404.
export default defineNuxtRouteMiddleware(async (to) => {
  const slug = String(to.params.slug ?? '')
  if (!slug) return
  const { data, error } = await useSupabase().rpc('shop_product_redirect', { p_color_slug: slug })
  if (error || data?.status !== 'archived') return
  return navigateTo(data.category_slug ? `/kategorija/${data.category_slug}` : '/proizvodi', { redirectCode: 301 })
})
