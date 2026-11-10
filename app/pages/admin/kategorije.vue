<script setup lang="ts">
import { Plus } from '@lucide/vue'
import type { Category } from '~/types/database'
import type { CategoryInput } from '~/composables/useCategories'

definePageMeta({ layout: 'admin' })
usePageSeo({ title: 'Kategorije', noindex: true })

const { can } = usePermissions()
const { categories, tree, isLoading, loadError, load, save, remove, move } = useCategories()

const canWrite = computed(() => can('write'))
const actionError = ref('')

const isFormOpen = ref(false)
const editing = ref<Category | null>(null)
const defaultParentId = ref<string | null>(null)

const deleting = ref<Category | null>(null)
const deleteError = ref('')
const isDeleting = ref(false)

function openForm(category: Category | null, parentId: string | null = null) {
  editing.value = category
  defaultParentId.value = parentId
  isFormOpen.value = true
}

async function submitForm(input: CategoryInput) {
  await save(input, editing.value)
  isFormOpen.value = false
}

function askDelete(category: Category) {
  deleteError.value = ''
  deleting.value = category
}

async function confirmDelete() {
  if (!deleting.value) return
  isDeleting.value = true
  deleteError.value = ''
  try {
    await remove(deleting.value.id)
    deleting.value = null
  } catch (error) {
    deleteError.value = categoryErrorMessage(error)
  } finally {
    isDeleting.value = false
  }
}

async function onMove(category: Category, direction: -1 | 1) {
  actionError.value = ''
  try {
    await move(category, direction)
  } catch (error) {
    actionError.value = categoryErrorMessage(error)
  }
}

onMounted(load)
</script>

<template>
  <div>
    <AdminPageHeader title="Kategorije" description="Glavne kategorije i podkategorije, u najviše tri razine.">
      <BaseButton v-if="canWrite" @click="openForm(null)">
        <Plus class="size-4" stroke-width="2" />
        Nova kategorija
      </BaseButton>
    </AdminPageHeader>

    <BaseAlert v-if="actionError" type="error" class="mb-4">{{ actionError }}</BaseAlert>

    <p v-if="isLoading && !categories.length" class="text-sm text-stone-500">Učitavanje...</p>
    <div v-else-if="loadError" class="space-y-3">
      <BaseAlert type="error">{{ loadError }}</BaseAlert>
      <BaseButton variant="secondary" @click="load">Pokušaj ponovno</BaseButton>
    </div>
    <p v-else-if="!tree.length" class="rounded-xl border border-dashed border-primary-300 bg-white px-4 py-12 text-center text-sm text-stone-500">
      Još nema kategorija.
    </p>
    <CategoryTree
      v-else
      :tree="tree"
      :can-write="canWrite"
      @add-child="openForm(null, $event.id)"
      @edit="openForm($event)"
      @delete="askDelete"
      @move="onMove"
    />

    <BaseModal :open="isFormOpen" :title="editing ? 'Uredi kategoriju' : 'Nova kategorija'" wide @close="isFormOpen = false">
      <CategoryForm
        :category="editing"
        :default-parent-id="defaultParentId"
        :categories="categories"
        :submit="submitForm"
        @cancel="isFormOpen = false"
      />
    </BaseModal>

    <ConfirmDialog
      :open="Boolean(deleting)"
      title="Obriši kategoriju"
      confirm-label="Obriši"
      :loading="isDeleting"
      :error="deleteError"
      @close="deleting = null"
      @confirm="confirmDelete"
    >
      Sigurno želiš obrisati kategoriju „{{ deleting?.name }}”? Ova radnja se ne može poništiti.
    </ConfirmDialog>
  </div>
</template>
