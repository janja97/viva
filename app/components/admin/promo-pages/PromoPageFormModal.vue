<script setup lang="ts">
import type { Campaign, FaqItem, PromoPageInput, PromoPageWithCampaigns } from '~/types/database'

const props = defineProps<{
  open: boolean
  page: PromoPageWithCampaigns | null
  campaigns: Campaign[]
  loading?: boolean
  error?: string
}>()
const emit = defineEmits<{ close: []; save: [input: PromoPageInput, campaignIds: string[]] }>()

const form = reactive({
  title: '',
  intro: '',
  navLabel: '',
  metaTitle: '',
  metaDescription: '',
  offText: '',
  campaignIds: [] as string[],
  isActive: false,
  faq: [] as FaqItem[],
})
const localError = ref('')

watch(() => props.open, (isOpen) => {
  if (!isOpen || !props.page) return
  localError.value = ''
  const page = props.page
  form.title = page.title
  form.intro = page.intro
  form.navLabel = page.nav_label
  form.metaTitle = page.meta_title ?? ''
  form.metaDescription = page.meta_description ?? ''
  form.offText = page.off_text
  form.campaignIds = [...page.campaign_ids]
  form.isActive = page.is_active
  form.faq = structuredClone(toRaw(page.faq))
})

// Najveći popust prvi, kao i na webu.
const sortedCampaigns = computed(() => [...props.campaigns].sort((a, b) => b.discount_percent - a.discount_percent))

function toggleCampaign(id: string) {
  form.campaignIds = form.campaignIds.includes(id) ? form.campaignIds.filter((item) => item !== id) : [...form.campaignIds, id]
}

function submit() {
  localError.value = form.isActive && !form.campaignIds.length ? 'Za uključenu stranicu odaberi barem jednu kampanju, jer kampanje daju proizvode, postotke i datume.' : ''
  if (localError.value) return
  emit('save', {
    title: form.title.trim(),
    intro: form.intro.trim(),
    nav_label: form.navLabel.trim(),
    meta_title: form.metaTitle.trim() || null,
    meta_description: form.metaDescription.trim() || null,
    off_text: form.offText.trim(),
    is_active: form.isActive,
    faq: form.faq
      .map((item) => ({ question: item.question.trim(), answer: item.answer.trim() }))
      .filter((item) => item.question && item.answer),
  }, form.campaignIds)
}
</script>

<template>
  <BaseModal :open="open" :title="page ? `Uredi: /${page.slug}` : 'Akcijska stranica'" wide @close="emit('close')">
    <form class="space-y-4" @submit.prevent="submit">
      <BaseSwitch v-model="form.isActive" label="Uključena" hint="Dok je uključena i barem jedna kampanja traje, stranica prikazuje proizvode, a stavka Popust u izborniku vodi ovamo." />

      <fieldset>
        <legend class="mb-1.5 text-sm font-medium text-stone-700">Kampanje (popusti)</legend>
        <p v-if="!campaigns.length" class="text-xs text-stone-500">Još nema kampanja. Napravi ih u Kampanjama, npr. −20 %, −30 % i −50 %.</p>
        <ul v-else class="divide-y divide-primary-200 border border-primary-300">
          <li v-for="campaign in sortedCampaigns" :key="campaign.id">
            <label class="flex min-h-11 cursor-pointer items-center gap-3 px-3 text-sm sm:min-h-9">
              <input type="checkbox" class="size-4 accent-primary-600" :checked="form.campaignIds.includes(campaign.id)" @change="toggleCampaign(campaign.id)">
              <span class="w-12 shrink-0 font-display text-lg text-red-700">−{{ campaign.discount_percent }}%</span>
              <span class="min-w-0 flex-1 truncate">{{ campaignOptionLabel(campaign) }}</span>
            </label>
          </li>
        </ul>
        <p class="mt-1.5 text-xs text-stone-500">
          Svaki postotak je na stranici zaseban odjeljak, od najvećeg. Proizvode kampanjama dodjeljuješ na popisu proizvoda.
        </p>
      </fieldset>

      <div class="grid gap-4 sm:grid-cols-2">
        <BaseInput v-model="form.title" label="Naslov na stranici" :maxlength="80" required />
        <BaseInput v-model="form.navLabel" label="Naziv u izborniku" :maxlength="30" hint="Zamjenjuje Popust dok akcija traje." />
      </div>
      <BaseTextarea v-model="form.intro" label="Tekst za vrijeme akcije" :maxlength="1000" hint="Npr. vrijedi li i u trgovini u Mostaru i Sarajevu." />
      <BaseTextarea v-model="form.offText" label="Tekst izvan akcije" :maxlength="500" hint="Stranica ostaje i kad akcija ne traje, uz prijavu na newsletter." />
      <BaseInput v-model="form.metaTitle" label="Naslov za Google" :maxlength="70" :hint="`${form.metaTitle.length}/70`" />
      <BaseTextarea v-model="form.metaDescription" label="Opis za Google" :maxlength="170" :hint="`${form.metaDescription.length}/170`" />
      <CategoryFaqField v-model="form.faq" />
      <p class="text-xs text-stone-500">
        U tekstove možeš upisati <code class="bg-primary-100 px-1">{godina}</code>: to je godina početka akcije, a izvan nje tekuća godina.
      </p>
      <BaseAlert v-if="localError || error" type="error">{{ localError || error }}</BaseAlert>
      <div class="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
        <BaseButton variant="secondary" @click="emit('close')">Odustani</BaseButton>
        <BaseButton type="submit" :loading="loading">Spremi</BaseButton>
      </div>
    </form>
  </BaseModal>
</template>
