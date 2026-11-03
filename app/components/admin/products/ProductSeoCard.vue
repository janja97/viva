<script setup lang="ts">
import { PRODUCT_PATH } from '~/config/products'
import type { ProductForm } from '~/types/productForm'

const props = defineProps<{
  form: ProductForm
  categoryName: string
}>()

const { siteName, siteUrl } = useRuntimeConfig().public
const origin = (siteUrl || useRequestURL().origin).replace(/\/$/, '')

const isManual = ref(Boolean(props.form.meta_title || props.form.meta_description))

function onManualChange(manual: boolean) {
  isManual.value = manual
  if (!manual) {
    props.form.meta_title = ''
    props.form.meta_description = ''
  }
}

const previews = computed(() =>
  props.form.colors.map((color) => {
    const input = {
      name: props.form.name,
      colorName: color.name,
      categoryName: props.categoryName,
      description: props.form.description,
      price: props.form.discount_percent
        ? String(discountedPrice(Number(props.form.price), Number(props.form.discount_percent)))
        : props.form.price,
      storeOnly: props.form.store_only,
      metaTitle: props.form.meta_title,
      metaDescription: props.form.meta_description,
    }
    return {
      id: color.id,
      title: `${productSeoTitle(input)} | ${siteName}`,
      url: `${origin}${PRODUCT_PATH}/${color.slug}`,
      description: productSeoDescription(input),
    }
  }),
)

const tips = computed(() => {
  const list: string[] = []
  if (props.form.description.trim().length < 50) list.push('Dodaj opis od barem nekoliko rečenica, vlastitim riječima. Google bolje rangira jedinstven tekst.')
  if (!props.form.colors.some((color) => color.images.length)) list.push('Dodaj slike proizvoda.')
  if (!props.form.material.trim()) list.push('Upiši sastav materijala, jer kupci često traže i po njemu.')
  return list
})
</script>

<template>
  <AdminCard title="SEO">
    <p class="text-sm text-stone-600">Naslov i opis stvaraju se sami, posebno za svaku boju. Ovako će otprilike izgledati na Googleu:</p>

    <p v-if="!previews.length" class="mt-3 text-sm text-stone-500">Dodaj boju za prikaz.</p>
    <ul class="mt-3 space-y-3">
      <li v-for="preview in previews" :key="preview.id" class="rounded-lg border border-primary-300 bg-white p-3" data-testid="seo-preview">
        <p class="break-all text-xs text-stone-600">{{ preview.url }}</p>
        <p class="mt-0.5 text-base text-sky-800">{{ preview.title }}</p>
        <p class="mt-0.5 text-sm text-stone-600">{{ preview.description }}</p>
      </li>
    </ul>

    <ul v-if="tips.length" class="mt-4 space-y-1 rounded-lg bg-amber-50 p-3 text-sm text-amber-900">
      <li v-for="tip in tips" :key="tip">{{ tip }}</li>
    </ul>

    <div class="mt-4 space-y-4 border-t border-primary-200 pt-3">
      <BaseSwitch
        :model-value="isManual"
        label="Ručno uredi naslov i opis"
        hint="Nije potrebno. Isključivanjem se vraćaju automatski tekstovi."
        @update:model-value="onManualChange"
      />
      <template v-if="isManual">
        <BaseInput v-model="form.meta_title" label="Meta naslov" :maxlength="50" hint="Boja se dodaje sama na kraj naslova." />
        <BaseTextarea v-model="form.meta_description" label="Meta opis" :maxlength="155" hint="Do 155 znakova. Vrijedi za sve boje ovog proizvoda." />
      </template>
    </div>
  </AdminCard>
</template>
