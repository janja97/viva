<script setup lang="ts">
import { PROMO_SORTS, type PromoCard } from '~/composables/usePromoFilters'

// Panel filtara akcijske stranice, isti izgled kao ShopFilterPanel: skupine se otvaraju i zatvaraju.
// Na računalu su sa strane i otvorene, a na mobitelu u prozoru (compact) otvorene su samo skupine s odabirom.
// Nude se samo vrijednosti koje postoje među proizvodima stranice, a skupina s jednom mogućnošću se ne prikazuje.
const props = defineProps<{ cards: PromoCard[]; compact?: boolean }>()

const { filters, apply, toggleColor, toggleDiscount } = usePromoFilters()
const options = computed(() => promoFilterOptions(props.cards))
// Panel je na stranici dvaput (sa strane i u prozoru), pa skupine radio gumba trebaju svoja imena.
const uid = useId()


const priceCount = computed(() => (filters.value.minPrice !== null ? 1 : 0) + (filters.value.maxPrice !== null ? 1 : 0))
const isOpen = (active: boolean) => !props.compact || active

const chipClass = (active: boolean) => [
  'inline-flex min-h-11 min-w-14 cursor-pointer items-center justify-center border px-3 text-sm transition-colors has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-gold lg:min-h-10',
  active ? 'border-ink bg-ink text-white' : 'border-line bg-white text-ink hover:border-ink',
]
</script>

<template>
  <div class="border-t border-line font-body">
    <!-- Poredak bira kupac. Zadano je Najnovije, redoslijed kako stižu iz baze. -->
    <FilterGroup title="Poredaj" :open="isOpen(filters.sort !== 'new')">
      <FilterOption v-for="sort in PROMO_SORTS" :key="sort.value" type="radio" :name="`${uid}-poredak`" :checked="filters.sort === sort.value" @change="apply({ sort: sort.value })">
        {{ sort.label }}
      </FilterOption>
    </FilterGroup>

    <FilterGroup v-if="options.categories.length > 1" title="Kategorija" :count="filters.category ? 1 : 0" :open="isOpen(Boolean(filters.category))">
      <FilterOption type="radio" :name="`${uid}-kategorija`" :checked="!filters.category" @change="apply({ category: '' })">Sve</FilterOption>
      <FilterOption v-for="category in options.categories" :key="category.slug" type="radio" :name="`${uid}-kategorija`" :checked="filters.category === category.slug" @change="apply({ category: category.slug })">
        {{ category.name }}
      </FilterOption>
    </FilterGroup>

    <FilterGroup v-if="options.discounts.length > 1" title="Popust" :count="filters.discounts.length" :open="isOpen(filters.discounts.length > 0)">
      <div class="flex flex-wrap gap-2">
        <label v-for="percent in options.discounts" :key="percent" :class="chipClass(filters.discounts.includes(percent))">
          <input type="checkbox" class="sr-only" :checked="filters.discounts.includes(percent)" @change="toggleDiscount(percent)">
          {{ percent ? `−${percent} %` : 'Bez popusta' }}
        </label>
      </div>
    </FilterGroup>

    <FilterGroup v-if="options.colors.length > 1" title="Boja" :count="filters.colors.length" :open="isOpen(filters.colors.length > 0)">
      <FilterOption v-for="color in options.colors" :key="color.name" :checked="filters.colors.includes(color.name)" @change="toggleColor(color.name)">
        <ColorSwatch class="size-4 flex-none" :name="color.name" :hex="color.hex" />
        {{ color.name }}
      </FilterOption>
    </FilterGroup>

    <FilterGroup v-if="options.price && options.price.max > options.price.min" title="Cijena" :count="priceCount" :open="isOpen(priceCount > 0)">
      <FilterPriceRange :min="filters.minPrice" :max="filters.maxPrice" :range-min="options.price.min" :range-max="options.price.max" @change="(key, value) => apply({ [key]: value })" />
    </FilterGroup>
  </div>
</template>
