<script setup lang="ts">
import type { PromoCodeInput } from '~/composables/usePromoCodes'
import type { PromoCode } from '~/types/database'

const props = defineProps<{
  open: boolean
  // Kod koji se uređuje. Bez njega se stvara novi.
  promoCode: PromoCode | null
  loading?: boolean
  error?: string
}>()
const emit = defineEmits<{ close: []; save: [input: PromoCodeInput] }>()

const form = reactive({ code: '', name: '', percent: '', startsAt: '', endsAt: '' })
const localError = ref('')

watch(() => props.open, (isOpen) => {
  if (!isOpen) return
  localError.value = ''
  const promoCode = props.promoCode
  form.code = promoCode?.code ?? ''
  form.name = promoCode?.name ?? ''
  form.percent = promoCode ? String(promoCode.discount_percent) : ''
  form.startsAt = toDateTimeInput(promoCode?.starts_at ?? new Date().toISOString())
  form.endsAt = toDateTimeInput(promoCode?.ends_at ?? null)
})

// Kod se uvijek sprema velikim slovima, a kupac ga smije upisati i malima.
const normalizedCode = computed(() => form.code.trim().toUpperCase())

function validate() {
  if (!/^[A-Z0-9-]{3,30}$/.test(normalizedCode.value)) return 'Kod ima 3 do 30 znakova: slova bez kvačica, brojke i crticu, npr. DRAMA10.'
  const percent = Number(form.percent)
  if (!Number.isInteger(percent) || percent < 1 || percent > 99) return 'Popust mora biti cijeli broj od 1 do 99.'
  if (!form.startsAt || !form.endsAt) return 'Upiši početak i kraj.'
  if (new Date(form.endsAt) <= new Date(form.startsAt)) return 'Kraj mora biti nakon početka.'
  return ''
}

function submit() {
  localError.value = validate()
  if (localError.value) return
  emit('save', {
    code: normalizedCode.value,
    name: form.name.trim() || null,
    discount_percent: Number(form.percent),
    starts_at: fromDateTimeInput(form.startsAt),
    ends_at: fromDateTimeInput(form.endsAt),
  })
}
</script>

<template>
  <BaseModal :open="open" :title="promoCode ? 'Uredi promo kod' : 'Novi promo kod'" @close="emit('close')">
    <form class="space-y-4" @submit.prevent="submit">
      <BaseInput v-model="form.code" label="Kod" :maxlength="30" hint="Ovo kupac upisuje u košarici, npr. DRAMA10." required />
      <BaseInput v-model="form.name" label="Naziv (neobavezno)" :maxlength="80" hint="Npr. Dan drame. Kupci ga ne vide." />
      <BaseInput
        v-model="form.percent"
        label="Popust (%)"
        type="number"
        inputmode="numeric"
        :min="1"
        :max="99"
        step="1"
        hint="Popust na iznos proizvoda u narudžbi."
        required
      />
      <div class="grid gap-4 sm:grid-cols-2">
        <BaseInput v-model="form.startsAt" label="Vrijedi od" type="datetime-local" required />
        <BaseInput v-model="form.endsAt" label="Vrijedi do" type="datetime-local" required />
      </div>
      <p class="text-xs text-stone-500">Kod vrijedi neograničeno puta unutar tog razdoblja.</p>
      <BaseAlert v-if="localError || error" type="error">{{ localError || error }}</BaseAlert>
      <div class="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
        <BaseButton variant="secondary" @click="emit('close')">Odustani</BaseButton>
        <BaseButton type="submit" :loading="loading">Spremi</BaseButton>
      </div>
    </form>
  </BaseModal>
</template>
