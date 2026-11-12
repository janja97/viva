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
// Upozorenja za slabije slike (imageQualityWarnings). Slika se svejedno doda.
const qualityWarnings = ref<{ file: string; messages: string[] }[]>([])

function onFiles(event: Event) {
  const input = event.target as HTMLInputElement
  const files = [...(input.files ?? [])]
  input.value = ''
  uploadFiles(files)
}

async function uploadFiles(files: File[]) {
  errorMessage.value = ''
  qualityWarnings.value = []

  const images = files.filter((file) => IMAGE_EXTENSIONS[file.type])
  if (images.length < files.length) errorMessage.value = 'Neke datoteke nisu slike pa su preskočene. Dopuštene su JPG, PNG, WEBP i AVIF.'

  for (const file of images) {
    uploadingCount.value++
    try {
      const messages = await imageQualityWarnings(file)
      if (messages.length) qualityWarnings.value.push({ file: file.name, messages })
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

// Povlačenje: datoteke s računala se dodaju, a postojeće slike se povlačenjem premještaju.
// Strelice ostaju za mobitel i tipkovnicu.
const isDraggingFiles = ref(false)
let dragDepth = 0
const draggedIndex = ref<number | null>(null)
const hasFiles = (event: DragEvent) => event.dataTransfer?.types.includes('Files') ?? false

function onDragEnter(event: DragEvent) {
  if (!hasFiles(event)) return
  dragDepth++
  isDraggingFiles.value = true
}

function onDragLeave(event: DragEvent) {
  if (!hasFiles(event)) return
  dragDepth = Math.max(0, dragDepth - 1)
  if (!dragDepth) isDraggingFiles.value = false
}

function onDrop(event: DragEvent) {
  dragDepth = 0
  isDraggingFiles.value = false
  const files = [...(event.dataTransfer?.files ?? [])]
  if (files.length) uploadFiles(files)
}

function onImageDrop(target: number) {
  const from = draggedIndex.value
  draggedIndex.value = null
  if (from === null || from === target) return
  const { images } = props.color
  const [image] = images.splice(from, 1)
  images.splice(target, 0, image!)
}
</script>

<template>
  <div>
    <p class="mb-1.5 text-sm font-medium text-stone-700">Slike</p>
    <BaseAlert v-if="errorMessage" type="error" class="mb-2">{{ errorMessage }}</BaseAlert>
    <div v-if="qualityWarnings.length" role="status" class="mb-2 border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-800">
      <p class="font-medium">Slika je dodana, ali provjeri kvalitetu:</p>
      <ul class="mt-1 space-y-1">
        <li v-for="warning in qualityWarnings" :key="warning.file">
          <span class="font-medium">{{ warning.file }}</span>: {{ warning.messages.join(' ') }}
        </li>
      </ul>
    </div>

    <!-- Cijelo polje prima slike povučene s računala. -->
    <div
      class="relative -m-2 p-2 transition-colors"
      :class="isDraggingFiles && 'bg-primary-100 outline-2 outline-dashed outline-primary-600'"
      @dragenter.prevent="onDragEnter"
      @dragover.prevent
      @dragleave="onDragLeave"
      @drop.prevent="onDrop"
    >
    <p v-if="isDraggingFiles" class="pointer-events-none absolute inset-0 z-10 flex items-center justify-center text-sm font-medium text-primary-800">
      Ispusti slike ovdje
    </p>
    <ul class="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4" :class="isDraggingFiles && 'opacity-40'">
      <li
        v-for="(image, index) in color.images"
        :key="image.id"
        draggable="true"
        class="cursor-grab overflow-hidden rounded-lg border bg-white active:cursor-grabbing"
        :class="draggedIndex === index ? 'border-primary-600 opacity-50' : 'border-primary-300'"
        @dragstart="draggedIndex = index"
        @dragend="draggedIndex = null"
        @dragover.prevent
        @drop.prevent.stop="draggedIndex !== null ? onImageDrop(index) : onDrop($event)"
      >
        <div class="relative">
          <img :src="api.urlFor(image.path)" :alt="image.alt || `${color.name} ${index + 1}`" loading="lazy" draggable="false" class="aspect-square w-full object-cover">
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
          {{ uploadingCount ? `Slanje (${uploadingCount})...` : 'Dodaj slike' }}
          <span v-if="!uploadingCount" class="hidden text-xs text-primary-700 sm:block">ili ih povuci ovamo</span>
          <input type="file" class="sr-only" multiple :accept="accept" @change="onFiles">
        </label>
      </li>
    </ul>
    </div>
    <p class="mt-1.5 text-xs text-stone-500">
      Slike možeš povući s računala, a redoslijed promijeniti povlačenjem ili strelicama. Prva slika je glavna. Najbolje uspravne, barem {{ RECOMMENDED_IMAGE.width }} × {{ RECOMMENDED_IMAGE.height }} px.
      JPG, PNG, WEBP ili AVIF do 25 MB, a slika se sama smanji i pretvori u WebP. Prazan opis popunit će se nazivom i bojom.
    </p>

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
