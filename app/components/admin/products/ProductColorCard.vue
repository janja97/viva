<script setup lang="ts">
import { ChevronDown, ChevronUp, Trash2 } from '@lucide/vue'
import { PRODUCT_COLORS } from '~/config/products'
import type { ProductImagesApi } from '~/composables/useProductImages'
import type { ColorForm } from '~/types/productForm'

const props = defineProps<{
  color: ColorForm
  sizes: string[]
  // Boje koje već koriste druge kartice istog proizvoda.
  usedColors: string[]
  generatedSlug: string
  api: ProductImagesApi
  isFirst: boolean
  isLast: boolean
}>()

const emit = defineEmits<{
  remove: []
  move: [direction: -1 | 1]
}>()

// Stari naziv koji nije na popisu ostaje ponuđen, kako se spremljena boja ne bi izgubila.
const colorOptions = computed(() => {
  const names = PRODUCT_COLORS.map(({ name }) => name).filter((name) => !props.usedColors.includes(name))
  if (props.color.name && !names.includes(props.color.name)) names.unshift(props.color.name)
  return [{ value: '', label: 'Odaberi boju' }, ...names.map((name) => ({ value: name, label: name }))]
})

function onColorChange(name: string) {
  props.color.name = name
  const known = PRODUCT_COLORS.find((item) => item.name === name)
  if (known) props.color.hex = known.hex
}

// Količine koje još nisu upisane računaju se kao 0.
const stock = computed(() =>
  props.sizes.reduce((sum, size) => sum + Number(props.color.quantities[size] || 0), 0),
)
</script>

<template>
  <section class="overflow-hidden rounded-xl border border-primary-300 bg-white shadow-sm">
    <header class="flex flex-wrap items-center justify-between gap-2 border-b border-primary-300 bg-primary-100 px-4 py-2">
      <div class="flex min-w-0 items-center gap-2">
        <ColorSwatch v-if="color.name" class="size-4" :name="color.name" :hex="color.hex" />
        <h3 class="truncate text-sm font-semibold text-primary-900">{{ color.name || 'Nova boja' }}</h3>
        <span class="whitespace-nowrap text-xs text-stone-600">{{ stock }} kom</span>
      </div>
      <div class="-mr-2 flex items-center">
        <IconButton label="Pomakni boju gore" :disabled="isFirst" @click="emit('move', -1)">
          <ChevronUp class="size-4" stroke-width="1.75" />
        </IconButton>
        <IconButton label="Pomakni boju dolje" :disabled="isLast" @click="emit('move', 1)">
          <ChevronDown class="size-4" stroke-width="1.75" />
        </IconButton>
        <IconButton :label="`Ukloni boju ${color.name}`" danger @click="emit('remove')">
          <Trash2 class="size-4" stroke-width="1.75" />
        </IconButton>
      </div>
    </header>

    <div class="space-y-5 p-4 sm:p-5">
      <BaseSelect
        :model-value="color.name"
        label="Boja"
        :options="colorOptions"
        required
        @update:model-value="onColorChange"
      />

      <div class="rounded-lg border border-primary-300 bg-primary-50 p-3 sm:p-4">
        <p class="text-sm font-semibold text-primary-900">Količina po veličini</p>
        <p v-if="!sizes.length" class="mt-1 text-sm text-stone-600">Odaberi veličine iznad i ovdje će se pojaviti polje za svaku od njih.</p>
        <template v-else>
          <p class="mt-0.5 text-xs text-stone-600">Upiši broj komada za svaku veličinu u ovoj boji, npr. S: 5, M: 4.</p>
          <div class="mt-3 grid grid-cols-3 gap-3 sm:grid-cols-5 lg:grid-cols-6">
            <BaseInput
              v-for="size in sizes"
              :key="size"
              v-model="color.quantities[size]"
              :label="size"
              type="number"
              inputmode="numeric"
              :min="0"
              step="1"
              placeholder="0"
            />
          </div>
        </template>
      </div>

      <ProductImagesField :color="color" :api="api" />

      <ProductSlugField :color="color" :generated="generatedSlug" />
    </div>
  </section>
</template>
