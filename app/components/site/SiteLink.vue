<script setup lang="ts">
defineProps<{
  to: string
  variant?: 'solid' | 'outline'
}>()
</script>

<template>
  <NuxtLink
    :to="to"
    class="inline-flex min-h-13 items-center justify-center border px-8 text-center text-xs font-medium uppercase tracking-[0.2em] transition-colors"
    :class="variant === 'outline'
      ? 'border-ink text-ink hover:bg-ink hover:text-white'
      : 'border-ink bg-ink text-white hover:bg-transparent hover:text-ink'"
  >
    <slot />
  </NuxtLink>
</template>
