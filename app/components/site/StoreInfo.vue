<script setup lang="ts">
import { STORE } from '~/config/store'
</script>

<template>
  <div>
    <address class="not-italic leading-relaxed">
      <strong class="font-medium">{{ STORE.mall }}</strong><br>
      <template v-if="STORE.street">{{ STORE.street }}<br></template>
      {{ STORE.postalCode }} {{ STORE.city }}, {{ STORE.country }}
    </address>
    <p v-if="STORE.hours" class="mt-3">{{ STORE.hours }}</p>
    <p v-if="STORE.phone" class="mt-3"><a :href="`tel:${STORE.phone.replace(/\s/g, '')}`" class="underline underline-offset-4">{{ STORE.phone }}</a></p>
    <p v-if="STORE.email" class="mt-1"><a :href="`mailto:${STORE.email}`" class="underline underline-offset-4">{{ STORE.email }}</a></p>
    <a
      :href="STORE.mapUrl"
      target="_blank"
      rel="noopener"
      class="mt-6 inline-flex min-h-12 items-center justify-center border border-current px-8 text-xs font-medium uppercase tracking-[0.2em]"
    >
      Prikaži na karti
    </a>
  </div>
</template>
