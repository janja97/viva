<script setup lang="ts">
import { ExternalLink, Pencil } from '@lucide/vue'
import type { PromoPageInput, PromoPageWithCampaigns } from '~/types/database'

definePageMeta({ layout: 'admin' })
usePageSeo({ title: 'Akcijske stranice', noindex: true })

const { can } = usePermissions()
const { pages, isLoading, loadError, load, save } = usePromoPages()
const { campaigns, load: loadCampaigns } = useCampaigns()

const canWrite = computed(() => can('write'))
const editing = ref<PromoPageWithCampaigns | null>(null)
const isSaving = ref(false)
const formError = ref('')

const pageCampaigns = (page: PromoPageWithCampaigns) => campaigns.value
  .filter((campaign) => page.campaign_ids.includes(campaign.id))
  .sort((a, b) => b.discount_percent - a.discount_percent)

// Npr. "−50 %, −30 %, −20 %", od najvećeg.
const percentList = (page: PromoPageWithCampaigns) => pageCampaigns(page).map((campaign) => `−${campaign.discount_percent} %`).join(', ') || 'bez kampanje'

// Isto pravilo kao shop_promo_page: u tijeku je dok traje barem jedna kampanja, a odbrojava dok neka tek počinje.
function pageStatus(page: PromoPageWithCampaigns) {
  const statuses = pageCampaigns(page).map((campaign) => campaignStatus(campaign))
  if (!page.is_active || !statuses.length) return { label: 'Isključena', color: 'bg-stone-200 text-stone-700' }
  const status = statuses.includes('active') ? 'active' : statuses.includes('scheduled') ? 'scheduled' : 'ended'
  if (status === 'active') return { label: 'U tijeku', color: 'bg-emerald-100 text-emerald-800' }
  if (status === 'scheduled') return { label: 'Odbrojava', color: 'bg-amber-100 text-amber-800' }
  return { label: 'Kampanja ne traje', color: 'bg-stone-200 text-stone-700' }
}

async function submit(input: PromoPageInput, campaignIds: string[]) {
  if (!editing.value) return
  isSaving.value = true
  formError.value = ''
  try {
    await save(editing.value.id, input, campaignIds)
    editing.value = null
  } catch (error) {
    formError.value = productErrorMessage(error)
  } finally {
    isSaving.value = false
  }
}

onMounted(() => Promise.all([load(), loadCampaigns()]))
</script>

<template>
  <div>
    <AdminPageHeader title="Akcijske stranice" description="Stalne stranice za akcije, npr. Black Friday. Proizvode, postotak i datume daje kampanja." />

    <p v-if="isLoading && !pages.length" class="text-sm text-stone-500">Učitavanje...</p>
    <div v-else-if="loadError" class="space-y-3">
      <BaseAlert type="error">{{ loadError }}</BaseAlert>
      <BaseButton variant="secondary" @click="load">Pokušaj ponovno</BaseButton>
    </div>
    <ul v-else class="divide-y divide-primary-200 border border-primary-300 bg-white">
      <li v-for="page in pages" :key="page.id" class="flex flex-wrap items-center gap-x-4 gap-y-2 px-4 py-3">
        <div class="min-w-0 flex-1">
          <p class="flex flex-wrap items-center gap-2">
            <span class="truncate text-sm font-medium text-stone-900">{{ page.title }}</span>
            <span class="rounded-md px-1.5 py-0.5 text-xs font-medium" :class="pageStatus(page).color">{{ pageStatus(page).label }}</span>
          </p>
          <p class="text-xs text-stone-500">/{{ page.slug }} · {{ percentList(page) }}</p>
        </div>
        <div class="flex items-center">
          <a :href="`/${page.slug}`" target="_blank" rel="noopener" :aria-label="`Otvori /${page.slug}`" :title="`Otvori /${page.slug}`" class="inline-flex size-11 items-center justify-center text-stone-500 hover:text-primary-700 sm:size-8">
            <ExternalLink class="size-4" stroke-width="1.75" />
          </a>
          <IconButton v-if="canWrite" :label="`Uredi: ${page.title}`" @click="editing = page; formError = ''">
            <Pencil class="size-4" stroke-width="1.75" />
          </IconButton>
        </div>
      </li>
    </ul>

    <div class="mt-4 max-w-2xl space-y-2 text-xs text-stone-500">
      <p>Kako pokrenuti Black Friday: 1. u Kampanjama napravi privremenu kampanju za svaki popust (npr. −20 %, −30 % i −50 %) s istim datumima, 2. na popisu proizvoda dodijeli proizvode kampanjama, 3. ovdje kvačicama odaberi te kampanje i uključi stranicu.</p>
      <p>Prije početka stranica odbrojava do početka, za vrijeme akcije prikazuje proizvode i odbrojava do kraja, a nakon kraja prikazuje tekst izvan akcije. Adresa ostaje ista svake godine.</p>
    </div>

    <PromoPageFormModal
      :open="Boolean(editing)"
      :page="editing"
      :campaigns="campaigns"
      :loading="isSaving"
      :error="formError"
      @close="editing = null"
      @save="submit"
    />
  </div>
</template>
