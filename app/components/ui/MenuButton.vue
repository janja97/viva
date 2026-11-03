<script setup lang="ts">
import { Menu, X } from '@lucide/vue'

defineProps<{ label: string; expanded?: boolean; close?: boolean }>()
</script>

<template>
  <button
    type="button"
    :aria-label="label"
    :aria-expanded="expanded"
    class="inline-flex size-11 items-center justify-center rounded-lg text-primary-900 hover:bg-primary-200"
  >
    <X v-if="close" class="size-5" stroke-width="1.75" />
    <Menu v-else class="size-5" stroke-width="1.75" />
  </button>
</template>
