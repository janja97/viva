<script setup lang="ts">
import { Minus, Plus } from '@lucide/vue'

const props = defineProps<{
  product: { id: string; sku: string; name: string } | null
}>()
const emit = defineEmits<{ close: []; saved: [] }>()

const { fetchStock, adjustStock } = useProducts()

type StockColor = {
  id: string
  name: string
  hex: string
  sizes: { id: string; size: string; original: number; value: number | '' }[]
}

const colors = ref<StockColor[]>([])
const isLoading = ref(false)
const isSaving = ref(false)
const error = ref('')

const isValid = (value: number | '') => Number.isInteger(value) && Number(value) >= 0

const allSizes = computed(() => colors.value.flatMap((color) => color.sizes))
const canSave = computed(() => allSizes.value.every((size) => isValid(size.value)))
const changes = computed(() => allSizes.value
  .filter((size) => isValid(size.value) && size.value !== size.original)
  .map((size) => ({ size_id: size.id, delta: Number(size.value) - size.original })))

watch(() => props.product, async (product) => {
  colors.value = []
  error.value = ''
  if (!product) return
  isLoading.value = true
  try {
    const stock = await fetchStock(product.id)
    colors.value = stock.map((color) => ({
      ...color,
      sizes: color.sizes.map(({ id, size, quantity }) => ({ id, size, original: quantity, value: quantity })),
    }))
  } catch (loadError) {
    error.value = productErrorMessage(loadError)
  } finally {
    isLoading.value = false
  }
})

function change(size: StockColor['sizes'][number], step: number) {
  size.value = Math.max(0, Number(size.value) + step)
}

const signed = (delta: number) => (delta > 0 ? `+${delta}` : String(delta))

async function save() {
  if (!props.product || !canSave.value || !changes.value.length) return
  isSaving.value = true
  error.value = ''
  try {
    await adjustStock(props.product.id, changes.value)
    emit('saved')
  } catch (saveError) {
    error.value = productErrorMessage(saveError)
  } finally {
    isSaving.value = false
  }
}
</script>

<template>
  <BaseModal :open="Boolean(product)" title="Količine" @close="emit('close')">
    <form v-if="product" class="space-y-5" @submit.prevent="save">
      <p class="text-sm text-stone-500">{{ product.name }} · {{ product.sku }}</p>

      <p v-if="isLoading" class="text-sm text-stone-500">Učitavanje...</p>
      <p v-else-if="!error && !allSizes.length" class="text-sm text-stone-500">Ovaj proizvod još nema boje ni veličine.</p>

      <section v-for="color in colors" :key="color.id">
        <h3 class="flex items-center gap-2 text-sm font-medium">
          <ColorSwatch class="size-3.5" :name="color.name" :hex="color.hex" />
          {{ color.name }}
        </h3>
        <ul class="mt-2 divide-y divide-primary-200 border-y border-primary-200">
          <li v-for="size in color.sizes" :key="size.id" class="flex items-center gap-2 py-1.5">
            <span class="min-w-10 text-sm font-medium">{{ size.size }}</span>
            <span class="min-w-8 flex-1 text-xs font-medium" :class="Number(size.value) > size.original ? 'text-emerald-700' : 'text-red-700'">
              <template v-if="isValid(size.value) && size.value !== size.original">{{ signed(Number(size.value) - size.original) }}</template>
            </span>
            <IconButton :label="`Smanji: ${color.name} ${size.size}`" :disabled="Number(size.value) <= 0" @click="change(size, -1)">
              <Minus class="size-4" stroke-width="1.75" />
            </IconButton>
            <input
              v-model.number="size.value"
              type="number"
              inputmode="numeric"
              min="0"
              step="1"
              :aria-label="`Količina: ${color.name} ${size.size}`"
              class="form-field w-20! text-center"
            >
            <IconButton :label="`Povećaj: ${color.name} ${size.size}`" @click="change(size, 1)">
              <Plus class="size-4" stroke-width="1.75" />
            </IconButton>
          </li>
        </ul>
      </section>

      <BaseAlert v-if="error" type="error">{{ error }}</BaseAlert>
      <p v-if="!canSave" class="text-sm text-red-700">Količina mora biti cijeli broj, 0 ili veći.</p>

      <div class="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
        <BaseButton variant="secondary" @click="emit('close')">Odustani</BaseButton>
        <BaseButton type="submit" :loading="isSaving || !canSave || !changes.length">Spremi</BaseButton>
      </div>
    </form>
  </BaseModal>
</template>
