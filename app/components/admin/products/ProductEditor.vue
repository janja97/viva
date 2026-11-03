<script setup lang="ts">
import { Plus } from '@lucide/vue'
import { DRESS_LENGTHS, HEEL_HEIGHTS } from '~/config/products'
import type { ColorForm, ProductForm } from '~/types/productForm'

const props = defineProps<{
  initial: ProductForm
  isNew: boolean
  readOnly?: boolean
}>()

const { can } = usePermissions()
const { categories, load: loadCategories, isLoading: isLoadingCategories } = useCategories()
const { save, fetchBrands } = useProducts()

// Prijedlozi već upisanih brendova, kako bi se isti brend pisao uvijek jednako.
const brands = ref<string[]>([])

const form = reactive<ProductForm>(structuredClone(toRaw(props.initial)))
const images = useProductImages(form.id)

const canWrite = computed(() => can('write') && !props.readOnly)
const errorMessage = ref('')
const isSaved = ref(false)
const isSaving = ref(false)

const historyKey = ref(0)

const categoryName = computed(
  () => categories.value.find((category) => category.id === form.category_id)?.name ?? '',
)

const mainCategoryPathIds = computed(() => categoryPath(categories.value, form.category_id).map((category) => category.id))

const isValidDiscount = computed(() => {
  const percent = Number(form.discount_percent)
  return Number.isInteger(percent) && percent >= 1 && percent <= 99
})

const discountHint = computed(() => {
  if (form.discount_percent === '' || form.price === '' || !isValidDiscount.value) {
    return 'Neobavezno. Upiši samo broj, npr. 20. Kupac vidi izračunatu cijenu i prekriženu redovnu.'
  }
  return `Kupac plaća ${formatPrice(discountedPrice(Number(form.price), Number(form.discount_percent)))}.`
})

function colorSlug(color: ColorForm) {
  return slugify(`${form.name} ${color.name} ${form.sku}`)
}

// Šifra čini slug jedinstvenim kad više proizvoda ima isti naziv i boju.
watch(
  () => [form.name, form.sku, ...form.colors.map((color) => color.name)],
  () => {
    for (const color of form.colors) {
      if (color.autoSlug) color.slug = colorSlug(color)
    }
  },
)

function addColor() {
  form.colors.push({
    id: crypto.randomUUID(),
    name: '',
    hex: '#000000',
    slug: '',
    autoSlug: true,
    quantities: {},
    images: [],
  })
}

function removeColor(index: number) {
  const [color] = form.colors.splice(index, 1)
  color?.images.forEach((image) => images.discard(image.path))
}

function moveColor(index: number, direction: -1 | 1) {
  const target = index + direction
  ;[form.colors[index], form.colors[target]] = [form.colors[target]!, form.colors[index]!]
}

function validate() {
  if (!form.category_id) return 'Odaberi kategoriju.'
  if (form.discount_percent !== '' && !isValidDiscount.value) {
    return 'Sniženje mora biti cijeli broj od 1 do 99.'
  }
  if (!form.sizes.length) return 'Odaberi barem jednu veličinu.'
  if (!form.colors.length) return 'Dodaj barem jednu boju.'
  if (form.is_visible && form.colors.some((color) => !color.images.length)) {
    return 'Proizvod vidljiv na webu mora imati barem jednu sliku za svaku boju.'
  }
  return ''
}

async function onSubmit() {
  isSaved.value = false
  errorMessage.value = validate()
  if (errorMessage.value) return

  isSaving.value = true
  try {
    await save(form)
    await images.commit()
    if (props.isNew) {
      await navigateTo({ path: '/admin/proizvodi', query: { spremljeno: form.sku } })
    } else {
      isSaved.value = true
      historyKey.value++
    }
  } catch (error) {
    errorMessage.value = productErrorMessage(error)
  } finally {
    isSaving.value = false
  }
}

// Nova forma odmah ima prvu boju, kako bi polja za količine bila vidljiva.
if (props.isNew) addColor()

onMounted(() => {
  loadCategories()
  // Bez prijedloga se brend i dalje može upisati, pa greška ovdje nije važna.
  if (canWrite.value) fetchBrands().then((list) => { brands.value = list }).catch(() => {})
})
onBeforeUnmount(images.rollback)
</script>

