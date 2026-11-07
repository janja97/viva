<script setup lang="ts">
import { Ban, Inbox, Percent, Receipt, ShoppingBag, Wallet } from '@lucide/vue'
import { INQUIRY_STATUSES } from '~/composables/useInquiries'
import type { SalesAnalytics } from '~/types/database'

// Kartica "Prodaja": brojevi za ovaj mjesec, a ispod tablica ili graf s vlastitim izborom razdoblja.
// newCount su sve narudžbe sa statusom Novo, kao u crvenom oblačiću, bez obzira na mjesec.
const props = defineProps<{ data: SalesAnalytics; newCount: number }>()

// Promjena prema jednako dugom razdoblju prije (isti broj dana prije 1. u mjesecu).
function delta(current: number, previous: number) {
  if (!previous) return null
  return Math.round(((current - previous) / previous) * 100)
}

const inquiryCount = computed(() => Object.values(props.data.statuses).reduce((sum, count) => sum + Number(count), 0))

// Npr. "1 novo · 1 u obradi · 1 prodano", da se pristigli upiti ne pomiješaju sa statusom Novo.
const statusBreakdown = computed(() => INQUIRY_STATUSES
  .filter(({ value }) => Number(props.data.statuses[value] ?? 0) > 0)
  .map(({ value, label }) => `${props.data.statuses[value]} ${label.toLowerCase()}`)
  .join(' · ') || 'nema upita')
const cancelRate = computed(() => (inquiryCount.value ? Math.round((Number(props.data.statuses.cancelled ?? 0) / inquiryCount.value) * 100) : 0))
const totalDiscount = computed(() => Number(props.data.kpi.promo_discount) + Number(props.data.kpi.sale_savings))
const monthName = new Intl.DateTimeFormat('hr-HR', { month: 'long', year: 'numeric' }).format(new Date())
</script>

<template>
  <div class="space-y-4">
    <h3 class="font-display text-2xl font-normal leading-tight">Ovaj mjesec <span class="text-base text-stone-500">({{ monthName }})</span></h3>
    <div class="grid grid-cols-2 gap-3 sm:gap-4 xl:grid-cols-3">
      <StatCard
        label="Prihod"
        :value="formatPrice(Number(data.kpi.revenue))"
        :icon="Wallet"
        :delta="delta(Number(data.kpi.revenue), Number(data.previous.revenue))"
        :hint="`Od toga poštarina ${formatPrice(Number(data.kpi.shipping))}`"
      />
      <StatCard
        label="Novi upiti"
        :value="String(newCount)"
        :icon="Inbox"
        :to="newCount ? '/admin/narudzbe?status=new' : undefined"
        :hint="`Čekaju obradu (status Novo). Ovaj mjesec stiglo ukupno ${inquiryCount}: ${statusBreakdown}`"
      />
      <StatCard
        label="Prodane narudžbe"
        :value="String(data.kpi.orders)"
        :icon="ShoppingBag"
        :delta="delta(Number(data.kpi.orders), Number(data.previous.orders))"
        :hint="`Prodanih komada: ${data.kpi.items}`"
      />
      <StatCard label="Prosječna narudžba" :value="formatPrice(Number(data.kpi.average_order))" :icon="Receipt" />
      <StatCard label="Otkazano" :value="`${cancelRate} %`" :icon="Ban" :hint="`${data.statuses.cancelled ?? 0} od ${inquiryCount} upita`" />
      <StatCard
        label="Dani popusti"
        :value="formatPrice(totalDiscount)"
        :icon="Percent"
        :hint="`Kampanje ${formatPrice(Number(data.kpi.sale_savings))}, promo kodovi ${formatPrice(Number(data.kpi.promo_discount))}`"
      />
    </div>

    <SalesPeriodCard />
  </div>
</template>
