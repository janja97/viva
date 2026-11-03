<script setup lang="ts">
import { RefreshCw } from '@lucide/vue'
import { PRODUCT_PATH } from '~/config/products'
import type { ColorForm } from '~/types/productForm'

const props = defineProps<{
  color: ColorForm
  // Slug koji proizlazi iz naziva proizvoda, boje i šifre.
  generated: string
}>()

const { siteUrl } = useRuntimeConfig().public
const origin = (siteUrl || useRequestURL().origin).replace(/\/$/, '')

function resetToGenerated() {
  props.color.autoSlug = true
  props.color.slug = props.generated
}

// Dopušta slobodno tipkanje, a pri izlasku iz polja slug svodi na ispravan oblik.
function normalize() {
  props.color.slug = slugify(props.color.slug)
  if (!props.color.slug) resetToGenerated()
}
</script>

<template>
  <div>
    <div class="flex items-start gap-2">
      <BaseInput
        v-model="color.slug"
        class="min-w-0 flex-1"
        label="Slug (URL)"
        pattern="[a-z0-9]+(-[a-z0-9]+)*"
        required
        @input="color.autoSlug = false"
        @focusout="normalize"
      />
      <BaseButton class="mt-6.5" variant="secondary" @click="resetToGenerated">
        <RefreshCw class="size-4" stroke-width="1.75" />
        Iz naziva i šifre
      </BaseButton>
    </div>
    <p class="mt-1.5 break-all text-xs text-stone-600">
      {{ origin }}{{ PRODUCT_PATH }}/<strong class="font-semibold text-primary-800">{{ color.slug || '...' }}</strong>
    </p>
    <p class="mt-0.5 text-xs text-stone-500">Slug se stvara sam, a možeš ga i urediti. Promjena već objavljenog sluga mijenja adresu stranice.</p>
  </div>
</template>
