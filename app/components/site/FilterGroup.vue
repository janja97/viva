<script setup lang="ts">
import { ChevronDown } from '@lucide/vue'

// Skupina filtara koja se otvara i zatvara (native <details>, radi i bez JavaScripta).
// count je broj odabranih vrijednosti u skupini, prikazan uz naslov i kad je skupina zatvorena.
defineProps<{ title: string; count?: number; open?: boolean }>()
</script>

<template>
  <details class="group border-b border-line" :open="open">
    <summary class="flex min-h-13 cursor-pointer list-none items-center justify-between gap-3 select-none text-xs font-medium uppercase tracking-[0.2em] text-ink transition-colors hover:text-gold lg:min-h-12 [&::-webkit-details-marker]:hidden">
      <span class="flex items-center gap-2">
        {{ title }}
        <span v-if="count" class="inline-flex size-5 items-center justify-center rounded-full bg-ink text-[10px] font-medium tracking-normal text-white">{{ count }}</span>
      </span>
      <ChevronDown class="size-4 flex-none text-muted transition-transform duration-200 group-open:rotate-180" stroke-width="1.5" aria-hidden="true" />
    </summary>
    <div class="pb-5">
      <slot />
    </div>
  </details>
</template>
