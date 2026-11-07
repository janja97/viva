<script setup lang="ts">
import type { SalesAnalytics } from '~/types/database'

// Kartica "Statistika": što se najviše prodaje, sniženja, promo kodovi i newsletter.
const props = defineProps<{ data: SalesAnalytics }>()

const saleShare = computed(() => {
  const goods = Number(props.data.kpi.goods_revenue)
  return goods ? Math.round((Number(props.data.kpi.sale_revenue) / goods) * 100) : 0
})
</script>

<template>
  <div class="space-y-4">
    <div class="grid gap-4 lg:grid-cols-2">
      <RankedBars title="Najprodavaniji proizvodi" :rows="data.products" />
      <RankedBars title="Kategorije" :rows="data.categories" />
      <RankedBars title="Boje" :rows="data.colors" />
      <RankedBars title="Veličine" :rows="data.sizes" />
    </div>

    <div class="grid gap-4 lg:grid-cols-2">
      <AdminCard title="Sniženja i promo kodovi">
        <!-- Jedan omjer, pa traka, a ne grafikon. -->
        <p class="text-sm text-stone-600">Prodano na sniženju: <strong class="text-stone-900">{{ saleShare }} %</strong> prihoda od proizvoda</p>
        <div class="mt-1.5 h-2 bg-primary-100" role="meter" :aria-valuenow="saleShare" aria-valuemin="0" aria-valuemax="100" aria-label="Udio prodaje na sniženju">
          <div class="h-full bg-primary-600" :style="{ width: `${saleShare}%` }" />
        </div>
        <p v-if="!data.promo_codes.length" class="mt-4 text-sm text-stone-500">U ovom razdoblju nije iskorišten nijedan promo kod.</p>
        <table v-else class="mt-4 w-full text-left text-sm">
          <thead class="border-b border-primary-300 text-xs text-stone-500">
            <tr>
              <th class="py-1.5 pr-3 font-medium">Kod</th>
              <th class="py-1.5 pr-3 text-right font-medium">Narudžbi</th>
              <th class="py-1.5 text-right font-medium">Popust</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-primary-200 tabular-nums">
            <tr v-for="code in data.promo_codes" :key="code.code">
              <td class="py-1.5 pr-3">
                <span class="font-mono">{{ code.code }}</span>
                <span v-if="code.kind === 'newsletter'" class="ml-1.5 text-xs text-stone-500">newsletter</span>
              </td>
              <td class="py-1.5 pr-3 text-right">{{ code.orders }}</td>
              <td class="py-1.5 text-right">{{ formatPrice(Number(code.discount)) }}</td>
            </tr>
          </tbody>
        </table>
      </AdminCard>

      <AdminCard title="Newsletter">
        <dl class="grid grid-cols-3 gap-4 text-center">
          <div>
            <dt class="text-xs text-stone-500">Ukupno pretplatnika</dt>
            <dd class="font-display text-3xl">{{ data.newsletter.total }}</dd>
          </div>
          <div>
            <dt class="text-xs text-stone-500">Novih u razdoblju</dt>
            <dd class="font-display text-3xl">{{ data.newsletter.new }}</dd>
          </div>
          <div>
            <dt class="text-xs text-stone-500">Kupnji s kodom</dt>
            <dd class="font-display text-3xl">{{ data.newsletter.codes_used }}</dd>
          </div>
        </dl>
      </AdminCard>
    </div>
  </div>
</template>
