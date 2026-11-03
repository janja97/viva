<script setup lang="ts">
defineProps<{
  eyebrow?: string
  title: string
  linkTo?: string
  linkLabel?: string
  linkLabelShort?: string
}>()
</script>

<template>
  <div class="mb-8 flex items-end justify-between gap-4 lg:mb-12">
    <div>
      <p v-if="eyebrow" class="mb-2 hidden text-xs font-medium uppercase tracking-[0.24em] text-gold sm:block">{{ eyebrow }}</p>
      <h2 class="font-display text-4xl font-normal leading-tight lg:text-5xl">{{ title }}</h2>
    </div>
    <NuxtLink
      v-if="linkTo"
      :to="linkTo"
      class="inline-flex min-h-11 flex-none items-center text-xs font-medium uppercase tracking-[0.16em] text-gold hover:underline hover:underline-offset-4"
    >
      <span class="sm:hidden">{{ linkLabelShort ?? linkLabel }}</span>
      <span class="hidden sm:inline">{{ linkLabel }}</span>
      <span aria-hidden="true" class="ml-2">→</span>
    </NuxtLink>
  </div>
</template>
