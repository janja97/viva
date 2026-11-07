<script setup lang="ts">
import { PRODUCT_PATH } from '~/config/products'
import type { ShopCard } from '~/composables/useShop'

defineProps<{
  card: ShopCard
  // Prve kartice su odmah vidljive, pa se ne učitavaju odgođeno.
  eager?: boolean
  isNew?: boolean
}>()
</script>

<template>
  <article class="group">
    <NuxtLink :to="`${PRODUCT_PATH}/${card.slug}`" class="block">
      <div class="relative aspect-3/4 overflow-hidden bg-photo">
        <img
          v-if="card.image"
          :src="card.image"
          :alt="card.alt"
          :loading="eager ? 'eager' : 'lazy'"
          width="600"
          height="800"
          class="size-full object-cover transition-transform duration-700 group-hover:scale-105"
        >
        <!-- Sniženje je crveno, a novo zeleno. Rasprodano se na kartici ne ističe. -->
        <span v-if="card.compareAtPrice" class="absolute left-3 top-3 bg-red-700 px-2.5 py-1 text-[11px] font-medium tracking-[0.1em] text-white">-{{ Math.round((1 - card.price / card.compareAtPrice) * 100) }}%</span>
        <span v-else-if="isNew" class="absolute left-3 top-3 bg-emerald-700 px-2.5 py-1 text-[11px] font-medium uppercase tracking-[0.2em] text-white">Novo</span>
      </div>
      <p v-if="card.categoryName" class="mt-3.5 hidden text-[11px] font-medium uppercase tracking-[0.16em] text-muted sm:block">{{ card.categoryName }}</p>
      <h3 class="mt-3 font-display text-xl font-normal leading-snug group-hover:text-gold sm:mt-1 sm:text-[22px]">{{ card.productName }}</h3>
    </NuxtLink>
    <p class="text-sm text-muted">{{ card.colorName }}</p>
    <p class="mt-1 flex flex-wrap items-baseline gap-x-2">
      <span class="font-medium text-gold">{{ formatPrice(card.price) }}</span>
      <del v-if="card.compareAtPrice" class="text-sm text-muted">{{ formatPrice(card.compareAtPrice) }}</del>
    </p>
    <p v-if="card.storeOnly" class="mt-1 text-xs text-gold">Dostupno samo u poslovnicama</p>
    <div v-if="card.colors.length > 1" class="mt-2 flex flex-wrap gap-1.5">
      <ColorSwatch v-for="color in card.colors" :key="color.id" class="size-3" :name="color.name" :hex="color.hex" />
    </div>
  </article>
</template>
