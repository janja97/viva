<script setup lang="ts">
import type { InquiryStatus } from '~/types/database'

const props = defineProps<{ status: InquiryStatus }>()

const info = computed(() => INQUIRY_STATUSES.find((item) => item.value === props.status) ?? INQUIRY_STATUSES[0]!)
</script>

<template>
  <span class="rounded-md px-1.5 py-0.5 text-xs font-medium" :class="info.color">{{ info.label }}</span>
</template>
