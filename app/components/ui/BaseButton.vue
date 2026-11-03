<script setup lang="ts">
withDefaults(defineProps<{
  type?: 'button' | 'submit'
  variant?: 'primary' | 'secondary' | 'danger'
  loading?: boolean
  block?: boolean
}>(), {
  type: 'button',
  variant: 'primary',
})
</script>

<template>
  <button
    :type="type"
    :disabled="loading"
    class="inline-flex min-h-11 items-center justify-center gap-1.5 rounded-lg px-3.5 text-sm font-medium transition-colors disabled:cursor-not-allowed disabled:opacity-50 sm:min-h-9"
    :class="[
      block && 'w-full',
      variant === 'primary' && 'bg-primary-600 text-white hover:bg-primary-700',
      variant === 'secondary' && 'border border-primary-300 bg-white text-stone-700 hover:border-primary-500 hover:bg-primary-50 hover:text-primary-800',
      variant === 'danger' && 'bg-red-600 text-white hover:bg-red-700',
    ]"
  >
    <slot />
  </button>
</template>
