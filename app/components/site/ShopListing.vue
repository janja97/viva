<script setup lang="ts">
import { SHOP_SORTS } from '~/composables/useShopFilters'
import type { ShopCard, ShopSort } from '~/composables/useShop'

const props = defineProps<{
  listingKey: string
  categoryIds?: string[]
  emptyText: string
  // Kategorija s vlastitim opisom korisna je Googleu i prije prvih proizvoda.
  indexWhenEmpty?: boolean
}>()

const route = useRoute()
const { filterCards, fetchFilterOptions } = useShop()
const { filters, page, activeCount, isFiltered, apply, clear } = useShopFilters()
const isModalOpen = ref(false)

const { data: options } = await useAsyncData(`filters-${props.listingKey}`, () => fetchFilterOptions(props.categoryIds))

const cardsKey = computed(() => `cards-${props.listingKey}-${JSON.stringify(filters.value)}-${page.value}`)
const { data, error } = await useAsyncData(
  () => cardsKey.value,
  () => filterCards(filters.value, { page: page.value - 1, categoryIds: props.categoryIds }),
)

const total = computed(() => data.value?.total ?? 0)
const pageCount = computed(() => Math.ceil(total.value / SHOP_PAGE_SIZE))
const totalLabel = computed(() => `${total.value} ${total.value === 1 ? 'proizvod' : 'proizvoda'}`)

// DODATNO UČITAVANJE
// Prva stranica dolazi sa servera (i ?stranica=N za Google). U pregledniku se sljedećih SHOP_PAGE_SIZE proizvoda
// učita samo kad kupac dođe do kraja popisa. Učitano se pamti, da povratak s proizvoda vrati isti popis.
const more = useState<{ key: string; cards: ShopCard[]; lastPage: number }>(`more-${props.listingKey}`, () => ({ key: '', cards: [], lastPage: 0 }))
const isLoadingMore = ref(false)
const loadMoreError = ref(false)
const isMounted = ref(false)
const sentinel = useTemplateRef<HTMLElement>('sentinel')

// Novi filtar, redoslijed ili stranica počinju ispočetka.
watch(cardsKey, (key) => {
  if (more.value.key !== key) more.value = { key, cards: [], lastPage: page.value }
}, { immediate: true })

const cards = computed(() => [...(data.value?.cards ?? []), ...more.value.cards])
const hasMore = computed(() => more.value.lastPage < pageCount.value)

async function loadMore() {
  if (isLoadingMore.value || !hasMore.value) return
  const key = cardsKey.value
  isLoadingMore.value = true
  loadMoreError.value = false
  try {
    const next = await filterCards(filters.value, { page: more.value.lastPage, categoryIds: props.categoryIds })
    // Odgovor za stari filtar se odbacuje.
    if (key !== cardsKey.value) return
    const known = new Set(cards.value.map((card) => card.id))
    more.value = {
      key,
      cards: [...more.value.cards, ...next.cards.filter((card) => !known.has(card.id))],
      lastPage: more.value.lastPage + 1,
    }
  } catch {
    loadMoreError.value = true
  } finally {
    isLoadingMore.value = false
  }
}

let observer: IntersectionObserver | null = null
onMounted(() => {
  isMounted.value = true
  // Učitava malo prije samog kraja, da kupac ne čeka.
  observer = new IntersectionObserver((entries) => {
    if (entries.some((entry) => entry.isIntersecting) && !loadMoreError.value) loadMore()
  }, { rootMargin: '600px 0px' })
})
// Nakon svakog učitavanja promatranje kreće iznova, pa se popis puni i kad je kraj još uvijek na ekranu.
watch([sentinel, isLoadingMore, isMounted], () => {
  observer?.disconnect()
  if (sentinel.value && !isLoadingMore.value) observer?.observe(sentinel.value)
}, { flush: 'post' })
onBeforeUnmount(() => observer?.disconnect())

useSeoMeta({
  robots: () => (isFiltered.value || (!total.value && !props.indexWhenEmpty) ? 'noindex, follow' : 'index, follow'),
})
</script>

