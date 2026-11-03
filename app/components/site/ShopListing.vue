<script setup lang="ts">
import { SlidersHorizontal } from '@lucide/vue'
import { SHOP_SORTS } from '~/composables/useShopFilters'
import type { ShopSort } from '~/composables/useShop'

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

const { data, error } = await useAsyncData(
  () => `cards-${props.listingKey}-${JSON.stringify(filters.value)}-${page.value}`,
  () => filterCards(filters.value, { page: page.value - 1, categoryIds: props.categoryIds }),
)

const total = computed(() => data.value?.total ?? 0)
const pageCount = computed(() => Math.ceil(total.value / SHOP_PAGE_SIZE))
const totalLabel = computed(() => `${total.value} ${total.value === 1 ? 'proizvod' : 'proizvoda'}`)

useSeoMeta({
  robots: () => (isFiltered.value || (!total.value && !props.indexWhenEmpty) ? 'noindex, follow' : 'index, follow'),
})
</script>

<template>
  <div class="lg:grid lg:grid-cols-[15rem_minmax(0,1fr)] lg:items-start lg:gap-12">
    <aside aria-label="Filteri" class="sticky top-24 hidden max-h-[calc(100dvh-7rem)] overflow-y-auto pb-4 pr-2 lg:block">
      <ShopFilterPanel :options="options ?? null" />
    </aside>

    <div class="min-w-0">
      <div class="mb-6 flex flex-wrap items-center justify-between gap-x-4 gap-y-1 border-y border-line py-2">
        <button
          type="button"
          class="inline-flex min-h-11 cursor-pointer items-center gap-2 text-xs font-medium uppercase tracking-[0.2em] lg:hidden"
          aria-haspopup="dialog"
          @click="isModalOpen = true"
        >
          <SlidersHorizontal class="size-4" stroke-width="1.25" />
          Filteri<template v-if="activeCount"> ({{ activeCount }})</template>
        </button>

        <p class="order-last w-full text-sm text-muted lg:order-none lg:w-auto" role="status">{{ totalLabel }}</p>

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
      <ProductGrid v-else-if="data?.cards.length" :cards="data.cards" with-sidebar />
      <div v-else-if="isFiltered" class="py-10 text-center">
        <p class="text-muted">Nema proizvoda za odabrane filtere.</p>
        <button type="button" class="mt-3 inline-flex min-h-11 cursor-pointer items-center text-xs font-medium uppercase tracking-[0.16em] underline underline-offset-4" @click="clear">
          Očisti filtere
        </button>
      </div>
      <p v-else class="py-10 text-center text-muted">{{ emptyText }}</p>

      <nav v-if="pageCount > 1" aria-label="Stranice" class="mt-14 flex items-center justify-center gap-6 text-sm">
        <NuxtLink v-if="page > 1" :to="{ query: { ...route.query, stranica: page === 2 ? undefined : page - 1 } }" class="inline-flex min-h-11 items-center underline underline-offset-4">Prethodna</NuxtLink>
        <span class="text-muted">{{ page }} / {{ pageCount }}</span>
        <NuxtLink v-if="page < pageCount" :to="{ query: { ...route.query, stranica: page + 1 } }" class="inline-flex min-h-11 items-center underline underline-offset-4">Sljedeća</NuxtLink>
      </nav>
    </div>

    <BaseModal :open="isModalOpen" title="Filteri" @close="isModalOpen = false">
      <ShopFilterPanel :options="options ?? null" />
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
