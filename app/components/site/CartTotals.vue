<script setup lang="ts">
const { subtotal, savings, shipping, total, missingForFreeShipping } = useCart()
</script>

<template>
  <dl class="space-y-2 text-sm">
    <div class="flex justify-between gap-3">
      <dt class="text-muted">Ukupno</dt>
      <dd>{{ formatPrice(subtotal) }}</dd>
    </div>
    <div v-if="savings > 0" class="flex justify-between gap-3">
      <dt class="text-muted">Ušteda</dt>
      <dd>{{ formatPrice(savings) }}</dd>
    </div>
    <div class="flex justify-between gap-3">
      <dt class="text-muted">Poštarina</dt>
      <dd>{{ shipping ? formatPrice(shipping) : 'Besplatna' }}</dd>
    </div>
    <p v-if="missingForFreeShipping > 0" class="text-xs text-muted">
      Još {{ formatPrice(missingForFreeShipping) }} do besplatne poštarine.
    </p>
    <div class="flex justify-between gap-3 border-t border-line pt-3 text-base">
      <dt>Sveukupno</dt>
      <dd class="font-medium text-gold">{{ formatPrice(total) }}</dd>
    </div>
  </dl>
</template>
