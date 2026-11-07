<script setup lang="ts">
import { CAMPAIGN_STATUSES, type CampaignStatus } from '~/composables/useCampaigns'

const props = defineProps<{ status: CampaignStatus }>()

const info = computed(() => CAMPAIGN_STATUSES[props.status])
</script>

<template>
  <span class="rounded-md px-1.5 py-0.5 text-xs font-medium" :class="info.color">{{ info.label }}</span>
</template>
