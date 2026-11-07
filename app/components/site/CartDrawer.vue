<script setup lang="ts">
import { X } from '@lucide/vue'

const route = useRoute()
const { items, isDrawerOpen, count, setQuantity, remove } = useCart()

const dialog = useTemplateRef<HTMLDialogElement>('dialog')
const isBusy = ref(false)
const error = ref('')

watch(isDrawerOpen, (isOpen) => {
  error.value = ''
  if (isOpen) dialog.value?.showModal()
  else dialog.value?.close()
})

// Prelazak na drugu stranicu (npr. Naruči) zatvara pregled.
watch(() => route.fullPath, () => {
  isDrawerOpen.value = false
})

const close = () => {
  isDrawerOpen.value = false
}

// Zatvara se samo klik koji je i počeo izvan ladice, a ne označavanje teksta otpušteno izvan nje.
const pressedOnBackdrop = ref(false)
function onBackdropClick() {
  if (pressedOnBackdrop.value) close()
  pressedOnBackdrop.value = false
}

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

const hasOverStock = computed(() => items.value.some((item) => item.quantity > item.stock))
</script>

<template>
  <dialog
    ref="dialog"
    aria-labelledby="kosarica-naslov"
    class="cart-drawer fixed inset-y-0 left-auto right-0 m-0 h-dvh max-h-dvh w-full max-w-md bg-ivory p-0 font-body text-ink backdrop:bg-ink/40"
    @cancel.prevent="close"
    @pointerdown="pressedOnBackdrop = $event.target === dialog"
    @click.self="onBackdropClick"
  >
    <div v-if="isDrawerOpen" class="flex h-full flex-col">
      <div class="flex items-center justify-between gap-4 border-b border-line px-5 py-3">
        <h2 id="kosarica-naslov" class="font-display text-2xl font-normal">Košarica<template v-if="count"> ({{ count }})</template></h2>
        <button type="button" aria-label="Zatvori košaricu" class="-mr-3 inline-flex size-11 items-center justify-center hover:text-gold" @click="close">
          <X class="size-5" stroke-width="1.25" />
        </button>
      </div>

      <div v-if="!items.length" class="flex flex-1 flex-col items-center justify-center gap-6 px-5 text-center">
        <p class="text-muted">Košarica je prazna.</p>
        <NuxtLink
          to="/proizvodi"
          class="inline-flex min-h-13 items-center justify-center border border-ink px-8 text-xs font-medium uppercase tracking-[0.2em] transition-colors hover:bg-ink hover:text-white"
        >
          Pogledaj kolekciju
        </NuxtLink>
      </div>

      <template v-else>
        <div class="flex-1 divide-y divide-line overflow-y-auto px-5">
          <CartItemRow
            v-for="item in items"
            :key="item.sizeId"
            :item="item"
            :disabled="isBusy"
            @quantity="(quantity) => run(() => setQuantity(item.sizeId, quantity))"
            @remove="run(() => remove(item.sizeId))"
          />
        </div>

        <div class="border-t border-line bg-sand px-5 py-5">
          <p v-if="error" role="alert" class="mb-3 text-sm text-red-700">{{ error }}</p>
          <CartTotals />
          <div class="mt-5 grid gap-2">
            <NuxtLink
              v-if="!hasOverStock"
              to="/kosarica"
              class="inline-flex min-h-13 items-center justify-center border border-ink bg-ink px-8 text-xs font-medium uppercase tracking-[0.2em] text-white transition-colors hover:bg-transparent hover:text-ink"
            >
              Naruči
            </NuxtLink>
            <p v-else class="text-sm text-red-700">Smanjite količinu označenih proizvoda prije narudžbe.</p>
            <button
              type="button"
              class="inline-flex min-h-13 items-center justify-center border border-line bg-white px-8 text-xs font-medium uppercase tracking-[0.2em] transition-colors hover:border-ink"
              @click="close"
            >
              Nastavi s kupnjom
            </button>
          </div>
        </div>
      </template>
    </div>
  </dialog>
</template>

<style scoped>
.cart-drawer[open] {
  animation: cart-drawer-in 0.25s ease-out;
}

@keyframes cart-drawer-in {
  from {
    transform: translateX(100%);
  }
}

@media (prefers-reduced-motion: reduce) {
  .cart-drawer[open] {
    animation: none;
  }
}
</style>
