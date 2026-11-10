<script setup lang="ts">
import { Mail, Trash2 } from '@lucide/vue'
import type { SubscriberRow } from '~/composables/useNewsletter'

definePageMeta({ layout: 'admin' })
usePageSeo({ title: 'Newsletter', noindex: true })

const { can } = usePermissions()
const { subscribers, isLoading, loadError, load, remove } = useNewsletter()

const canWrite = computed(() => can('write'))
const dateFormat = new Intl.DateTimeFormat('hr-HR', { dateStyle: 'short' })

const isBccOpen = ref(false)
// Abecedno, kako bi se adrese lakše pregledale prije slanja. Odjavljeni se ne uključuju.
const activeSubscribers = computed(() => subscribers.value.filter((subscriber) => !subscriber.unsubscribed_at))
const emails = computed(() => activeSubscribers.value.map((subscriber) => subscriber.email).sort((a, b) => a.localeCompare(b)))
const usedCount = computed(() => subscribers.value.filter((subscriber) => subscriber.orderNumbers.length).length)

const deleting = ref<SubscriberRow | null>(null)
const deleteError = ref('')
const isDeleting = ref(false)

async function confirmDelete() {
  if (!deleting.value) return
  isDeleting.value = true
  deleteError.value = ''
  try {
    await remove(deleting.value.id)
    deleting.value = null
  } catch (error) {
    deleteError.value = productErrorMessage(error)
  } finally {
    isDeleting.value = false
  }
}

onMounted(load)
</script>

<template>
  <div>
    <AdminPageHeader
      title="Newsletter"
      :description="isLoading ? undefined : `Pretplatnika: ${activeSubscribers.length}, odjavljenih: ${subscribers.length - activeSubscribers.length}. Kod za 10 % iskoristilo je ${usedCount}.`"
    >
      <BaseButton :disabled="!emails.length" @click="isBccOpen = true">
        <Mail class="size-4" stroke-width="2" />
        E-mailovi za BCC
      </BaseButton>
    </AdminPageHeader>

    <p v-if="isLoading && !subscribers.length" class="text-sm text-stone-500">Učitavanje...</p>
    <div v-else-if="loadError" class="space-y-3">
      <BaseAlert type="error">{{ loadError }}</BaseAlert>
      <BaseButton variant="secondary" @click="load">Pokušaj ponovno</BaseButton>
    </div>
    <p v-else-if="!subscribers.length" class="border border-dashed border-primary-300 bg-white px-4 py-12 text-center text-sm text-stone-500">
      Još nema pretplatnika.
    </p>
    <ul v-else class="divide-y divide-primary-200 border border-primary-300 bg-white">
      <li v-for="subscriber in subscribers" :key="subscriber.id" class="flex flex-wrap items-center gap-x-4 gap-y-1 px-4 py-3">
        <div class="min-w-0 flex-1">
          <p class="truncate text-sm font-medium" :class="subscriber.unsubscribed_at ? 'text-stone-400 line-through' : 'text-stone-900'">{{ subscriber.email }}</p>
          <p class="text-xs text-stone-500">Prijava {{ dateFormat.format(new Date(subscriber.created_at)) }}<template v-if="subscriber.unsubscribed_at"> · <span class="text-amber-700">odjava {{ dateFormat.format(new Date(subscriber.unsubscribed_at)) }}</span></template></p>
        </div>
        <div v-if="subscriber.code" class="text-right text-xs">
          <p class="flex items-center justify-end gap-2">
            <span class="font-mono text-sm text-stone-800">{{ subscriber.code.code }}</span>
            <PromoCodeStatusBadge :status="promoCodeStatus(subscriber.code)" />
          </p>
          <p class="mt-0.5 text-stone-500">
            <template v-if="subscriber.orderNumbers.length">
              Narudžba
              <NuxtLink
                v-for="number in subscriber.orderNumbers"
                :key="number"
                to="/admin/narudzbe"
                class="text-primary-700 hover:text-primary-900"
              >br. {{ number }}</NuxtLink>
            </template>
            <template v-else>Vrijedi do {{ dateFormat.format(new Date(subscriber.code.ends_at)) }}</template>
          </p>
        </div>
        <IconButton v-if="canWrite" :label="`Obriši: ${subscriber.email}`" danger @click="deleting = subscriber; deleteError = ''">
          <Trash2 class="size-4" stroke-width="1.75" />
        </IconButton>
      </li>
    </ul>

    <BccEmailsModal :open="isBccOpen" :emails="emails" @close="isBccOpen = false" />

    <ConfirmDialog
      :open="Boolean(deleting)"
      title="Obriši pretplatnika"
      confirm-label="Obriši"
      :loading="isDeleting"
      :error="deleteError"
      @close="deleting = null"
      @confirm="confirmDelete"
    >
      Sigurno želiš obrisati {{ deleting?.email }} s popisa? Obrisat će se i njegov promo kod. Ova radnja se ne može poništiti.
    </ConfirmDialog>
  </div>
</template>
