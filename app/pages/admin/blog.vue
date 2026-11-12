<script setup lang="ts">
import { ExternalLink, Pencil, Plus, Trash2 } from '@lucide/vue'
import type { BlogPost, BlogPostInput } from '~/types/database'

definePageMeta({ layout: 'admin' })
usePageSeo({ title: 'Blog', noindex: true })

const { can } = usePermissions()
const { posts, isLoading, loadError, load, save, remove, uploadCover } = useBlogAdmin()

const canWrite = computed(() => can('write'))
const isFormOpen = ref(false)
const editing = ref<BlogPost | null>(null)
const isSaving = ref(false)
const formError = ref('')

const deleting = ref<BlogPost | null>(null)
const deleteError = ref('')
const isDeleting = ref(false)

function openForm(post: BlogPost | null) {
  editing.value = post
  formError.value = ''
  isFormOpen.value = true
}

async function submit(input: BlogPostInput) {
  isSaving.value = true
  formError.value = ''
  try {
    await save(input, editing.value?.id)
    isFormOpen.value = false
  } catch (error) {
    const code = (error as { code?: string }).code
    formError.value = code === '23505' ? 'Taj URL već koristi drugi članak.' : productErrorMessage(error)
  } finally {
    isSaving.value = false
  }
}

async function confirmDelete() {
  if (!deleting.value) return
  isDeleting.value = true
  deleteError.value = ''
  try {
    await remove(deleting.value)
    deleting.value = null
  } catch (error) {
    deleteError.value = productErrorMessage(error)
  } finally {
    isDeleting.value = false
  }
}

onMounted(load)
</script>

<template>
  <div>
    <AdminPageHeader title="Blog" description="Savjeti koji odgovaraju na pitanja kupaca i vode na kategorije. Dobro za Google.">
      <BaseButton v-if="canWrite" @click="openForm(null)">
        <Plus class="size-4" stroke-width="2" />
        Novi članak
      </BaseButton>
    </AdminPageHeader>

    <p v-if="isLoading && !posts.length" class="text-sm text-stone-500">Učitavanje...</p>
    <div v-else-if="loadError" class="space-y-3">
      <BaseAlert type="error">{{ loadError }}</BaseAlert>
      <BaseButton variant="secondary" @click="load">Pokušaj ponovno</BaseButton>
    </div>
    <p v-else-if="!posts.length" class="border border-dashed border-primary-300 bg-white px-4 py-12 text-center text-sm text-stone-500">
      Još nema članaka.
    </p>
    <ul v-else class="divide-y divide-primary-200 border border-primary-300 bg-white">
      <li v-for="post in posts" :key="post.id" class="flex flex-wrap items-center gap-x-4 gap-y-2 px-4 py-3">
        <div class="min-w-0 flex-1">
          <p class="flex flex-wrap items-center gap-2">
            <span class="truncate text-sm font-medium text-stone-900">{{ post.title }}</span>
            <span
              class="rounded-md px-1.5 py-0.5 text-xs font-medium"
              :class="post.is_published ? 'bg-emerald-100 text-emerald-800' : 'bg-stone-200 text-stone-700'"
            >{{ post.is_published ? 'Objavljen' : 'Skica' }}</span>
          </p>
          <p class="text-xs text-stone-500">/blog/{{ post.slug }}<template v-if="post.published_at"> · {{ blogDate(post.published_at) }}</template></p>
        </div>
        <div class="flex items-center">
          <a v-if="post.is_published" :href="`/blog/${post.slug}`" target="_blank" rel="noopener" :aria-label="`Otvori: ${post.title}`" :title="`Otvori: ${post.title}`" class="inline-flex size-11 items-center justify-center text-stone-500 hover:text-primary-700 sm:size-8">
            <ExternalLink class="size-4" stroke-width="1.75" />
          </a>
          <template v-if="canWrite">
            <IconButton :label="`Uredi: ${post.title}`" @click="openForm(post)">
              <Pencil class="size-4" stroke-width="1.75" />
            </IconButton>
            <IconButton :label="`Obriši: ${post.title}`" danger @click="deleting = post; deleteError = ''">
              <Trash2 class="size-4" stroke-width="1.75" />
            </IconButton>
          </template>
        </div>
      </li>
    </ul>

    <p class="mt-4 max-w-2xl text-xs text-stone-500">
      Dobar članak odgovara na jedno pitanje koje kupci stvarno postavljaju, ima 800 do 1500 riječi, vlastito iskustvo iz trgovine
      i poveznice na 2 do 4 kategorije. Tekst napisan umjetnom inteligencijom uvijek pročitaj i dopuni prije objave.
    </p>

    <BlogPostFormModal
      :open="isFormOpen"
      :post="editing"
      :loading="isSaving"
      :error="formError"
      :upload-cover="uploadCover"
      @close="isFormOpen = false"
      @save="submit"
    />

    <ConfirmDialog
      :open="Boolean(deleting)"
      title="Obriši članak"
      confirm-label="Obriši"
      :loading="isDeleting"
      :error="deleteError"
      @close="deleting = null"
      @confirm="confirmDelete"
    >
      Sigurno želiš obrisati članak „{{ deleting?.title }}”? Briše se i naslovna slika. Ova radnja se ne može poništiti.
    </ConfirmDialog>
  </div>
</template>
