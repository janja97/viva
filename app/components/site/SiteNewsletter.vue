<script setup lang="ts">
const id = useId()
const message = ref('')

// Prijave se još nigdje ne spremaju, pa adresa ne izlazi iz preglednika.
function onSubmit() {
  message.value = 'Prijave na newsletter otvaramo uskoro.'
}
</script>

<template>
  <section aria-labelledby="naslov-newsletter" class="hidden bg-champagne px-4 py-20 text-center sm:block">
    <h2 id="naslov-newsletter" class="font-display text-4xl font-normal lg:text-5xl">Budite prvi uz nove kolekcije</h2>
    <p class="mb-6 mt-2 text-muted">Pozivnice na privatne večeri u butiku i rani pristup sniženjima.</p>
    <form class="mx-auto flex max-w-xl gap-2" @submit.prevent="onSubmit">
      <label :for="id" class="sr-only">E-mail adresa</label>
      <input
        :id="id"
        type="email"
        name="email"
        required
        autocomplete="email"
        placeholder="Vaša e-mail adresa"
        class="min-h-13 min-w-0 flex-1 border border-ink bg-ivory px-4 placeholder:text-muted"
      >
      <button type="submit" class="min-h-13 flex-none cursor-pointer border border-ink bg-ink px-8 text-xs font-medium uppercase tracking-[0.2em] text-white transition-colors hover:bg-transparent hover:text-ink">
        Prijava
      </button>
    </form>
    <p class="mt-3 min-h-6 text-sm" role="status">{{ message }}</p>
  </section>
</template>
