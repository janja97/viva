<script setup lang="ts">
// Odjava s newslettera. Iz e-maila s kodom dolazi s osobnim tokenom (?token=), a inače se upisuje adresa
// (npr. iz e-mailova poslanih kroz BCC). Odjava se uvijek potvrđuje gumbom, jer skeneri poveznica
// u e-mail programima otvaraju poveznice sami. Odgovor je isti i za nepoznatu adresu.
usePageSeo({
  title: 'Odjava s newslettera',
  description: 'Odjavite se s newslettera i više nećete primati naše e-mailove.',
  noindex: true,
})

const route = useRoute()
const supabase = useSupabase()
const token = computed(() => (typeof route.query.token === 'string' ? route.query.token : ''))

const email = ref('')
const isSending = ref(false)
const isDone = ref(false)
const errorMessage = ref('')
const inputId = useId()

async function unsubscribe() {
  isSending.value = true
  errorMessage.value = ''
  const { error } = token.value
    ? await supabase.rpc('newsletter_unsubscribe', { p_token: token.value })
    : await supabase.rpc('newsletter_unsubscribe_email', { p_email: email.value.trim() })
  isSending.value = false
  if (error) {
    console.error(error)
    errorMessage.value = 'Odjava trenutno nije uspjela. Pokušajte ponovno ili nam se javite e-mailom.'
    return
  }
  isDone.value = true
}

const buttonClass = 'min-h-13 flex-none cursor-pointer border border-ink bg-ink px-8 text-xs font-medium uppercase tracking-[0.2em] text-white transition-colors hover:bg-transparent hover:text-ink disabled:cursor-wait disabled:opacity-60'
</script>

<template>
  <section class="mx-auto max-w-xl px-4 py-16 text-center sm:px-6 sm:py-24">
    <h1 class="font-display text-4xl font-normal leading-tight sm:text-5xl">Odjava s newslettera</h1>

    <div v-if="isDone" role="status" class="mt-6 space-y-6">
      <p class="text-muted">Odjavljeni ste i više vam nećemo slati e-mailove. Ako se predomislite, ponovno se prijavite u dnu stranice.</p>
      <NuxtLink to="/" class="inline-flex min-h-11 items-center text-xs font-medium uppercase tracking-[0.2em] text-gold hover:text-ink">Na naslovnu</NuxtLink>
    </div>

    <template v-else-if="token">
      <p class="mb-8 mt-4 text-muted">Potvrdite da više ne želite primati naše e-mailove.</p>
      <button type="button" :class="buttonClass" :disabled="isSending" @click="unsubscribe">
        {{ isSending ? 'Odjava...' : 'Odjavi me' }}
      </button>
    </template>

    <template v-else>
      <p class="mb-8 mt-4 text-muted">Upišite adresu na koju primate naše e-mailove.</p>
      <form class="flex flex-col gap-2 sm:flex-row" @submit.prevent="unsubscribe">
        <label :for="inputId" class="sr-only">E-mail adresa</label>
        <input
          :id="inputId"
          v-model="email"
          type="email"
          required
          maxlength="200"
          autocomplete="email"
          placeholder="Vaša e-mail adresa"
          class="min-h-13 min-w-0 flex-1 border border-ink bg-ivory px-4 placeholder:text-muted"
        >
        <button type="submit" :class="buttonClass" :disabled="isSending">
          {{ isSending ? 'Odjava...' : 'Odjavi me' }}
        </button>
      </form>
    </template>

    <p v-if="errorMessage" class="mt-4 text-sm text-red-700" role="alert">{{ errorMessage }}</p>
  </section>
</template>
