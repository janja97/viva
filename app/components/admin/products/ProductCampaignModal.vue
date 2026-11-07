<script setup lang="ts">
import type { Campaign } from '~/types/database'

const props = defineProps<{
  open: boolean
  count: number
  campaigns: Campaign[]
  loading?: boolean
  error?: string
}>()
const emit = defineEmits<{ close: []; apply: [campaignId: string | null] }>()

const campaignId = ref('')
const localError = ref('')

const options = computed(() => props.campaigns.map((campaign) => ({
  value: campaign.id,
  label: campaignOptionLabel(campaign),
})))

watch(() => props.open, (isOpen) => {
  if (isOpen) {
    campaignId.value = ''
    localError.value = ''
  }
})

function submit() {
  if (!campaignId.value) {
    localError.value = 'Odaberi kampanju.'
    return
  }
  emit('apply', campaignId.value)
}
</script>

<template>
  <BaseModal :open="open" title="Kampanja" @close="emit('close')">
    <form class="space-y-4" @submit.prevent="submit">
      <p class="text-sm text-stone-600">
        Kampanja vrijedi za {{ count }} odabranih proizvoda i zamjenjuje njihovu dosadašnju kampanju.
      </p>
      <p v-if="!campaigns.length" class="text-sm text-stone-500">
        Još nema kampanja. Napravi je na stranici <NuxtLink to="/admin/kampanje" class="text-primary-700 underline">Kampanje</NuxtLink>.
      </p>
      <BaseSelect
        v-else
        v-model="campaignId"
        label="Kampanja"
        :options="[{ value: '', label: 'Odaberi kampanju' }, ...options]"
        hint="Sniženje se prikazuje kupcima samo dok je kampanja aktivna."
      />
      <BaseAlert v-if="localError || error" type="error">{{ localError || error }}</BaseAlert>
      <div class="flex flex-col-reverse gap-2 sm:flex-row sm:justify-between">
        <BaseButton variant="secondary" :loading="loading" @click="emit('apply', null)">Makni iz kampanje</BaseButton>
        <div class="flex flex-col-reverse gap-2 sm:flex-row">
          <BaseButton variant="secondary" @click="emit('close')">Odustani</BaseButton>
          <BaseButton v-if="campaigns.length" type="submit" :loading="loading">Dodijeli</BaseButton>
        </div>
      </div>
    </form>
  </BaseModal>
</template>
