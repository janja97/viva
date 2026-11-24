<script setup lang="ts">
import { WEEK_DAYS } from '~/config/store'

// Radno vrijeme po danima (iz postavki trgovine). Današnji dan se ističe tek u pregledniku,
// jer se stranica kešira na serveru i ne zna kupčev dan.
const { settings } = useStoreSettings()

const today = ref<string | null>(null)
onMounted(() => {
  const day = new Intl.DateTimeFormat('en-US', { weekday: 'long', timeZone: 'Europe/Sarajevo' }).format(new Date())
  today.value = day
})

const rows = computed(() => settings.value.opening_hours.map((item) => ({
  day: item.day,
  label: WEEK_DAYS.find((week) => week.value === item.day)?.label ?? item.day,
  hours: item.closed ? 'Zatvoreno' : `${item.opens} – ${item.closes}`,
  closed: item.closed,
})))
</script>

<template>
  <dl class="divide-y divide-line border-y border-line">
    <div
      v-for="row in rows"
      :key="row.day"
      class="flex items-center justify-between gap-4 py-3 text-sm"
      :class="row.day === today ? 'font-medium text-ink' : 'text-muted'"
    >
      <dt class="flex items-center gap-2.5">
        <span class="size-1.5 rounded-full" :class="row.day === today ? 'bg-gold' : 'bg-transparent'" aria-hidden="true" />
        {{ row.label }}<span v-if="row.day === today" class="sr-only"> (danas)</span>
      </dt>
      <dd class="tabular-nums" :class="row.closed && 'italic'">{{ row.hours }}</dd>
    </div>
  </dl>
</template>
