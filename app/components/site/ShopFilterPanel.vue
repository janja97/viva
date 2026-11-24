<script setup lang="ts">
import { DRESS_LENGTHS, HEEL_HEIGHTS, PRODUCT_COLORS } from '~/config/products'

// Skupine se otvaraju i zatvaraju (FilterGroup). Na računalu su otvorene, a u prozoru na mobitelu (compact)
// otvorene su samo skupine u kojima je nešto odabrano.
const props = defineProps<{
  compact?: boolean
  options: {
    colors: { name: string; hex: string }[]
    sizes: string[]
    lengths: string[]
    heels: string[]
    hasSale: boolean
    minPrice: number | null
    maxPrice: number | null
  } | null
}>()

const { filters, apply, toggle } = useShopFilters()

// Nude se samo vrijednosti koje postoje među proizvodima ovog popisa (npr. obuća nema duljinu haljine),
// uz one koje su već odabrane u adresi, da se odabir uvijek može i maknuti.
const sortedSizes = computed(() => sortSizes([...new Set([...(props.options?.sizes ?? []), ...filters.value.sizes])]))
const colors = computed(() => {
  const available = props.options?.colors ?? []
  const missing = filters.value.colors
    .filter((name) => !available.some((color) => color.name === name))
    .map((name) => ({ name, hex: PRODUCT_COLORS.find((color) => color.name === name)?.hex ?? '' }))
  return [...available, ...missing]
})
const lengths = computed(() => DRESS_LENGTHS.filter((item) =>
  props.options?.lengths.includes(item.value) || filters.value.lengths.includes(item.value)))
const heels = computed(() => HEEL_HEIGHTS.filter((item) =>
  props.options?.heels.includes(item.value) || filters.value.heels.includes(item.value)))
const showSale = computed(() => props.options?.hasSale || filters.value.onSale)

// Računalo: dugi popis boja skraćuje se na prvih COLOR_LIMIT, uz "Prikaži sve". Odabrane boje se uvijek vide.
// Na mobitelu (compact) popis je cijeli, kao i dosad.
const COLOR_LIMIT = 10
const showAllColors = ref(false)
const visibleColors = computed(() => {
  if (props.compact || showAllColors.value || colors.value.length <= COLOR_LIMIT) return colors.value
  return colors.value.filter((color, index) => index < COLOR_LIMIT || filters.value.colors.includes(color.name))
})
const hiddenColorCount = computed(() => colors.value.length - visibleColors.value.length)


const offerCount = computed(() => (filters.value.onSale ? 1 : 0) + (filters.value.inStock ? 1 : 0))
const priceCount = computed(() => (filters.value.minPrice !== null ? 1 : 0) + (filters.value.maxPrice !== null ? 1 : 0))
const isOpen = (active: boolean) => !props.compact || active

const sizeClass = (active: boolean) => [
  'inline-flex min-h-11 min-w-11 cursor-pointer items-center justify-center border px-2.5 text-sm transition-colors has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-gold lg:min-h-10 lg:min-w-0 lg:px-1 lg:text-[13px]',
  active ? 'border-ink bg-ink text-white' : 'border-line bg-white text-ink hover:border-ink',
]
</script>

<template>
  <div class="border-t border-line font-body">
    <!-- Ponuda (Na sniženju, Samo dostupno) zasad je isključena na zahtjev vlasnice. Za povratak makni komentar.
    <FilterGroup title="Ponuda" :count="offerCount" :open="isOpen(offerCount > 0)">
      <FilterOption v-if="showSale" :checked="filters.onSale" @change="apply({ onSale: !filters.onSale })">Na sniženju</FilterOption>
      <FilterOption :checked="filters.inStock" @change="apply({ inStock: !filters.inStock })">Samo dostupno</FilterOption>
    </FilterGroup>
    -->

    <FilterGroup v-if="sortedSizes.length" title="Veličina" :count="filters.sizes.length" :open="isOpen(filters.sizes.length > 0)">
      <!-- Računalo: veličine u jednakoj mreži od 4 stupca, da se poravnaju. -->
      <div class="flex flex-wrap gap-2" :class="!compact && 'lg:grid lg:grid-cols-4'">
        <label v-for="size in sortedSizes" :key="size" :class="sizeClass(filters.sizes.includes(size))">
          <input type="checkbox" class="sr-only" :checked="filters.sizes.includes(size)" @change="toggle('sizes', size)">
          {{ size }}
        </label>
      </div>
    </FilterGroup>

    <FilterGroup v-if="colors.length" title="Boja" :count="filters.colors.length" :open="isOpen(filters.colors.length > 0)">
      <!-- Računalo: boje u dva stupca. -->
      <div :class="!compact && 'lg:grid lg:grid-cols-2 lg:gap-x-3'">
        <FilterOption v-for="color in visibleColors" :key="color.name" :checked="filters.colors.includes(color.name)" @change="toggle('colors', color.name)">
          <ColorSwatch class="size-4 flex-none" :name="color.name" :hex="color.hex" />
          <span class="truncate">{{ color.name }}</span>
        </FilterOption>
      </div>
      <button
        v-if="hiddenColorCount > 0 || (showAllColors && colors.length > COLOR_LIMIT)"
        type="button"
        class="mt-2 inline-flex min-h-9 cursor-pointer items-center text-[11px] font-medium uppercase tracking-[0.16em] text-muted underline underline-offset-4 hover:text-ink"
        @click="showAllColors = !showAllColors"
      >
        {{ showAllColors ? 'Prikaži manje' : `Prikaži sve (${colors.length})` }}
      </button>
    </FilterGroup>

    <FilterGroup title="Cijena" :count="priceCount" :open="isOpen(priceCount > 0)">
      <FilterPriceRange :min="filters.minPrice" :max="filters.maxPrice" :range-min="options?.minPrice" :range-max="options?.maxPrice" @change="(key, value) => apply({ [key]: value })" />
    </FilterGroup>

    <FilterGroup v-if="lengths.length" title="Duljina haljine" :count="filters.lengths.length" :open="isOpen(filters.lengths.length > 0)">
      <FilterOption v-for="item in lengths" :key="item.value" :checked="filters.lengths.includes(item.value)" @change="toggle('lengths', item.value)">{{ item.label }}</FilterOption>
    </FilterGroup>

    <FilterGroup v-if="heels.length" title="Visina pete" :count="filters.heels.length" :open="isOpen(filters.heels.length > 0)">
      <FilterOption v-for="item in heels" :key="item.value" :checked="filters.heels.includes(item.value)" @change="toggle('heels', item.value)">{{ item.label }}</FilterOption>
    </FilterGroup>
  </div>
</template>
