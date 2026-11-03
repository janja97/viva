<script setup lang="ts">
import { Minus, Plus, X } from '@lucide/vue'
import { PRODUCT_PATH } from '~/config/products'
import type { CartItem } from '~/composables/useCart'

const props = defineProps<{ item: CartItem; disabled?: boolean }>()
const emit = defineEmits<{ quantity: [quantity: number]; remove: [] }>()

const maxQuantity = computed(() => Math.min(props.item.stock, 20))
const overStock = computed(() => props.item.quantity > props.item.stock)

const stepClass = 'inline-flex size-11 items-center justify-center transition-colors hover:text-gold disabled:cursor-not-allowed disabled:opacity-40'
</script>

<template>
  <article class="flex gap-4 py-5">
    <NuxtLink :to="`${PRODUCT_PATH}/${item.slug}`" class="block w-24 shrink-0 sm:w-28">
      <div class="aspect-3/4 overflow-hidden bg-photo">
        <img v-if="item.image" :src="item.image" :alt="item.imageAlt ?? `${item.productName} ${item.colorName}`" loading="lazy" width="300" height="400" class="size-full object-cover">
      </div>
    </NuxtLink>

    <div class="flex min-w-0 flex-1 flex-col">
      <div class="flex items-start justify-between gap-3">
        <div class="min-w-0">
          <h2 class="font-display text-xl font-normal leading-snug">
            <NuxtLink :to="`${PRODUCT_PATH}/${item.slug}`" class="hover:text-gold">{{ item.productName }}</NuxtLink>
          </h2>
          <p class="mt-1 text-sm text-muted">{{ item.colorName }} · Veličina {{ item.size }}</p>
          <p class="text-xs text-muted">Šifra: {{ item.sku }}</p>
        </div>
        <button
          type="button"
          :disabled="disabled"
          :aria-label="`Ukloni iz košarice: ${item.productName}, ${item.colorName}, ${item.size}`"
          class="-mr-3 -mt-2 inline-flex size-11 shrink-0 items-center justify-center text-muted hover:text-ink disabled:opacity-40"
          @click="emit('remove')"
        >
          <X class="size-4" stroke-width="1.5" />
        </button>
      </div>

      <div class="mt-auto flex flex-wrap items-end justify-between gap-3 pt-3">
        <div class="inline-flex items-center border border-line bg-white">
          <button type="button" :class="stepClass" :disabled="disabled || item.quantity <= 1" aria-label="Smanji količinu" @click="emit('quantity', item.quantity - 1)">
            <Minus class="size-4" stroke-width="1.5" />
          </button>
          <span class="min-w-8 text-center text-sm" aria-live="polite">{{ item.quantity }}</span>
          <button type="button" :class="stepClass" :disabled="disabled || item.quantity >= maxQuantity" aria-label="Povećaj količinu" @click="emit('quantity', item.quantity + 1)">
            <Plus class="size-4" stroke-width="1.5" />
          </button>
        </div>
        <p class="text-right">
          <span class="block font-medium text-gold">{{ formatPrice(item.price * item.quantity) }}</span>
          <del v-if="item.compareAtPrice" class="block text-xs text-muted">{{ formatPrice(item.compareAtPrice * item.quantity) }}</del>
        </p>
      </div>

      <p v-if="overStock" class="mt-2 text-sm text-red-700">
        Dostupno je još {{ item.stock }} kom. Smanjite količinu prije slanja upita.
      </p>
    </div>
  </article>
</template>
