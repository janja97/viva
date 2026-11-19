<script setup lang="ts">
import { Smartphone, UserRound, Users } from '@lucide/vue'
import type { AnalyticsPeriod } from '~/composables/useDashboard'
import type { VisitAnalytics, VisitMedium } from '~/types/database'

// Kartica "Posjete" (migracija 0046): odakle kupci dolaze, iz koje države i grada, s kojeg uređaja i kamo prvo dođu.
// Jedan dolazak je jedna posjeta preglednika (ponovni ulaz unutar 30 minuta je isti dolazak). Članovi tima nisu u brojkama.
const { fetchVisits } = useDashboard()

const period = ref<AnalyticsPeriod>(DEFAULT_ANALYTICS_PERIOD)
const data = ref<VisitAnalytics | null>(null)
const isLoading = ref(false)
const loadError = ref('')

async function load() {
  isLoading.value = true
  loadError.value = ''
  try {
    data.value = await fetchVisits(period.value)
  } catch (error) {
    loadError.value = productErrorMessage(error)
  } finally {
    isLoading.value = false
  }
}

watch(period, load)
onMounted(load)

const MEDIUMS: Record<VisitMedium, string> = {
  organic: 'Google i tražilice',
  social: 'Društvene mreže',
  paid: 'Oglasi',
  email: 'E-mail',
  referral: 'Druge stranice',
  direct: 'Izravno (upisana adresa, spremljena poveznica)',
}
const DEVICES = { mobile: 'Mobitel', tablet: 'Tablet', desktop: 'Računalo' } as const
const SOURCES: Record<string, string> = { izravno: 'Izravno', google: 'Google', instagram: 'Instagram', facebook: 'Facebook', whatsapp: 'WhatsApp', viber: 'Viber', tiktok: 'TikTok', youtube: 'YouTube', pinterest: 'Pinterest', bing: 'Bing' }

const regionNames = (() => {
  try {
    return new Intl.DisplayNames(['hr'], { type: 'region' })
  } catch {
    return null
  }
})()
const countryName = (code: string | null) => (code ? (regionNames?.of(code) ?? code) : 'Nepoznato')

const lists = computed(() => {
  const value = data.value
  if (!value) return null
  return {
    mediums: value.mediums.map((row) => ({ label: MEDIUMS[row.name] ?? row.name, visits: row.visits })),
    sources: value.sources.map((row) => ({ label: SOURCES[row.name] ?? row.name, hint: MEDIUMS[row.medium]?.split(' (')[0], visits: row.visits })),
    countries: value.countries.map((row) => ({ label: countryName(row.name), visits: row.visits })),
    cities: value.cities.map((row) => ({ label: row.name, hint: countryName(row.country), visits: row.visits })),
    devices: value.devices.map((row) => ({ label: DEVICES[row.name] ?? row.name, visits: row.visits })),
    landings: value.landings.map((row) => ({ label: row.name, visits: row.visits })),
    campaigns: value.campaigns.map((row) => ({ label: row.name, hint: row.source, visits: row.visits })),
  }
})

const points = computed(() => (data.value?.series ?? []).map((row) => ({ bucket: row.bucket, value: Number(row.visits) })))
const mobileShare = computed(() => {
  const totals = data.value?.totals
  return totals?.visits ? `${Math.round((totals.mobile / totals.visits) * 100)} %` : '–'
})
</script>

<template>
  <div class="space-y-4">
    <PeriodPicker v-model="period" />

    <p class="text-xs text-stone-500">
      Jedan dolazak je jedna posjeta preglednika; ponovni ulaz unutar 30 minuta broji se jednom. Država i grad procjenjuju se iz IP adrese
      (lokalno i prije objave na Netlifyju ih nema), a IP se ne sprema. Članovi tima nisu u brojkama.
    </p>

    <p v-if="!data && !loadError" class="text-sm text-stone-500">Učitavanje...</p>
    <div v-else-if="loadError" class="space-y-3">
      <BaseAlert type="error">{{ loadError }}</BaseAlert>
      <BaseButton variant="secondary" @click="load">Pokušaj ponovno</BaseButton>
    </div>

    <template v-else-if="data && lists">
      <div class="grid grid-cols-2 gap-2 sm:grid-cols-3 sm:gap-4" :class="isLoading && 'opacity-60'">
        <AdminCard v-for="item in [
          { label: 'Dolazaka', value: data.totals.visits, icon: Users },
          { label: 'Različitih posjetitelja', value: data.totals.visitors, icon: UserRound },
          { label: 'S mobitela', value: mobileShare, icon: Smartphone },
        ]" :key="item.label" :title="String(item.value)">
          <p class="-mt-2 flex items-center gap-1.5 text-xs text-stone-500 sm:text-sm">
            <component :is="item.icon" class="size-4 shrink-0" stroke-width="1.75" />
            {{ item.label }}
          </p>
        </AdminCard>
      </div>

      <AdminCard title="Dolasci kroz vrijeme" :class="isLoading && 'opacity-60'">
        <TrendChart :points="points" :bucket="data.bucket" label="Dolazaka" format="count" />
      </AdminCard>

      <div class="grid gap-4 lg:grid-cols-2" :class="isLoading && 'opacity-60'">
        <VisitRankList title="Vrsta izvora" :rows="lists.mediums" />
        <VisitRankList title="Izvori" :rows="lists.sources" />
        <VisitRankList title="Države" :rows="lists.countries" />
        <VisitRankList title="Gradovi" :rows="lists.cities" empty-text="Gradovi se vide tek na objavljenom webu (Netlify)." />
        <VisitRankList title="Uređaji" :rows="lists.devices" />
        <VisitRankList title="Prva stranica" :rows="lists.landings" />
        <VisitRankList
          title="Kampanje (utm_campaign)"
          :rows="lists.campaigns"
          empty-text="Nema dolazaka s oznakom kampanje. Dodaj ?utm_source=instagram&utm_campaign=matura na poveznicu u objavi ili oglasu."
        />
      </div>

      <p v-if="data.totals.team" class="text-xs text-stone-500">Dolasci članova tima u razdoblju (nisu u brojkama): {{ data.totals.team }}</p>
    </template>
  </div>
</template>
