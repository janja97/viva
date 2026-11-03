<script setup lang="ts">
import type { AdminNavLink } from '~/config/navigation'

defineProps<{ links: AdminNavLink[] }>()

const { count: newInquiries } = useNewInquiries()
const badgeCount = (link: AdminNavLink) => (link.badge === 'newInquiries' ? newInquiries.value : 0)
</script>

<template>
  <ul class="space-y-0.5">
    <li v-for="link in links" :key="link.to">
      <NuxtLink
        :to="link.to"
        class="flex min-h-11 items-center gap-2.5 rounded-lg px-2.5 text-sm text-primary-900 transition-colors hover:bg-primary-200 lg:min-h-9"
        exact-active-class="bg-primary-600 font-medium text-white hover:bg-primary-600"
        :aria-label="badgeCount(link) ? `${link.label}, novih: ${badgeCount(link)}` : undefined"
      >
        <component :is="link.icon" class="size-4" stroke-width="1.75" />
        {{ link.label }}
        <span
          v-if="badgeCount(link)"
          class="ml-auto flex h-5 min-w-5 items-center justify-center rounded-full bg-red-600 px-1.5 text-xs font-semibold text-white"
          aria-hidden="true"
        >
          {{ badgeCount(link) }}
        </span>
      </NuxtLink>
    </li>
  </ul>
</template>
