<script setup lang="ts">
import { HOME_TOP_BAR } from '~/config/home'

// Traka iznad zaglavlja. Uključena obavijest iz postavki (/admin/postavke) zamjenjuje zadani tekst.
const { settings } = useStoreSettings()
const announcement = computed(() => (settings.value.announcement_enabled ? settings.value.announcement_text.trim() : ''))
</script>

<template>
  <p class="bg-graphite px-4 py-2 text-center text-[11px] uppercase tracking-[0.16em] text-white">
    <template v-if="announcement">{{ announcement }}</template>
    <template v-else>
      <span class="hidden sm:inline">{{ HOME_TOP_BAR.desktop }}</span>
      <span class="sm:hidden">{{ HOME_TOP_BAR.mobile }}</span>
    </template>
  </p>
</template>
