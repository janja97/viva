<script setup lang="ts">
// Oblačić s odbrojavanjem na naslovnoj (/admin/odbrojavanja). Kupac ga ne može zatvoriti.
// Prije početka odbrojava do početka, a za vrijeme akcije do kraja. Nakon kraja nestaje.
const { data: countdown } = useActiveCountdown()

const now = ref(Date.now())
let timer: ReturnType<typeof setInterval> | undefined
onMounted(() => {
  timer = setInterval(() => { now.value = Date.now() }, 1000)
})
onBeforeUnmount(() => clearInterval(timer))

const status = computed(() => (countdown.value ? countdownStatus(countdown.value, now.value) : 'ended'))
const target = computed(() => {
  if (!countdown.value) return 0
  return new Date(status.value === 'upcoming' ? countdown.value.starts_at : countdown.value.ends_at).getTime()
})

const parts = computed(() => {
  const seconds = Math.max(0, Math.floor((target.value - now.value) / 1000))
  const pad = (value: number) => String(value).padStart(2, '0')
  return [
    { value: String(Math.floor(seconds / 86_400)), label: 'd' },
    { value: pad(Math.floor((seconds % 86_400) / 3600)), label: 'h' },
    { value: pad(Math.floor((seconds % 3600) / 60)), label: 'min' },
    { value: pad(seconds % 60), label: 's' },
  ]
})

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
      <p class="mt-1 flex gap-3 font-display text-2xl tabular-nums sm:text-3xl" role="timer" aria-live="off">
        <span v-for="part in parts" :key="part.label">
          {{ part.value }}<span class="ml-0.5 font-body text-xs text-gold-light">{{ part.label }}</span>
        </span>
      </p>
      <p v-if="countdown.link" class="mt-2 text-xs font-medium uppercase tracking-[0.2em] text-gold-light underline underline-offset-4">
        Pogledaj ponudu
      </p>
    </component>
  </aside>
</template>
