<script setup lang="ts">
import { Check } from '@lucide/vue'

// Kvačica ili izbor jednog (radio) u filtrima, u stilu trgovine: tanki okvir, tamna ispuna kad je odabrano.
const props = defineProps<{ type?: 'checkbox' | 'radio'; checked: boolean; name?: string }>()
const emit = defineEmits<{ change: [] }>()
const isRadio = computed(() => props.type === 'radio')
</script>

<template>
  <label class="group/option flex min-h-11 cursor-pointer items-center gap-3 text-sm text-ink lg:min-h-9">
    <input :type="type ?? 'checkbox'" :name="name" :checked="checked" class="peer sr-only" @change="emit('change')">
    <span
      class="flex size-[18px] flex-none items-center justify-center border transition-colors peer-focus-visible:outline-2 peer-focus-visible:outline-offset-2 peer-focus-visible:outline-gold"
      :class="[
        isRadio && 'rounded-full',
        checked ? 'border-ink' : 'border-line bg-white group-hover/option:border-ink',
        checked && !isRadio && 'bg-ink',
      ]"
      aria-hidden="true"
    >
      <Check v-if="checked && !isRadio" class="size-3 text-white" stroke-width="2.5" />
      <span v-else-if="checked" class="size-2 rounded-full bg-ink" />
    </span>
    <span class="flex min-w-0 items-center gap-2" :class="checked ? 'font-medium' : 'text-ink/85'">
      <slot />
    </span>
  </label>
</template>
