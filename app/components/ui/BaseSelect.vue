<script setup lang="ts">
defineProps<{
  label: string
  options: { value: string; label: string }[]
  disabled?: boolean
  required?: boolean
  hint?: string
}>()

const model = defineModel<string>({ default: '' })
const id = useId()
</script>

<template>
  <div>
    <label :for="id" class="mb-1.5 block text-sm font-medium text-stone-700">{{ label }}</label>
    <select :id="id" v-model="model" :disabled="disabled" :required="required" class="form-field">
      <option v-for="option in options" :key="option.value" :value="option.value">{{ option.label }}</option>
    </select>
    <p v-if="hint" class="mt-1.5 text-xs text-stone-500">{{ hint }}</p>
  </div>
</template>
