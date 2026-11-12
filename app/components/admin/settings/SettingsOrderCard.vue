<script setup lang="ts">
import type { OrderChannel, StoreSettingsInput } from '~/types/database'

// Kako kupac naručuje iz košarice (migracija 0035). Obrazac na webu i upiti ostaju spremni za kasnije.
const form = defineModel<StoreSettingsInput>({ required: true })

const OPTIONS: { value: OrderChannel; label: string; hint: string }[] = [
  {
    value: 'whatsapp',
    label: 'WhatsApp poruka',
    hint: 'Gumb u košarici otvara WhatsApp s popisom proizvoda, veličina i poveznica. Narudžbe ne stižu u Narudžbe u adminu.',
  },
  {
    value: 'web',
    label: 'Obrazac na webu',
    hint: 'Kupac upisuje podatke za dostavu, a narudžba stiže u Narudžbe u adminu.',
  },
]
</script>

<template>
  <AdminCard title="Narudžbe">
    <fieldset class="space-y-2">
      <legend class="sr-only">Kako kupci naručuju</legend>
      <label
        v-for="option in OPTIONS"
        :key="option.value"
        class="flex cursor-pointer items-start gap-3 border px-3 py-3"
        :class="form.order_channel === option.value ? 'border-primary-600 bg-primary-50' : 'border-primary-300'"
      >
        <input v-model="form.order_channel" type="radio" name="order-channel" :value="option.value" class="mt-0.5 size-4 accent-primary-600">
        <span>
          <span class="block text-sm font-medium text-stone-800">{{ option.label }}</span>
          <span class="mt-0.5 block text-xs text-stone-500">{{ option.hint }}</span>
        </span>
      </label>
    </fieldset>
    <BaseAlert v-if="form.order_channel === 'whatsapp' && !form.whatsapp.trim()" type="warning" class="mt-3">
      Upiši WhatsApp broj u kartici Kontakt. Dok ga nema, kupci naručuju preko obrasca na webu.
    </BaseAlert>
  </AdminCard>
</template>
