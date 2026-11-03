<script setup lang="ts">
import type { Component } from 'vue'

defineProps<{
  label: string
  value: string
  icon: Component
  tone: 'primary' | 'pink' | 'sky'
}>()

const TONES = {
  primary: 'bg-primary-100 text-primary-700',
  pink: 'bg-primary-200 text-primary-900',
  sky: 'bg-primary-200 text-primary-900',
}
</script>

<template>
  <div class="flex items-center gap-4 rounded-xl border border-primary-300 bg-white p-5 shadow-sm">
    <span class="flex size-11 shrink-0 items-center justify-center rounded-lg" :class="TONES[tone]">
      <component :is="icon" class="size-5" stroke-width="1.75" />
    </span>
    <div>
      <p class="text-sm text-stone-500">{{ label }}</p>
      <p class="font-display text-3xl font-normal">{{ value }}</p>
    </div>
  </div>
</template>
