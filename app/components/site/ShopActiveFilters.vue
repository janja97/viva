<script setup lang="ts">
import { X } from '@lucide/vue'
import { DRESS_LENGTHS, HEEL_HEIGHTS } from '~/config/products'

const { filters, activeCount, apply, toggle, clear } = useShopFilters()

const labelOf = (list: { value: string; label: string }[], value: string) =>
  list.find((item) => item.value === value)?.label ?? value

const chips = computed(() => {
  const f = filters.value
  return [
    ...(f.onSale ? [{ key: 'sale', label: 'Na sniženju', remove: () => apply({ onSale: false }) }] : []),
    ...(f.inStock ? [{ key: 'stock', label: 'Samo dostupno', remove: () => apply({ inStock: false }) }] : []),
    ...f.sizes.map((size) => ({ key: `size-${size}`, label: `Veličina ${size}`, remove: () => toggle('sizes', size) })),
    ...f.colors.map((color) => ({ key: `color-${color}`, label: `Boja ${color}`, remove: () => toggle('colors', color) })),
    ...(f.minPrice !== null ? [{ key: 'min', label: `Od ${f.minPrice} KM`, remove: () => apply({ minPrice: null }) }] : []),
    ...(f.maxPrice !== null ? [{ key: 'max', label: `Do ${f.maxPrice} KM`, remove: () => apply({ maxPrice: null }) }] : []),
    ...f.lengths.map((value) => ({ key: `length-${value}`, label: labelOf(DRESS_LENGTHS, value), remove: () => toggle('lengths', value) })),
    ...f.heels.map((value) => ({ key: `heel-${value}`, label: labelOf(HEEL_HEIGHTS, value), remove: () => toggle('heels', value) })),
  ]
})
</script>

<template>
  <div v-if="activeCount" class="mb-6 flex flex-wrap items-center gap-2">
    <button
      v-for="chip in chips"
      :key="chip.key"
      type="button"
      class="inline-flex min-h-11 cursor-pointer items-center gap-1.5 bg-sand px-3 text-sm lg:min-h-9"
      :aria-label="`Ukloni filter: ${chip.label}`"
      @click="chip.remove"
    >
      {{ chip.label }} <X class="size-3" stroke-width="1.25" />
    </button>
    <button type="button" class="inline-flex min-h-11 cursor-pointer items-center px-1 text-xs font-medium uppercase tracking-[0.16em] underline underline-offset-4 lg:min-h-9" @click="clear">
      Očisti sve
    </button>
  </div>
</template>
