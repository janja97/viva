<script setup lang="ts">
import type { InquiryCustomer } from '~/composables/useCart'

usePageSeo({ title: 'Košarica', noindex: true })

const { items, isLoaded, load, setQuantity, remove, submitInquiry } = useCart()

const isFormOpen = ref(false)
const isBusy = ref(false)
const error = ref('')
const formError = ref('')
const orderNumber = ref<number | null>(null)

const hasOverStock = computed(() => items.value.some((item) => item.quantity > item.stock))

async function run(action: () => Promise<unknown>) {
  isBusy.value = true
  error.value = ''
  try {
    await action()
  } catch (caught) {
    error.value = shopErrorMessage(caught)
  } finally {
    isBusy.value = false
  }
}

function openForm() {
  formError.value = ''
  isFormOpen.value = true
}

async function onSubmit(customer: InquiryCustomer) {
  isBusy.value = true
  formError.value = ''
  try {
    orderNumber.value = await submitInquiry(customer)
    isFormOpen.value = false
  } catch (caught) {
    formError.value = shopErrorMessage(caught)
  } finally {
    isBusy.value = false
  }
}

// Uvijek svježi podaci, jer se cijena ili stanje mogu promijeniti dok je košarica otvorena.
onMounted(() => run(load))
</script>

<template>
  <div class="mx-auto max-w-6xl px-4 pb-20 pt-8 sm:px-6 lg:px-8 lg:pt-12">
    <h1 class="font-display text-4xl font-normal leading-tight lg:text-5xl">Košarica</h1>

    <p v-if="!isLoaded" class="mt-8 text-muted">Učitavanje...</p>

    <div v-else-if="!items.length" class="mt-8 border-y border-line py-16 text-center">
      <p class="text-muted">Košarica je prazna.</p>
      <p v-if="error" role="alert" class="mt-3 text-sm text-red-700">{{ error }}</p>
      <SiteLink to="/proizvodi" class="mt-6">Pogledaj kolekciju</SiteLink>
    </div>

    <div v-else class="mt-8 grid gap-10 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)] lg:gap-16">
      <div>
        <div class="divide-y divide-line border-y border-line">
          <CartItemRow
            v-for="item in items"
            :key="item.sizeId"
            :item="item"
            :disabled="isBusy"
            @quantity="(quantity) => run(() => setQuantity(item.sizeId, quantity))"
            @remove="run(() => remove(item.sizeId))"
          />
        </div>
        <p v-if="error" role="alert" class="mt-4 text-sm text-red-700">{{ error }}</p>
      </div>

      <aside class="self-start bg-sand p-6 lg:sticky lg:top-28 lg:p-8" aria-label="Sažetak">
        <h2 class="mb-4 font-display text-2xl font-normal">Sažetak</h2>
        <CartTotals />
        <button
          type="button"
          aria-haspopup="dialog"
          :disabled="isBusy || hasOverStock"
          class="mt-6 inline-flex min-h-13 w-full items-center justify-center border border-ink bg-ink px-8 text-xs font-medium uppercase tracking-[0.2em] text-white transition-colors hover:bg-transparent hover:text-ink disabled:cursor-not-allowed disabled:opacity-60"
          @click="openForm"
        >
          Naruči
        </button>
      </aside>
    </div>

    <BaseModal :open="isFormOpen" title="Podaci za dostavu" @close="isFormOpen = false">
      <InquiryForm :loading="isBusy" :error="formError" @submit="onSubmit" @cancel="isFormOpen = false" />
    </BaseModal>

    <!-- Košarica je već prazna, pa nakon potvrde kupac ide na naslovnu. -->
    <OrderSuccessModal :number="orderNumber" @close="navigateTo('/')" />
  </div>
</template>
