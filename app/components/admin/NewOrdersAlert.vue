<script setup lang="ts">
import { ShoppingBag } from '@lucide/vue'

const { count } = useNewInquiries()

// "1 nova narudžba", "2 nove narudžbe", "5 novih narudžbi"
const label = computed(() => {
  const value = count.value
  const lastTwo = value % 100
  const last = value % 10
  if (last === 1 && lastTwo !== 11) return `${value} nova narudžba`
  if (last >= 2 && last <= 4 && (lastTwo < 12 || lastTwo > 14)) return `${value} nove narudžbe`
  return `${value} novih narudžbi`
})
</script>

<template>
  <NuxtLink
    v-if="count"
    to="/admin/narudzbe"
    class="inline-flex min-h-11 items-center gap-2 rounded-full bg-red-600 py-1 pl-1.5 pr-3.5 text-sm font-semibold text-white transition-colors hover:bg-red-700 sm:min-h-9"
  >
    <span class="relative flex size-7 items-center justify-center rounded-full bg-white text-red-600">
      <ShoppingBag class="size-4" stroke-width="2" />
      <span class="absolute -right-0.5 -top-0.5 size-2.5 animate-ping rounded-full bg-white motion-reduce:hidden" aria-hidden="true" />
    </span>
    <span class="sm:hidden">{{ count }}</span>
    <span class="hidden sm:inline">{{ label }}</span>
    <span class="sr-only sm:hidden">{{ label }}</span>
  </NuxtLink>
</template>
