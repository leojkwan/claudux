<template>
  <nav v-if="breadcrumbs.length > 1" class="breadcrumbs" aria-label="Breadcrumb">
    <ol class="breadcrumb-list">
      <li v-for="(crumb, index) in breadcrumbs" :key="crumb.path" class="breadcrumb-item">
        <a 
          v-if="index < breadcrumbs.length - 1" 
          :href="withBase(crumb.path)" 
          class="breadcrumb-link"
          :aria-label="`Go to ${crumb.text}`"
        >
          <span class="breadcrumb-icon" v-if="crumb.icon">{{ crumb.icon }}</span>
          {{ crumb.text }}
        </a>
        <span v-else class="breadcrumb-current" :aria-current="'page'">
          <span class="breadcrumb-icon" v-if="crumb.icon">{{ crumb.icon }}</span>
          {{ crumb.text }}
        </span>
        <svg 
          v-if="index < breadcrumbs.length - 1" 
          class="breadcrumb-separator" 
          width="16" 
          height="16" 
          viewBox="0 0 16 16" 
          fill="none"
          aria-hidden="true"
        >
          <path d="M6 4L10 8L6 12" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </li>
    </ol>
  </nav>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useData, useRoute, withBase } from 'vitepress'

const { site } = useData()
const route = useRoute()

interface BreadcrumbItem {
  text: string
  path: string
  icon?: string
}

const breadcrumbs = computed<BreadcrumbItem[]>(() => {
  // Normalize route path to strip site base so links don't double-prefix base in production
  const base = site.value.base || '/'
  let normalizedPath = route.path
  if (base !== '/' && normalizedPath.startsWith(base)) {
    normalizedPath = normalizedPath.slice(base.length)
    if (!normalizedPath.startsWith('/')) normalizedPath = '/' + normalizedPath
  }
  const segments = normalizedPath.split('/').filter(Boolean)
  
  // Always start with home
  const crumbs: BreadcrumbItem[] = [
    { text: 'Home', path: '/', icon: '🏠' }
  ]
  
  // Build breadcrumbs from path segments
  let currentPath = ''
  
  for (let i = 0; i < segments.length; i++) {
    currentPath += '/' + segments[i]
    
    // Skip if this is an index file (will be handled by parent)
    if (segments[i] === 'index') continue
    
    let text = segments[i]
    let icon = ''
    
    // Add icons and better names for common sections
    switch (segments[i]) {
      case 'guide':
        text = 'Guide'
        icon = '📚'
        break
      case 'technical':
        text = 'Technical'
        icon = '⚙️'
        break
      case 'features':
        text = 'Features'
        icon = '✨'
        break
      case 'testing':
        text = 'Testing'
        icon = '🧪'
        break
      case 'data-models':
        text = 'Data Models'
        icon = '📊'
        break
      // keep mapping minimal and platform-agnostic
      default:
        // Convert kebab-case to Title Case
        text = segments[i]
          .split('-')
          .map(word => word.charAt(0).toUpperCase() + word.slice(1))
          .join(' ')
    }
    
    crumbs.push({
      text,
      path: currentPath,
      icon
    })
  }
  
  return crumbs
})
</script>

<style scoped>
.breadcrumbs {
  margin-bottom: 1.5rem;
  padding: 0.75rem 0;
  border-bottom: 1px solid var(--vp-c-divider);
}

.breadcrumb-list {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 0.25rem;
  margin: 0;
  padding: 0;
  list-style: none;
  font-size: 0.875rem;
}

.breadcrumb-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.breadcrumb-link {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.25rem 0.5rem;
  border-radius: 0.375rem;
  color: var(--vp-c-text-2);
  text-decoration: none;
  transition: all 0.2s ease;
  border: 1px solid transparent;
}

.breadcrumb-link:hover {
  color: var(--vp-c-brand-1);
  background-color: var(--vp-c-default-soft);
  border-color: var(--vp-c-brand-soft);
}

.breadcrumb-current {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.25rem 0.5rem;
  color: var(--vp-c-text-1);
  font-weight: 500;
  background-color: var(--vp-c-brand-soft);
  border-radius: 0.375rem;
  border: 1px solid var(--vp-c-brand-soft);
}

.breadcrumb-icon {
  font-size: 0.875rem;
  line-height: 1;
}

.breadcrumb-separator {
  color: var(--vp-c-text-3);
  flex-shrink: 0;
}

/* Responsive adjustments */
@media (max-width: 768px) {
  .breadcrumbs {
    margin-bottom: 1rem;
    padding: 0.5rem 0;
  }
  
  .breadcrumb-list {
    font-size: 0.8125rem;
  }
  
  .breadcrumb-link,
  .breadcrumb-current {
    padding: 0.1875rem 0.375rem;
  }
  
  .breadcrumb-icon {
    font-size: 0.8125rem;
  }
}

/* Dark mode specific adjustments */
@media (prefers-color-scheme: dark) {
  .breadcrumb-link:hover {
    background-color: var(--vp-c-default-soft);
  }
}
</style> 