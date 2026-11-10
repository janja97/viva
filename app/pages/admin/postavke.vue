<script setup lang="ts">
import type { StoreSettings, StoreSettingsInput } from '~/types/database'

definePageMeta({ layout: 'admin' })
usePageSeo({ title: 'Postavke', noindex: true })

// Postavke mijenjaju samo admin i super admin (RLS u migraciji 0029). Čitatelj stranicu ne vidi u izborniku.
const { can } = usePermissions()
const canWrite = computed(() => can('write'))
const { settings, save, refresh } = useStoreSettings()

const form = ref<StoreSettingsInput | null>(null)
const isSaving = ref(false)
const saveError = ref('')
const saved = ref(false)

function toForm({ id: _id, updated_at: _updatedAt, updated_by_email: _updatedBy, ...input }: StoreSettings): StoreSettingsInput {
  return structuredClone({ ...input, shipping_price: Number(input.shipping_price), free_shipping_above: Number(input.free_shipping_above) })
}

// Uvijek svježi podaci iz baze, pa se tek onda puni forma.
onMounted(async () => {
  await refresh()
  form.value = toForm(settings.value)
})

async function submit() {
  if (!form.value) return
  isSaving.value = true
  saveError.value = ''
  saved.value = false
  try {
    await save(form.value)
    form.value = toForm(settings.value)
    saved.value = true
  } catch (error) {
    // Provjere u bazi (migracija 0029) odbijaju neispravan telefon, e-mail, adresu mreže ili iznos.
    saveError.value = (error as { code?: string }).code === '23514'
      ? 'Neki podatak nije ispravan. Provjeri telefone, e-mail, adrese mreža (https://) i poštarinu.'
      : productErrorMessage(error)
  } finally {
    isSaving.value = false
  }
}

const updatedText = computed(() => {
  if (!settings.value.updated_at || !settings.value.updated_by_email) return ''
  const date = new Intl.DateTimeFormat('hr-HR', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(settings.value.updated_at))
  return `Zadnja izmjena: ${date}, ${settings.value.updated_by_email}`
})
</script>

<template>
  <div>
    <AdminPageHeader title="Postavke" description="Kontakt, društvene mreže, radno vrijeme, poštarina i obavijest na webu." />

    <BaseAlert v-if="!canWrite" type="warning" class="max-w-2xl">Postavke mogu mijenjati samo administratori.</BaseAlert>

    <p v-else-if="!form" class="text-sm text-stone-500">Učitavanje...</p>

    <form v-else class="max-w-3xl space-y-4" @submit.prevent="submit" @input="saved = false">
      <SettingsContactCard v-model="form" />
      <SettingsSocialCard v-model="form" />
      <SettingsHoursCard v-model="form" />
      <SettingsShippingCard v-model="form" />
      <SettingsAnnouncementCard v-model="form" />

      <div class="sticky bottom-0 -mx-4 flex flex-col gap-3 border-t border-primary-300 bg-primary-50 px-4 py-3 sm:mx-0 sm:flex-row sm:items-center sm:px-0">
        <BaseButton type="submit" :loading="isSaving">{{ isSaving ? 'Spremanje...' : 'Spremi postavke' }}</BaseButton>
        <p v-if="saved" class="text-sm text-emerald-700" role="status">Spremljeno. Promjene su odmah na webu.</p>
        <p v-else-if="updatedText" class="text-xs text-stone-500">{{ updatedText }}</p>
      </div>
      <BaseAlert v-if="saveError" type="error">{{ saveError }}</BaseAlert>
    </form>
  </div>
</template>
