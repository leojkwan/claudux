import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Claudux',
  description: 'Documentation from your codebase',
  themeConfig: {
    outline: { level: [2,3], label: 'On this page' },
    sidebar: {
      '/': [
        { text: 'Getting Started', items: [
          { text: 'Welcome', link: '/' }
        ]}
      ]
    }
  },
  cleanUrls: true
})
