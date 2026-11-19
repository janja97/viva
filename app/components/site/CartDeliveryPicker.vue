<script setup lang="ts">
import { DELIVERY_METHODS } from '~/config/store'

// Dostava na adresu ili preuzimanje u trgovini (migracija 0048). Preuzimanje je bez poštarine,
// pa se iznosi u CartTotals odmah mijenjaju. Izbor ide uz narudžbu (obrazac i WhatsApp).
const { deliveryMethod } = useCart()
</script>

<template>
  <fieldset>
    <legend class="mb-2 text-xs font-medium uppercase tracking-[0.16em]">Preuzimanje</legend>
    <div class="space-y-1">
      <label
        v-for="option in DELIVERY_METHODS"
        :key="option.value"
        class="flex min-h-11 cursor-pointer items-start gap-3 py-1.5"
      >
        <input
          v-model="deliveryMethod"
          type="radio"
          name="nacin-preuzimanja"
          :value="option.value"
          class="mt-1 size-4 flex-none accent-ink"
        >
        <span class="text-sm leading-snug">
          {{ option.label }}
          <span class="block text-xs text-muted">{{ option.hint }}</span>
        </span>
      </label>
    </div>
  </fieldset>
</template>
