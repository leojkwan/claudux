import { defineConfig } from 'vitepress'

const base = process.env.DOCS_BASE || '/'

export default defineConfig({
  title: 'Claudux',
  appearance: false,
  description: 'Update documentation with Claude Code or Codex and preserve the sections you pin.',
  base,
  
  // Ignore localhost links during static builds
  ignoreDeadLinks: [
    /^https?:\/\/localhost/
  ],
  
  head: [
    ['link', { rel: 'icon', type: 'image/png', href: `${base}claudux-icon.png` }],
    ['meta', { name: 'theme-color', content: '#f4f2eb' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:locale', content: 'en' }],
    ['meta', { property: 'og:title', content: 'Claudux — Update the docs. Keep your words.' }],
    ['meta', { property: 'og:site_name', content: 'Claudux' }],
    ['meta', { property: 'og:url', content: 'https://firstbitelabsllc.github.io/claudux/' }],
    ['meta', { property: 'og:image', content: 'https://firstbitelabsllc.github.io/claudux/claudux-cover.png' }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
  ],

  cleanUrls: true,

  markdown: {
    theme: { light: 'github-light', dark: 'github-dark' },
    lineNumbers: true
  },

  themeConfig: {
    siteTitle: 'Claudux',
    logo: '/claudux-icon.png',

    nav: [
      { text: 'Guide', link: '/guide/', activeMatch: '/guide/' },
      { text: 'Features', link: '/features/', activeMatch: '/features/' },
      { text: 'Technical', link: '/technical/', activeMatch: '/technical/' },
      { text: 'API', link: '/api/', activeMatch: '/api/' }
    ],

    sidebar: {
      '/': [
        {
          text: 'Getting Started',
          collapsed: false,
          items: [
            { text: 'Overview', link: '/guide/' },
            { text: 'Installation', link: '/guide/installation' },
            { text: 'Commands', link: '/guide/commands' },
            { text: 'Configuration', link: '/guide/configuration' }
          ]
        },
        {
          text: 'Features',
          collapsed: false,
          items: [
            { text: 'Overview', link: '/features/' },
            { text: 'Generation Pipeline', link: '/features/two-phase-generation' },
            { text: 'Cleanup', link: '/features/smart-cleanup' },
            { text: 'Content Protection', link: '/features/content-protection' }
          ]
        },
        {
          text: 'Technical',
          collapsed: true,
          items: [
            { text: 'Architecture', link: '/technical/' },
            { text: 'Project Profiles', link: '/technical/templates' },
            { text: 'Deterministic Generation', link: '/technical/deterministic-generation' }
          ]
        },
        {
          text: 'Reference',
          collapsed: true,
          items: [
            { text: 'API Reference', link: '/api/' },
            { text: 'Troubleshooting', link: '/troubleshooting' }
          ]
        }
      ],
      '/guide/': [
        {
          text: 'Getting Started',
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
          text: 'Features',
          collapsed: false,
          items: [
            { text: 'Overview', link: '/features/' },
            { text: 'Generation Pipeline', link: '/features/two-phase-generation' },
            { text: 'Cleanup', link: '/features/smart-cleanup' },
            { text: 'Content Protection', link: '/features/content-protection' }
          ]
        }
      ],
      '/technical/': [
        {
          text: 'Technical',
          collapsed: false,
          items: [
            { text: 'Architecture', link: '/technical/' },
            { text: 'Project Profiles', link: '/technical/templates' },
            { text: 'Deterministic Generation', link: '/technical/deterministic-generation' }
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/firstbitelabsllc/claudux' }
    ],

    footer: {
      message: 'Open source. Review the diff.',
      copyright: 'Copyright © 2026 First Bite Labs'
    },

    search: {
      provider: 'local'
    },

    editLink: {
      pattern: 'https://github.com/firstbitelabsllc/claudux/edit/main/docs/:path',
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
