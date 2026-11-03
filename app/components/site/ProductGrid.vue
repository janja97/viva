<script setup lang="ts">
import type { ShopCard } from '~/composables/useShop'

defineProps<{ cards: ShopCard[]; isNew?: boolean; withSidebar?: boolean }>()
</script>

<template>
  <ul class="grid grid-cols-2 gap-x-4 gap-y-10" :class="withSidebar ? 'lg:grid-cols-3' : 'lg:grid-cols-4'">
    <li v-for="(card, index) in cards" :key="card.id">
      <ProductCard :card="card" :eager="index < 2" :is-new="isNew" />
    </li>
  </ul>
</template>
