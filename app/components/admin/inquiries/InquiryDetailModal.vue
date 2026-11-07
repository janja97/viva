<script setup lang="ts">
import { Mail, MapPin, Phone } from '@lucide/vue'
import type { InquiryWithItems } from '~/composables/useInquiries'
import type { InquiryAuditEntry, InquiryStatus } from '~/types/database'

const props = defineProps<{
  inquiry: InquiryWithItems | null
  canWrite: boolean
  canDelete: boolean
  loading?: boolean
  error?: string
}>()
const emit = defineEmits<{ close: []; status: [status: InquiryStatus]; delete: [] }>()

const statusOptions = INQUIRY_STATUSES.map(({ value, label }) => ({ value, label }))
const status = computed({
  get: () => props.inquiry?.status ?? 'new',
  set: (value: string) => emit('status', value as InquiryStatus),
})

const dateFormat = new Intl.DateTimeFormat('hr-HR', { dateStyle: 'medium', timeStyle: 'short' })

const { fetchHistory } = useInquiries()
const history = ref<InquiryAuditEntry[]>([])
const isHistoryLoading = ref(false)

// Povijest se učitava pri otvaranju i nakon svake promjene statusa.
watch(() => [props.inquiry?.id, props.inquiry?.status], async ([id]) => {
  history.value = []
  if (!id) return
  isHistoryLoading.value = true
  try {
    history.value = await fetchHistory(id as string)
  } catch (error) {
    console.error(error)
  } finally {
    isHistoryLoading.value = false
  }
}, { immediate: true })
</script>

<template>
  <BaseModal :open="Boolean(inquiry)" :title="inquiry ? `Narudžba br. ${inquiry.number}` : ''" wide @close="emit('close')">
    <div v-if="inquiry" class="space-y-5 text-sm">
      <div class="flex flex-wrap items-center gap-2 text-stone-500">
        <InquiryStatusBadge :status="inquiry.status" />
        <span>Zaprimljeno {{ dateFormat.format(new Date(inquiry.created_at)) }}</span>
      </div>
      <p v-if="inquiry.status_changed_at" class="-mt-3 text-xs text-stone-500">
        Status je promijenio {{ inquiry.status_changed_by_email ?? 'nepoznat korisnik' }}, {{ dateFormat.format(new Date(inquiry.status_changed_at)) }}
      </p>

      <div class="space-y-1">
        <p class="font-medium text-stone-900">{{ inquiry.customer_name }}</p>
        <a :href="`tel:${inquiry.phone.replace(/[^\d+]/g, '')}`" class="flex min-h-11 items-center gap-2 text-primary-800 hover:text-primary-900 sm:min-h-8">
          <Phone class="size-4" stroke-width="1.75" />
          {{ inquiry.phone }}
        </a>
        <a v-if="inquiry.email" :href="`mailto:${inquiry.email}`" class="flex min-h-11 items-center gap-2 break-all text-primary-800 hover:text-primary-900 sm:min-h-8">
          <Mail class="size-4 shrink-0" stroke-width="1.75" />
          {{ inquiry.email }}
        </a>
        <p v-if="inquiry.address" class="flex items-start gap-2 py-1 text-stone-700">
          <MapPin class="mt-0.5 size-4 shrink-0" stroke-width="1.75" />
          <span>{{ inquiry.address }}, {{ inquiry.postal_code }} {{ inquiry.city }}</span>
        </p>
        <p v-if="inquiry.note" class="whitespace-pre-line border-l-2 border-primary-300 pl-3 text-stone-700">{{ inquiry.note }}</p>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-md text-left">
          <thead class="border-b border-primary-300 text-xs text-stone-500">
            <tr>
              <th class="py-2 pr-3 font-medium">Proizvod</th>
              <th class="py-2 pr-3 font-medium">Boja / veličina</th>
              <th class="py-2 pr-3 text-right font-medium">Kom.</th>
              <th class="py-2 text-right font-medium">Iznos</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-primary-200">
            <tr v-for="item in inquiry.inquiry_items" :key="item.id">
              <td class="py-2 pr-3">
                <NuxtLink v-if="item.product_id" :to="`/admin/proizvodi/${item.product_id}?pregled=1`" class="font-medium text-primary-800 hover:text-primary-900">{{ item.product_name }}</NuxtLink>
                <span v-else class="font-medium">{{ item.product_name }}</span>
                <span class="block text-xs text-stone-500">{{ item.sku }}</span>
              </td>
              <td class="py-2 pr-3">{{ item.color_name }} / {{ item.size }}</td>
              <td class="py-2 pr-3 text-right">{{ item.quantity }}</td>
              <td class="py-2 text-right">
                {{ formatPrice(Number(item.unit_price) * item.quantity) }}
                <del v-if="Number(item.unit_price) !== Number(item.regular_price)" class="block text-xs text-stone-500">{{ formatPrice(Number(item.regular_price) * item.quantity) }}</del>
              </td>
            </tr>
          </tbody>
          <tfoot>
            <tr class="border-t border-primary-300 text-stone-600">
              <td colspan="3" class="pt-2 pr-3">Ukupno</td>
              <td class="pt-2 text-right">{{ formatPrice(Number(inquiry.subtotal)) }}</td>
            </tr>
            <tr v-if="inquiry.promo_code" class="text-stone-600">
              <td colspan="3" class="pr-3">Promo kod {{ inquiry.promo_code }}</td>
              <td class="text-right">-{{ formatPrice(Number(inquiry.promo_discount)) }}</td>
            </tr>
            <tr class="text-stone-600">
              <td colspan="3" class="pr-3">Poštarina</td>
              <td class="text-right">{{ Number(inquiry.shipping) ? formatPrice(Number(inquiry.shipping)) : 'Besplatna' }}</td>
            </tr>
            <tr>
              <td colspan="3" class="py-2 pr-3 font-medium">Sveukupno</td>
              <td class="py-2 text-right font-semibold">{{ formatPrice(Number(inquiry.total)) }}</td>
            </tr>
          </tfoot>
        </table>
      </div>
      <p class="text-xs text-stone-500">Cijene su one koje je kupac vidio u trenutku narudžbe. Stanje na zalihi se ne mijenja samo, nego ga ažuriraš kad potvrdiš prodaju.</p>

      <InquiryHistory :entries="history" :loading="isHistoryLoading" />

      <BaseAlert v-if="error" type="error">{{ error }}</BaseAlert>

      <div v-if="canWrite" class="flex flex-col gap-3 border-t border-primary-300 pt-4 sm:flex-row sm:items-end sm:justify-between">
        <BaseSelect v-model="status" class="sm:w-56" label="Status" :options="statusOptions" :disabled="loading" />
        <BaseButton v-if="canDelete" variant="danger" :loading="loading" @click="emit('delete')">Obriši narudžbu</BaseButton>
      </div>
    </div>
  </BaseModal>
</template>
