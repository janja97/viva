<script setup lang="ts">
// Narudžba preko WhatsAppa (Postavke > Narudžbe, migracija 0035). Otvara WhatsApp s gotovom porukom,
// a kupac je pošalje sam. Upit se ne sprema u bazu i košarica ostaje, ako kupac poruku ipak ne pošalje.
const props = defineProps<{ phone: string }>()
const emit = defineEmits<{ cancel: [] }>()

const { items, promo } = useCart()
const { siteUrl } = useRuntimeConfig().public

const note = ref('')
const isOpened = ref(false)

const message = computed(() => whatsappOrderMessage({
  items: items.value,
  promoCode: promo.value?.code ?? null,
  note: note.value,
  origin: (siteUrl || window.location.origin).replace(/\/$/, ''),
}))
const url = computed(() => whatsappUrl(props.phone, message.value))

function open() {
  window.open(url.value, '_blank', 'noopener')
  isOpened.value = true
}

const labelClass = 'mb-1.5 block text-xs font-medium uppercase tracking-[0.16em]'
const buttonClass = 'inline-flex min-h-13 w-full items-center justify-center border px-8 text-xs font-medium uppercase tracking-[0.2em] transition-colors'
</script>

<template>
  <div class="space-y-5 font-body text-ink">
    <p class="text-sm leading-relaxed text-muted">
      Otvorit će se WhatsApp s popisom odabranih proizvoda, veličina i poveznica. Poruku samo pošaljete, a mi vam odgovaramo
      i dogovaramo dostavu ili preuzimanje.
    </p>

    <div>
      <label for="whatsapp-napomena" :class="labelClass">
        Poruka <span class="font-normal normal-case tracking-normal text-muted">(neobavezno)</span>
      </label>
      <textarea
        id="whatsapp-napomena"
        v-model="note"
        rows="3"
        maxlength="1000"
        placeholder="Npr. pitanje o veličini ili preuzimanje u trgovini"
        class="block w-full border border-line bg-white px-3 py-2 text-base text-ink focus:border-ink focus:outline-none"
      />
    </div>

    <p v-if="isOpened" role="status" class="text-sm text-emerald-700">
      WhatsApp je otvoren u novoj kartici ili aplikaciji. Ako se nije otvorio,
      <a :href="url" target="_blank" rel="noopener" class="underline underline-offset-4">kliknite ovdje</a>.
    </p>

    <div class="flex flex-col gap-2">
      <button type="button" :class="[buttonClass, 'border-ink bg-ink text-white hover:bg-transparent hover:text-ink']" @click="open">
        Otvori WhatsApp
      </button>
      <button type="button" :class="[buttonClass, 'border-line hover:border-ink']" @click="emit('cancel')">
        Natrag u košaricu
      </button>
    </div>
  </div>
</template>
