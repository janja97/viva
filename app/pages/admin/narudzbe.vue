<script setup lang="ts">
import { ChevronRight } from '@lucide/vue'
import type { InquiryStatus } from '~/types/database'

definePageMeta({ layout: 'admin' })
usePageSeo({ title: 'Narudžbe', noindex: true })

const { can } = usePermissions()
const { rows, total, page, pageCount, status, isLoading, loadError, load, setStatus, remove } = useInquiries()
const { refresh: refreshNewCount } = useNewInquiries()

const canWrite = computed(() => can('write'))
// Brisati smije samo super admin (RLS, migracija 0023).
const canDelete = computed(() => can('delete_inquiries'))
const openId = ref<string | null>(null)
const opened = computed(() => rows.value.find((row) => row.id === openId.value) ?? null)
const deleting = ref<{ id: string; number: number } | null>(null)
const isWorking = ref(false)
const actionError = ref('')

const tabs = [{ value: '' as const, label: 'Svi' }, ...INQUIRY_STATUSES]
const dateFormat = new Intl.DateTimeFormat('hr-HR', { dateStyle: 'short', timeStyle: 'short' })

function showStatus(value: InquiryStatus | '') {
  status.value = value
  page.value = 0
  load()
}

// Oblačići u gornjoj traci vode ovamo s odabranim statusom, npr. ?status=new.
const route = useRoute()
const statusFromQuery = () => {
  const value = route.query.status
  return INQUIRY_STATUSES.some((item) => item.value === value) ? (value as InquiryStatus) : ''
}
status.value = statusFromQuery()
watch(() => route.query.status, () => showStatus(statusFromQuery()))

function goToPage(target: number) {
  page.value = target
  load()
}

function open(id: string) {
  actionError.value = ''
  openId.value = id
}

async function onStatus(next: InquiryStatus) {
  if (!opened.value) return
  isWorking.value = true
  actionError.value = ''
  try {
    await setStatus(opened.value.id, next)
    await refreshNewCount()
  } catch (error) {
    actionError.value = productErrorMessage(error)
  } finally {
    isWorking.value = false
  }
}

function askDelete() {
  if (!opened.value) return
  deleting.value = { id: opened.value.id, number: opened.value.number }
  openId.value = null
}

async function confirmDelete() {
  if (!deleting.value) return
  isWorking.value = true
  actionError.value = ''
  try {
    await remove(deleting.value.id)
    deleting.value = null
    await Promise.all([load(), refreshNewCount()])
  } catch (error) {
    actionError.value = productErrorMessage(error)
  } finally {
    isWorking.value = false
  }
}

onMounted(load)
</script>

<template>
  <div>
    <AdminPageHeader title="Narudžbe" :description="`Narudžbe kupaca iz košarice. Broj narudžbi: ${total}`" />

    <div class="mb-4 flex overflow-x-auto border-b border-primary-300 [scrollbar-width:none]">
      <button
        v-for="tab in tabs"
        :key="tab.value"
        type="button"
        :aria-pressed="status === tab.value"
        class="-mb-px min-h-11 shrink-0 cursor-pointer border-b-2 px-4 text-sm font-medium transition-colors sm:min-h-9"
        :class="status === tab.value ? 'border-primary-700 text-stone-900' : 'border-transparent text-stone-500 hover:text-stone-800'"
        @click="navigateTo({ query: { status: tab.value || undefined } })"
      >
        {{ tab.label }}
      </button>
    </div>

    <div v-if="loadError" class="space-y-3">
      <BaseAlert type="error">{{ loadError }}</BaseAlert>
      <BaseButton variant="secondary" @click="load">Pokušaj ponovno</BaseButton>
    </div>
    <p v-else-if="isLoading && !rows.length" class="text-sm text-stone-500">Učitavanje...</p>
    <p v-else-if="!rows.length" class="rounded-xl border border-dashed border-primary-300 bg-white px-4 py-12 text-center text-sm text-stone-500">
      Nema narudžbi.
    </p>
    <template v-else>
      <ul class="divide-y divide-primary-200 rounded-xl border border-primary-300 bg-white shadow-sm">
        <li v-for="inquiry in rows" :key="inquiry.id">
          <button type="button" class="flex w-full cursor-pointer items-center gap-3 px-4 py-3 text-left hover:bg-primary-50" @click="open(inquiry.id)">
            <span class="min-w-0 flex-1">
              <span class="flex flex-wrap items-center gap-2">
                <span class="text-sm font-medium">#{{ inquiry.number }} · {{ inquiry.customer_name }}</span>
                <InquiryStatusBadge :status="inquiry.status" />
              </span>
              <span class="block truncate text-xs text-stone-500">
                {{ dateFormat.format(new Date(inquiry.created_at)) }} · {{ inquiry.phone }} · {{ inquiry.inquiry_items.reduce((sum, item) => sum + item.quantity, 0) }} kom.
              </span>
              <span v-if="inquiry.status_changed_at" class="block truncate text-xs text-stone-500">
                Zadnja promjena: {{ inquiry.status_changed_by_email ?? 'nepoznat korisnik' }}, {{ dateFormat.format(new Date(inquiry.status_changed_at)) }}
              </span>
            </span>
            <span class="shrink-0 text-sm font-semibold">{{ formatPrice(Number(inquiry.total)) }}</span>
            <ChevronRight class="size-4 shrink-0 text-stone-400" stroke-width="1.75" />
          </button>
        </li>
      </ul>

      <nav v-if="pageCount > 1" aria-label="Stranice" class="mt-4 flex items-center justify-between gap-3">
        <BaseButton variant="secondary" :loading="page === 0" @click="goToPage(page - 1)">Prethodna</BaseButton>
        <span class="text-sm text-stone-600">{{ page + 1 }} / {{ pageCount }}</span>
        <BaseButton variant="secondary" :loading="page >= pageCount - 1" @click="goToPage(page + 1)">Sljedeća</BaseButton>
      </nav>
    </template>

    <InquiryDetailModal
      :inquiry="opened"
      :can-write="canWrite"
      :can-delete="canDelete"
      :loading="isWorking"
      :error="actionError"
      @close="openId = null"
      @status="onStatus"
      @delete="askDelete"
    />

    <ConfirmDialog
      :open="Boolean(deleting)"
      title="Obriši narudžbu"
      confirm-label="Obriši"
      :loading="isWorking"
      :error="actionError"
      @close="deleting = null"
      @confirm="confirmDelete"
    >
      Sigurno želiš obrisati narudžbu br. {{ deleting?.number }}? Nestat će i iz statistike, a u povijesti ostaje samo zapis o brisanju. Ova radnja se ne može poništiti.
    </ConfirmDialog>
  </div>
</template>
