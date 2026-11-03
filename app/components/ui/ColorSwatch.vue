<script setup lang="ts">
import { MULTICOLOR } from '~/config/products'

defineProps<{ name: string; hex: string }>()
</script>

<template>
  <span
    :title="name"
    class="inline-block shrink-0 rounded-full border border-black/25"
    :style="name === MULTICOLOR
      ? { background: 'conic-gradient(#dc2626, #facc15, #16a34a, #2563eb, #7e22ce, #dc2626)' }
      : { backgroundColor: hex }"
  />
</template>
