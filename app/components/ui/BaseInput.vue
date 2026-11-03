<script setup lang="ts">
withDefaults(defineProps<{
  label: string
  type?: string
  autocomplete?: string
  inputmode?: 'text' | 'numeric' | 'decimal'
  required?: boolean
  minlength?: number
  maxlength?: number
  min?: number
  step?: string
  pattern?: string
  placeholder?: string
  hint?: string
  // Prijedlozi pri upisu, a dopušten je i drugi tekst.
  suggestions?: string[]
}>(), {
  type: 'text',
})

const model = defineModel<string>({ default: '' })
const id = useId()
</script>

<template>
  <div>
    <label :for="id" class="mb-1.5 block text-sm font-medium text-stone-700">{{ label }}</label>
    <input
      :id="id"
      v-model="model"
      :type="type"
      :autocomplete="autocomplete"
      :inputmode="inputmode"
      :required="required"
      :minlength="minlength"
      :maxlength="maxlength"
      :min="min"
      :step="step"
      :pattern="pattern"
      :placeholder="placeholder"
      :list="suggestions?.length ? `${id}-list` : undefined"
      class="form-field"
    >
    <datalist v-if="suggestions?.length" :id="`${id}-list`">
      <option v-for="item in suggestions" :key="item" :value="item" />
    </datalist>
    <p v-if="hint" class="mt-1.5 text-xs text-stone-500">{{ hint }}</p>
  </div>
</template>
