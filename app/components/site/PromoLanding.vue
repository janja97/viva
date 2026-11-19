<script setup lang="ts">
import type { PromoCard } from '~/composables/usePromoFilters'
// Akcijska stranica (npr. /ciscenje-zaliha,/admin/akcijske-stranice, migracije 0033 i 0034).
// U tijeku: odjeljak za svaki postotak (od najvećeg) i odbrojavanje do kraja. Prije početka: odbrojavanje do početka.
// Izvan akcije stranica ostaje, s tekstom i prijavom na newsletter, kako bi je Google zadržao.
const props = defineProps<{ slug: string }>()

const { fetchCards } = useShop()
const { data: page, refresh } = await useShopPromoPage(props.slug)

if (!page.value) {
  throw createError({ statusCode: 404, message: 'Stranica nije pronađena', fatal: true })
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
    cards: (await fetchCards({ productIds: group.product_ids, pageSize: 96, includePromoOnly: true })).cards,
  })))
  return groups.filter((group) => group.cards.length)
}, { watch: [page], default: () => [] })

// FILTRI (kategorija, popust, boja, cijena), u pregledniku, nad svim proizvodima stranice.
// Glavna kategorija kartice je najviša razina njezine kategorije (Haljine, Obuća...).
const { data: siteCategories } = useSiteCategories()
const { activeCount: promoFilterCount, isFiltered: promoIsFiltered, matches, sortCards, clear: clearPromoFilters } = usePromoFilters()
const isFilterModalOpen = ref(false)
const promoCards = computed<PromoCard[]>(() => sections.value.flatMap((section) => section.cards.map((card) => {
  const main = card.categoryId ? categoryPath(siteCategories.value, card.categoryId)[0] : undefined
  return { ...card, discount: section.percent, mainCategory: main ? { slug: main.slug, name: main.name } : null }
})))
// Jedan popis bez naslova po popustu: najprije veći popust (redoslijed odjeljaka iz baze), osim ako kupac odabere drugi poredak.
const visibleCards = computed(() => sortCards(promoCards.value.filter(matches)))
const visibleTotal = computed(() => visibleCards.value.length)
const visibleTotalLabel = computed(() => `${visibleTotal.value} ${visibleTotal.value % 10 === 1 && visibleTotal.value % 100 !== 11 ? 'model' : 'modela'}`)
// Panel (poredak i filtri) ima smisla čim je više od jednog proizvoda.
const hasFilterOptions = computed(() => promoCards.value.length > 1)

// Filtrirana stranica nije za Google (duplikat), kao i popisi trgovine.
useSeoMeta({ robots: () => (promoIsFiltered.value ? 'noindex, follow' : 'index, follow, max-image-preview:large') })

// "−30 %" za jedan popust, a "do −50 %" kad ih je više. Postotak 0 su proizvodi bez sniženja (Čišćenje zaliha).
const headline = computed(() => {
  const percents = sections.value.map((section) => section.percent).filter(Boolean)
  if (!percents.length) return ''
  return percents.length > 1 ? `do −${Math.max(...percents)} %` : `−${percents[0]} %`
})

