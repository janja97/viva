<script setup lang="ts">
import type { InquiryAuditEntry } from '~/types/database'

defineProps<{ entries: InquiryAuditEntry[]; loading?: boolean }>()

const dateFormat = new Intl.DateTimeFormat('hr-HR', { dateStyle: 'short', timeStyle: 'short' })

function describe(entry: InquiryAuditEntry) {
  if (entry.action === 'created') return 'Narudžba zaprimljena'
  if (entry.action === 'deleted') return 'Narudžba obrisana'
  return `${inquiryStatusLabel(entry.from_status)} → ${inquiryStatusLabel(entry.to_status)}`
}
</script>

<template>
  <section aria-labelledby="povijest-narudzbe">
    <h3 id="povijest-narudzbe" class="mb-2 text-sm font-medium text-stone-900">Povijest promjena</h3>
    <p v-if="loading" class="text-stone-500">Učitavanje...</p>
    <ol v-else class="space-y-2 border-l border-primary-300 pl-4">
      <li v-for="entry in entries" :key="entry.id" class="relative">
        <span class="absolute -left-[21px] top-1.5 size-2 rounded-full bg-primary-500" aria-hidden="true" />
        <p class="font-medium text-stone-800">{{ describe(entry) }}</p>
        <p class="text-xs text-stone-500">
          {{ dateFormat.format(new Date(entry.created_at)) }} ·
          {{ entry.action === 'created' ? 'Kupac (web trgovina)' : entry.user_email ?? 'Nepoznat korisnik' }}
        </p>
      </li>
    </ol>
  </section>
</template>
