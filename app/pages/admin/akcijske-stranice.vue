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
const percentList = (page: PromoPageWithCampaigns) => page.is_exclusive ? 'proizvodi se dodaju pojedinačno i prikazuju samo ovdje' : pageCampaigns(page).map((campaign) => `−${campaign.discount_percent} %`).join(', ') || 'bez kampanje'

// Isto pravilo kao shop_promo_page: u tijeku je dok traje barem jedna kampanja, a odbrojava dok neka tek počinje.
function pageStatus(page: PromoPageWithCampaigns) {
  // Stranica s pojedinačno dodanim proizvodima je u tijeku čim je uključena.
  if (page.is_exclusive && page.is_active) return { label: 'U tijeku', color: 'bg-emerald-100 text-emerald-800' }
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
    <AdminPageHeader title="Akcijske stranice" description="Stalne stranice za akcije, npr. Čišćenje zaliha. Proizvode, postotak i datume daje kampanja." />

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
      <p>Čišćenje zaliha: 1. na popisu proizvoda označi kvačicom proizvode i odaberi "Dodaj u Čišćenje zaliha", 2. ovdje uključi stranicu. Dok je uključena, ti se proizvodi vide samo na /ciscenje-zaliha, a nema ih u kolekciji, kategorijama ni pretrazi.</p>
      <p>Sniženje daje kampanja, kao i dosad. Ostali proizvodi iste kampanje ostaju u trgovini.</p>
    </div>

    <template v-for="page in pages" :key="page.id">
      <PromoPageProducts v-if="page.is_exclusive" class="mt-8" :page="page" :can-write="canWrite" />
    </template>

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
