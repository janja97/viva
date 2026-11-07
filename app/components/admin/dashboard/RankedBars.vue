<script setup lang="ts">
import type { AnalyticsRankRow } from '~/types/database'

const props = defineProps<{
  title: string
  rows: AnalyticsRankRow[]
  emptyText?: string
}>()

// Duljina trake je udio prema najprodavanijem retku. Jedna boja, jer redoslijed nosi poredak, a ne boja.
const max = computed(() => Math.max(1, ...props.rows.map((row) => Number(row.quantity))))
</script>

<template>
  <AdminCard :title="title">
    <p v-if="!rows.length" class="text-sm text-stone-500">{{ emptyText ?? 'Nema prodaje u ovom razdoblju.' }}</p>
    <ol v-else class="space-y-3">
      <li
        v-for="(row, index) in rows"
        :key="`${row.name}-${row.sku ?? ''}`"
        :title="`${row.name}: ${row.quantity} kom, ${formatPrice(Number(row.revenue))}`"
      >
        <div class="flex items-baseline justify-between gap-3 text-sm">
          <p class="min-w-0 truncate">
            <span class="mr-1.5 text-stone-400">{{ index + 1 }}.</span>
            <span class="text-stone-900">{{ row.name }}</span>
            <span v-if="row.sku" class="ml-1.5 hidden text-xs text-stone-500 sm:inline">{{ row.sku }}</span>
          </p>
          <p class="shrink-0 tabular-nums text-stone-700">
            {{ row.quantity }} kom <span class="text-stone-500">· {{ formatPrice(Number(row.revenue)) }}</span>
          </p>
        </div>
        <div class="mt-1 h-2 bg-primary-100" aria-hidden="true">
          <div class="h-full bg-primary-600" :style="{ width: `${(Number(row.quantity) / max) * 100}%` }" />
        </div>
      </li>
    </ol>
  </AdminCard>
</template>
