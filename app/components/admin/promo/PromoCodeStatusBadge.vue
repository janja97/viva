<script setup lang="ts">
import { PROMO_CODE_STATUSES, type PromoCodeStatus } from '~/composables/usePromoCodes'

const props = defineProps<{ status: PromoCodeStatus }>()

const info = computed(() => PROMO_CODE_STATUSES[props.status])
</script>

<template>
  <span class="rounded-md px-1.5 py-0.5 text-xs font-medium" :class="info.color">{{ info.label }}</span>
</template>
