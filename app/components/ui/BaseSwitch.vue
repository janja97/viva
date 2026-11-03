<script setup lang="ts">
defineProps<{ label: string; hint?: string }>()

const model = defineModel<boolean>({ default: false })
</script>

<template>
  <label class="flex min-h-11 cursor-pointer items-center justify-between gap-4">
    <span>
      <span class="block text-sm font-medium text-stone-700">{{ label }}</span>
      <span v-if="hint" class="mt-0.5 block text-xs text-stone-500">{{ hint }}</span>
    </span>
    <input v-model="model" type="checkbox" role="switch" class="peer sr-only">
    <span
      aria-hidden="true"
      class="relative h-5 w-9 shrink-0 rounded-full bg-stone-300 transition-colors peer-checked:bg-primary-600 peer-focus-visible:outline-2 peer-focus-visible:outline-offset-2 peer-focus-visible:outline-primary-600 after:absolute after:left-0.5 after:top-0.5 after:size-4 after:rounded-full after:bg-white after:transition-transform peer-checked:after:translate-x-4"
    />
  </label>
</template>
