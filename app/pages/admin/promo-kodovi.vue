<script setup lang="ts">
import { Pause, Pencil, Play, Plus, Trash2 } from '@lucide/vue'
import type { PromoCodeInput } from '~/composables/usePromoCodes'
import type { PromoCode } from '~/types/database'

definePageMeta({ layout: 'admin' })
usePageSeo({ title: 'Promo kodovi', noindex: true })

const { can } = usePermissions()
const { codes, isLoading, loadError, load, save, setActive, remove } = usePromoCodes()

const canWrite = computed(() => can('write'))
const dateFormat = new Intl.DateTimeFormat('hr-HR', { dateStyle: 'short', timeStyle: 'short' })
const isWorking = ref(false)
const actionError = ref('')

const isFormOpen = ref(false)
const editing = ref<PromoCode | null>(null)
const formError = ref('')

const deleting = ref<PromoCode | null>(null)
const deleteError = ref('')

function openForm(promoCode: PromoCode | null) {
  editing.value = promoCode
  formError.value = ''
  isFormOpen.value = true
}

// Isti kod ne smije postojati dvaput (ni među kodovima pretplatnika).
function saveErrorMessage(error: unknown) {
  return (error as { code?: string }).code === '23505' ? 'Taj kod već postoji. Upiši drugi.' : productErrorMessage(error)
}

async function submitForm(input: PromoCodeInput) {
  isWorking.value = true
  formError.value = ''
  try {
    await save(input, editing.value?.id)
    isFormOpen.value = false
  } catch (error) {
    formError.value = saveErrorMessage(error)
  } finally {
    isWorking.value = false
  }
}

async function toggleActive(promoCode: PromoCode) {
  isWorking.value = true
  actionError.value = ''
  try {
    await setActive(promoCode.id, !promoCode.is_active)
  } catch (error) {
    actionError.value = productErrorMessage(error)
  } finally {
    isWorking.value = false
  }
}

async function confirmDelete() {
  if (!deleting.value) return
  isWorking.value = true
  deleteError.value = ''
  try {
    await remove(deleting.value.id)
    deleting.value = null
  } catch (error) {
    deleteError.value = productErrorMessage(error)
  } finally {
    isWorking.value = false
  }
}

onMounted(load)
</script>

<template>
  <div>
    <AdminPageHeader title="Promo kodovi" description="Vlastiti kodovi, npr. za Dan drame. Vrijede više puta, od početka do kraja. Kodove pretplatnika vidiš na stranici Newsletter.">
      <BaseButton v-if="canWrite" @click="openForm(null)">
        <Plus class="size-4" stroke-width="2" />
        Novi promo kod
      </BaseButton>
    </AdminPageHeader>

    <BaseAlert v-if="actionError" type="error" class="mb-4">{{ actionError }}</BaseAlert>

    <p v-if="isLoading && !codes.length" class="text-sm text-stone-500">Učitavanje...</p>
    <div v-else-if="loadError" class="space-y-3">
      <BaseAlert type="error">{{ loadError }}</BaseAlert>
      <BaseButton variant="secondary" @click="load">Pokušaj ponovno</BaseButton>
    </div>
    <p v-else-if="!codes.length" class="border border-dashed border-primary-300 bg-white px-4 py-12 text-center text-sm text-stone-500">
      Još nema promo kodova.
    </p>
    <ul v-else class="divide-y divide-primary-200 border border-primary-300 bg-white">
      <li v-for="promoCode in codes" :key="promoCode.id" class="flex flex-wrap items-center gap-x-4 gap-y-2 px-4 py-3">
        <span class="w-14 shrink-0 font-display text-2xl text-red-700">-{{ promoCode.discount_percent }}%</span>
        <div class="min-w-0 flex-1">
          <p class="flex flex-wrap items-center gap-2">
            <span class="font-mono text-sm font-medium text-stone-900">{{ promoCode.code }}</span>
            <PromoCodeStatusBadge :status="promoCodeStatus(promoCode)" />
            <span v-if="promoCode.name" class="text-sm text-stone-500">{{ promoCode.name }}</span>
          </p>
          <p class="text-xs text-stone-500">
            {{ dateFormat.format(new Date(promoCode.starts_at)) }} – {{ dateFormat.format(new Date(promoCode.ends_at)) }} · iskorišten {{ promoCode.used_count }} puta
          </p>
        </div>
        <div v-if="canWrite" class="flex items-center">
          <IconButton :label="promoCode.is_active ? `Pauziraj: ${promoCode.code}` : `Nastavi: ${promoCode.code}`" :disabled="isWorking" @click="toggleActive(promoCode)">
            <Pause v-if="promoCode.is_active" class="size-4" stroke-width="1.75" />
            <Play v-else class="size-4" stroke-width="1.75" />
          </IconButton>
          <IconButton :label="`Uredi: ${promoCode.code}`" @click="openForm(promoCode)">
            <Pencil class="size-4" stroke-width="1.75" />
          </IconButton>
          <IconButton :label="`Obriši: ${promoCode.code}`" danger @click="deleting = promoCode; deleteError = ''">
            <Trash2 class="size-4" stroke-width="1.75" />
          </IconButton>
        </div>
      </li>
    </ul>

    <PromoCodeFormModal
      :open="isFormOpen"
      :promo-code="editing"
      :loading="isWorking"
      :error="formError"
      @close="isFormOpen = false"
      @save="submitForm"
    />

    <ConfirmDialog
      :open="Boolean(deleting)"
      title="Obriši promo kod"
      confirm-label="Obriši"
      :loading="isWorking"
      :error="deleteError"
      @close="deleting = null"
      @confirm="confirmDelete"
    >
      Sigurno želiš obrisati promo kod {{ deleting?.code }}? Kupci ga više neće moći upisati, a narudžbe s njim ostaju. Ova radnja se ne može poništiti.
    </ConfirmDialog>
  </div>
</template>
