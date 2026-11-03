<script setup lang="ts">
withDefaults(defineProps<{
  open: boolean
  title: string
  confirmLabel: string
  variant?: 'primary' | 'danger'
  loading?: boolean
  error?: string
}>(), {
  variant: 'danger',
})
const emit = defineEmits<{ close: []; confirm: [] }>()
</script>

<template>
  <BaseModal :open="open" :title="title" @close="emit('close')">
    <div class="space-y-4">
      <p class="text-sm text-stone-600"><slot /></p>
      <BaseAlert v-if="error" type="error">{{ error }}</BaseAlert>
      <div class="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
        <BaseButton variant="secondary" @click="emit('close')">Odustani</BaseButton>
        <BaseButton :variant="variant" :loading="loading" @click="emit('confirm')">{{ confirmLabel }}</BaseButton>
      </div>
    </div>
  </BaseModal>
</template>
