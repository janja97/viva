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

const categorySizeType = computed(() => sizeTypeForCategory(categories.value, form.category_id))
const isDress = computed(() => isDressCategory(categories.value, form.category_id))

// Pri promjeni kategorije vrsta veličina prati kategoriju (obuća, odjeća, torbice).
// Pri otvaranju postojećeg proizvoda ništa se ne mijenja, jer se kategorija tada ne mijenja.
watch(() => form.category_id, () => {
  const type = categorySizeType.value
  if (type && type !== form.size_type) applySizeType(form, type)
  if (!isDress.value) form.dress_length = ''
})

// Sniženje dolazi iz kampanje i vrijedi samo dok je ona aktivna.
const { campaigns, load: loadCampaigns } = useCampaigns()
const campaignOptions = computed(() => [
  { value: '', label: 'Bez kampanje' },
  ...campaigns.value.map((campaign) => ({ value: campaign.id, label: campaignOptionLabel(campaign) })),
])
const selectedCampaign = computed(() => campaigns.value.find((campaign) => campaign.id === form.campaign_id) ?? null)
const activeDiscount = computed(() => (
  selectedCampaign.value && campaignStatus(selectedCampaign.value) === 'active' ? selectedCampaign.value.discount_percent : null
))

const campaignHint = computed(() => {
  if (!selectedCampaign.value) return 'Neobavezno. Kampanje se uređuju na stranici Kampanje.'
  if (activeDiscount.value === null) return 'Kampanja trenutno nije aktivna, pa kupac plaća redovnu cijenu.'
  if (form.price === '') return `Sniženje ${activeDiscount.value} %.`
  return `Kupac plaća ${formatPrice(discountedPrice(Number(form.price), activeDiscount.value))}.`
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

// Uklanjanje boje uvijek traži potvrdu, jer odnosi i njezine količine i slike.
const removingColor = ref<{ index: number; name: string } | null>(null)

function removeColor() {
  if (!removingColor.value) return
  const [color] = form.colors.splice(removingColor.value.index, 1)
  color?.images.forEach((image) => images.discard(image.path))
  removingColor.value = null
}

function moveColor(index: number, direction: -1 | 1) {
  const target = index + direction
  ;[form.colors[index], form.colors[target]] = [form.colors[target]!, form.colors[index]!]
}

function validate() {
  if (!form.category_id) return 'Odaberi kategoriju.'
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
  loadCampaigns()
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
          <BaseSelect
            v-model="form.campaign_id"
            label="Kampanja (sniženje)"
            :options="campaignOptions"
            :hint="campaignHint"
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
        <ProductSizesField :form="form" :category-size-type="categorySizeType" />
        <BaseSelect
          v-if="form.size_type === 'footwear'"
          v-model="form.heel_height"
          class="mt-4 max-w-sm"
          label="Visina pete"
          :options="[{ value: '', label: 'Nije određeno' }, ...HEEL_HEIGHTS]"
          hint="Neobavezno. Koristi se za filter na webu."
        />
        <BaseSelect
          v-else-if="isDress"
          v-model="form.dress_length"
          class="mt-4 max-w-sm"
          label="Duljina haljine"
          :options="[{ value: '', label: 'Nije određeno' }, ...DRESS_LENGTHS]"
          hint="Neobavezno. Koristi se za filter na webu."
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
          @remove="removingColor = { index, name: color.name }"
          @move="moveColor(index, $event)"
        />
        <!-- Kod više boja gumb na vrhu je daleko, pa je isti i na dnu. -->
        <div v-if="form.colors.length" class="flex justify-end">
          <BaseButton variant="secondary" @click="addColor">
            <Plus class="size-4" stroke-width="2" />
            Dodaj boju
          </BaseButton>
        </div>
      </div>

      <AdminCard title="Materijal i održavanje">
        <div class="space-y-4">
          <BaseTextarea v-model="form.material" label="Sastav materijala" :maxlength="500" hint="Npr. 95% pamuk, 5% elastan. Kod tekstila se prikazuje kupcu." />
          <BaseTextarea v-model="form.care" label="Upute za održavanje" :maxlength="1000" />
          <BaseTextarea v-model="form.size_guide" label="Vodič za veličine" :maxlength="2000" hint="Npr. mjere po veličini ili duljina stopala u cm." />
          <BaseInput v-model="form.weight_grams" label="Masa (g)" type="number" inputmode="numeric" :min="0" step="1" hint="Neobavezno. Za izračun dostave." />
        </div>
      </AdminCard>

      <ProductSeoCard :form="form" :category-name="categoryName" :discount-percent="activeDiscount" />
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

    <ConfirmDialog
      :open="Boolean(removingColor)"
      title="Ukloni boju"
      confirm-label="Ukloni"
      @close="removingColor = null"
      @confirm="removeColor"
    >
      Sigurno želiš ukloniti boju {{ removingColor?.name || 'bez naziva' }} sa svim količinama i slikama? Promjena vrijedi tek kad spremiš proizvod.
    </ConfirmDialog>
  </form>
</template>
