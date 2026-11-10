<script setup lang="ts">
import type { Category, FaqItem } from '~/types/database'
import type { CategoryInput } from '~/composables/useCategories'

const props = defineProps<{
  category: Category | null
  defaultParentId: string | null
  categories: Category[]
  submit: (input: CategoryInput) => Promise<void>
}>()
const emit = defineEmits<{ cancel: [] }>()

const name = ref(props.category?.name ?? '')
const slug = ref(props.category?.slug ?? '')
const parentId = ref(props.category?.parent_id ?? props.defaultParentId ?? '')
const description = ref(props.category?.description ?? '')
const isActive = ref(props.category?.is_active ?? true)
const metaTitle = ref(props.category?.meta_title ?? '')
const metaDescription = ref(props.category?.meta_description ?? '')
const seoText = ref(props.category?.seo_text ?? '')
const faq = ref<FaqItem[]>(structuredClone(toRaw(props.category?.faq ?? [])))

const errorMessage = ref('')
const isSaving = ref(false)

// URL naziv prati ime samo kod nove kategorije, dok ga korisnik ne promijeni.
let isSlugEdited = Boolean(props.category)
watch(name, (value) => {
  if (!isSlugEdited) slug.value = slugify(value)
})
function onSlugInput() {
  isSlugEdited = true
}

// Nudi samo mjesta na kojima kategorija, zajedno sa svime ispod sebe, ostaje unutar dopuštenih razina.
const parentOptions = computed(() => {
  const own = props.category
  const excluded = own ? [own.id, ...descendantIds(props.categories, own.id)] : []
  const height = own ? categoryHeight(props.categories, own.id) : 0
  const allowed = props.categories.filter((item) =>
    !excluded.includes(item.id)
    && categoryPath(props.categories, item.id).length + 1 + height <= MAX_CATEGORY_DEPTH)
  const allowedIds = new Set(allowed.map((item) => item.id))
  return [
    { value: '', label: 'Nema (glavna kategorija)' },
    ...categoryOptions(props.categories).filter((option) => allowedIds.has(option.value)),
  ]
})

async function onSubmit() {
  errorMessage.value = ''
  isSaving.value = true
  try {
    await props.submit({
      name: name.value.trim(),
      slug: slug.value,
      parent_id: parentId.value || null,
      description: description.value.trim() || null,
      is_active: isActive.value,
      meta_title: metaTitle.value.trim() || null,
      meta_description: metaDescription.value.trim() || null,
      seo_text: seoText.value.trim() || null,
      // Prazna pitanja se ne spremaju.
      faq: faq.value
        .map((item) => ({ question: item.question.trim(), answer: item.answer.trim() }))
        .filter((item) => item.question && item.answer),
    })
  } catch (error) {
    errorMessage.value = categoryErrorMessage(error)
  } finally {
    isSaving.value = false
  }
}
</script>

<template>
  <form class="space-y-4" @submit.prevent="onSubmit">
    <BaseAlert v-if="errorMessage" type="error">{{ errorMessage }}</BaseAlert>
    <BaseInput v-model="name" label="Naziv" :maxlength="80" required />
    <BaseInput
      v-model="slug"
      label="URL naziv"
      pattern="[a-z0-9]+(-[a-z0-9]+)*"
      hint="Mala slova, brojevi i crtice. Važno za SEO, zato ga ne mijenjaj bez potrebe."
      required
      @input="onSlugInput"
    />
    <BaseSelect
      v-model="parentId"
      label="Nadređena kategorija"
      :options="parentOptions"
      hint="Najviše tri razine, npr. Obuća / Sandale / Ravne sandale."
    />
    <BaseTextarea v-model="description" label="Kratki opis" :maxlength="500" hint="Neobavezno. Jedna do dvije rečenice ispod naslova kategorije." />
    <CategorySeoFields
      v-model:meta-title="metaTitle"
      v-model:meta-description="metaDescription"
      v-model:seo-text="seoText"
      v-model:faq="faq"
      :name="name || 'Kategorija'"
    />
    <BaseSwitch v-model="isActive" label="Aktivna" hint="Neaktivne kategorije kupci ne vide." />
    <div class="flex flex-col-reverse gap-2 pt-2 sm:flex-row sm:justify-end">
      <BaseButton variant="secondary" @click="emit('cancel')">Odustani</BaseButton>
      <BaseButton type="submit" :loading="isSaving">{{ isSaving ? 'Spremanje...' : 'Spremi' }}</BaseButton>
    </div>
  </form>
</template>
