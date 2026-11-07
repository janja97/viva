<script setup lang="ts">
import type { Component } from 'vue'

const props = defineProps<{
  label: string
  value: string
  icon?: Component
  hint?: string
  // Promjena u postocima prema prethodnom razdoblju. Null kad usporedbe nema.
  delta?: number | null
  to?: string
}>()

const deltaText = computed(() => {
  if (props.delta === null || props.delta === undefined) return ''
  if (props.delta === 0) return 'Isto kao prethodno razdoblje'
  return `${props.delta > 0 ? '▲' : '▼'} ${Math.abs(props.delta)} % prema prethodnom razdoblju`
})
</script>

<template>
  <component
    :is="to ? resolveComponent('NuxtLink') : 'div'"
    :to="to"
    class="flex items-start gap-4 border border-primary-300 bg-white p-4 sm:p-5"
    :class="to && 'transition-colors hover:border-primary-500'"
  >
    <span v-if="icon" class="hidden size-11 shrink-0 items-center justify-center bg-primary-100 text-primary-700 sm:flex">
      <component :is="icon" class="size-5" stroke-width="1.75" />
    </span>
    <div class="min-w-0">
      <p class="text-sm text-stone-500">{{ label }}</p>
      <p class="font-display text-2xl font-normal leading-tight sm:text-3xl">{{ value }}</p>
      <p v-if="deltaText" class="mt-0.5 text-xs" :class="delta! > 0 ? 'text-emerald-700' : delta! < 0 ? 'text-red-700' : 'text-stone-500'">{{ deltaText }}</p>
      <p v-if="hint" class="mt-0.5 text-xs text-stone-500">{{ hint }}</p>
    </div>
  </component>
</template>
