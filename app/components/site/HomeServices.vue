<script setup lang="ts">
import { HOME_SERVICES } from '~/config/home'
</script>

<template>
  <section aria-label="Usluge" class="hidden bg-sand sm:block">
    <ul class="mx-auto grid max-w-7xl grid-cols-2 gap-8 px-4 py-12 sm:px-6 lg:grid-cols-4 lg:px-8">
      <li v-for="service in HOME_SERVICES" :key="service.title">
        <h3 class="font-display text-2xl font-normal text-gold">{{ service.title }}</h3>
        <p class="mt-1 text-sm leading-relaxed text-muted">{{ service.text }}</p>
      </li>
    </ul>
  </section>
</template>