<template>
  <form class="space-y-4 pb-24" @submit.prevent="onSubmit">
    <!-- U pregledu i kod čitatelja vide se svi podaci, ali su polja i gumbi isključeni. -->
    <fieldset :disabled="!canWrite" class="min-w-0 space-y-4">
      <AdminCard title="Osnovni podaci">
        <div class="grid gap-4 sm:grid-cols-2">
          <BaseInput v-model="form.sku" label="Šifra" :maxlength="50" required />
          <BaseInput v-model="form.name" label="Naziv" :maxlength="150" required />
          <BaseInput
            v-model="form.price"
            label="Cijena (KM, s PDV-om)"
            type="number"
            inputmode="decimal"
            :min="0"
            step="0.01"
            hint="Ista za sve boje i veličine."
            required
          />
          <BaseInput
            v-model="form.discount_percent"
            label="Sniženje (%)"
            type="number"
            inputmode="numeric"
            :min="1"
            :max="99"
            step="1"
            :hint="discountHint"
          />
          <BaseInput
            v-model="form.brand"
            label="Brend (neobavezno)"
            :maxlength="80"
            :suggestions="brands"
            hint="Interni podatak. Kupci ga ne vide."
          />
          <ProductCategoryPicker
            v-model="form.category_id"
            class="sm:col-span-2"
            :categories="categories"
            :disabled="isLoadingCategories"
          />
          <ProductExtraCategories
            v-model="form.extra_category_ids"
            class="sm:col-span-2"
            :options="categoryOptions(categories)"
            :excluded-ids="mainCategoryPathIds"
          />
          <BaseTextarea v-model="form.description" class="sm:col-span-2" label="Opis" :maxlength="5000" />
        </div>
      </AdminCard>

      <AdminCard title="Prikaz na webu">
        <div class="divide-y divide-primary-200">
          <BaseSwitch v-model="form.is_visible" class="py-1" label="Vidljiv na webu" hint="Ako je isključeno, kupci ne vide proizvod." />
          <BaseSwitch
            v-model="form.store_only"
            class="py-1"
            label="Samo u poslovnicama"
            hint="Prikazuje se na webu, ali se ne može kupiti. Piše: Dostupno samo u poslovnicama."
          />
        </div>
      </AdminCard>

      <AdminCard title="Veličine">
        <ProductSizesField :form="form" />
        <BaseSelect
          v-if="form.size_type === 'footwear'"
          v-model="form.heel_height"
          class="mt-4 max-w-sm"
          label="Visina pete"
          :options="[{ value: '', label: 'Nije određeno' }, ...HEEL_HEIGHTS]"
          hint="Neobavezno. Koristi se za filter na webu."
        />
        <BaseSelect
          v-else-if="form.size_type === 'clothing'"
          v-model="form.dress_length"
          class="mt-4 max-w-sm"
          label="Duljina haljine"
          :options="[{ value: '', label: 'Nije određeno' }, ...DRESS_LENGTHS]"
          hint="Neobavezno. Samo za haljine, koristi se za filter na webu."
        />
      </AdminCard>

      <div class="space-y-3">
        <div class="flex items-center justify-between gap-4">
          <h2 class="font-display text-2xl font-normal leading-tight">Boje, količine i slike</h2>
          <BaseButton variant="secondary" @click="addColor">
            <Plus class="size-4" stroke-width="2" />
            Dodaj boju
          </BaseButton>
        </div>
        <p v-if="!form.colors.length" class="rounded-xl border border-dashed border-primary-300 bg-white px-4 py-8 text-center text-sm text-stone-500">
          Još nema boja. Na popisu shopa svaka boja će biti zasebna kartica.
        </p>
        <ProductColorCard
          v-for="(color, index) in form.colors"
          :key="color.id"
          :color="color"
          :sizes="form.sizes"
          :used-colors="form.colors.filter((other) => other.id !== color.id).map((other) => other.name)"
          :generated-slug="colorSlug(color)"
          :api="images"
          :is-first="index === 0"
          :is-last="index === form.colors.length - 1"
          @remove="removeColor(index)"
          @move="moveColor(index, $event)"
        />
      </div>

      <AdminCard title="Materijal i održavanje">
        <div class="space-y-4">
          <BaseTextarea v-model="form.material" label="Sastav materijala" :maxlength="500" hint="Npr. 95% pamuk, 5% elastan. Kod tekstila se prikazuje kupcu." />
          <BaseTextarea v-model="form.care" label="Upute za održavanje" :maxlength="1000" />
          <BaseTextarea v-model="form.size_guide" label="Vodič za veličine" :maxlength="2000" hint="Npr. mjere po veličini ili duljina stopala u cm." />
          <BaseInput v-model="form.weight_grams" label="Masa (g)" type="number" inputmode="numeric" :min="0" step="1" hint="Neobavezno. Za izračun dostave." />
        </div>
      </AdminCard>

      <ProductSeoCard :form="form" :category-name="categoryName" />
    </fieldset>

    <ProductHistory v-if="!isNew" :product-id="form.id" :refresh-key="historyKey" />

    <div v-if="canWrite" class="fixed inset-x-0 bottom-0 z-20 border-t border-primary-300 bg-white px-4 py-3 sm:px-6 lg:left-60 lg:px-8">
      <div class="mx-auto flex max-w-5xl flex-wrap items-center justify-end gap-3">
        <BaseAlert v-if="errorMessage" type="error" class="w-full sm:mr-auto sm:w-auto">{{ errorMessage }}</BaseAlert>
        <BaseAlert v-else-if="isSaved" type="success" class="w-full sm:mr-auto sm:w-auto">Proizvod je spremljen.</BaseAlert>
        <NuxtLink to="/admin/proizvodi" class="inline-flex min-h-11 items-center rounded-lg px-3.5 text-sm font-medium text-stone-700 hover:bg-primary-100 sm:min-h-9">
          Natrag
        </NuxtLink>
        <BaseButton type="submit" :loading="isSaving">{{ isSaving ? 'Spremanje...' : 'Spremi proizvod' }}</BaseButton>
      </div>
    </div>
  </form>
</template>
