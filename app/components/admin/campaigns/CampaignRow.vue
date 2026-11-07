<script setup lang="ts">
import { Pause, Pencil, Play, Trash2 } from '@lucide/vue'
import type { Campaign } from '~/types/database'

const props = defineProps<{
  campaign: Campaign
  productCount: number
  canWrite: boolean
  loading?: boolean
}>()
const emit = defineEmits<{ edit: []; togglePause: []; delete: [] }>()

const status = computed(() => campaignStatus(props.campaign))
const dateFormat = new Intl.DateTimeFormat('hr-HR', { dateStyle: 'short', timeStyle: 'short' })

const period = computed(() => {
  const { kind, starts_at: startsAt, ends_at: endsAt } = props.campaign
  if (kind === 'permanent' || !startsAt || !endsAt) return 'Trajna'
  return `${dateFormat.format(new Date(startsAt))} – ${dateFormat.format(new Date(endsAt))}`
})

// "1 proizvod", "21 proizvod", a inače "proizvoda".
const productLabel = computed(() => {
  const count = props.productCount
  return count % 10 === 1 && count % 100 !== 11 ? `${count} proizvod` : `${count} proizvoda`
})
</script>

<template>
  <div class="flex flex-wrap items-center gap-x-4 gap-y-2 px-4 py-3">
    <span class="w-14 shrink-0 font-display text-2xl text-red-700">-{{ campaign.discount_percent }}%</span>
    <div class="min-w-0 flex-1">
      <p class="flex flex-wrap items-center gap-2">
        <span class="truncate text-sm font-medium text-stone-900">{{ campaign.name }}</span>
        <CampaignStatusBadge :status="status" />
      </p>
      <p class="text-xs text-stone-500">{{ period }} · {{ productLabel }}</p>
    </div>
    <div v-if="canWrite" class="flex items-center">
      <IconButton
        :label="campaign.is_paused ? `Nastavi: ${campaign.name}` : `Pauziraj: ${campaign.name}`"
        :disabled="loading"
        @click="emit('togglePause')"
      >
        <Play v-if="campaign.is_paused" class="size-4" stroke-width="1.75" />
        <Pause v-else class="size-4" stroke-width="1.75" />
      </IconButton>
      <IconButton :label="`Uredi: ${campaign.name}`" @click="emit('edit')">
        <Pencil class="size-4" stroke-width="1.75" />
      </IconButton>
      <IconButton :label="`Obriši: ${campaign.name}`" danger @click="emit('delete')">
        <Trash2 class="size-4" stroke-width="1.75" />
      </IconButton>
    </div>
  </div>
</template>