const faq = computed(() => page.value!.faq.map((item) => ({ question: fill(item.question), answer: fill(item.answer) })))
const target = computed(() => (page.value?.state === 'upcoming' ? page.value.starts_at : page.value?.ends_at) ?? null)
const sectionLabel = (percent: number) => (percent ? `−${percent} %` : 'Ostali modeli')

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
        <!-- Gumbi popusta uključuju filtar tog popusta i vode do proizvoda. -->
        <nav v-if="sections.length > 1" aria-label="Popusti" class="mt-10">
          <ul class="flex flex-wrap justify-center gap-2">
            <li v-for="section in sections" :key="section.percent">
              <NuxtLink :to="{ query: { popust: String(section.percent) }, hash: '#proizvodi' }" class="inline-flex min-h-11 items-center border border-gold px-5 font-display text-xl text-gold-light transition-colors hover:bg-gold hover:text-graphite">
                {{ sectionLabel(section.percent) }}
              </NuxtLink>
            </li>
          </ul>
        </nav>
      </div>
    </section>

    <template v-if="page.state === 'live'">
      <p v-if="!sections.length" class="py-16 text-center text-muted">Proizvodi na akciji stižu uskoro.</p>

      <!-- Kao popisi trgovine: filtri sa strane (sticky) na računalu, a na mobitelu u prozoru. -->
      <div v-else class="mx-auto max-w-7xl px-4 pt-10 sm:px-6 lg:grid lg:grid-cols-[15rem_minmax(0,1fr)] lg:items-start lg:gap-12 lg:px-8 lg:pt-14" :class="!hasFilterOptions && 'lg:block'">
        <aside v-if="hasFilterOptions" aria-label="Filteri" class="sticky top-24 hidden max-h-[calc(100dvh-7rem)] overflow-y-auto pb-4 pr-2 lg:block">
          <button v-if="promoFilterCount" type="button" class="mb-5 inline-flex min-h-9 cursor-pointer items-center text-xs font-medium uppercase tracking-[0.16em] underline underline-offset-4" @click="clearPromoFilters">
            Očisti filtere ({{ promoFilterCount }})
          </button>
          <PromoFilters :cards="promoCards" />
        </aside>

        <div id="proizvodi" class="min-w-0 scroll-mt-24">
          <ProductGrid v-if="visibleCards.length" :cards="visibleCards" :with-sidebar="hasFilterOptions" />
          <div v-else class="py-16 text-center">
            <p class="text-muted">Nema proizvoda za odabrane filtere.</p>
            <button type="button" class="mt-3 inline-flex min-h-11 cursor-pointer items-center text-xs font-medium uppercase tracking-[0.16em] underline underline-offset-4" @click="clearPromoFilters">
              Očisti filtere
            </button>
          </div>
        </div>
      </div>

      <!-- Na mobitelu je gumb za filtre i poredak uvijek dostupan u donjem desnom kutu. -->
      <FilterFloatingButton v-if="hasFilterOptions && !isFilterModalOpen" :count="promoFilterCount" @open="isFilterModalOpen = true" />

      <BaseModal :open="isFilterModalOpen" title="Filteri i poredak" @close="isFilterModalOpen = false">
        <PromoFilters :cards="promoCards" compact />
        <div class="sticky bottom-0 -mx-5 -mb-5 mt-6 flex gap-2 border-t border-line bg-white p-4 font-body sm:-mx-6 sm:-mb-6 sm:px-6">
          <button v-if="promoFilterCount" type="button" class="min-h-12 flex-none cursor-pointer border border-ink px-4 text-xs font-medium uppercase tracking-[0.16em]" @click="clearPromoFilters">
            Očisti
          </button>
          <button type="button" class="min-h-12 flex-1 cursor-pointer bg-ink px-4 text-xs font-medium uppercase tracking-[0.16em] text-white" @click="isFilterModalOpen = false">
            Prikaži {{ visibleTotalLabel }}
          </button>
        </div>
      </BaseModal>
      <!-- Popust je zasad isključen (i u SHOP_NAV). Za povratak makni komentar.
      <div class="mx-auto max-w-7xl px-4 py-12 text-center sm:px-6 lg:px-8">
        <SiteLink to="/proizvodi?snizeno=1" variant="outline">
          {{ page.is_exclusive ? 'Ostali sniženi proizvodi' : 'Svi sniženi proizvodi s filtrima' }}
        </SiteLink>
      </div>
      -->
      <div class="pb-12" />
    </template>

    <SiteNewsletter v-else />

    <div v-if="faq.length" class="mx-auto max-w-3xl px-4 pb-16 sm:px-6">
      <SiteFaq :items="faq" />
    </div>
  </div>
</template>
