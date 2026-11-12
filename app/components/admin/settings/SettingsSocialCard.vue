<script setup lang="ts">
import type { StoreSettingsInput } from '~/types/database'

// Profili na društvenim mrežama: footer i sameAs u Googleovim podacima o trgovini.
const form = defineModel<StoreSettingsInput>({ required: true })
</script>

<template>
  <AdminCard title="Društvene mreže">
    <div class="space-y-4">
      <BaseInput v-model="form.instagram_url" label="Instagram" type="url" pattern="https://.*" :maxlength="300" placeholder="https://www.instagram.com/..." />
      <BaseInput v-model="form.facebook_url" label="Facebook" type="url" pattern="https://.*" :maxlength="300" placeholder="https://www.facebook.com/..." />
      <p class="text-xs text-stone-500">Upiši punu adresu profila koja počinje s https://. Prazno se ne prikazuje.</p>
    </div>
  </AdminCard>
</template>
