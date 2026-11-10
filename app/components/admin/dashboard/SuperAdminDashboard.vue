<script setup lang="ts">
import { DEFAULT_ANALYTICS_PERIOD, type AnalyticsPeriod } from '~/composables/useDashboard'
import type { DashboardBasic as DashboardBasicData, SalesAnalytics } from '~/types/database'

// Nadzorna ploča super admina po karticama. Odabrana kartica je u adresi (?kartica=statistika).
// Prodaja: brojevi za ovaj mjesec, a razdoblje se bira samo za tablicu i graf (SalesPeriodCard).
// Statistika ima vlastiti izbor razdoblja.
defineProps<{ basic: DashboardBasicData | null }>()

type Tab = 'prodaja' | 'statistika' | 'zalihe'
const TABS: { value: Tab; label: string }[] = [
  { value: 'prodaja', label: 'Prodaja' },
  { value: 'statistika', label: 'Statistika' },
  { value: 'zalihe', label: 'Zalihe' },
]

const route = useRoute()
const tab = computed<Tab>(() => TABS.find((item) => item.value === route.query.kartica)?.value ?? 'prodaja')
const showTab = (value: Tab) => navigateTo({ query: { ...route.query, kartica: value === 'prodaja' ? undefined : value } }, { replace: true })

const { fetchAnalytics } = useDashboard()

function useAnalytics(period: () => AnalyticsPeriod) {
  const data = ref<SalesAnalytics | null>(null)
  const isLoading = ref(false)
  const loadError = ref('')

  async function load() {
    isLoading.value = true
    loadError.value = ''
    try {
      data.value = await fetchAnalytics(period())
    } catch (error) {
      loadError.value = productErrorMessage(error)
    } finally {
      isLoading.value = false
    }
  }

  return { data, isLoading, loadError, load }
}

const month = useAnalytics(() => 'month')
const statsPeriod = ref<AnalyticsPeriod>(DEFAULT_ANALYTICS_PERIOD)
const stats = useAnalytics(() => statsPeriod.value)

// Svaka kartica učitava podatke tek kad se prvi put otvori.
watch(tab, (value) => {
  if (value === 'prodaja' && !month.data.value) month.load()
  if (value === 'statistika' && !stats.data.value) stats.load()
}, { immediate: true })
watch(statsPeriod, () => stats.load())
</script>

<template>
  <div>
    <div class="mb-5 flex overflow-x-auto border-b border-primary-300 [scrollbar-width:none]" role="tablist" aria-label="Nadzorna ploča">
      <button
        v-for="item in TABS"
        :key="item.value"
        type="button"
        role="tab"
        :aria-selected="tab === item.value"
        class="-mb-px min-h-11 shrink-0 cursor-pointer border-b-2 px-4 text-sm font-medium transition-colors sm:min-h-10"
        :class="tab === item.value ? 'border-primary-700 text-stone-900' : 'border-transparent text-stone-500 hover:text-stone-800'"
        @click="showTab(item.value)"
      >
        {{ item.label }}
      </button>
    </div>

    <template v-if="tab === 'zalihe'">
      <p v-if="!basic" class="text-sm text-stone-500">Učitavanje...</p>
      <DashboardBasic v-else :data="basic" />
    </template>

    <template v-else>
      <p class="mb-4 text-xs text-stone-500">Prihod i prodaja računaju se iz narudžbi sa statusom Prodano, a pristigli upiti su sve narudžbe koje su stigle, u bilo kojem statusu. Gleda se datum narudžbe.</p>

      <template v-if="tab === 'prodaja'">
        <p v-if="!month.data.value && !month.loadError.value" class="text-sm text-stone-500">Učitavanje...</p>
        <div v-else-if="month.loadError.value" class="space-y-3">
          <BaseAlert type="error">{{ month.loadError.value }}</BaseAlert>
          <BaseButton variant="secondary" @click="month.load">Pokušaj ponovno</BaseButton>
        </div>
        <SalesOverview v-else-if="month.data.value" :data="month.data.value" :basic="basic" />
      </template>

      <template v-else>
        <PeriodPicker v-model="statsPeriod" class="mb-4" />
        <p v-if="!stats.data.value && !stats.loadError.value" class="text-sm text-stone-500">Učitavanje...</p>
        <div v-else-if="stats.loadError.value" class="space-y-3">
          <BaseAlert type="error">{{ stats.loadError.value }}</BaseAlert>
          <BaseButton variant="secondary" @click="stats.load">Pokušaj ponovno</BaseButton>
        </div>
        <SalesStatistics v-else-if="stats.data.value" :class="stats.isLoading.value && 'opacity-60'" :data="stats.data.value" />
      </template>
    </template>
  </div>
</template>
