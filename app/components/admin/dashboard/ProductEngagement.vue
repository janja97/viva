<script setup lang="ts">
import { Eye, MessageCircle } from '@lucide/vue'
import type { AnalyticsPeriod } from '~/composables/useDashboard'
import type { ProductEngagement } from '~/types/database'

// Kartica "Pregledi": što se najviše gleda i naručuje preko WhatsAppa (migracije 0041 i 0043).
// Bira se razdoblje i glavna kategorija (Haljine, Obuća...), s podkategorijama.
const { fetchEngagement } = useDashboard()
const { categories, load: loadCategories } = useCategories()

const period = ref<AnalyticsPeriod>(DEFAULT_ANALYTICS_PERIOD)
const categoryId = ref('')
const data = ref<ProductEngagement | null>(null)
const isLoading = ref(false)
const loadError = ref('')

const mainCategories = computed(() => categories.value.filter((category) => !category.parent_id).sort((a, b) => a.sort_order - b.sort_order))
const categoryIds = computed(() => (categoryId.value ? [categoryId.value, ...descendantIds(categories.value, categoryId.value)] : null))

async function load() {
  isLoading.value = true
  loadError.value = ''
  try {
    data.value = await fetchEngagement(period.value, categoryIds.value)
  } catch (error) {
    loadError.value = productErrorMessage(error)
  } finally {
    isLoading.value = false
  }
}

// Udio pregleda koji završe WhatsApp narudžbom.
const rate = (part: number, whole: number) => (whole ? `${Math.round((part / whole) * 100)} %` : '–')
const maxViews = computed(() => Math.max(1, ...(data.value?.products ?? []).map((row) => Number(row.views))))

watch([period, categoryId], load)
onMounted(async () => {
  await loadCategories()
  load()
})

const chipClass = (active: boolean) => [
  'min-h-11 shrink-0 cursor-pointer border px-3.5 text-sm font-medium transition-colors sm:min-h-9',
  active ? 'border-primary-950 bg-primary-950 text-white' : 'border-primary-300 bg-white text-stone-700 hover:bg-primary-50',
]
</script>

<template>
  <div class="space-y-4">
    <PeriodPicker v-model="period" />
    <div class="flex gap-2 overflow-x-auto [scrollbar-width:none]" role="group" aria-label="Glavna kategorija">
      <button type="button" :class="chipClass(!categoryId)" :aria-pressed="!categoryId" @click="categoryId = ''">Sve</button>
      <button v-for="category in mainCategories" :key="category.id" type="button" :class="chipClass(categoryId === category.id)" :aria-pressed="categoryId === category.id" @click="categoryId = category.id">
        {{ category.name }}
      </button>
    </div>

    <p class="text-xs text-stone-500">
      Pregled se broji svaki put kad netko otvori stranicu proizvoda (osvježavanje unutar 10 sekundi broji se jednom), i kad je to član tima.
      WhatsApp znači da je kupac otvorio WhatsApp s narudžbom, ne nužno i poslao poruku.
    </p>

    <p v-if="!data && !loadError" class="text-sm text-stone-500">Učitavanje...</p>
    <div v-else-if="loadError" class="space-y-3">
      <BaseAlert type="error">{{ loadError }}</BaseAlert>
      <BaseButton variant="secondary" @click="load">Pokušaj ponovno</BaseButton>
    </div>

    <template v-else-if="data">
      <div class="grid grid-cols-2 gap-2 sm:gap-4" :class="isLoading && 'opacity-60'">
        <AdminCard v-for="item in [
          { label: 'Pregleda', value: data.totals.views, icon: Eye },
          { label: 'WhatsApp', value: data.totals.whatsapp_orders, icon: MessageCircle },
        ]" :key="item.label" :title="String(item.value)">
          <p class="-mt-2 flex items-center gap-1.5 text-xs text-stone-500 sm:text-sm">
            <component :is="item.icon" class="size-4 shrink-0" stroke-width="1.75" />
            {{ item.label }}
          </p>
        </AdminCard>
      </div>

      <AdminCard v-if="!categoryId && data.categories.length" title="Po kategoriji" :class="isLoading && 'opacity-60'">
        <div class="overflow-x-auto">
          <table class="w-full text-left text-sm">
            <thead class="border-b border-primary-300 text-xs text-stone-500">
              <tr>
                <th class="py-1.5 pr-3 font-medium">Kategorija</th>
                <th class="py-1.5 pr-3 text-right font-medium">Pregleda</th>
                <th class="py-1.5 text-right font-medium">WhatsApp</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-primary-200 tabular-nums">
              <tr v-for="row in data.categories" :key="row.name">
                <td class="py-2 pr-3">{{ row.name }}</td>
                <td class="py-2 pr-3 text-right">{{ row.views }}</td>
                <td class="py-2 text-right">{{ row.whatsapp_orders }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </AdminCard>

      <AdminCard title="Najgledaniji proizvodi" :class="isLoading && 'opacity-60'">
        <p v-if="!data.products.length" class="text-sm text-stone-500">U ovom razdoblju još nema pregleda.</p>
        <ol v-else class="space-y-3">
          <li v-for="(row, index) in data.products" :key="`${row.product_id}-${row.slug}`">
            <div class="flex items-baseline justify-between gap-3 text-sm">
              <NuxtLink :to="`/admin/proizvodi/${row.product_id}`" class="min-w-0 truncate hover:underline">
                <span class="mr-1.5 text-stone-400">{{ index + 1 }}.</span>
                <span class="text-stone-900">{{ row.name }}</span>
                <span class="ml-1.5 text-xs text-stone-500">{{ row.sku }}</span>
              </NuxtLink>
              <p class="shrink-0 tabular-nums text-stone-700" :title="`${row.whatsapp_orders} preko WhatsAppa (${rate(row.whatsapp_orders, row.views)} pregleda)`">
                {{ row.views }} <span class="text-stone-500">· {{ row.whatsapp_orders }}</span>
              </p>
            </div>
            <div class="mt-1 h-1.5 bg-primary-100">
              <div class="h-full bg-primary-600" :style="{ width: `${(Number(row.views) / maxViews) * 100}%` }" />
            </div>
          </li>
        </ol>
        <p v-if="data.products.length" class="mt-4 text-xs text-stone-500">Brojevi: pregleda · WhatsApp narudžbi.</p>
      </AdminCard>
    </template>
  </div>
</template>
