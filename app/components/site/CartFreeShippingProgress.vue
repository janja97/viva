<script setup lang="ts">
// Traka do besplatne poštarine (košarica i CartDrawer). Samo za dostavu na adresu i dok poštarina postoji.
// Pravilo je isto kao shippingFor: besplatna je za iznos proizvoda (prije promo popusta) veći od praga.
const { items, subtotal, shipping, deliveryMethod } = useCart()
const { settings } = useStoreSettings()

const threshold = computed(() => Number(settings.value.free_shipping_above))
const visible = computed(() => items.value.length > 0 && deliveryMethod.value === 'delivery'
  && Number(settings.value.shipping_price) > 0 && threshold.value > 0)
const isFree = computed(() => shipping.value === 0)
const progress = computed(() => (isFree.value ? 100 : Math.min(99, (subtotal.value / threshold.value) * 100)))
// Prag mora biti prijeđen, pa na točno pragu nedostaje još 0,01 KM.
const missing = computed(() => Math.max(0.01, threshold.value - subtotal.value))
</script>

<template>
  <div v-if="visible">
    <p class="mb-2 text-xs" :class="isFree ? 'font-medium text-ink' : 'text-muted'" aria-live="polite">
      <template v-if="isFree">Ostvarili ste besplatnu poštarinu.</template>
      <template v-else>Još <strong class="font-medium text-ink">{{ formatPrice(missing) }}</strong> do besplatne poštarine.</template>
    </p>
    <div
      class="h-1 overflow-hidden rounded-full bg-line"
      role="progressbar"
      aria-label="Do besplatne poštarine"
      aria-valuemin="0"
      aria-valuemax="100"
      :aria-valuenow="Math.round(progress)"
    >
      <div class="h-full rounded-full bg-gold transition-[width] duration-500 ease-out" :style="{ width: `${progress}%` }" />
    </div>
  </div>
</template>
