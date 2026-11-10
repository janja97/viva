<script setup lang="ts">
withDefaults(defineProps<{ label: string; maxlength?: number; hint?: string; rows?: number }>(), { rows: 3 })

const model = defineModel<string>({ default: '' })
const id = useId()
</script>

<template>
  <div>
    <label :for="id" class="mb-1.5 block text-sm font-medium text-stone-700">{{ label }}</label>
    <textarea :id="id" v-model="model" :maxlength="maxlength" :rows="rows" class="form-field" />
    <p v-if="hint" class="mt-1.5 text-xs text-stone-500">{{ hint }}</p>
  </div>
</template>
