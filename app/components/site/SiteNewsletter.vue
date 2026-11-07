<script setup lang="ts">
const id = useId()
const email = ref('')
// Skriveno polje za botove (vidi server/api/newsletter.post.ts).
const website = ref('')
const message = ref('')
const isError = ref(false)
const isSending = ref(false)

async function onSubmit() {
  isSending.value = true
  message.value = ''
  isError.value = false
  try {
    await $fetch('/api/newsletter', { method: 'POST', body: { email: email.value, website: website.value } })
    message.value = 'Hvala na prijavi! Ako je ovo vaša prva prijava, kod za popust stiže na vaš e-mail za nekoliko minuta.'
    email.value = ''
  } catch (error) {
    isError.value = true
    message.value = (error as { data?: { message?: string } }).data?.message ?? 'Prijava trenutno nije moguća. Pokušajte ponovno kasnije.'
  } finally {
    isSending.value = false
  }
}
</script>

<template>
  <section aria-labelledby="naslov-newsletter" class="bg-champagne px-4 py-16 text-center sm:py-20">
    <h2 id="naslov-newsletter" class="font-display text-4xl font-normal lg:text-5xl">Budite prvi uz nove kolekcije</h2>
    <p class="mb-6 mt-2 text-muted">Prijavite se na newsletter i na e-mail dobijte kod za 10 % popusta na prvu narudžbu.</p>
    <form class="mx-auto flex max-w-xl flex-col gap-2 sm:flex-row" @submit.prevent="onSubmit">
      <label :for="id" class="sr-only">E-mail adresa</label>
      <input
        :id="id"
        v-model="email"
        type="email"
        name="email"
        required
        maxlength="200"
        autocomplete="email"
        placeholder="Vaša e-mail adresa"
        class="min-h-13 min-w-0 flex-1 border border-ink bg-ivory px-4 placeholder:text-muted"
      >
      <input v-model="website" type="text" name="website" tabindex="-1" autocomplete="off" aria-hidden="true" class="hidden">
      <button
        type="submit"
        :disabled="isSending"
        class="min-h-13 flex-none cursor-pointer border border-ink bg-ink px-8 text-xs font-medium uppercase tracking-[0.2em] text-white transition-colors hover:bg-transparent hover:text-ink disabled:cursor-wait disabled:opacity-60"
      >
        {{ isSending ? 'Slanje...' : 'Prijava' }}
      </button>
    </form>
    <p class="mx-auto mt-3 min-h-6 max-w-xl text-sm" :class="isError ? 'text-red-700' : 'text-ink'" role="status">{{ message }}</p>
    <p class="mx-auto mt-1 max-w-xl text-xs text-muted">Kod vrijedi 15 dana za jednu narudžbu. Prijavom pristajete na primanje e-mailova od nas, a odjavu možete zatražiti u svakom trenutku.</p>
  </section>
</template>
