<script setup lang="ts">
import { Ban, Eye, EyeOff, Inbox, Mail } from '@lucide/vue'
import type { DashboardBasic as DashboardBasicData, SalesAnalytics } from '~/types/database'

// Kartica "Prodaja": nekoliko jednostavnih brojeva, a ispod tablica ili graf s vlastitim izborom razdoblja.
// Novi upiti su sve narudžbe sa statusom Novo (kao crveni oblačić), a ukupno i otkazano su za ovaj mjesec.
// Proizvodi su trenutno stanje, bez arhiviranih.
const props = defineProps<{ data: SalesAnalytics; basic: DashboardBasicData | null }>()

const inquiryCount = computed(() => Object.values(props.data.statuses).reduce((sum, count) => sum + Number(count), 0))
const cancelledCount = computed(() => Number(props.data.statuses.cancelled ?? 0))
const newCount = computed(() => props.basic?.orders.new ?? 0)
const monthHint = `Ovaj mjesec (${new Intl.DateTimeFormat('hr-HR', { month: 'long', year: 'numeric' }).format(new Date())})`
const count = (value?: number) => (value === undefined ? '–' : String(value))
</script>

<template>
  <div class="space-y-4">
    <div class="grid grid-cols-2 gap-3 sm:gap-4 xl:grid-cols-3">
      <StatCard
        label="Novi upiti"
        :value="String(newCount)"
        :icon="Inbox"
        :to="newCount ? '/admin/narudzbe?status=new' : undefined"
        hint="Čekaju obradu"
      />
      <StatCard label="Ukupno upita" :value="String(inquiryCount)" :icon="Mail" :hint="monthHint" to="/admin/narudzbe" />
      <StatCard
        label="Otkazani upiti"
        :value="String(cancelledCount)"
        :icon="Ban"
        :hint="monthHint"
        :to="cancelledCount ? '/admin/narudzbe?status=cancelled' : undefined"
      />
      <StatCard label="Proizvodi na webu" :value="count(basic?.products.visible)" :icon="Eye" to="/admin/proizvodi?web=da" />
      <StatCard label="Skriveni proizvodi" :value="count(basic?.products.hidden)" :icon="EyeOff" to="/admin/proizvodi?web=ne" />
    </div>

    <SalesPeriodCard />
  </div>
</template>
