<script setup lang="ts">
import { Copy } from '@lucide/vue'

const props = defineProps<{ open: boolean; emails: string[] }>()
const emit = defineEmits<{ close: [] }>()

// Zarez i razmak razumiju Gmail, Outlook i ostali programi za e-mail.
const text = computed(() => props.emails.join(', '))
const copied = ref(false)

// Admin radi samo u pregledniku, pa je bez NUXT_PUBLIC_SITE_URL adresa ista kao adresa admina.
const { siteUrl } = useRuntimeConfig().public
const unsubscribeUrl = `${(siteUrl || window.location.origin).replace(/\/$/, '')}/odjava`

watch(() => props.open, () => { copied.value = false })

async function copy() {
  try {
    await navigator.clipboard.writeText(text.value)
    copied.value = true
  } catch {
    // Bez dopuštenja za međuspremnik adrese se mogu označiti i kopirati ručno.
    copied.value = false
  }
}
</script>

<template>
  <BaseModal :open="open" title="E-mailovi za BCC" wide @close="emit('close')">
    <div class="space-y-4">
      <p class="text-sm text-stone-600">
        {{ emails.length }} adresa, odvojenih zarezom. Zalijepi ih u polje BCC (skrivena kopija), kako primatelji ne bi vidjeli tuđe adrese.
      </p>
      <p class="text-sm text-stone-600">
        Odjavljeni nisu na popisu. Na dno svakog e-maila stavi poveznicu za odjavu, npr.
        <span class="font-medium text-stone-800">„Ne želite više primati naše e-mailove? Odjavite se: {{ unsubscribeUrl }}”</span>
      </p>
      <textarea readonly :value="text" rows="8" class="form-field font-mono text-xs" aria-label="E-mail adrese" @focus="($event.target as HTMLTextAreaElement).select()" />
      <BaseAlert v-if="copied" type="success">Adrese su kopirane.</BaseAlert>
      <div class="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
        <BaseButton variant="secondary" @click="emit('close')">Zatvori</BaseButton>
        <BaseButton :disabled="!emails.length" @click="copy">
          <Copy class="size-4" stroke-width="2" />
          Kopiraj sve
        </BaseButton>
      </div>
    </div>
  </BaseModal>
</template>
