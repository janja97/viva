<script setup lang="ts">
defineProps<{ title: string }>()
</script>

<template>
  <section class="rounded-xl border border-primary-300 bg-white p-5 shadow-sm sm:p-6">
    <h2 class="mb-4 font-display text-2xl font-normal leading-tight">{{ title }}</h2>
    <slot />
  </section>
</template>
