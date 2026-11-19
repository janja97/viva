<script setup lang="ts">
// Popis s trakama za karticu "Posjete" (izvori, države, gradovi...). Traka je udio prema najvećem retku.
const props = defineProps<{
  title: string
  rows: { label: string; hint?: string; visits: number }[]
  emptyText?: string
}>()

const max = computed(() => Math.max(1, ...props.rows.map((row) => Number(row.visits))))
const total = computed(() => props.rows.reduce((sum, row) => sum + Number(row.visits), 0))
const share = (visits: number) => (total.value ? `${Math.round((visits / total.value) * 100)} %` : '')
</script>

<template>
  <AdminCard :title="title">
    <p v-if="!rows.length" class="text-sm text-stone-500">{{ emptyText ?? 'Još nema posjeta u ovom razdoblju.' }}</p>
    <ol v-else class="space-y-3">
      <li v-for="row in rows" :key="`${row.label}-${row.hint ?? ''}`">
        <div class="flex items-baseline justify-between gap-3 text-sm">
          <p class="min-w-0 truncate">
            <span class="text-stone-900">{{ row.label }}</span>
            <span v-if="row.hint" class="ml-1.5 text-xs text-stone-500">{{ row.hint }}</span>
          </p>
          <p class="shrink-0 tabular-nums text-stone-700">
            {{ row.visits }} <span class="text-stone-500">· {{ share(row.visits) }}</span>
          </p>
        </div>
        <div class="mt-1 h-1.5 bg-primary-100">
          <div class="h-full bg-primary-600" :style="{ width: `${(Number(row.visits) / max) * 100}%` }" />
        </div>
      </li>
    </ol>
  </AdminCard>
</template>
