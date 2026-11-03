<script setup lang="ts">
const props = defineProps<{
  open: boolean
  count: number
  loading?: boolean
  error?: string
}>()
const emit = defineEmits<{ close: []; apply: [percent: number | null] }>()

const percent = ref('')
const localError = ref('')

watch(() => props.open, (isOpen) => {
  if (isOpen) {
    percent.value = ''
    localError.value = ''
  }
})

function submit() {
  const value = Number(percent.value)
  if (!Number.isInteger(value) || value < 1 || value > 99) {
    localError.value = 'Sniženje mora biti cijeli broj od 1 do 99.'
    return
  }
  localError.value = ''
  emit('apply', value)
}
</script>

<template>
  <BaseModal :open="open" title="Sniženje" @close="emit('close')">
    <form class="space-y-4" @submit.prevent="submit">
      <p class="text-sm text-stone-600">
        Postotak vrijedi za {{ count }} odabranih proizvoda i zamjenjuje njihovo dosadašnje sniženje.
      </p>
      <BaseInput
        v-model="percent"
        label="Sniženje (%)"
        type="number"
        inputmode="numeric"
        :min="1"
        step="1"
        hint="Upiši samo broj, npr. 20. Kupac vidi izračunatu cijenu i prekriženu redovnu."
        required
      />
      <BaseAlert v-if="localError || error" type="error">{{ localError || error }}</BaseAlert>
      <div class="flex flex-col-reverse gap-2 sm:flex-row sm:justify-between">
        <BaseButton variant="secondary" :loading="loading" @click="emit('apply', null)">Ukloni sniženje</BaseButton>
        <div class="flex flex-col-reverse gap-2 sm:flex-row">
          <BaseButton variant="secondary" @click="emit('close')">Odustani</BaseButton>
          <BaseButton type="submit" :loading="loading">Primijeni</BaseButton>
        </div>
      </div>
    </form>
  </BaseModal>
</template>
