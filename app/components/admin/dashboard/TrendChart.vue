<script setup lang="ts">
import { analyticsBucketLabel } from '~/composables/useDashboard'
import type { AnalyticsBucket } from '~/types/database'

// Jedna mjera kroz vrijeme, u stupcima jedne boje. Tablicu s istim podacima prikazuje SalesPeriodTable.
const props = defineProps<{
  points: { bucket: string; value: number }[]
  bucket: AnalyticsBucket
  label: string
  format: 'money' | 'count'
}>()

const axisFormat = new Intl.NumberFormat('hr-HR', { notation: 'compact', maximumFractionDigits: 1 })
const formatValue = (value: number) => (props.format === 'money' ? formatPrice(value) : String(value))

const max = computed(() => Math.max(0, ...props.points.map((point) => point.value)))
const axisMax = computed(() => (props.format === 'money' ? `${axisFormat.format(max.value)} KM` : axisFormat.format(max.value)))

// Oznake ispod osi samo na nekoliko mjesta, da se ne preklapaju.
const labelEvery = computed(() => Math.max(1, Math.ceil(props.points.length / 5)))

// Svaka točka je u sredini svog stupca (kao oznaka ispod osi), u postocima širine i visine.
// Vrh grafa je najveća vrijednost, kao i oznaka na osi.
const coordinates = computed(() => props.points.map((point, index) => ({
  x: ((index + 0.5) / props.points.length) * 100,
  y: 100 - (point.value / max.value) * 100,
})))
const linePoints = computed(() => coordinates.value.map(({ x, y }) => `${x},${y}`).join(' '))

const active = ref<number | null>(null)
</script>

<template>
  <p v-if="!max" class="py-8 text-center text-sm text-stone-500">Nema podataka u ovom razdoblju.</p>
  <div v-else>
    <div class="flex items-stretch gap-3">
      <!-- Os: najveća vrijednost i nula. Mreža je samo crta na dnu. -->
      <div class="flex w-16 shrink-0 flex-col justify-between whitespace-nowrap text-right text-xs tabular-nums text-stone-500">
        <span>{{ axisMax }}</span>
        <span>0</span>
      </div>
      <div class="relative h-48 min-w-0 flex-1 border-b border-primary-300">
        <!-- Linija od 2 px u jednoj boji. Debljina ostaje ista bez obzira na širinu grafa. -->
        <svg class="absolute inset-0 size-full overflow-visible text-primary-600" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">
          <polyline
            :points="linePoints"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linejoin="round"
            stroke-linecap="round"
            vector-effect="non-scaling-stroke"
          />
        </svg>

        <!-- Okomita crta i točka za razdoblje ispod miša. -->
        <template v-if="active !== null">
          <span class="pointer-events-none absolute inset-y-0 w-px bg-primary-300" :style="{ left: `${coordinates[active]!.x}%` }" aria-hidden="true" />
          <span
            class="pointer-events-none absolute size-2.5 -translate-x-1/2 -translate-y-1/2 rounded-full border-2 border-white bg-primary-800"
            :style="{ left: `${coordinates[active]!.x}%`, top: `${coordinates[active]!.y}%` }"
            aria-hidden="true"
          />
        </template>

        <!-- Nevidljiva polja preko cijele visine, po jedno za svako razdoblje, za miš i tipkovnicu. -->
        <div class="absolute inset-0 flex" role="list" :aria-label="label">
          <button
            v-for="(point, index) in points"
            :key="point.bucket"
            type="button"
            role="listitem"
            class="relative h-full min-w-0 flex-1 cursor-default focus:outline-none"
            :aria-label="`${analyticsBucketLabel(point.bucket, bucket)}: ${formatValue(point.value)}`"
            @mouseenter="active = index"
            @mouseleave="active = null"
            @focus="active = index"
            @blur="active = null"
          >
            <span
              v-if="active === index"
              class="pointer-events-none absolute top-0 z-10 whitespace-nowrap border border-primary-300 bg-white px-2.5 py-1.5 text-left text-xs text-stone-700"
              :class="index > points.length / 2 ? 'right-0' : 'left-0'"
            >
              <span class="block font-medium text-stone-900">{{ analyticsBucketLabel(point.bucket, bucket) }}</span>
              {{ label }}: {{ formatValue(point.value) }}
            </span>
          </button>
        </div>
      </div>
    </div>
    <div class="ml-19 mt-1.5 flex gap-px text-[11px] text-stone-500" aria-hidden="true">
      <span v-for="(point, index) in points" :key="point.bucket" class="flex min-w-0 flex-1 justify-center overflow-visible whitespace-nowrap">
        {{ index % labelEvery === 0 ? analyticsBucketLabel(point.bucket, bucket, true) : '' }}
      </span>
    </div>
  </div>
</template>
