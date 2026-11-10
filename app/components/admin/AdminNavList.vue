<script setup lang="ts">
import type { AdminNavLink } from '~/config/navigation'

const props = defineProps<{ links: AdminNavLink[] }>()

const { can } = usePermissions()
const visibleLinks = computed(() => props.links.filter((link) => !link.permission || can(link.permission)))

const { count: newInquiries, inProgressCount } = useNewInquiries()
const badgeCount = (link: AdminNavLink) => (link.badge === 'newInquiries' ? newInquiries.value : 0)
const inProgressBadge = (link: AdminNavLink) => (link.badge === 'newInquiries' ? inProgressCount.value : 0)

function badgeLabel(link: AdminNavLink) {
  const parts = [
    badgeCount(link) && `novih: ${badgeCount(link)}`,
    inProgressBadge(link) && `u obradi: ${inProgressBadge(link)}`,
  ].filter(Boolean)
  return parts.length ? `${link.label}, ${parts.join(', ')}` : undefined
}
</script>

<template>
  <ul class="space-y-0.5">
    <li v-for="link in visibleLinks" :key="link.to">
      <NuxtLink
        :to="link.to"
        class="flex min-h-11 items-center gap-2.5 rounded-lg px-2.5 text-sm text-primary-900 transition-colors hover:bg-primary-200 lg:min-h-9"
        exact-active-class="bg-primary-600 font-medium text-white hover:bg-primary-600"
        :aria-label="badgeLabel(link)"
      >
        <component :is="link.icon" class="size-4" stroke-width="1.75" />
        {{ link.label }}
        <span v-if="badgeCount(link) || inProgressBadge(link)" class="ml-auto flex items-center gap-1" aria-hidden="true">
          <span
            v-if="badgeCount(link)"
            class="flex h-5 min-w-5 items-center justify-center rounded-full bg-red-600 px-1.5 text-xs font-semibold text-white"
          >
            {{ badgeCount(link) }}
          </span>
          <span
            v-if="inProgressBadge(link)"
            class="flex h-5 min-w-5 items-center justify-center rounded-full bg-amber-400 px-1.5 text-xs font-semibold text-stone-900"
          >
            {{ inProgressBadge(link) }}
          </span>
        </span>
      </NuxtLink>
    </li>
  </ul>
</template>
