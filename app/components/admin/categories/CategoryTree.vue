<script setup lang="ts">
import type { Category } from '~/types/database'

defineProps<{
  tree: (Category & { children: (Category & { children: Category[] })[] })[]
  canWrite: boolean
}>()

const emit = defineEmits<{
  addChild: [parent: Category]
  edit: [category: Category]
  delete: [category: Category]
  move: [category: Category, direction: -1 | 1]
}>()
</script>

<template>
  <ul class="space-y-3">
    <li v-for="(main, mainIndex) in tree" :key="main.id" class="overflow-hidden rounded-xl border border-primary-300 bg-white shadow-sm">
      <CategoryRow
        :category="main"
        :is-first="mainIndex === 0"
        :is-last="mainIndex === tree.length - 1"
        :can-write="canWrite"
        can-add-child
        is-main
        @add-child="emit('addChild', main)"
        @edit="emit('edit', main)"
        @delete="emit('delete', main)"
        @move="emit('move', main, $event)"
      />
      <ul v-if="main.children.length" class="divide-y divide-primary-200 border-t border-primary-300">
        <li v-for="(child, childIndex) in main.children" :key="child.id">
          <CategoryRow
            :category="child"
            :is-first="childIndex === 0"
            :is-last="childIndex === main.children.length - 1"
            :can-write="canWrite"
            can-add-child
            @add-child="emit('addChild', child)"
            @edit="emit('edit', child)"
            @delete="emit('delete', child)"
            @move="emit('move', child, $event)"
          />
          <ul v-if="child.children.length" class="divide-y divide-primary-200 border-t border-primary-200 bg-primary-50 pl-4 sm:pl-8">
            <li v-for="(grandchild, grandchildIndex) in child.children" :key="grandchild.id">
              <CategoryRow
                :category="grandchild"
                :is-first="grandchildIndex === 0"
                :is-last="grandchildIndex === child.children.length - 1"
                :can-write="canWrite"
                @edit="emit('edit', grandchild)"
                @delete="emit('delete', grandchild)"
                @move="emit('move', grandchild, $event)"
              />
            </li>
          </ul>
        </li>
      </ul>
    </li>
  </ul>
</template>
