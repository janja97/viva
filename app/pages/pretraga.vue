<script setup lang="ts">
definePageMeta({ key: (route) => route.fullPath })

// Rezultati pretrage ne smiju u Google.
usePageSeo({ title: 'Pretraga', noindex: true })

const route = useRoute()
const q = typeof route.query.q === 'string' ? route.query.q.trim() : ''
const { searchCards } = useShop()

const { data } = await useAsyncData(`search-${q}`, () => searchCards(q))
</script>

<template>
  <section class="mx-auto max-w-7xl px-4 py-14 sm:px-6 lg:px-8">
    <h1 class="text-center font-display text-4xl font-medium sm:text-5xl">
      {{ q ? `Rezultati za „${q}”` : 'Pretraga' }}
    </h1>

    <ul v-if="data?.categories.length" class="mt-8 flex flex-wrap justify-center gap-2">
      <li v-for="category in data.categories" :key="category.id">
        <NuxtLink :to="`/kategorija/${category.slug}`" class="inline-flex min-h-11 items-center rounded-full bg-sand px-5 text-sm font-medium text-graphite hover:bg-line">
          {{ category.name }}
        </NuxtLink>
      </li>
    </ul>

    <ProductGrid v-if="data?.cards.length" class="mt-12" :cards="data.cards" />
    <div v-else class="mt-10 text-center">
      <p class="text-muted">{{ q ? 'Nismo pronašli proizvode za taj pojam.' : 'Upiši što tražiš u polje za pretragu.' }}</p>
      <div class="mt-8">
        <SiteLink to="/proizvodi" variant="outline">Pogledajte kolekciju</SiteLink>
      </div>
    </div>
  </section>
</template>
