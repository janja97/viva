<script setup lang="ts">
import { STOCK_GROUP_SLUGS } from '~/config/products'
import type { StockBySizeRow } from '~/types/database'

// "Zaliha po veličinama": koliko komada ima na stanju po veličini, za svaku skupinu i njezine podkategorije.
const { fetchStockBySize } = useDashboard()
const { categories, load: loadCategories } = useCategories()

const rows = ref<StockBySizeRow[]>([])
const isLoading = ref(true)
const loadError = ref('')
// Dodatna kategorija iz izbornika, uz zadane skupine.
const extraCategoryId = ref('')

async function load() {
  isLoading.value = true
  loadError.value = ''
  try {
    const [stock] = await Promise.all([fetchStockBySize(), loadCategories()])
    rows.value = stock
  } catch (error) {
    loadError.value = productErrorMessage(error)
  } finally {
    isLoading.value = false
  }
}

onMounted(load)

function groupFor(categoryId: string) {
  const category = categories.value.find((item) => item.id === categoryId)
  if (!category) return null
  const ids = new Set([category.id, ...descendantIds(categories.value, category.id)])
  const totals = new Map<string, number>()
  for (const row of rows.value) {
    if (ids.has(row.category_id)) totals.set(row.size, (totals.get(row.size) ?? 0) + Number(row.quantity))
  }
  const sizes = sortSizes([...totals.keys()]).map((size) => ({ size, quantity: totals.get(size)! }))
  return { id: category.id, name: category.name, sizes, total: sizes.reduce((sum, item) => sum + item.quantity, 0) }
}

const groups = computed(() => {
  const ids = STOCK_GROUP_SLUGS
    .map((slug) => categories.value.find((category) => category.slug === slug)?.id)
    .filter((id): id is string => Boolean(id))
  if (extraCategoryId.value && !ids.includes(extraCategoryId.value)) ids.push(extraCategoryId.value)
  return ids.map(groupFor).filter((group) => group !== null)
})

const categorySelectOptions = computed(() => [{ value: '', label: 'Odaberi kategoriju' }, ...categoryOptions(categories.value)])

// Nula je crvena, a jedan ili dva komada žuti, isto kao na popisu "Malo zalihe".
const cellClass = (quantity: number) => (quantity === 0
  ? 'border-red-200 bg-red-50 text-red-800'
  : quantity <= 2 ? 'border-amber-200 bg-amber-50 text-amber-900' : 'border-primary-300 bg-white text-stone-900')
</script>

<template>
  <AdminCard title="Zaliha po veličinama">
    <p v-if="isLoading" class="text-sm text-stone-500">Učitavanje...</p>
    <div v-else-if="loadError" class="space-y-3">
      <BaseAlert type="error">{{ loadError }}</BaseAlert>
      <BaseButton variant="secondary" @click="load">Pokušaj ponovno</BaseButton>
    </div>
    <div v-else class="space-y-6">
      <p class="text-xs text-stone-500">Komadi na stanju, zbrojeni za sve boje. Skupina uključuje i svoje podkategorije. Arhivirani proizvodi se ne broje.</p>

      <section v-for="group in groups" :key="group.id" :aria-labelledby="`zaliha-${group.id}`">
        <h3 :id="`zaliha-${group.id}`" class="mb-2 flex items-baseline justify-between gap-3 text-sm">
          <span class="font-medium text-stone-900">{{ group.name }}</span>
          <span class="tabular-nums text-stone-500">ukupno {{ group.total }} kom</span>
        </h3>
        <p v-if="!group.sizes.length" class="text-sm text-stone-500">Nema proizvoda u ovoj skupini.</p>
        <ul v-else class="grid grid-cols-4 gap-1.5 sm:grid-cols-6 lg:grid-cols-8">
          <li
            v-for="item in group.sizes"
            :key="item.size"
            class="flex flex-col items-center border px-1 py-1.5 text-center"
            :class="cellClass(item.quantity)"
            :title="`${group.name}, veličina ${item.size}: ${item.quantity} kom`"
          >
            <span class="max-w-full truncate text-xs opacity-75">{{ item.size }}</span>
            <span class="font-display text-xl leading-tight tabular-nums">{{ item.quantity }}</span>
          </li>
        </ul>
      </section>

      <BaseSelect v-model="extraCategoryId" class="max-w-sm" label="Pogledaj drugu kategoriju" :options="categorySelectOptions" />
    </div>
  </AdminCard>
</template>
