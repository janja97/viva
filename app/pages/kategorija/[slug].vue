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

usePageSeo({
  title: `${category.name} - svečana moda`,
  description: category.description
    ?? `${category.name} iz naše svečane kolekcije. Pogledajte ponudu online ili nas posjetite u Mepas Mallu u Mostaru.`,
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
    <p v-if="category.description" class="mt-4 max-w-2xl text-muted">{{ category.description }}</p>

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
      :index-when-empty="Boolean(category.description)"
      empty-text="U ovoj kategoriji uskoro stižu novi modeli."
    />
  </section>
</template>
