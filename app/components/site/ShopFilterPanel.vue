<script setup lang="ts">
import { DRESS_LENGTHS, HEEL_HEIGHTS, PRODUCT_COLORS } from '~/config/products'

const props = defineProps<{
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

function onPrice(key: 'minPrice' | 'maxPrice', event: Event) {
  const { value } = event.target as HTMLInputElement
  const price = value === '' ? null : Number(value)
  apply({ [key]: price !== null && Number.isFinite(price) && price >= 0 ? price : null })
}

const headingClass = 'mb-3 text-xs font-medium uppercase tracking-[0.2em] text-ink'
const checkClass = 'flex min-h-11 cursor-pointer items-center gap-2.5 text-sm text-ink lg:min-h-9'
const inputClass = 'size-4 flex-none accent-ink'
const priceClass = 'min-h-11 w-full min-w-0 border border-line bg-white px-3 text-base text-ink focus:border-ink focus:outline-none lg:text-sm'
</script>

<template>
  <div class="space-y-7 font-body">
    <fieldset class="min-w-0">
      <legend :class="headingClass">Ponuda</legend>
      <label v-if="showSale" :class="checkClass">
        <input type="checkbox" :class="inputClass" :checked="filters.onSale" @change="apply({ onSale: !filters.onSale })">
        Na sniženju
      </label>
      <label :class="checkClass">
        <input type="checkbox" :class="inputClass" :checked="filters.inStock" @change="apply({ inStock: !filters.inStock })">
        Samo dostupno
      </label>
    </fieldset>

    <fieldset v-if="sortedSizes.length" class="min-w-0">
      <legend :class="headingClass">Veličina</legend>
      <div class="flex flex-wrap gap-2">
        <label
          v-for="size in sortedSizes"
          :key="size"
          class="inline-flex min-h-11 min-w-11 cursor-pointer items-center justify-center border px-2.5 text-sm transition-colors has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-gold"
          :class="filters.sizes.includes(size) ? 'border-ink bg-ink text-white' : 'border-line bg-white text-ink hover:border-ink'"
        >
          <input type="checkbox" class="sr-only" :checked="filters.sizes.includes(size)" @change="toggle('sizes', size)">
          {{ size }}
        </label>
      </div>
    </fieldset>

    <fieldset v-if="colors.length" class="min-w-0">
      <legend :class="headingClass">Boja</legend>
      <label v-for="color in colors" :key="color.name" :class="checkClass">
        <input type="checkbox" :class="inputClass" :checked="filters.colors.includes(color.name)" @change="toggle('colors', color.name)">
        <ColorSwatch class="size-4 flex-none" :name="color.name" :hex="color.hex" />
        {{ color.name }}
      </label>
    </fieldset>

    <fieldset class="min-w-0">
      <legend :class="headingClass">Cijena (KM)</legend>
      <div class="flex items-center gap-2">
        <label class="min-w-0 flex-1">
          <span class="sr-only">Cijena od</span>
          <input :class="priceClass" type="number" min="0" inputmode="numeric" :placeholder="options?.minPrice != null ? `Od ${Math.floor(options.minPrice)}` : 'Od'" :value="filters.minPrice ?? ''" @change="onPrice('minPrice', $event)">
        </label>
        <span aria-hidden="true" class="text-muted">–</span>
        <label class="min-w-0 flex-1">
          <span class="sr-only">Cijena do</span>
          <input :class="priceClass" type="number" min="0" inputmode="numeric" :placeholder="options?.maxPrice != null ? `Do ${Math.ceil(options.maxPrice)}` : 'Do'" :value="filters.maxPrice ?? ''" @change="onPrice('maxPrice', $event)">
        </label>
      </div>
    </fieldset>

    <fieldset v-if="lengths.length" class="min-w-0">
      <legend :class="headingClass">Duljina haljine</legend>
      <label v-for="item in lengths" :key="item.value" :class="checkClass">
        <input type="checkbox" :class="inputClass" :checked="filters.lengths.includes(item.value)" @change="toggle('lengths', item.value)">
        {{ item.label }}
      </label>
    </fieldset>

    <fieldset v-if="heels.length" class="min-w-0">
      <legend :class="headingClass">Visina pete</legend>
      <label v-for="item in heels" :key="item.value" :class="checkClass">
        <input type="checkbox" :class="inputClass" :checked="filters.heels.includes(item.value)" @change="toggle('heels', item.value)">
        {{ item.label }}
      </label>
    </fieldset>
  </div>
</template>
