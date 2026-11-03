<script setup lang="ts">
defineProps<{ type: 'error' | 'success' | 'warning' }>()

const COLORS = {
  error: 'border-red-200 bg-red-50 text-red-700',
  success: 'border-emerald-200 bg-emerald-50 text-emerald-700',
  warning: 'border-amber-200 bg-amber-50 text-amber-800',
}
</script>

<template>
  <p
    :role="type === 'error' ? 'alert' : 'status'"
    class="rounded-lg border px-3 py-2.5 text-sm"
    :class="COLORS[type]"
  >
    <slot />
  </p>
</template>