<template>
  <div class="lg:grid lg:grid-cols-[16rem_minmax(0,1fr)] lg:items-start lg:gap-14">
    <!-- Računalo: filteri sa strane, sticky. Mobitel ih otvara gumbom (FilterFloatingButton) u prozoru niže. -->
    <aside aria-label="Filteri" class="sticky top-24 hidden max-h-[calc(100dvh-7rem)] overflow-y-auto pb-4 pr-3 [scrollbar-width:thin] lg:block">
      <div class="mb-4 flex items-end justify-between gap-3">
        <h2 class="font-display text-2xl font-normal leading-none">Filtriraj</h2>
        <button
          v-if="activeCount"
          type="button"
          class="cursor-pointer text-[11px] font-medium uppercase tracking-[0.16em] text-muted underline underline-offset-4 transition-colors hover:text-ink"
          @click="clear"
        >
          Očisti ({{ activeCount }})
        </button>
      </div>
      <ShopFilterPanel :options="options ?? null" />
    </aside>

    <div class="min-w-0">
      <div class="mb-6 flex flex-wrap items-center justify-between gap-x-4 gap-y-1 border-y border-line py-2">
        <p class="text-sm text-muted" role="status">{{ totalLabel }}</p>

        <label class="flex items-center gap-2 text-sm">
          <span class="text-muted">Poredaj</span>
          <select
            class="min-h-11 cursor-pointer border border-line bg-white px-2 text-base focus:border-ink focus:outline-none lg:text-sm"
            :value="filters.sort"
            @change="apply({ sort: ($event.target as HTMLSelectElement).value as ShopSort })"
          >
            <option v-for="sort in SHOP_SORTS" :key="sort.value" :value="sort.value">{{ sort.label }}</option>
          </select>
        </label>
      </div>

      <ShopActiveFilters />

      <p v-if="error" class="py-10 text-center text-muted">Proizvode trenutno nije moguće učitati. Pokušajte ponovno malo kasnije.</p>
      <ProductGrid v-else-if="cards.length" :cards="cards" with-sidebar />
      <div v-else-if="isFiltered" class="py-10 text-center">
        <p class="text-muted">Nema proizvoda za odabrane filtere.</p>
        <button type="button" class="mt-3 inline-flex min-h-11 cursor-pointer items-center text-xs font-medium uppercase tracking-[0.16em] underline underline-offset-4" @click="clear">
          Očisti filtere
        </button>
      </div>
      <p v-else class="py-10 text-center text-muted">{{ emptyText }}</p>

      <!-- U pregledniku: sljedeći proizvodi se učitaju sami pri dnu popisa, a gumb je rezerva. -->
      <div v-if="isMounted && hasMore && !error" ref="sentinel" class="mt-12 flex min-h-11 flex-col items-center justify-center gap-3 text-sm" aria-live="polite">
        <p v-if="isLoadingMore" class="text-muted">Učitavanje proizvoda...</p>
        <template v-else>
          <p v-if="loadMoreError" class="text-muted">Proizvode nije moguće učitati.</p>
          <button type="button" class="inline-flex min-h-11 cursor-pointer items-center border border-ink px-6 text-xs font-medium uppercase tracking-[0.16em] transition-colors hover:bg-ink hover:text-white" @click="loadMore">
            {{ loadMoreError ? 'Pokušaj ponovno' : 'Učitaj još proizvoda' }}
          </button>
        </template>
      </div>

      <!-- Bez JavaScripta i za Google ostaju obične stranice (?stranica=N). -->
      <nav v-if="!isMounted && pageCount > 1" aria-label="Stranice" class="mt-14 flex items-center justify-center gap-6 text-sm">
        <NuxtLink v-if="page > 1" :to="{ query: { ...route.query, stranica: page === 2 ? undefined : page - 1 } }" class="inline-flex min-h-11 items-center underline underline-offset-4">Prethodna</NuxtLink>
        <span class="text-muted">{{ page }} / {{ pageCount }}</span>
        <NuxtLink v-if="page < pageCount" :to="{ query: { ...route.query, stranica: page + 1 } }" class="inline-flex min-h-11 items-center underline underline-offset-4">Sljedeća</NuxtLink>
      </nav>
    </div>

    <!-- Na mobitelu je gumb za filtre uvijek dostupan u donjem desnom kutu. -->
    <FilterFloatingButton v-if="!isModalOpen" :count="activeCount" @open="isModalOpen = true" />

    <BaseModal :open="isModalOpen" title="Filteri" @close="isModalOpen = false">
      <ShopFilterPanel :options="options ?? null" compact />
      <div class="sticky bottom-0 -mx-5 -mb-5 mt-6 flex gap-2 border-t border-line bg-white p-4 font-body sm:-mx-6 sm:-mb-6 sm:px-6">
        <button v-if="activeCount" type="button" class="min-h-12 flex-none cursor-pointer border border-ink px-4 text-xs font-medium uppercase tracking-[0.16em]" @click="clear">
          Očisti
        </button>
        <button type="button" class="min-h-12 flex-1 cursor-pointer bg-ink px-4 text-xs font-medium uppercase tracking-[0.16em] text-white" @click="isModalOpen = false">
          Prikaži {{ totalLabel }}
        </button>
      </div>
    </BaseModal>
  </div>
</template>
