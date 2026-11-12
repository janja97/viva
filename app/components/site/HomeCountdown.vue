<script setup lang="ts">
// Oblačić s odbrojavanjem na naslovnoj (/admin/odbrojavanja). Kupac ga ne može zatvoriti.
// Prije početka odbrojava do početka, a za vrijeme akcije do kraja. Nakon kraja nestaje.
const { data: countdown } = useActiveCountdown()

// Mijenja se kad odbrojavanje dođe do nule, pa se stanje ponovno izračuna.
const now = ref(Date.now())
const status = computed(() => (countdown.value ? countdownStatus(countdown.value, now.value) : 'ended'))
const target = computed(() => (status.value === 'upcoming' ? countdown.value!.starts_at : countdown.value!.ends_at))

const isVisible = computed(() => status.value === 'upcoming' || status.value === 'live')
const isExternal = computed(() => countdown.value?.link?.startsWith('https://') ?? false)
</script>

<template>
  <aside
    v-if="countdown && isVisible"
    :aria-label="`${countdown.title}, odbrojavanje`"
    class="fixed inset-x-3 bottom-3 z-30 border border-gold bg-graphite px-4 py-3 text-white sm:inset-x-auto sm:bottom-6 sm:left-6 sm:w-80 sm:px-5 sm:py-4"
  >
    <component
      :is="countdown.link ? (isExternal ? 'a' : resolveComponent('NuxtLink')) : 'div'"
      v-bind="countdown.link ? (isExternal ? { href: countdown.link, target: '_blank', rel: 'noopener' } : { to: countdown.link }) : {}"
      class="block"
    >
      <p class="flex items-baseline justify-between gap-3">
        <span class="font-display text-2xl leading-tight">{{ countdown.title }}</span>
        <span class="shrink-0 text-[10px] font-medium uppercase tracking-[0.2em] text-gold-light">
          {{ status === 'live' ? 'U tijeku' : 'Uskoro' }}
        </span>
      </p>
      <p v-if="countdown.message" class="mt-0.5 text-sm text-white/80">{{ countdown.message }}</p>
      <p class="mt-2 text-[11px] uppercase tracking-[0.16em] text-white/70">
        {{ status === 'live' ? 'Završava za' : 'Počinje za' }}
      </p>
      <CountdownTimer :key="target" class="mt-1 font-display text-2xl sm:text-3xl" :target="target" @done="now = Date.now()" />
      <p v-if="countdown.link" class="mt-2 text-xs font-medium uppercase tracking-[0.2em] text-gold-light underline underline-offset-4">
        Pogledaj ponudu
      </p>
    </component>
  </aside>
</template>
