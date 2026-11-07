<script setup lang="ts">
import { analyticsBucketLabel } from '~/composables/useDashboard'
import type { SalesAnalytics } from '~/types/database'

const props = defineProps<{ data: SalesAnalytics }>()

// Najnovije razdoblje prvo, kao u izvještaju.
const rows = computed(() => [...props.data.trend].reverse())
const totals = computed(() => props.data.trend.reduce(
  (sum, row) => ({
    inquiries: sum.inquiries + Number(row.inquiries),
    orders: sum.orders + Number(row.orders),
    revenue: sum.revenue + Number(row.revenue),
  }),
  { inquiries: 0, orders: 0, revenue: 0 },
))
</script>

<template>
  <div class="max-h-[28rem] overflow-auto">
    <table class="w-full text-left text-sm">
      <thead class="sticky top-0 border-b border-primary-300 bg-white text-xs text-stone-500">
        <tr>
          <th class="py-2 pr-3 font-medium">Razdoblje</th>
          <th class="py-2 pr-3 text-right font-medium">Pristigli upiti</th>
          <th class="py-2 pr-3 text-right font-medium">Prodano</th>
          <th class="py-2 text-right font-medium">Prihod</th>
        </tr>
      </thead>
      <tbody class="divide-y divide-primary-200 tabular-nums">
        <tr v-for="row in rows" :key="row.bucket" :class="!Number(row.inquiries) && !Number(row.orders) && 'text-stone-400'">
          <td class="py-1.5 pr-3">{{ analyticsBucketLabel(row.bucket, data.bucket) }}</td>
          <td class="py-1.5 pr-3 text-right">{{ row.inquiries }}</td>
          <td class="py-1.5 pr-3 text-right">{{ row.orders }}</td>
          <td class="py-1.5 text-right">{{ formatPrice(Number(row.revenue)) }}</td>
        </tr>
      </tbody>
      <tfoot class="sticky bottom-0 border-t border-primary-300 bg-white font-medium tabular-nums">
        <tr>
          <td class="py-2 pr-3">Ukupno</td>
          <td class="py-2 pr-3 text-right">{{ totals.inquiries }}</td>
          <td class="py-2 pr-3 text-right">{{ totals.orders }}</td>
          <td class="py-2 text-right">{{ formatPrice(totals.revenue) }}</td>
        </tr>
      </tfoot>
    </table>
  </div>
</template>
