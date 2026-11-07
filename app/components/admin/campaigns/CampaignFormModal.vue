<script setup lang="ts">
import type { CampaignInput } from '~/composables/useCampaigns'
import type { Campaign, CampaignKind } from '~/types/database'

const props = defineProps<{
  open: boolean
  // Kampanja koja se uređuje. Bez nje se stvara nova.
  campaign: Campaign | null
  loading?: boolean
  error?: string
}>()
const emit = defineEmits<{ close: []; save: [input: CampaignInput] }>()

const KIND_OPTIONS: { value: CampaignKind; label: string }[] = [
  { value: 'permanent', label: 'Trajna (traje dok je ne pauziraš)' },
  { value: 'temporary', label: 'Privremena (od – do)' },
]

const form = reactive({ name: '', percent: '', kind: 'permanent' as CampaignKind, startsAt: '', endsAt: '' })
const localError = ref('')

watch(() => props.open, (isOpen) => {
  if (!isOpen) return
  localError.value = ''
  const campaign = props.campaign
  form.name = campaign?.name ?? ''
  form.percent = campaign ? String(campaign.discount_percent) : ''
  form.kind = campaign?.kind ?? 'permanent'
  form.startsAt = toDateTimeInput(campaign?.starts_at ?? null)
  form.endsAt = toDateTimeInput(campaign?.ends_at ?? null)
})

function validate() {
  if (!form.name.trim()) return 'Upiši naziv kampanje.'
  const percent = Number(form.percent)
  if (!Number.isInteger(percent) || percent < 1 || percent > 99) return 'Sniženje mora biti cijeli broj od 1 do 99.'
  if (form.kind === 'temporary') {
    if (!form.startsAt || !form.endsAt) return 'Upiši početak i kraj kampanje.'
    if (new Date(form.endsAt) <= new Date(form.startsAt)) return 'Kraj mora biti nakon početka.'
  }
  return ''
}

function submit() {
  localError.value = validate()
  if (localError.value) return
  const isTemporary = form.kind === 'temporary'
  emit('save', {
    name: form.name.trim(),
    discount_percent: Number(form.percent),
    kind: form.kind,
    starts_at: isTemporary ? fromDateTimeInput(form.startsAt) : null,
    ends_at: isTemporary ? fromDateTimeInput(form.endsAt) : null,
  })
}
</script>

<template>
  <BaseModal :open="open" :title="campaign ? 'Uredi kampanju' : 'Nova kampanja'" @close="emit('close')">
    <form class="space-y-4" @submit.prevent="submit">
      <BaseInput v-model="form.name" label="Naziv" :maxlength="80" hint="Npr. Zimsko sniženje ili Black Friday. Kupci ga ne vide." required />
      <BaseInput
        v-model="form.percent"
        label="Sniženje (%)"
        type="number"
        inputmode="numeric"
        :min="1"
        :max="99"
        step="1"
        hint="Upiši samo broj, npr. 20."
        required
      />
      <BaseSelect v-model="form.kind" label="Vrsta" :options="KIND_OPTIONS" />
      <div v-if="form.kind === 'temporary'" class="grid gap-4 sm:grid-cols-2">
        <BaseInput v-model="form.startsAt" label="Početak" type="datetime-local" required />
        <BaseInput v-model="form.endsAt" label="Kraj" type="datetime-local" required />
      </div>
      <p class="text-xs text-stone-500">Promjena postotka, datuma ili pauze odmah vrijedi za sve proizvode u kampanji.</p>
      <BaseAlert v-if="localError || error" type="error">{{ localError || error }}</BaseAlert>
      <div class="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
        <BaseButton variant="secondary" @click="emit('close')">Odustani</BaseButton>
        <BaseButton type="submit" :loading="loading">Spremi</BaseButton>
      </div>
    </form>
  </BaseModal>
</template>
