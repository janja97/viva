<script setup lang="ts">
import { DEFAULT_ANALYTICS_PERIOD, tableBucket, type AnalyticsPeriod } from '~/composables/useDashboard'
import type { SalesAnalytics } from '~/types/database'

// "Po razdobljima": tablica ili graf s vlastitim izborom razdoblja. Ne mijenja kartice s brojevima iznad.
type View = 'table' | 'chart'
type Metric = 'revenue' | 'inquiries' | 'orders'

const METRICS: { value: Metric; label: string; format: 'money' | 'count' }[] = [
  { value: 'revenue', label: 'Prihod', format: 'money' },
  { value: 'inquiries', label: 'Pristigli upiti', format: 'count' },
  { value: 'orders', label: 'Prodane narudžbe', format: 'count' },
]

const { fetchAnalytics } = useDashboard()
const period = ref<AnalyticsPeriod>(DEFAULT_ANALYTICS_PERIOD)
const view = ref<View>('table')
const metric = ref<Metric>('revenue')
const data = ref<SalesAnalytics | null>(null)
const isLoading = ref(true)
const loadError = ref('')

// Tablica je po mjesecima (osim za ovaj mjesec), a graf ima gušće točke, npr. tjedne za 3 mjeseca.
async function load() {
  isLoading.value = true
  loadError.value = ''
  try {
    data.value = await fetchAnalytics(period.value, view.value === 'table' ? tableBucket(period.value) : undefined)
  } catch (error) {
    loadError.value = productErrorMessage(error)
  } finally {
    isLoading.value = false
  }
}

watch([period, view], load)
onMounted(load)

const activeMetric = computed(() => METRICS.find((item) => item.value === metric.value)!)
const points = computed(() => (data.value?.trend ?? []).map((row) => ({ bucket: row.bucket, value: Number(row[metric.value]) })))

const toggleClass = (isActive: boolean) => [
  'min-h-11 shrink-0 cursor-pointer px-3.5 text-sm font-medium transition-colors sm:min-h-9',
  isActive ? 'bg-primary-600 text-white' : 'text-stone-600 hover:bg-primary-50',
]
</script>

<template>
  <section class="border border-primary-300 bg-white p-5 sm:p-6" aria-labelledby="naslov-po-razdobljima">
    <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
      <h3 id="naslov-po-razdobljima" class="font-display text-2xl font-normal leading-tight">Po razdobljima</h3>
      <div class="flex border border-primary-300" role="group" aria-label="Prikaz">
        <button type="button" :aria-pressed="view === 'table'" :class="toggleClass(view === 'table')" @click="view = 'table'">Tablica</button>
        <button type="button" :aria-pressed="view === 'chart'" :class="toggleClass(view === 'chart')" @click="view = 'chart'">Graf</button>
      </div>
    </div>

    <div class="mb-4 flex flex-col gap-2 lg:flex-row lg:items-center lg:justify-between">
      <PeriodPicker v-model="period" />
      <!-- Jedan graf, jedna mjera: prihod i broj upita imaju različite jedinice. -->
      <div v-if="view === 'chart'" class="flex overflow-x-auto border border-primary-300 [scrollbar-width:none] sm:w-fit" role="group" aria-label="Mjera">
        <button
          v-for="item in METRICS"
          :key="item.value"
          type="button"
          :aria-pressed="metric === item.value"
          :class="toggleClass(metric === item.value)"
          @click="metric = item.value"
        >
          {{ item.label }}
        </button>
      </div>
    </div>

    <p v-if="isLoading && !data" class="text-sm text-stone-500">Učitavanje...</p>
    <div v-else-if="loadError" class="space-y-3">
      <BaseAlert type="error">{{ loadError }}</BaseAlert>
      <BaseButton variant="secondary" @click="load">Pokušaj ponovno</BaseButton>
    </div>
    <div v-else-if="data" :class="isLoading && 'opacity-60'">
      <SalesPeriodTable v-if="view === 'table'" :data="data" />
      <TrendChart v-else :points="points" :bucket="data.bucket" :label="activeMetric.label" :format="activeMetric.format" />
    </div>
  </section>
</template>
