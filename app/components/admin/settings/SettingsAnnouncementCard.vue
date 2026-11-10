<script setup lang="ts">
import type { StoreSettingsInput } from '~/types/database'

// Obavijest u tamnoj traci na vrhu weba. Dok je isključena, traka prikazuje zadani tekst.
const form = defineModel<StoreSettingsInput>({ required: true })
</script>

<template>
  <AdminCard title="Obavijest na vrhu weba">
    <div class="space-y-4">
      <BaseSwitch v-model="form.announcement_enabled" label="Prikaži obavijest" hint="Zamjenjuje zadani tekst u traci iznad izbornika." />
      <BaseInput
        v-model="form.announcement_text"
        label="Tekst obavijesti"
        :maxlength="160"
        :required="form.announcement_enabled"
        placeholder="Npr. Za praznike radimo do 15 h"
        hint="Najviše 160 znakova. Na mobitelu neka bude kratko."
      />
      <p v-if="form.announcement_text.trim()" class="bg-primary-950 px-4 py-2 text-center text-[11px] uppercase tracking-[0.16em] text-white" aria-label="Pregled obavijesti">
        {{ form.announcement_text.trim() }}
      </p>
    </div>
  </AdminCard>
</template>
