<script setup lang="ts">
import { Pencil, Power, PowerOff, Trash2 } from '@lucide/vue'
import { COUNTDOWN_STATUSES } from '~/composables/useCountdowns'
import type { Countdown } from '~/types/database'

const props = defineProps<{
  countdown: Countdown
  canWrite: boolean
  loading?: boolean
}>()
const emit = defineEmits<{ edit: []; toggle: []; delete: [] }>()

const status = computed(() => COUNTDOWN_STATUSES[countdownStatus(props.countdown)])
const dateFormat = new Intl.DateTimeFormat('hr-HR', { dateStyle: 'short', timeStyle: 'short' })
const period = computed(() => `${dateFormat.format(new Date(props.countdown.starts_at))} – ${dateFormat.format(new Date(props.countdown.ends_at))}`)
</script>

<template>
  <div class="flex flex-wrap items-center gap-x-4 gap-y-2 px-4 py-3">
    <div class="min-w-0 flex-1">
      <p class="flex flex-wrap items-center gap-2">
        <span class="truncate text-sm font-medium text-stone-900">{{ countdown.title }}</span>
        <span class="rounded-md px-1.5 py-0.5 text-xs font-medium" :class="status.color">{{ status.label }}</span>
      </p>
      <p class="text-xs text-stone-500">
        {{ period }}<template v-if="countdown.message"> · {{ countdown.message }}</template>
      </p>
    </div>
    <div v-if="canWrite" class="flex items-center">
      <IconButton
        :label="countdown.is_enabled ? `Isključi: ${countdown.title}` : `Uključi: ${countdown.title}`"
        :disabled="loading"
        @click="emit('toggle')"
      >
        <PowerOff v-if="countdown.is_enabled" class="size-4" stroke-width="1.75" />
        <Power v-else class="size-4" stroke-width="1.75" />
      </IconButton>
      <IconButton :label="`Uredi: ${countdown.title}`" @click="emit('edit')">
        <Pencil class="size-4" stroke-width="1.75" />
      </IconButton>
      <IconButton :label="`Obriši: ${countdown.title}`" danger @click="emit('delete')">
        <Trash2 class="size-4" stroke-width="1.75" />
      </IconButton>
    </div>
  </div>
</template>
