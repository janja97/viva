<script setup lang="ts">
defineProps<{ label: string; danger?: boolean; disabled?: boolean }>()
</script>

<template>
  <button
    type="button"
    :aria-label="label"
    :title="label"
    :disabled="disabled"
    class="inline-flex size-11 shrink-0 items-center justify-center rounded-lg text-stone-500 transition-colors disabled:pointer-events-none disabled:opacity-30 sm:size-8"
    :class="danger ? 'hover:bg-red-50 hover:text-red-600' : 'hover:bg-primary-100 hover:text-primary-700'"
  >
    <slot />
  </button>
</template>
