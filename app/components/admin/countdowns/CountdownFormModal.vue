<script setup lang="ts">
import type { Countdown, CountdownInput } from '~/types/database'

const props = defineProps<{
  open: boolean
  // Odbrojavanje koje se uređuje. Bez njega se stvara novo.
  countdown: Countdown | null
  loading?: boolean
  error?: string
}>()
const emit = defineEmits<{ close: []; save: [input: CountdownInput] }>()

const form = reactive({ title: '', message: '', link: '', startsAt: '', endsAt: '', isEnabled: false })
const localError = ref('')

watch(() => props.open, (isOpen) => {
  if (!isOpen) return
  localError.value = ''
  const countdown = props.countdown
  form.title = countdown?.title ?? ''
  form.message = countdown?.message ?? ''
  form.link = countdown?.link ?? ''
  form.startsAt = toDateTimeInput(countdown?.starts_at ?? null)
  form.endsAt = toDateTimeInput(countdown?.ends_at ?? null)
  form.isEnabled = countdown?.is_enabled ?? false
})

function validate() {
  if (form.title.trim().length < 2) return 'Upiši naziv, npr. Dan drame.'
  if (!form.startsAt || !form.endsAt) return 'Upiši početak i kraj.'
  if (new Date(form.endsAt) <= new Date(form.startsAt)) return 'Kraj mora biti nakon početka.'
  const link = form.link.trim()
  if (link && !link.startsWith('/') && !link.startsWith('https://')) return 'Poveznica mora počinjati s / (stranica na webu) ili s https://.'
  return ''
}

function submit() {
  localError.value = validate()
  if (localError.value) return
  emit('save', {
    title: form.title.trim(),
    message: form.message.trim(),
    link: form.link.trim() || null,
    starts_at: fromDateTimeInput(form.startsAt),
    ends_at: fromDateTimeInput(form.endsAt),
    is_enabled: form.isEnabled,
  })
}
</script>

<template>
  <BaseModal :open="open" :title="countdown ? 'Uredi odbrojavanje' : 'Novo odbrojavanje'" @close="emit('close')">
    <form class="space-y-4" @submit.prevent="submit">
      <BaseInput v-model="form.title" label="Naziv" :maxlength="60" hint="Kupci ga vide, npr. Dan drame ili Black Friday." required />
      <BaseInput v-model="form.message" label="Kratki tekst" :maxlength="120" hint="Neobavezno, npr. -20 % na sve haljine." />
      <div class="grid gap-4 sm:grid-cols-2">
        <BaseInput v-model="form.startsAt" label="Početak" type="datetime-local" required />
        <BaseInput v-model="form.endsAt" label="Kraj" type="datetime-local" required />
      </div>
      <BaseInput
        v-model="form.link"
        label="Poveznica"
        :maxlength="300"
        placeholder="/proizvodi?snizeno=1"
        hint="Neobavezno. Kamo vodi klik na oblačić, npr. /proizvodi?snizeno=1 ili /kategorija/haljine."
      />
      <BaseSwitch v-model="form.isEnabled" label="Uključeno" hint="Dok je uključeno, oblačić je na naslovnoj i odbrojava do početka, a zatim do kraja." />
      <p class="text-xs text-stone-500">Oblačić je samo obavijest. Sniženje i dalje postavljaš kroz kampanje ili promo kodove.</p>
      <BaseAlert v-if="localError || error" type="error">{{ localError || error }}</BaseAlert>
      <div class="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
        <BaseButton variant="secondary" @click="emit('close')">Odustani</BaseButton>
        <BaseButton type="submit" :loading="loading">Spremi</BaseButton>
      </div>
    </form>
  </BaseModal>
</template>
