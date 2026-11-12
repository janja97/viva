<script setup lang="ts">
// Akcijska stranica (npr. /black-friday, /admin/akcijske-stranice, migracije 0033 i 0034).
// U tijeku: odjeljak za svaki postotak (od najvećeg) i odbrojavanje do kraja. Prije početka: odbrojavanje do početka.
// Izvan akcije stranica ostaje, s tekstom i prijavom na newsletter, kako bi je Google zadržao.
const props = defineProps<{ slug: string }>()

const { fetchCards } = useShop()
const { data: page, refresh } = await useShopPromoPage(props.slug)

if (!page.value) {
  throw createError({ statusCode: 404, statusMessage: 'Stranica nije pronađena', fatal: true })
}

const fill = (text: string) => fillPromoYear(text, page.value)
const title = computed(() => fill(page.value!.title))

usePageSeo({
  title: fill(page.value.meta_title || page.value.title),
  description: fill(page.value.meta_description || page.value.intro || page.value.off_text),
})

// Kartice po postotku. Svaka skupina se učitava zasebno, jer kartice ne nose id proizvoda.
const { data: sections } = await useAsyncData(`promo-cards-${props.slug}`, async () => {
  if (page.value?.state !== 'live') return []
  const groups = await Promise.all(page.value.groups.map(async (group) => ({
    percent: group.discount_percent,
    cards: (await fetchCards({ productIds: group.product_ids, pageSize: 96 })).cards,
  })))
  return groups.filter((group) => group.cards.length)
}, { watch: [page], default: () => [] })

// "−30 %" za jedan popust, a "do −50 %" kad ih je više.
const headline = computed(() => {
  const percents = sections.value.map((section) => section.percent)
  if (!percents.length) return ''
  return percents.length > 1 ? `do −${Math.max(...percents)} %` : `−${percents[0]} %`
})

const faq = computed(() => page.value!.faq.map((item) => ({ question: fill(item.question), answer: fill(item.answer) })))
const target = computed(() => (page.value?.state === 'upcoming' ? page.value.starts_at : page.value?.ends_at) ?? null)
const sectionId = (percent: number) => `popust-${percent}`

// Kad odbrojavanje dođe do nule, stanje se ponovno čita iz baze (početak ili kraj akcije).
async function onCountdownDone() {
  await refresh()
}
</script>

<template>
  <div v-if="page">
    <SiteBreadcrumbs class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8" :items="[{ label: 'Početna', to: '/' }, { label: title }]" />
    <section class="bg-graphite text-white">
      <div class="mx-auto max-w-4xl px-4 py-14 text-center sm:px-6 sm:py-20">
        <p v-if="page.state === 'live' && headline" class="font-display text-6xl text-gold-light sm:text-7xl">{{ headline }}</p>
        <p v-else-if="page.state === 'upcoming'" class="text-xs font-medium uppercase tracking-[0.24em] text-gold-light">Uskoro</p>
        <h1 class="mt-3 font-display text-5xl font-normal leading-tight sm:text-6xl">{{ title }}</h1>
        <p class="mx-auto mt-5 max-w-2xl leading-relaxed text-white/80">
          {{ page.state === 'off' ? fill(page.off_text) : fill(page.intro) }}
        </p>

        <div v-if="page.state !== 'off' && target" class="mt-8">
          <p class="text-[11px] uppercase tracking-[0.2em] text-white/70">{{ page.state === 'live' ? 'Završava za' : 'Počinje za' }}</p>
          <CountdownTimer :key="target" class="mt-2 justify-center font-display text-4xl sm:text-5xl" :target="target" @done="onCountdownDone" />
        </div>

        <!-- Kratke poveznice na odjeljke kad je popusta više. -->
        <nav v-if="sections.length > 1" aria-label="Popusti" class="mt-10">
          <ul class="flex flex-wrap justify-center gap-2">
            <li v-for="section in sections" :key="section.percent">
              <a :href="`#${sectionId(section.percent)}`" class="inline-flex min-h-11 items-center border border-gold px-5 font-display text-xl text-gold-light transition-colors hover:bg-gold hover:text-graphite">
                −{{ section.percent }} %
              </a>
            </li>
          </ul>
        </nav>
      </div>
    </section>

    <template v-if="page.state === 'live'">
      <section
        v-for="section in sections"
        :id="sectionId(section.percent)"
        :key="section.percent"
        :aria-labelledby="`${sectionId(section.percent)}-naslov`"
        class="mx-auto max-w-7xl scroll-mt-24 px-4 pt-12 sm:px-6 lg:px-8"
      >
        <h2 :id="`${sectionId(section.percent)}-naslov`" class="mb-6 flex items-baseline gap-3 border-b border-line pb-3 font-display text-4xl font-normal">
          <span class="text-red-700">−{{ section.percent }} %</span>
          <span class="font-body text-sm text-muted">{{ section.cards.length }} {{ section.cards.length % 10 === 1 && section.cards.length % 100 !== 11 ? 'model' : 'modela' }}</span>
        </h2>
        <ProductGrid :cards="section.cards" />
      </section>

      <p v-if="!sections.length" class="py-16 text-center text-muted">Proizvodi na akciji stižu uskoro.</p>
      <div class="mx-auto max-w-7xl px-4 py-12 text-center sm:px-6 lg:px-8">
        <SiteLink to="/proizvodi?snizeno=1" variant="outline">Svi sniženi proizvodi s filtrima</SiteLink>
      </div>
    </template>

    <SiteNewsletter v-else />

    <div v-if="faq.length" class="mx-auto max-w-3xl px-4 pb-16 sm:px-6">
      <SiteFaq :items="faq" />
    </div>
  </div>
</template>
