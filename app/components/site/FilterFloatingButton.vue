<script setup lang="ts">
import { SlidersHorizontal } from '@lucide/vue'

// Gumb za filtre na mobitelu, uvijek vidljiv u donjem desnom kutu dok se popis pomiče.
defineProps<{ count?: number; label?: string }>()
const emit = defineEmits<{ open: [] }>()
</script>

<template>
  <button
    type="button"
    aria-haspopup="dialog"
    class="fixed bottom-[max(1rem,env(safe-area-inset-bottom))] right-4 z-30 inline-flex min-h-12 cursor-pointer items-center gap-2.5 border border-graphite bg-graphite px-5 font-body text-xs font-medium uppercase tracking-[0.2em] text-white transition-colors hover:bg-ink lg:hidden"
    @click="emit('open')"
  >
    <SlidersHorizontal class="size-4" stroke-width="1.5" />
    {{ label ?? 'Filteri' }}
    <span v-if="count" class="inline-flex size-5 items-center justify-center rounded-full bg-gold-light text-[10px] tracking-normal text-graphite">{{ count }}</span>
  </button>
</template>
