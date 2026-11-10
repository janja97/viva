<script setup lang="ts">
import type { StoreSettingsInput } from '~/types/database'

// Kontakt na webu (footer, kontakt, "Posjetite nas") i u Googleovim podacima o trgovini.
const form = defineModel<StoreSettingsInput>({ required: true })

const phonePattern = '[0-9 +()/\\-]{6,30}'
const phoneHint = 'Npr. +387 36 123 456. Prazno se ne prikazuje.'
</script>

<template>
  <AdminCard title="Kontakt">
    <div class="grid gap-4 sm:grid-cols-2">
      <BaseInput v-model="form.phone" label="Telefon" type="tel" autocomplete="off" :pattern="phonePattern" :hint="phoneHint" />
      <BaseInput v-model="form.email" label="E-mail" type="email" autocomplete="off" :maxlength="200" hint="Prazno se ne prikazuje." />
      <BaseInput v-model="form.whatsapp" label="WhatsApp broj" type="tel" autocomplete="off" :pattern="phonePattern" hint="S pozivnim brojem države, npr. +387 63 123 456." />
      <BaseInput v-model="form.viber" label="Viber broj" type="tel" autocomplete="off" :pattern="phonePattern" hint="S pozivnim brojem države, npr. +387 63 123 456." />
    </div>
  </AdminCard>
</template>
