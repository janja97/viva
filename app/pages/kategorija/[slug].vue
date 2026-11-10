<script setup lang="ts">
// Promjena filtra mijenja samo upit u adresi, pa se stranica ne učitava iznova.
definePageMeta({ key: (route) => route.path })

const route = useRoute()
const slug = route.params.slug as string
const { fetchCategories } = useShop()

const { data } = await useAsyncData(`category-${slug}`, async () => {
  const categories = await fetchCategories()
  const category = categories.find((item) => item.slug === slug)
  if (!category) return null

  return {
    category,
    children: childrenOf(categories, category.id),
    path: categoryPath(categories, category.id),
    // Proizvodi iz svih razina ispod ove kategorije.
    categoryIds: [category.id, ...descendantIds(categories, category.id)],
  }
})

if (!data.value) {
  throw createError({ statusCode: 404, statusMessage: 'Kategorija nije pronađena', fatal: true })
}

const { category, children, path, categoryIds } = data.value

// SEO iz admina (migracija 0031), uz {godina} = godina sljedeće mature. Bez upisa vrijede zadani tekstovi.
const description = category.description ? fillYear(category.description) : ''
const seoText = category.seo_text ? fillYear(category.seo_text) : ''
const faq = (category.faq ?? []).map((item) => ({ question: fillYear(item.question), answer: fillYear(item.answer) }))

usePageSeo({
  title: category.meta_title ? fillYear(category.meta_title) : `${category.name} - svečana moda`,
  description: (category.meta_description ? fillYear(category.meta_description) : description)
    || `${category.name} iz naše svečane kolekcije. Pogledajte ponudu online ili nas posjetite u Mepas Mallu u Mostaru.`,
})

const breadcrumbs = [
  { label: 'Početna', to: '/' },
  { label: 'Kolekcija', to: '/proizvodi' },
  ...path.slice(0, -1).map((item) => ({ label: item.name, to: `/kategorija/${item.slug}` })),
  { label: category.name },
]
</script>

<template>
  <section class="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8 lg:py-14">
    <SiteBreadcrumbs class="mb-6" :items="breadcrumbs" />
    <h1 class="font-display text-5xl font-normal leading-tight">{{ category.name }}</h1>
    <p v-if="description" class="mt-4 max-w-2xl text-muted">{{ description }}</p>

    <ul v-if="children.length" class="mt-6 flex flex-wrap gap-2">
      <li v-for="child in children" :key="child.id">
        <NuxtLink :to="`/kategorija/${child.slug}`" class="inline-flex min-h-11 items-center border border-line bg-white px-4 text-xs font-medium uppercase tracking-[0.15em] hover:border-ink">
          {{ child.name }}
        </NuxtLink>
      </li>
    </ul>

    <ShopListing
      class="mt-8"
      :listing-key="`category-${slug}`"
      :category-ids="categoryIds"
      :index-when-empty="Boolean(description || seoText)"
      empty-text="U ovoj kategoriji uskoro stižu novi modeli."
    />

    <!-- Duži tekst i pitanja su ispod proizvoda, da kupac prvo vidi ponudu. -->
    <div v-if="seoText || faq.length" class="mt-16 grid gap-12 border-t border-line pt-12 lg:grid-cols-2 lg:gap-20">
      <SiteRichText v-if="seoText" class="max-w-2xl" :text="seoText" />
      <SiteFaq v-if="faq.length" :class="!seoText && 'lg:col-span-2 max-w-3xl'" :items="faq" />
    </div>
  </section>
</template>
