<script setup lang="ts">
import { PROMO_SORTS, type PromoCard } from '~/composables/usePromoFilters'

// Panel filtara akcijske stranice, isti izgled kao ShopFilterPanel: na računalu sa strane, na mobitelu u prozoru.
// Nude se samo vrijednosti koje postoje među proizvodima stranice, a skupina s jednom mogućnošću se ne prikazuje.
const props = defineProps<{ cards: PromoCard[] }>()

const { filters, apply, toggleColor, toggleDiscount } = usePromoFilters()
const options = computed(() => promoFilterOptions(props.cards))
// Panel je na stranici dvaput (sa strane i u prozoru), pa skupine radio gumba trebaju svoja imena.
const uid = useId()

function onPrice(key: 'minPrice' | 'maxPrice', event: Event) {
  const { value } = event.target as HTMLInputElement
  const price = value === '' ? null : Number(value)
  apply({ [key]: price !== null && Number.isFinite(price) && price >= 0 ? price : null })
}

const headingClass = 'mb-3 text-xs font-medium uppercase tracking-[0.2em] text-ink'
const checkClass = 'flex min-h-11 cursor-pointer items-center gap-2.5 text-sm text-ink lg:min-h-9'
const inputClass = 'size-4 flex-none accent-ink'
const chipClass = (active: boolean) => [
  'inline-flex min-h-11 min-w-11 cursor-pointer items-center justify-center border px-3 text-sm transition-colors has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-gold',
  active ? 'border-ink bg-ink text-white' : 'border-line bg-white text-ink hover:border-ink',
]
const priceClass = 'min-h-11 w-full min-w-0 border border-line bg-white px-3 text-base text-ink focus:border-ink focus:outline-none lg:text-sm'
</script>

<template>
  <div class="space-y-7 font-body">
    <!-- Poredak bira kupac. Zadano je Najnovije, redoslijed kako stižu iz baze. -->
    <fieldset class="min-w-0">
      <legend :class="headingClass">Poredaj</legend>
      <label v-for="sort in PROMO_SORTS" :key="sort.value" :class="checkClass">
        <input type="radio" :name="`${uid}-poredak`" :class="inputClass" :checked="filters.sort === sort.value" @change="apply({ sort: sort.value })">
        {{ sort.label }}
      </label>
    </fieldset>

    <fieldset v-if="options.categories.length > 1" class="min-w-0">
      <legend :class="headingClass">Kategorija</legend>
      <label :class="checkClass">
        <input type="radio" :name="`${uid}-kategorija`" :class="inputClass" :checked="!filters.category" @change="apply({ category: '' })">
        Sve
      </label>
      <label v-for="category in options.categories" :key="category.slug" :class="checkClass">
        <input type="radio" :name="`${uid}-kategorija`" :class="inputClass" :checked="filters.category === category.slug" @change="apply({ category: category.slug })">
        {{ category.name }}
      </label>
    </fieldset>

    <fieldset v-if="options.discounts.length > 1" class="min-w-0">
      <legend :class="headingClass">Popust</legend>
      <div class="flex flex-wrap gap-2">
        <label v-for="percent in options.discounts" :key="percent" :class="chipClass(filters.discounts.includes(percent))">
          <input type="checkbox" class="sr-only" :checked="filters.discounts.includes(percent)" @change="toggleDiscount(percent)">
          {{ percent ? `−${percent} %` : 'Bez popusta' }}
        </label>
      </div>
    </fieldset>

    <fieldset v-if="options.colors.length > 1" class="min-w-0">
      <legend :class="headingClass">Boja</legend>
      <label v-for="color in options.colors" :key="color.name" :class="checkClass">
        <input type="checkbox" :class="inputClass" :checked="filters.colors.includes(color.name)" @change="toggleColor(color.name)">
        <ColorSwatch class="size-4 flex-none" :name="color.name" :hex="color.hex" />
        {{ color.name }}
      </label>
    </fieldset>

    <fieldset v-if="options.price && options.price.max > options.price.min" class="min-w-0">
      <legend :class="headingClass">Cijena (KM)</legend>
      <div class="flex items-center gap-2">
        <label class="min-w-0 flex-1">
          <span class="sr-only">Cijena od</span>
          <input :class="priceClass" type="number" min="0" inputmode="numeric" :placeholder="`Od ${options.price.min}`" :value="filters.minPrice ?? ''" @change="onPrice('minPrice', $event)">
        </label>
        <span aria-hidden="true" class="text-muted">–</span>
        <label class="min-w-0 flex-1">
          <span class="sr-only">Cijena do</span>
          <input :class="priceClass" type="number" min="0" inputmode="numeric" :placeholder="`Do ${options.price.max}`" :value="filters.maxPrice ?? ''" @change="onPrice('maxPrice', $event)">
        </label>
      </div>
    </fieldset>
  </div>
</template>
