<script setup lang="ts">
import { computed } from 'vue'
import { useData } from 'vitepress'

const deriveInitials = (name: string): string => {
  const fallback = 'DD'
  if (!name) return fallback
  const cleaned = name
    .replace(/[_\-]+/g, ' ')
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .trim()
  const tokens = cleaned.split(/\s+/).filter(Boolean)
  if (tokens.length >= 2) {
    return (tokens[0][0] + tokens[1][0]).toUpperCase()
  }
  const token = tokens[0] || name
  const camelSplits = token.replace(/([A-Z])/g, ' $1').split(/\s+/).filter(Boolean)
  if (camelSplits.length >= 2) {
    return (camelSplits[0][0] + camelSplits[1][0]).toUpperCase()
  }
  const firstTwo = Array.from(token).slice(0, 2).join('')
  if (firstTwo.length === 2) return firstTwo.toUpperCase()
  if (firstTwo.length === 1) return (firstTwo + firstTwo).toUpperCase()
  return fallback
}

const { site } = useData()

const hasLogo = computed(() => {
  const logo = (site.value.themeConfig as any)?.logo
  if (!logo) return false
  if (typeof logo === 'string') return !!logo
  if (typeof logo === 'object' && logo !== null) return !!(logo as any).src
  return false
})

const siteTitle = computed(() => ((site.value.themeConfig as any)?.siteTitle || site.value.title || 'Docs') as string)
const initials = computed(() => deriveInitials(siteTitle.value))
</script>

<template>
  <span v-if="!hasLogo" class="vp-monogram" :aria-label="siteTitle">
    {{ initials }}
  </span>
</template>

<style scoped>
.vp-monogram {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  margin-right: 8px;
  border-radius: 6px;
  background: var(--vp-c-brand-2, var(--vp-c-brand));
  color: #ffffff;
  font-weight: 700;
  font-size: 12px;
  letter-spacing: 0.5px;
  text-transform: uppercase;
}
</style>


