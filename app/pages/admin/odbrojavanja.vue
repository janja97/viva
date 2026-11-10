<script setup lang="ts">
import { Plus } from '@lucide/vue'
import type { Countdown, CountdownInput } from '~/types/database'

definePageMeta({ layout: 'admin' })
usePageSeo({ title: 'Odbrojavanja', noindex: true })

const { can } = usePermissions()
const { countdowns, isLoading, loadError, load, save, setEnabled, remove } = useCountdowns()

const canWrite = computed(() => can('write'))
const isWorking = ref(false)
const actionError = ref('')

const isFormOpen = ref(false)
const editing = ref<Countdown | null>(null)
const formError = ref('')

const deleting = ref<Countdown | null>(null)
const deleteError = ref('')

function openForm(countdown: Countdown | null) {
  editing.value = countdown
  formError.value = ''
  isFormOpen.value = true
}

async function submitForm(input: CountdownInput) {
  isWorking.value = true
  formError.value = ''
  try {
    await save(input, editing.value?.id)
    isFormOpen.value = false
  } catch (error) {
    formError.value = productErrorMessage(error)
  } finally {
    isWorking.value = false
  }
}

async function toggle(countdown: Countdown) {
  isWorking.value = true
  actionError.value = ''
  try {
    await setEnabled(countdown.id, !countdown.is_enabled)
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
    <AdminPageHeader title="Odbrojavanja" description="Oblačić na naslovnoj koji odbrojava do akcije, npr. Dana drame.">
      <BaseButton v-if="canWrite" @click="openForm(null)">
        <Plus class="size-4" stroke-width="2" />
        Novo odbrojavanje
      </BaseButton>
    </AdminPageHeader>

    <BaseAlert v-if="actionError" type="error" class="mb-4">{{ actionError }}</BaseAlert>

    <p v-if="isLoading && !countdowns.length" class="text-sm text-stone-500">Učitavanje...</p>
    <div v-else-if="loadError" class="space-y-3">
      <BaseAlert type="error">{{ loadError }}</BaseAlert>
      <BaseButton variant="secondary" @click="load">Pokušaj ponovno</BaseButton>
    </div>
    <p v-else-if="!countdowns.length" class="border border-dashed border-primary-300 bg-white px-4 py-12 text-center text-sm text-stone-500">
      Još nema odbrojavanja.
    </p>
    <ul v-else class="divide-y divide-primary-200 border border-primary-300 bg-white">
      <li v-for="countdown in countdowns" :key="countdown.id">
        <CountdownRow
          :countdown="countdown"
          :can-write="canWrite"
          :loading="isWorking"
          @toggle="toggle(countdown)"
          @edit="openForm(countdown)"
          @delete="deleting = countdown; deleteError = ''"
        />
      </li>
    </ul>

    <p class="mt-4 max-w-2xl text-xs text-stone-500">
      Uključeno odbrojavanje do početka pokazuje „Počinje za”, a od početka do kraja „U tijeku” i „Završava za”. Nakon kraja samo nestane.
      Ako je uključeno više njih, na webu je ono koje najranije počinje. Kupci oblačić ne mogu zatvoriti.
    </p>

    <CountdownFormModal
      :open="isFormOpen"
      :countdown="editing"
      :loading="isWorking"
      :error="formError"
      @close="isFormOpen = false"
      @save="submitForm"
    />

    <ConfirmDialog
      :open="Boolean(deleting)"
      title="Obriši odbrojavanje"
      confirm-label="Obriši"
      :loading="isWorking"
      :error="deleteError"
      @close="deleting = null"
      @confirm="confirmDelete"
    >
      Sigurno želiš obrisati odbrojavanje „{{ deleting?.title }}”? Ova radnja se ne može poništiti.
    </ConfirmDialog>
  </div>
</template>
