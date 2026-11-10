<script setup lang="ts">
import { WEEK_DAYS } from '~/config/store'
import type { StoreSettingsInput } from '~/types/database'

// Radno vrijeme po danima. Na webu se uzastopni dani s istim vremenom spajaju (npr. "Pon – Sub 09:00 – 21:00").
const form = defineModel<StoreSettingsInput>({ required: true })

const dayLabel = (day: string) => WEEK_DAYS.find((item) => item.value === day)?.label ?? day
</script>

<template>
  <AdminCard title="Radno vrijeme">
    <ul class="divide-y divide-primary-200">
      <li v-for="day in form.opening_hours" :key="day.day" class="grid grid-cols-[1fr_auto] items-center gap-x-4 gap-y-2 py-2 sm:grid-cols-[8rem_auto_1fr]">
        <span class="text-sm font-medium text-stone-700">{{ dayLabel(day.day) }}</span>
        <label class="flex min-h-11 cursor-pointer items-center gap-2 text-sm text-stone-600 sm:order-last sm:min-h-9 sm:justify-self-end">
          <input v-model="day.closed" type="checkbox" class="size-4 accent-primary-600">
          Zatvoreno
        </label>
        <div v-if="!day.closed" class="col-span-2 flex items-center gap-2 sm:col-span-1">
          <input v-model="day.opens" type="time" required class="form-field w-32!" :aria-label="`${dayLabel(day.day)}, otvara`">
          <span aria-hidden="true" class="text-stone-500">–</span>
          <input v-model="day.closes" type="time" required class="form-field w-32!" :aria-label="`${dayLabel(day.day)}, zatvara`">
        </div>
      </li>
    </ul>
  </AdminCard>
</template>
