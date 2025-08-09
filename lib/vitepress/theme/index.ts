// Custom VitePress theme with breadcrumbs and enhanced features
import { h } from 'vue'
import type { Theme } from 'vitepress'
import DefaultTheme from 'vitepress/theme'
import './custom.css'
import Breadcrumbs from './components/Breadcrumbs.vue'

export default {
  extends: DefaultTheme,
  Layout: () => {
    return h(DefaultTheme.Layout, null, {
      // Add breadcrumbs before doc content
      'doc-before': () => h(Breadcrumbs),
      
      // Could add other slot content here
      // 'doc-footer-before': () => h(SomeComponent),
      // 'nav-bar-title-after': () => h(SomeComponent),
    })
  },
  enhanceApp({ app, router, siteData }) {
    // Register global components
    app.component('Breadcrumbs', Breadcrumbs)
    
    // Add custom router guards or global properties if needed
    // router.beforeEach((to, from, next) => {
    //   // Custom routing logic
    //   next()
    // })
  }
} satisfies Theme 