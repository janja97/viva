<script setup lang="ts">
import { ANALYTICS_PERIODS, type AnalyticsPeriod } from '~/composables/useDashboard'

const model = defineModel<AnalyticsPeriod>({ required: true })
</script>

<template>
  <div class="flex overflow-x-auto border border-primary-300 bg-white [scrollbar-width:none] sm:w-fit" role="group" aria-label="Razdoblje">
    <button
      v-for="option in ANALYTICS_PERIODS"
      :key="option.value"
      type="button"
      :aria-pressed="model === option.value"
      class="min-h-11 shrink-0 cursor-pointer px-3.5 text-sm font-medium transition-colors sm:min-h-9"
      :class="model === option.value ? 'bg-primary-600 text-white' : 'text-stone-600 hover:bg-primary-50'"
      @click="model = option.value"
    >
      {{ option.label }}
    </button>
  </div>
</template>
