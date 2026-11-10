<script setup lang="ts">
import { STORE } from '~/config/store'

const { settings, hoursText } = useStoreSettings()
</script>

<template>
  <div>
    <address class="not-italic leading-relaxed">
      <strong class="font-medium">{{ STORE.mall }}</strong><br>
      <template v-if="STORE.street">{{ STORE.street }}<br></template>
      {{ STORE.postalCode }} {{ STORE.city }}, {{ STORE.country }}
    </address>
    <p v-if="hoursText" class="mt-3">{{ hoursText }}</p>
    <p v-if="settings.phone" class="mt-3"><a :href="`tel:${phoneDigits(settings.phone)}`" class="underline underline-offset-4">{{ settings.phone }}</a></p>
    <p v-if="settings.email" class="mt-1"><a :href="`mailto:${settings.email}`" class="underline underline-offset-4">{{ settings.email }}</a></p>
    <SiteChatLinks class="mt-3" />
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
