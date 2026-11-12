<script setup lang="ts">
// Odbrojavanje do zadanog trenutka (dani, sati, minute, sekunde). Broji tek u pregledniku,
// a do tada prikazuje crtice, kako se HTML sa servera ne bi razlikovao od onoga u pregledniku.
const props = defineProps<{ target: string }>()
const emit = defineEmits<{ done: [] }>()

const now = ref<number | null>(null)
let timer: ReturnType<typeof setInterval> | undefined

onMounted(() => {
  now.value = Date.now()
  timer = setInterval(() => {
    now.value = Date.now()
    if (now.value >= new Date(props.target).getTime()) emit('done')
  }, 1000)
})
onBeforeUnmount(() => clearInterval(timer))

const parts = computed(() => {
  const labels = ['d', 'h', 'min', 's']
  if (now.value === null) return labels.map((label) => ({ value: '–', label }))
  const seconds = Math.max(0, Math.floor((new Date(props.target).getTime() - now.value) / 1000))
  const pad = (value: number) => String(value).padStart(2, '0')
  const values = [String(Math.floor(seconds / 86_400)), pad(Math.floor((seconds % 86_400) / 3600)), pad(Math.floor((seconds % 3600) / 60)), pad(seconds % 60)]
  return labels.map((label, index) => ({ value: values[index]!, label }))
})
</script>

<template>
  <p class="flex gap-3 tabular-nums" role="timer" aria-live="off">
    <span v-for="part in parts" :key="part.label">
      {{ part.value }}<span class="ml-0.5 font-body text-[0.45em] opacity-80">{{ part.label }}</span>
    </span>
  </p>
</template>
