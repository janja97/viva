<script setup lang="ts">
import type { StoreSettingsInput } from '~/types/database'

// Poštarina u KM. Isto pravilo koriste košarica i baza (shipping_for), pa vrijedi odmah i za nove upite.
const form = defineModel<StoreSettingsInput>({ required: true })

const asText = (value: number) => String(value)
const asNumber = (value: string) => Math.max(0, Number(value.replace(',', '.')) || 0)
</script>

<template>
  <AdminCard title="Poštarina">
    <div class="grid gap-4 sm:grid-cols-2">
      <BaseInput
        :model-value="asText(form.shipping_price)"
        label="Cijena poštarine (KM)"
        type="number"
        inputmode="decimal"
        :min="0"
        step="0.01"
        required
        @update:model-value="form.shipping_price = asNumber($event)"
      />
      <BaseInput
        :model-value="asText(form.free_shipping_above)"
        label="Besplatna za narudžbe veće od (KM)"
        type="number"
        inputmode="decimal"
        :min="0"
        step="0.01"
        required
        @update:model-value="form.free_shipping_above = asNumber($event)"
      />
    </div>
    <p class="mt-3 text-xs text-stone-500">
      Već poslane narudžbe zadržavaju poštarinu s kojom su poslane. Iznos besplatne dostave prikazuje se i na naslovnoj.
    </p>
  </AdminCard>
</template>
