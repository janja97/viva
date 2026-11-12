<script setup lang="ts">
import { ImagePlus, Trash2 } from '@lucide/vue'
import { IMAGE_EXTENSIONS } from '~/config/products'
import type { BlogPost, BlogPostInput, FaqItem } from '~/types/database'

const props = defineProps<{
  open: boolean
  post: BlogPost | null
  loading?: boolean
  error?: string
  uploadCover: (file: File, slug: string) => Promise<string>
}>()
const emit = defineEmits<{ close: []; save: [input: BlogPostInput] }>()

const imageFor = useBlogImage()
const form = reactive({
  title: '',
  slug: '',
  excerpt: '',
  body: '',
  coverPath: null as string | null,
  coverAlt: '',
  metaTitle: '',
  metaDescription: '',
  faq: [] as FaqItem[],
  isPublished: false,
})
const localError = ref('')
const isUploading = ref(false)
const isRemovingCover = ref(false)
let isSlugEdited = false

watch(() => props.open, (isOpen) => {
  if (!isOpen) return
  localError.value = ''
  const post = props.post
  form.title = post?.title ?? ''
  form.slug = post?.slug ?? ''
  form.excerpt = post?.excerpt ?? ''
  form.body = post?.body ?? ''
  form.coverPath = post?.cover_path ?? null
  form.coverAlt = post?.cover_alt ?? ''
  form.metaTitle = post?.meta_title ?? ''
  form.metaDescription = post?.meta_description ?? ''
  form.faq = structuredClone(toRaw(post?.faq ?? []))
  form.isPublished = post?.is_published ?? false
  isSlugEdited = Boolean(post)
})

// URL prati naslov samo kod novog članka, dok ga korisnik ne promijeni.
watch(() => form.title, (title) => {
  if (!isSlugEdited) form.slug = slugify(title)
})

async function onCover(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  input.value = ''
  if (!file) return
  isUploading.value = true
  localError.value = ''
  try {
    form.coverPath = await props.uploadCover(file, form.slug || form.title)
  } catch (error) {
    localError.value = productErrorMessage(error)
  } finally {
    isUploading.value = false
  }
}

function submit() {
  localError.value = ''
  if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(form.slug)) {
    localError.value = 'URL smije imati samo mala slova, brojeve i crtice.'
    return
  }
  emit('save', {
    title: form.title.trim(),
    slug: form.slug,
    excerpt: form.excerpt.trim(),
    body: form.body.trim(),
    cover_path: form.coverPath,
    cover_alt: form.coverAlt.trim(),
    meta_title: form.metaTitle.trim() || null,
    meta_description: form.metaDescription.trim() || null,
    faq: form.faq
      .map((item) => ({ question: item.question.trim(), answer: item.answer.trim() }))
      .filter((item) => item.question && item.answer),
    is_published: form.isPublished,
  })
}

const accept = Object.keys(IMAGE_EXTENSIONS).join(',')
</script>

<template>
  <BaseModal :open="open" :title="post ? 'Uredi članak' : 'Novi članak'" wide @close="emit('close')">
    <form class="space-y-4" @submit.prevent="submit">
      <BaseSwitch v-model="form.isPublished" label="Objavljen" hint="Neobjavljen članak kupci ne vide i nije u sitemapu." />
      <BaseInput v-model="form.title" label="Naslov" :maxlength="120" hint="Pitanje ili tema koju ljudi traže, npr. Kako odabrati haljinu za maturu." required />
      <BaseInput
        v-model="form.slug"
        label="URL"
        :maxlength="100"
        pattern="[a-z0-9]+(-[a-z0-9]+)*"
        :hint="`/blog/${form.slug || '...'}. Nakon objave ga ne mijenjaj, jer bi se izgubila pozicija na Googleu.`"
        required
        @input="isSlugEdited = true"
      />
      <BaseTextarea v-model="form.excerpt" label="Kratki uvod" :maxlength="300" hint="Dvije rečenice na popisu članaka i ispod naslova." />

      <div>
        <p class="mb-1.5 text-sm font-medium text-stone-700">Naslovna slika</p>
        <div class="flex flex-wrap items-start gap-3">
          <img v-if="form.coverPath" :src="imageFor(form.coverPath)!" alt="" class="aspect-4/3 w-40 border border-primary-300 object-cover">
          <label class="inline-flex min-h-11 cursor-pointer items-center gap-2 border border-primary-300 bg-white px-3 text-sm text-stone-700 hover:border-primary-500 sm:min-h-9">
            <ImagePlus class="size-4" stroke-width="1.75" />
            {{ isUploading ? 'Slanje...' : form.coverPath ? 'Zamijeni sliku' : 'Dodaj sliku' }}
            <input type="file" :accept="accept" class="sr-only" :disabled="isUploading" @change="onCover">
          </label>
          <BaseButton v-if="form.coverPath" variant="secondary" @click="isRemovingCover = true">
            <Trash2 class="size-4" stroke-width="1.75" />
            Ukloni
          </BaseButton>
        </div>
        <p class="mt-1.5 text-xs text-stone-500">Smanjuje se i pretvara u WebP. Najbolje vodoravna, 4 : 3.</p>
      </div>
      <BaseInput v-if="form.coverPath" v-model="form.coverAlt" label="Opis slike (alt)" :maxlength="200" hint="Što je na slici, npr. Duga maturalna haljina u boji šampanjca." />

      <BaseTextarea
        v-model="form.body"
        label="Tekst"
        :rows="16"
        :maxlength="30000"
        hint="800 do 1500 riječi. Prazan red je novi odlomak, ## na početku reda je podnaslov, a [maturalne haljine](/kategorija/maturalne-haljine) je poveznica. Poveži 2 do 4 kategorije."
      />

      <details class="border border-primary-300">
        <summary class="flex min-h-11 cursor-pointer items-center px-3 text-sm font-medium text-stone-700">SEO i česta pitanja</summary>
        <div class="space-y-4 border-t border-primary-300 p-3">
          <BaseInput v-model="form.metaTitle" label="Naslov za Google" :maxlength="70" :hint="`${form.metaTitle.length}/70. Ako je prazno, koristi se naslov.`" />
          <BaseTextarea v-model="form.metaDescription" label="Opis za Google" :maxlength="170" :hint="`${form.metaDescription.length}/170. Ako je prazno, koristi se kratki uvod.`" />
          <CategoryFaqField v-model="form.faq" />
        </div>
      </details>

      <BaseAlert v-if="localError || error" type="error">{{ localError || error }}</BaseAlert>
      <div class="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
        <BaseButton variant="secondary" @click="emit('close')">Odustani</BaseButton>
        <BaseButton type="submit" :loading="loading || isUploading">Spremi</BaseButton>
      </div>
    </form>

    <ConfirmDialog
      :open="isRemovingCover"
      title="Ukloni sliku"
      confirm-label="Ukloni"
      @close="isRemovingCover = false"
      @confirm="form.coverPath = null; isRemovingCover = false"
    >
      Ukloniti naslovnu sliku članka? Promjena vrijedi tek kad spremiš članak.
    </ConfirmDialog>
  </BaseModal>
</template>
