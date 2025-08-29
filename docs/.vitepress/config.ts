import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'claudux',
  description: 'AI-powered documentation generator for your codebase using Claude Code and VitePress',
  base: (process.env.DOCS_BASE as string) || '/',
  
  // Ignore localhost links during static builds
  ignoreDeadLinks: [
    /^https?:\/\/localhost/
  ],
  
  head: [
    ['meta', { name: 'theme-color', content: '#5f67ee' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:locale', content: 'en' }],
    ['meta', { property: 'og:title', content: 'claudux Documentation' }],
    ['meta', { property: 'og:site_name', content: 'claudux Docs' }],
    ['meta', { property: 'og:url', content: '/' }],
  ],

  cleanUrls: true,

  markdown: {
    theme: { light: 'github-light', dark: 'github-dark' },
    lineNumbers: true
  },

  themeConfig: {
    siteTitle: 'claudux',

    nav: [
      { text: 'Guide', link: '/guide/', activeMatch: '/guide/' },
      { text: 'Features', link: '/features/', activeMatch: '/features/' },
      { text: 'Technical', link: '/technical/', activeMatch: '/technical/' },
      { text: 'API', link: '/api/', activeMatch: '/api/' }
    ],

    sidebar: {
      '/': [
        {
          text: '🚀 Getting Started',
          collapsed: false,
          items: [
            { text: 'Overview', link: '/guide/' },
            { text: 'Installation', link: '/guide/installation' },
            { text: 'Commands', link: '/guide/commands' },
            { text: 'Configuration', link: '/guide/configuration' }
          ]
        },
        {
          text: '✨ Features',
          collapsed: false,
          items: [
            { text: 'Overview', link: '/features/' },
            { text: 'Two-Phase Generation', link: '/features/two-phase-generation' },
            { text: 'Smart Cleanup', link: '/features/smart-cleanup' },
            { text: 'Content Protection', link: '/features/content-protection' }
          ]
        },
        {
          text: '🔧 Technical',
          collapsed: true,
          items: [
            { text: 'Architecture', link: '/technical/' },
            { text: 'Templates', link: '/technical/templates' }
          ]
        },
        {
          text: '📚 Reference',
          collapsed: true,
          items: [
            { text: 'Examples', link: '/examples/' },
            { text: 'API Reference', link: '/api/' },
            { text: 'Troubleshooting', link: '/troubleshooting' }
          ]
        }
      ],
      '/guide/': [
        {
          text: '🚀 Getting Started',
          collapsed: false,
          items: [
            { text: 'Overview', link: '/guide/' },
            { text: 'Installation', link: '/guide/installation' },
            { text: 'Commands', link: '/guide/commands' },
            { text: 'Configuration', link: '/guide/configuration' }
          ]
        }
      ],
      '/features/': [
        {
          text: '✨ Features',
          collapsed: false,
          items: [
            { text: 'Overview', link: '/features/' },
            { text: 'Two-Phase Generation', link: '/features/two-phase-generation' },
            { text: 'Smart Cleanup', link: '/features/smart-cleanup' },
            { text: 'Content Protection', link: '/features/content-protection' }
          ]
        }
      ],
      '/technical/': [
        {
          text: '🔧 Technical',
          collapsed: false,
          items: [
            { text: 'Architecture', link: '/technical/' },
            { text: 'Templates', link: '/technical/templates' }
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/leojkwan/claudux' },
      { icon: { svg: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M18.7 2.3c-1.1-1.1-2.7-1.1-3.8 0L11.3 5.9c-1.1 1.1-1.1 2.7 0 3.8L12.5 11c0.5 0.5 1.3 0.5 1.8 0c0.5-0.5 0.5-1.3 0-1.8l-1.2-1.2c-0.2-0.2-0.2-0.5 0-0.7l3.5-3.5c0.2-0.2 0.5-0.2 0.7 0l4.4 4.4c0.2 0.2 0.2 0.5 0 0.7l-3.5 3.5c-0.2 0.2-0.5 0.2-0.7 0l-1.2-1.2c-0.5-0.5-1.3-0.5-1.8 0c-0.5 0.5-0.5 1.3 0 1.8l1.2 1.2c1.1 1.1 2.7 1.1 3.8 0l3.5-3.5c1.1-1.1 1.1-2.7 0-3.8L18.7 2.3z"/></svg>' }, link: 'https://www.npmjs.com/package/claudux' }
    ],

    footer: {
      message: 'Generated with claudux',
      copyright: 'Copyright © 2025 claudux'
    },

    search: {
      provider: 'local'
    },

    editLink: {
      pattern: 'https://github.com/leojkwan/claudux/edit/main/docs/:path',
      text: 'Edit this page'
    },

    lastUpdated: {
      text: 'Last updated',
      formatOptions: {
        dateStyle: 'short',
        timeStyle: 'short'
      }
    },

    outline: {
      level: [2, 3],
      label: 'On this page'
    },

    docFooter: {
      prev: 'Previous page',
      next: 'Next page'
    }
  }
})