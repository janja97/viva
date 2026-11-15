<script setup lang="ts">
import { HOME_CLEARANCE, HOME_FAQ, HOME_NEW, HOME_SEASON } from '~/config/home'
import { EXCLUSIVE_PROMO_PAGE } from '~/config/navigation'

const { siteName, siteUrl } = useRuntimeConfig().public
const origin = (siteUrl || useRequestURL().origin).replace(/\/$/, '')

usePageSeo({
  title: 'Svečane i maturalne haljine u Mostaru',
  description: 'Svečane i maturalne haljine, haljine za svadbu, ženska odijela, cipele na petu i torbice u Mepas Mallu u Mostaru. Dostava po BiH, plaćanje pouzećem.',
})

const { fetchCards } = useShop()

// "Novo": nasumičan izbor među najnovijim proizvodima, pa nije uvijek isti. Miješa se ovdje (na serveru),
// a rezultat ide pregledniku, da se prikaz ne razlikuje. Greška baze ne smije srušiti naslovnu.
const { data } = await useAsyncData('home', async () => {
  const products = await fetchCards({ pageSize: HOME_NEW.pool })
  const cards = [...products.cards]
  for (let index = cards.length - 1; index > 0; index--) {
    const other = Math.floor(Math.random() * (index + 1))
    ;[cards[index], cards[other]] = [cards[other]!, cards[index]!]
  }
  return { cards: cards.slice(0, HOME_NEW.count) }
})

// Najava čišćenja zaliha vidi se samo dok je ta stranica uključena.
const { data: clearance } = await useShopPromoPage(EXCLUSIVE_PROMO_PAGE.slug)
const categoryLink = useCategoryLink()

const storeSettings = useStoreSettings()
await storeSettings.ready()

useHead({
  script: [
    {
      type: 'application/ld+json',
      innerHTML: JSON.stringify(storeJsonLd(siteName, origin, storeSettings.settings.value)),
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
    <HomeOccasions />
    <HomeFeature
      :eyebrow="HOME_SEASON.eyebrow"
      :title="HOME_SEASON.title"
      :accent="HOME_SEASON.accent"
      :text="HOME_SEASON.text"
      :link-label="HOME_SEASON.link"
      :to="categoryLink(HOME_SEASON.slug)"
      :image="HOME_SEASON.image"
      :image-alt="HOME_SEASON.imageAlt"
    />
    <HomeLookbook />
    <HomeNew v-if="data?.cards.length" :cards="data.cards" />
    <HomeFeature
      v-if="clearance?.state === 'live'"
      :eyebrow="HOME_CLEARANCE.eyebrow"
      :title="HOME_CLEARANCE.title"
      :accent="HOME_CLEARANCE.accent"
      :text="HOME_CLEARANCE.text"
      :link-label="HOME_CLEARANCE.link"
      :to="`/${EXCLUSIVE_PROMO_PAGE.slug}`"
      :image="HOME_CLEARANCE.image"
      :image-alt="HOME_CLEARANCE.imageAlt"
      reverse
      dark
    />

    <HomeVideo />
    <HomeHighlights />
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
    <HomeCountdown />
  </div>
</template>
