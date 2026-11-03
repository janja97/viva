<script setup lang="ts">
import { HOME_FAQ } from '~/config/home'

const { siteName, siteUrl } = useRuntimeConfig().public
const origin = (siteUrl || useRequestURL().origin).replace(/\/$/, '')

usePageSeo({
  title: 'Svečane i maturalne haljine u Mostaru',
  description: 'Svečane, maturalne i elegantne haljine, odijela, cipele i dodaci u Mostaru. Pogledajte kolekciju online i posjetite Vivu u Mepas Mallu.',
})

const { fetchCards } = useShop()

// Greška baze ne smije srušiti naslovnu, pa se tada proizvodi samo ne prikazuju.
const { data } = await useAsyncData('home', async () => {
  const products = await fetchCards({ pageSize: 4 })
  return { cards: products.cards.slice(0, 4) }
})

useHead({
  script: [
    {
      type: 'application/ld+json',
      innerHTML: JSON.stringify(storeJsonLd(siteName, origin)),
    },
    {
      type: 'application/ld+json',
      innerHTML: JSON.stringify({
        '@context': 'https://schema.org',
        '@type': 'WebSite',
        name: siteName,
        url: origin,
        inLanguage: 'hr-BA',
      }),
    },
    {
      type: 'application/ld+json',
      innerHTML: JSON.stringify({
        '@context': 'https://schema.org',
        '@type': 'FAQPage',
        mainEntity: HOME_FAQ.map(({ question, answer }) => ({
          '@type': 'Question',
          name: question,
          acceptedAnswer: { '@type': 'Answer', text: answer },
        })),
      }),
    },
  ],
})
</script>

<template>
  <div>
    <HomeHero />
    <HomeCategories />
    <HomePanels />
    <HomeLookbook />

    <section v-if="data?.cards.length" class="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8 lg:py-28">
      <SectionHeading
        eyebrow="Upravo stiglo"
        title="Novo u butiku"
        link-to="/proizvodi"
        link-label="Pogledaj sve"
        link-label-short="Sve"
      />
      <ProductGrid :cards="data.cards" is-new />
    </section>

    <HomeVideo />
    <HomeServices />
    <HomeVisit />

    <section class="border-t border-line px-4 py-14 lg:py-20">
      <div class="mx-auto max-w-3xl">
        <SectionHeading eyebrow="Pitanja" title="Često postavljana pitanja" />
        <div class="divide-y divide-line border-y border-line">
          <details v-for="item in HOME_FAQ" :key="item.question" class="py-3">
            <summary class="flex min-h-11 cursor-pointer items-center font-display text-xl">{{ item.question }}</summary>
            <p class="mt-1 pb-2 leading-relaxed text-muted">{{ item.answer }}</p>
          </details>
        </div>
      </div>
    </section>

    <SiteNewsletter />
  </div>
</template>
