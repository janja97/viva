<script setup lang="ts">
import type { InquiryCustomer } from '~/composables/useCart'

defineProps<{ loading?: boolean; error?: string }>()
const emit = defineEmits<{ submit: [customer: InquiryCustomer]; cancel: [] }>()

const form = reactive<InquiryCustomer>({ name: '', phone: '', address: '', postal_code: '', city: '', email: '', note: '' })
const consent = ref(false)

const labelClass = 'mb-1.5 block text-xs font-medium uppercase tracking-[0.16em]'
const optionalClass = 'font-normal normal-case tracking-normal text-muted'
const fieldClass = 'block min-h-12 w-full border border-line bg-white px-3 py-2 text-base text-ink focus:border-ink focus:outline-none'
</script>

<template>
  <form class="space-y-5 font-body text-ink" @submit.prevent="emit('submit', { ...form })">
    <div>
      <label for="narudzba-ime" :class="labelClass">Ime i prezime</label>
      <input id="narudzba-ime" v-model="form.name" :class="fieldClass" autocomplete="name" minlength="2" maxlength="100" required>
    </div>
    <div>
      <label for="narudzba-telefon" :class="labelClass">Telefon</label>
      <input id="narudzba-telefon" v-model="form.phone" :class="fieldClass" type="tel" autocomplete="tel" inputmode="tel" minlength="6" maxlength="30" required>
    </div>
    <div>
      <label for="narudzba-adresa" :class="labelClass">Adresa</label>
      <input id="narudzba-adresa" v-model="form.address" :class="fieldClass" autocomplete="street-address" minlength="3" maxlength="200" required>
    </div>
    <div class="grid grid-cols-[minmax(0,2fr)_minmax(0,3fr)] gap-3">
      <div>
        <label for="narudzba-postanski" :class="labelClass">Poštanski broj</label>
        <input id="narudzba-postanski" v-model="form.postal_code" :class="fieldClass" autocomplete="postal-code" inputmode="numeric" pattern="[0-9]{5}" maxlength="5" required>
      </div>
      <div>
        <label for="narudzba-grad" :class="labelClass">Grad</label>
        <input id="narudzba-grad" v-model="form.city" :class="fieldClass" autocomplete="address-level2" minlength="2" maxlength="100" required>
      </div>
    </div>
    <div>
      <label for="narudzba-email" :class="labelClass">E-mail <span :class="optionalClass">(neobavezno)</span></label>
      <input id="narudzba-email" v-model="form.email" :class="fieldClass" type="email" autocomplete="email" maxlength="200">
    </div>
    <div>
      <label for="narudzba-napomena" :class="labelClass">Napomena <span :class="optionalClass">(neobavezno)</span></label>
      <textarea id="narudzba-napomena" v-model="form.note" :class="fieldClass" rows="3" maxlength="2000" />
    </div>

    <label class="flex cursor-pointer items-start gap-3 text-sm text-muted">
      <input v-model="consent" type="checkbox" class="mt-1 size-4 flex-none accent-ink" required>
      Slažem se da me trgovina kontaktira telefonom ili e-mailom u vezi s ovom narudžbom.
    </label>

    <p v-if="error" role="alert" class="text-sm text-red-700">{{ error }}</p>

    <div class="flex flex-col gap-2 sm:flex-row-reverse">
      <button
        type="submit"
        :disabled="loading"
        class="inline-flex min-h-13 flex-1 items-center justify-center border border-ink bg-ink px-8 text-xs font-medium uppercase tracking-[0.2em] text-white transition-colors hover:bg-transparent hover:text-ink disabled:cursor-wait disabled:opacity-70"
      >
        {{ loading ? 'Slanje...' : 'Pošalji upit' }}
      </button>
      <button
        type="button"
        class="inline-flex min-h-13 items-center justify-center border border-line px-8 text-xs font-medium uppercase tracking-[0.2em] transition-colors hover:border-ink"
        @click="emit('cancel')"
      >
        Odustani
      </button>
    </div>
  </form>
</template>
