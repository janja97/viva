// ClothingStore JSON-LD (lokacija, radno vrijeme, kontakt) za stranice o trgovini: naslovna, kontakt, kupovina u Mostaru.
// Stranica ga poziva s await, da radno vrijeme i telefon budu u HTML-u sa servera.
// useHead mora biti prije await: nakon njega composable gubi Nuxtov kontekst.
export function useStoreJsonLd() {
  const { siteName, siteUrl } = useRuntimeConfig().public
  const origin = (siteUrl || useRequestURL().origin).replace(/\/$/, '')
  const storeSettings = useStoreSettings()

  useHead({
    script: [{
      key: 'store-json-ld',
      type: 'application/ld+json',
      innerHTML: computed(() => JSON.stringify(storeJsonLd(siteName, origin, storeSettings.settings.value))),
    }],
  })

  return storeSettings.ready()
}
