<script setup lang="ts">
import { Heart, Search, ShoppingBag, X } from '@lucide/vue'
import { PUBLIC_NAV, SHOP_NAV } from '~/config/navigation'

const route = useRoute()
const { siteName } = useRuntimeConfig().public
const categoryLink = useCategoryLink()
const isMenuOpen = ref(false)
const isSearchOpen = ref(route.path === '/pretraga')

const { count: cartCount, ensureLoaded: loadCart, isDrawerOpen } = useCart()
const { count: wishlistCount, ensureLoaded: loadWishlist } = useWishlist()

// Brojevi se učitavaju tek u pregledniku, jer sesija kupca postoji samo ondje.
onMounted(() => {
  loadCart().catch(console.error)
  loadWishlist().catch(console.error)
})

const iconClass = 'relative inline-flex size-11 items-center justify-center hover:text-gold'
const badgeClass = 'absolute right-0.5 top-1 flex h-4 min-w-4 items-center justify-center rounded-full bg-graphite px-1 text-[10px] font-medium leading-none text-white'

watch(() => route.fullPath, () => {
  isMenuOpen.value = false
  isSearchOpen.value = route.path === '/pretraga'
})

// Stavka bez postojeće kategorije također vodi na kolekciju, pa se aktivna ne prepoznaje po poveznici.
const isActive = (slug?: string) => route.path === (slug ? `/kategorija/${slug}` : '/proizvodi')

const linkClass ='inline-flex min-h-11 items-center text-xs font-medium uppercase tracking-[0.2em] transition-colors hover:text-gold'
</script>

<template>
  <header class="sticky top-0 z-40 border-b border-line bg-ivory">
    <div class="mx-auto grid min-h-17 max-w-7xl grid-cols-[1fr_auto_1fr] items-center px-4 sm:px-6 lg:min-h-21 lg:grid-cols-[auto_1fr_auto] lg:gap-10 lg:px-8">
      <MenuButton
        class="justify-self-start text-ink! hover:bg-sand! lg:hidden"
        :label="isMenuOpen ? 'Zatvori izbornik' : 'Otvori izbornik'"
        :expanded="isMenuOpen"
        :close="isMenuOpen"
        @click="isMenuOpen = !isMenuOpen"
      />

      <NuxtLink to="/" class="inline-flex min-h-11 items-center justify-self-center lg:justify-self-start" :aria-label="`${siteName}, početna`">
        <img src="/logo/logo-dark.png" :alt="siteName" width="400" height="214" class="h-13 w-auto lg:h-15">
      </NuxtLink>

      <nav aria-label="Glavna navigacija" class="hidden lg:block">
        <ul class="flex justify-center gap-5 xl:gap-9">
          <li v-for="link in SHOP_NAV" :key="link.label">
            <NuxtLink
              :to="categoryLink(link.slug)"
              :class="[linkClass, (link.highlight || isActive(link.slug)) && 'text-gold']"
              :aria-current="isActive(link.slug) ? 'page' : undefined"
            >
              {{ link.label }}
            </NuxtLink>
          </li>
        </ul>
      </nav>

      <div class="-mr-2 flex items-center justify-self-end">
        <button
          type="button"
          :aria-label="isSearchOpen ? 'Zatvori pretragu' : 'Otvori pretragu'"
          :aria-expanded="isSearchOpen"
          :class="iconClass"
          @click="isSearchOpen = !isSearchOpen"
        >
          <X v-if="isSearchOpen" class="size-5" stroke-width="1.25" />
          <Search v-else class="size-5" stroke-width="1.25" />
        </button>
        <NuxtLink to="/lista-zelja" :class="iconClass" :aria-label="`Lista želja${wishlistCount ? `, ${wishlistCount}` : ''}`">
          <Heart class="size-5" stroke-width="1.25" />
          <span v-if="wishlistCount" :class="badgeClass" aria-hidden="true">{{ wishlistCount }}</span>
        </NuxtLink>
        <button
          type="button"
          aria-haspopup="dialog"
          :class="iconClass"
          :aria-label="`Košarica${cartCount ? `, ${cartCount} kom` : ''}`"
          @click="isDrawerOpen = true"
        >
          <ShoppingBag class="size-5" stroke-width="1.25" />
          <span v-if="cartCount" :class="badgeClass" aria-hidden="true">{{ cartCount }}</span>
        </button>
      </div>
    </div>

    <div v-if="isSearchOpen" class="border-t border-line px-4 py-3 sm:px-6 lg:px-8">
      <SiteSearch class="mx-auto max-w-xl" />
    </div>

    <nav aria-label="Kategorije" class="flex gap-2 overflow-x-auto border-t border-line px-4 py-3 [scrollbar-width:none] sm:px-6 lg:hidden">
      <NuxtLink
        v-for="link in SHOP_NAV"
        :key="link.label"
        :to="categoryLink(link.slug)"
        class="inline-flex min-h-11 flex-none items-center border px-4 text-[11px] font-medium uppercase tracking-[0.16em]"
        :class="isActive(link.slug) ? 'border-graphite bg-graphite text-white' : 'border-line bg-white'"
        :aria-current="isActive(link.slug) ? 'page' : undefined"
      >
        {{ link.label }}
      </NuxtLink>
    </nav>

    <nav v-if="isMenuOpen" aria-label="Mobilna navigacija" class="border-t border-line lg:hidden">
      <ul class="px-4 py-2 sm:px-6">
        <li v-for="link in PUBLIC_NAV" :key="link.to">
          <NuxtLink :to="link.to" class="flex min-h-12 items-center text-xs font-medium uppercase tracking-[0.2em]" exact-active-class="text-gold">
            {{ link.label }}
          </NuxtLink>
        </li>
      </ul>
    </nav>
  </header>
</template>
