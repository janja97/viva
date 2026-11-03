<script setup lang="ts">
defineProps<{ number: number | null }>()
const emit = defineEmits<{ close: [] }>()
</script>

<template>
  <BaseModal :open="number !== null" title="Hvala na narudžbi" @close="emit('close')">
    <div class="space-y-6 font-body text-ink" aria-live="polite">
      <p class="text-xs font-medium uppercase tracking-[0.24em] text-gold">Narudžba br. {{ number }}</p>
      <p class="leading-relaxed text-muted">Vaš upit je zaprimljen. Javit ćemo vam se telefonom ili e-mailom radi potvrde.</p>
      <button
        type="button"
        class="inline-flex min-h-13 w-full items-center justify-center border border-ink bg-ink px-8 text-xs font-medium uppercase tracking-[0.2em] text-white transition-colors hover:bg-transparent hover:text-ink"
        @click="emit('close')"
      >
        Na naslovnu
      </button>
    </div>
  </BaseModal>
</template>
