// Custom VitePress theme with breadcrumbs and enhanced features
import { h } from 'vue'
import type { Theme } from 'vitepress'
import DefaultTheme from 'vitepress/theme'
import './custom.css'
import Breadcrumbs from './components/Breadcrumbs.vue'
import Monogram from './components/Monogram.vue'

export default {
  extends: DefaultTheme,
  Layout: () => {
    return h(DefaultTheme.Layout, null, {
      // Add breadcrumbs before doc content
      'doc-before': () => h(Breadcrumbs),
      // Add programmatic monogram before the nav title when no logo is configured
      'nav-bar-title-before': () => h(Monogram),
      
      // Could add other slot content here
      // 'doc-footer-before': () => h(SomeComponent),
      // 'nav-bar-title-after': () => h(SomeComponent),
    })
  },
  enhanceApp({ app, router, siteData }) {
    // Register global components
    app.component('Breadcrumbs', Breadcrumbs)
    app.component('Monogram', Monogram)
    
    // Add custom router guards or global properties if needed
    // router.beforeEach((to, from, next) => {
    //   // Custom routing logic
    //   next()
    // })
  }
} satisfies Theme 