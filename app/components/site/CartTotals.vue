<script setup lang="ts">
const { subtotal, savings, shipping, deliveryMethod, promo, promoDiscount, total } = useCart()
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
    <div v-if="promo" class="flex justify-between gap-3">
      <dt class="text-muted">Promo kod ({{ promo.code }})</dt>
      <dd>-{{ formatPrice(promoDiscount) }}</dd>
    </div>
    <div class="flex justify-between gap-3">
      <dt class="text-muted">Poštarina</dt>
      <dd>{{ deliveryMethod !== 'delivery' ? 'Bez poštarine' : shipping ? formatPrice(shipping) : 'Besplatna' }}</dd>
    </div>
    <CartFreeShippingProgress class="pb-1 pt-1" />
    <div class="flex justify-between gap-3 border-t border-line pt-3 text-base">
      <dt>Sveukupno</dt>
      <dd class="font-medium text-gold">{{ formatPrice(total) }}</dd>
    </div>
  </dl>
</template>
