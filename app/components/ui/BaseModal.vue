<script setup lang="ts">
import { X } from '@lucide/vue'

const props = defineProps<{ open: boolean; title: string; wide?: boolean }>()
const emit = defineEmits<{ close: [] }>()

const dialog = useTemplateRef<HTMLDialogElement>('dialog')

watch(() => props.open, (isOpen) => {
  if (isOpen) dialog.value?.showModal()
  else dialog.value?.close()
})

// Zatvara se samo klik koji je i počeo izvan prozora. Inače bi označavanje teksta u prozoru,
// otpušteno izvan njega, zatvorilo prozor bez upozorenja.
const pressedOnBackdrop = ref(false)

function onBackdropClick() {
  if (pressedOnBackdrop.value) emit('close')
  pressedOnBackdrop.value = false
}
</script>

<template>
  <dialog
    ref="dialog"
    class="m-auto w-[calc(100%-2rem)] rounded-xl border border-primary-300 bg-white font-admin text-stone-900 backdrop:bg-primary-950/50"
    :class="wide ? 'max-w-3xl' : 'max-w-lg'"
    @cancel.prevent="emit('close')"
    @pointerdown="pressedOnBackdrop = $event.target === dialog"
    @click.self="onBackdropClick"
  >
    <div v-if="open" class="p-5 sm:p-6">
      <div class="mb-5 flex items-center justify-between gap-4">
        <h2 class="font-display text-2xl font-normal leading-tight">{{ title }}</h2>
        <IconButton label="Zatvori" @click="emit('close')">
          <X class="size-4" />
        </IconButton>
      </div>
      <slot />
    </div>
  </dialog>
</template>
