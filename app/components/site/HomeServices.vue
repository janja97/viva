<script setup lang="ts">
import { HOME_SERVICES } from '~/config/home'

const { settings } = useStoreSettings()
const services = computed(() => HOME_SERVICES.map((service) => ({
  ...service,
  text: service.text.replace('{prag}', formatPrice(Number(settings.value.free_shipping_above))),
})))
</script>

<template>
  <section aria-label="Usluge" class="hidden bg-sand sm:block">
    <ul class="mx-auto grid max-w-7xl gap-8 px-4 py-12 sm:grid-cols-3 sm:px-6 lg:px-8">
      <li v-for="service in services" :key="service.title">
        <h3 class="font-display text-2xl font-normal text-gold">{{ service.title }}</h3>
        <p class="mt-1 text-sm leading-relaxed text-muted">{{ service.text }}</p>
      </li>
    </ul>
  </section>
</template>
