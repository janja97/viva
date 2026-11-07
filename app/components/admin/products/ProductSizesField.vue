<script setup lang="ts">
import { Plus } from '@lucide/vue'
import { SIZE_PRESETS, SIZE_TYPES } from '~/config/products'
import type { ProductForm } from '~/types/productForm'
import type { SizeType } from '~/types/database'

const props = defineProps<{
  form: ProductForm
  // Vrsta koju je odredila kategorija, samo za opis ispod izbornika.
  categorySizeType?: SizeType | null
}>()

const customSize = ref('')

const sizeOptions = computed(() => {
  const preset = SIZE_PRESETS[props.form.size_type]
  return [...preset, ...props.form.sizes.filter((size) => !preset.includes(size))]
})

function onTypeChange(type: string) {
  applySizeType(props.form, type as SizeType)
}

const typeHint = computed(() => props.categorySizeType
  ? 'Postavljeno prema kategoriji. Promjena vrste briše odabrane veličine.'
  : 'Promjena vrste briše odabrane veličine.')

function sortSizes(sizes: string[]) {
  return sizeOptions.value.filter((size) => sizes.includes(size))
}

function toggle(size: string) {
  const { sizes } = props.form
  props.form.sizes = sortSizes(sizes.includes(size) ? sizes.filter((item) => item !== size) : [...sizes, size])
}

function addCustom() {
  const size = customSize.value.trim()
  if (size && !props.form.sizes.includes(size)) props.form.sizes = [...props.form.sizes, size]
  customSize.value = ''
}
</script>

<template>
  <div class="space-y-4">
    <p class="text-sm text-stone-600">Odaberi koje veličine proizvod ima. Količinu za svaku veličinu upisuješ ispod, posebno za svaku boju.</p>
    <BaseSelect
      :model-value="form.size_type"
      label="Vrsta veličina"
      :options="SIZE_TYPES"
      :hint="typeHint"
      @update:model-value="onTypeChange"
    />

    <div v-if="form.size_type !== 'universal'" class="space-y-3">
      <div class="flex flex-wrap gap-2">
        <button
          v-for="size in sizeOptions"
          :key="size"
          type="button"
          :aria-pressed="form.sizes.includes(size)"
          class="min-h-11 min-w-11 rounded-lg border px-3 text-sm font-medium transition-colors disabled:cursor-not-allowed sm:min-h-9 sm:min-w-9"
          :class="form.sizes.includes(size)
            ? 'border-primary-600 bg-primary-600 text-white'
            : 'border-primary-300 bg-white text-stone-700 hover:border-primary-500'"
          @click="toggle(size)"
        >
          {{ size }}
        </button>
      </div>

      <div class="flex items-start gap-2">
        <BaseInput
          v-model="customSize"
          class="min-w-0 flex-1"
          label="Druga veličina"
          :maxlength="20"
          hint="Npr. 38/40 ili 110 cm."
          @keydown.enter.prevent="addCustom"
        />
        <BaseButton class="mt-6.5" variant="secondary" @click="addCustom">
          <Plus class="size-4" stroke-width="2" />
          Dodaj
        </BaseButton>
      </div>
    </div>
  </div>
</template>
