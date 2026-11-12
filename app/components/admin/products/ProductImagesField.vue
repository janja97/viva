<script setup lang="ts">
import { ChevronLeft, ChevronRight, ImagePlus, Trash2 } from '@lucide/vue'
import { IMAGE_EXTENSIONS } from '~/config/products'
import type { ProductImagesApi } from '~/composables/useProductImages'
import type { ColorForm } from '~/types/productForm'

const props = defineProps<{
  color: ColorForm
  api: ProductImagesApi
}>()

const accept = Object.keys(IMAGE_EXTENSIONS).join(',')
const errorMessage = ref('')
const uploadingCount = ref(0)

async function onFiles(event: Event) {
  const input = event.target as HTMLInputElement
  const files = [...(input.files ?? [])]
  input.value = ''
  errorMessage.value = ''

  for (const file of files) {
    uploadingCount.value++
    try {
      // Ime datoteke prati URL boje (naziv-boja-sifra), npr. aurora-crna-123-1a2b3c4d.webp.
      props.color.images.push(await props.api.upload(props.color.id, file, props.color.slug || props.color.name))
    } catch (error) {
      errorMessage.value = productErrorMessage(error)
    } finally {
      uploadingCount.value--
    }
  }
}

// Uklanjanje slike traži potvrdu, kao i svako brisanje u adminu.
const removingIndex = ref<number | null>(null)

function remove() {
  if (removingIndex.value === null) return
  const [image] = props.color.images.splice(removingIndex.value, 1)
  if (image) props.api.discard(image.path)
  removingIndex.value = null
}

function move(index: number, direction: -1 | 1) {
  const { images } = props.color
  const target = index + direction
  ;[images[index], images[target]] = [images[target]!, images[index]!]
}
</script>

<template>
  <div>
    <p class="mb-1.5 text-sm font-medium text-stone-700">Slike</p>
    <BaseAlert v-if="errorMessage" type="error" class="mb-2">{{ errorMessage }}</BaseAlert>

    <ul class="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
      <li v-for="(image, index) in color.images" :key="image.id" class="overflow-hidden rounded-lg border border-primary-300 bg-white">
        <div class="relative">
          <img :src="api.urlFor(image.path)" :alt="image.alt || `${color.name} ${index + 1}`" loading="lazy" class="aspect-square w-full object-cover">
          <span v-if="index === 0" class="absolute left-1.5 top-1.5 rounded-md bg-primary-600 px-1.5 py-0.5 text-xs font-medium text-white">Glavna</span>
        </div>
        <div class="flex items-center justify-between px-1">
          <IconButton label="Pomakni lijevo" :disabled="index === 0" @click="move(index, -1)">
            <ChevronLeft class="size-4" stroke-width="1.75" />
          </IconButton>
          <IconButton label="Pomakni desno" :disabled="index === color.images.length - 1" @click="move(index, 1)">
            <ChevronRight class="size-4" stroke-width="1.75" />
          </IconButton>
          <IconButton label="Ukloni sliku" danger @click="removingIndex = index">
            <Trash2 class="size-4" stroke-width="1.75" />
          </IconButton>
        </div>
        <div class="px-2 pb-2">
          <input
            v-model="image.alt"
            class="form-field"
            maxlength="150"
            placeholder="Opis slike"
            :aria-label="`Opis slike ${index + 1}`"
          >
        </div>
      </li>

      <li>
        <label class="flex aspect-square w-full cursor-pointer flex-col items-center justify-center gap-1.5 rounded-lg border border-dashed border-primary-500 bg-primary-50 p-2 text-center text-sm text-primary-800 transition-colors hover:bg-primary-100 has-disabled:cursor-not-allowed has-disabled:opacity-50 has-focus-visible:outline-2 has-focus-visible:outline-primary-600">
          <ImagePlus class="size-5" stroke-width="1.75" />
          {{ uploadingCount ? 'Slanje...' : 'Dodaj slike' }}
          <input type="file" class="sr-only" multiple :accept="accept" @change="onFiles">
        </label>
      </li>
    </ul>
    <p class="mt-1.5 text-xs text-stone-500">Prva slika je glavna. JPG, PNG, WEBP ili AVIF, najviše 5 MB. Prazan opis popunit će se nazivom i bojom.</p>

    <ConfirmDialog
      :open="removingIndex !== null"
      title="Ukloni sliku"
      confirm-label="Ukloni"
      @close="removingIndex = null"
      @confirm="remove"
    >
      Sigurno želiš ukloniti ovu sliku? Promjena vrijedi tek kad spremiš proizvod.
    </ConfirmDialog>
  </div>
</template>
