<script setup lang="ts">
import { COMPLETE_LOOK, CURRENCY_CODE, DRESS_LENGTHS, HEEL_HEIGHTS, PRODUCT_PATH } from '~/config/products'
import { DELIVERY, EXCHANGE, STORE } from '~/config/store'

// Svaka boja ima svoj URL, pa se stranica učitava iznova pri promjeni boje.
// Arhivirani proizvod trajno vodi na svoju kategoriju (middleware archived-product, migracija 0036).
definePageMeta({ key: (route) => route.fullPath, middleware: 'archived-product' })

const route = useRoute()
const slug = route.params.slug as string
const { fetchProduct, fetchCards, fetchCategories } = useShop()
const { siteUrl } = useRuntimeConfig().public
const origin = (siteUrl || useRequestURL().origin).replace(/\/$/, '')

const storeSettings = useStoreSettings()
const { data } = await useAsyncData(`product-${slug}`, () => fetchProduct(slug))

if (!data.value) {
  throw createError({ statusCode: 404, statusMessage: 'Proizvod nije pronađen', fatal: true })
}

const { product, colors, color } = data.value
const category = product.categories

const { data: allCategories } = await useAsyncData('shop-categories', fetchCategories)
// Nadređene kategorije glavne kategorije proizvoda, za putanju.
const parents = categoryPath(allCategories.value ?? [], product.category_id).slice(0, -1)

const soldOut = color.sizes.every((size) => size.quantity === 0)

const regularPrice = Number(product.price)
const isOnSale = product.sale_price !== null && product.sale_price !== undefined
const currentPrice = isOnSale ? Number(product.sale_price) : regularPrice

const dressLength = DRESS_LENGTHS.find((item) => item.value === product.dress_length)?.label
const heelHeight = HEEL_HEIGHTS.find((item) => item.value === product.heel_height)?.label

// "Kompletirajte izgled": proizvodi iz kategorija koje idu uz ovu (COMPLETE_LOOK), naizmjence po kategoriji.
// Bez pravila, ili ako tamo nema proizvoda, najnoviji proizvodi. Greška ovdje ne smije srušiti stranicu.
const { data: related } = await useAsyncData(`related-${slug}`, () => completeLook().catch((error) => {
  console.error(error)
  return []
}))

async function completeLook() {
  const categories = allCategories.value ?? []
  const path = categoryPath(categories, product.category_id)
  const rule = [...path].reverse().map((item) => COMPLETE_LOOK[item.slug]).find(Boolean) ?? []
  const groups = await Promise.all(rule.map(async (ruleSlug) => {
    const target = categories.find((item) => item.slug === ruleSlug)
    if (!target) return []
    return (await fetchCards({ pageSize: 4, categoryIds: [target.id, ...descendantIds(categories, target.id)] })).cards
  }))
  const isOther = (card: { colors: { id: string }[] }) => !card.colors.some((item) => item.id === color.id)
  // Jedna kartica iz svake kategorije redom, pa sljedeća.
  const mixed = Array.from({ length: 4 }, (_, index) => groups.map((group) => group[index]))
    .flat()
    .filter((card): card is NonNullable<typeof card> => Boolean(card) && isOther(card!))
  if (mixed.length >= 2) return mixed.slice(0, 4)
  const { cards } = await fetchCards({ pageSize: 8 })
  return cards.filter(isOther).slice(0, 4)
}

const seoInput = {
  name: product.name,
  colorName: color.name,
  categoryName: category.name,
  description: product.description ?? '',
  price: String(currentPrice),
  storeOnly: product.store_only,
  metaTitle: product.meta_title ?? '',
  metaDescription: product.meta_description ?? '',
}
const title = productSeoTitle(seoInput)
const description = productSeoDescription(seoInput)
const url = `${origin}${PRODUCT_PATH}/${color.slug}`

usePageSeo({ title, description, image: color.images[0]?.url })

// Poštarina u JSON-LD-u dolazi iz postavki trgovine.
await storeSettings.ready()

function availability() {
  if (soldOut) return 'https://schema.org/OutOfStock'
  return product.store_only ? 'https://schema.org/InStoreOnly' : 'https://schema.org/InStock'
}

useHead({
  script: [
    {
      type: 'application/ld+json',
      innerHTML: JSON.stringify({
        '@context': 'https://schema.org',
        '@type': 'Product',
        name: `${product.name} ${color.name}`,
        sku: product.sku,
        color: color.name,
        category: category.name,
        description,
        ...(product.material && { material: product.material }),
        image: color.images.map((image) => image.url),
        url,
        offers: {
          '@type': 'Offer',
          url,
          price: currentPrice.toFixed(2),
          priceCurrency: CURRENCY_CODE,
          availability: availability(),
          itemCondition: 'https://schema.org/NewCondition',
          // Poštarina po istom pravilu kao u košarici. Proizvod samo za poslovnice se ne šalje.
          ...(!product.store_only && {
            shippingDetails: {
              '@type': 'OfferShippingDetails',
              shippingRate: { '@type': 'MonetaryAmount', value: storeSettings.shippingFor(currentPrice).toFixed(2), currency: CURRENCY_CODE },
              shippingDestination: { '@type': 'DefinedRegion', addressCountry: DELIVERY.countryCode },
              deliveryTime: {
                '@type': 'ShippingDeliveryTime',
                transitTime: { '@type': 'QuantitativeValue', minValue: DELIVERY.minDays, maxValue: DELIVERY.maxDays, unitCode: 'DAY' },
              },
            },
            // Samo zamjena (bez povrata novca), u roku od EXCHANGE.days dana.
            hasMerchantReturnPolicy: {
              '@type': 'MerchantReturnPolicy',
              applicableCountry: DELIVERY.countryCode,
              returnPolicyCategory: 'https://schema.org/MerchantReturnFiniteReturnWindow',
              merchantReturnDays: EXCHANGE.days,
              refundType: 'https://schema.org/ExchangeRefund',
            },
          }),
        },
      }),
    },
    {
      type: 'application/ld+json',
      innerHTML: JSON.stringify(breadcrumbJsonLd([
        { name: 'Početna', url: `${origin}/` },
        { name: 'Kolekcija', url: `${origin}/proizvodi` },
        ...parents.map((item) => ({ name: item.name, url: `${origin}/kategorija/${item.slug}` })),
        { name: category.name, url: `${origin}/kategorija/${category.slug}` },
        { name: `${product.name} ${color.name}`, url },
      ])),
    },
  ],
})
</script>

