<script setup lang="ts">
import { Pause, Play, Plus } from '@lucide/vue'
import type { CampaignInput } from '~/composables/useCampaigns'
import type { Campaign } from '~/types/database'

definePageMeta({ layout: 'admin' })
usePageSeo({ title: 'Kampanje', noindex: true })

const { can } = usePermissions()
const { campaigns, productCounts, isLoading, loadError, load, save, setPaused, remove } = useCampaigns()

const canWrite = computed(() => can('write'))
const isWorking = ref(false)
const actionError = ref('')

const isFormOpen = ref(false)
const editing = ref<Campaign | null>(null)
const formError = ref('')

const deleting = ref<Campaign | null>(null)
const deleteError = ref('')

// "Pauziraj sve" djeluje samo na kampanje koje nisu završene.
const runningIds = computed(() => campaigns.value.filter((campaign) => !campaign.is_paused && campaignStatus(campaign) !== 'ended').map((campaign) => campaign.id))
const pausedIds = computed(() => campaigns.value.filter((campaign) => campaign.is_paused).map((campaign) => campaign.id))

function openForm(campaign: Campaign | null) {
  editing.value = campaign
  formError.value = ''
  isFormOpen.value = true
}

async function submitForm(input: CampaignInput) {
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

async function pause(ids: string[], isPaused: boolean) {
  isWorking.value = true
  actionError.value = ''
  try {
    await setPaused(ids, isPaused)
  } catch (error) {
    actionError.value = productErrorMessage(error)
  } finally {
    isWorking.value = false
  }
}

function askDelete(campaign: Campaign) {
  deleteError.value = ''
  deleting.value = campaign
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
    <AdminPageHeader title="Kampanje" description="Sniženja za više proizvoda. Proizvode dodjeljuješ kampanji na popisu proizvoda.">
      <div v-if="canWrite" class="flex flex-wrap gap-2">
        <BaseButton v-if="runningIds.length" variant="secondary" :loading="isWorking" @click="pause(runningIds, true)">
          <Pause class="size-4" stroke-width="2" />
          Pauziraj sve
        </BaseButton>
        <BaseButton v-if="pausedIds.length" variant="secondary" :loading="isWorking" @click="pause(pausedIds, false)">
          <Play class="size-4" stroke-width="2" />
          Nastavi sve
        </BaseButton>
        <BaseButton @click="openForm(null)">
          <Plus class="size-4" stroke-width="2" />
          Nova kampanja
        </BaseButton>
      </div>
    </AdminPageHeader>

    <BaseAlert v-if="actionError" type="error" class="mb-4">{{ actionError }}</BaseAlert>

    <p v-if="isLoading && !campaigns.length" class="text-sm text-stone-500">Učitavanje...</p>
    <div v-else-if="loadError" class="space-y-3">
      <BaseAlert type="error">{{ loadError }}</BaseAlert>
      <BaseButton variant="secondary" @click="load">Pokušaj ponovno</BaseButton>
    </div>
    <p v-else-if="!campaigns.length" class="border border-dashed border-primary-300 bg-white px-4 py-12 text-center text-sm text-stone-500">
      Još nema kampanja.
    </p>
    <ul v-else class="divide-y divide-primary-200 border border-primary-300 bg-white">
      <li v-for="campaign in campaigns" :key="campaign.id">
        <CampaignRow
          :campaign="campaign"
          :product-count="productCounts[campaign.id] ?? 0"
          :can-write="canWrite"
          :loading="isWorking"
          @toggle-pause="pause([campaign.id], !campaign.is_paused)"
          @edit="openForm(campaign)"
          @delete="askDelete(campaign)"
        />
      </li>
    </ul>

    <p class="mt-4 max-w-2xl text-xs text-stone-500">
      Trajna kampanja vrijedi dok je ne pauziraš. Privremena vrijedi samo između početka i kraja, a cijene se same mijenjaju u roku od minute.
      Pauzirana ili završena kampanja ostaje dodijeljena proizvodima, pa se sniženje vraća čim je ponovno pokreneš.
    </p>

    <CampaignFormModal
      :open="isFormOpen"
      :campaign="editing"
      :loading="isWorking"
      :error="formError"
      @close="isFormOpen = false"
      @save="submitForm"
    />

    <ConfirmDialog
      :open="Boolean(deleting)"
      title="Obriši kampanju"
      confirm-label="Obriši"
      :loading="isWorking"
      :error="deleteError"
      @close="deleting = null"
      @confirm="confirmDelete"
    >
      Sigurno želiš obrisati kampanju „{{ deleting?.name }}”? Proizvodi u njoj ostaju, ali gube sniženje. Ova radnja se ne može poništiti.
    </ConfirmDialog>
  </div>
</template>
