<script setup lang="ts">
defineProps<{ open: boolean }>()
const emit = defineEmits<{ close: [] }>()
</script>

<template>
  <BaseModal :open="open" title="Upit je poslan" @close="emit('close')">
    <div class="space-y-6 font-body text-ink" aria-live="polite">
      <p class="text-xs font-medium uppercase tracking-[0.24em] text-gold">Hvala vam</p>
      <div class="space-y-3 leading-relaxed text-muted">
        <p>Vaš upit je uspješno poslan.</p>
        <p>Javit ćemo vam se telefonom ili e-mailom kako bismo potvrdili dostupnost i dogovorili dostavu.</p>
        <p>Do tada nas možete posjetiti i u butiku u Mepas Mallu u Mostaru.</p>
      </div>
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
