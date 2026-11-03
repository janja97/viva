<script setup lang="ts">
defineProps<{ items: { label: string; to?: string }[] }>()
</script>

<template>
  <nav aria-label="Putanja" class="text-[11px] uppercase tracking-[0.14em] text-muted">
    <ol class="flex flex-wrap items-center gap-x-2.5">
      <li v-for="(item, index) in items" :key="item.label" class="flex items-center gap-2.5">
        <span v-if="index > 0" aria-hidden="true">/</span>
        <NuxtLink v-if="item.to" :to="item.to" class="inline-flex min-h-11 min-w-11 items-center hover:text-ink">{{ item.label }}</NuxtLink>
        <span v-else aria-current="page" class="text-ink">{{ item.label }}</span>
      </li>
    </ol>
  </nav>
</template>