<template>
  <div class="mx-auto max-w-7xl px-4 pt-2 sm:px-6 lg:px-8">
    <SiteBreadcrumbs
      class="mb-4"
      :items="[
        { label: 'Početna', to: '/' },
        { label: 'Kolekcija', to: '/proizvodi' },
        ...parents.map((item) => ({ label: item.name, to: `/kategorija/${item.slug}` })),
        { label: category.name, to: `/kategorija/${category.slug}` },
        { label: `${product.name} ${color.name}` },
      ]"
    />

    <article class="grid grid-cols-[minmax(0,1fr)] gap-10 pb-20 md:grid-cols-[minmax(0,3fr)_minmax(0,2fr)] lg:gap-20">
      <ProductGallery :images="color.images" />

      <div class="md:sticky md:top-28 md:self-start">
        <p class="text-xs font-medium uppercase tracking-[0.24em] text-gold">{{ category.name }}</p>
        <h1 class="mt-3 font-display text-5xl font-normal leading-[1.1] lg:text-6xl">{{ product.name }}</h1>
        <p class="mt-3 flex flex-wrap items-baseline gap-x-3">
          <span class="text-2xl font-medium text-gold">{{ formatPrice(currentPrice) }}</span>
          <del v-if="isOnSale" class="text-muted">{{ formatPrice(regularPrice) }}</del>
        </p>
        <p class="mt-1 text-sm text-muted">Šifra: {{ product.sku }}</p>
        <div v-if="product.description" class="mt-5 whitespace-pre-line font-light leading-relaxed text-muted">{{ product.description }}</div>

        <div class="mt-7">
          <p class="text-xs font-medium uppercase tracking-[0.2em]">Boja: <span class="font-normal text-muted">{{ color.name }}</span></p>
          <ul class="mt-3 flex flex-wrap gap-2">
            <li v-for="item in colors" :key="item.id">
              <NuxtLink
                :to="`${PRODUCT_PATH}/${item.slug}`"
                :aria-label="`Boja: ${item.name}`"
                :aria-current="item.id === color.id ? 'page' : undefined"
                class="flex size-11 items-center justify-center rounded-full border"
                :class="item.id === color.id ? 'border-ink' : 'border-transparent hover:border-line'"
              >
                <ColorSwatch class="size-9" :name="item.name" :hex="item.hex" />
              </NuxtLink>
            </li>
          </ul>
        </div>

        <ProductPurchase :color-id="color.id" :sizes="color.sizes" :store-only="product.store_only" />

        <ul class="mt-7 space-y-2 border-y border-line py-4 text-sm text-muted">
          <li>Dostupno u butiku · {{ STORE.mall }}, {{ STORE.city }}</li>
          <template v-if="!product.store_only">
            <li>
              <NuxtLink to="/dostava" class="hover:text-ink hover:underline">Dostava po BiH za {{ DELIVERY.minDays }} do {{ DELIVERY.maxDays }} dana · plaćanje pouzećem</NuxtLink>
            </li>
            <li>
              <NuxtLink to="/povrat-i-zamjena" class="hover:text-ink hover:underline">Zamjena u roku od {{ EXCHANGE.days }} dana</NuxtLink>
            </li>
          </template>
          <li v-if="dressLength">Duljina: {{ dressLength }}</li>
          <li v-if="heelHeight">Peta: {{ heelHeight }}</li>
        </ul>

        <div class="divide-y divide-line border-b border-line">
          <details v-if="product.material" class="group">
            <summary class="flex min-h-13 cursor-pointer items-center text-xs font-medium uppercase tracking-[0.2em]">Materijal</summary>
            <p class="whitespace-pre-line pb-4 text-sm text-muted">{{ product.material }}</p>
          </details>
          <details v-if="product.care">
            <summary class="flex min-h-13 cursor-pointer items-center text-xs font-medium uppercase tracking-[0.2em]">Održavanje</summary>
            <p class="whitespace-pre-line pb-4 text-sm text-muted">{{ product.care }}</p>
          </details>
          <details v-if="product.size_guide">
            <summary class="flex min-h-13 cursor-pointer items-center text-xs font-medium uppercase tracking-[0.2em]">Kroj i mjere</summary>
            <p class="whitespace-pre-line pb-4 text-sm text-muted">{{ product.size_guide }}</p>
          </details>
        </div>
      </div>
    </article>

    <section v-if="related?.length" class="pb-20">
      <SectionHeading title="Kompletirajte izgled" />
      <ProductGrid :cards="related" />
    </section>
  </div>
</template>
