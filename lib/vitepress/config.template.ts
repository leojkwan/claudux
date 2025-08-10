/* @ts-nocheck */
import { defineConfig } from 'vitepress'

export default defineConfig({
  title: '{{PROJECT_NAME}}',
  description: '{{PROJECT_DESCRIPTION}}',
  
  // Enhanced head configuration
  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/icon.svg' }],
    ['meta', { name: 'theme-color', content: '#5f67ee' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:locale', content: 'en' }],
    ['meta', { property: 'og:title', content: '{{PROJECT_NAME}} Documentation' }],
    ['meta', { property: 'og:site_name', content: '{{PROJECT_NAME}} Docs' }],
    ['meta', { property: 'og:image', content: '/og-image.png' }],
    ['meta', { property: 'og:url', content: '/' }],
  ],

  // Clean URLs
  cleanUrls: true,

  // Enhanced markdown configuration
  markdown: {
    theme: { light: 'github-light', dark: 'github-dark' },
    lineNumbers: true,
    codeTransformers: [
      // Add copy button and language labels
    ]
  },

  // Theme configuration with enhanced sidebar and navigation
  themeConfig: {
    // Site branding - auto-detected logo
    logo: { src: '{{LOGO_PATH}}', width: 24, height: 24 },
    siteTitle: '{{PROJECT_NAME}}',

    // Navigation bar (keep minimal and project-agnostic by default)
    nav: [
      { text: 'Guide', link: '/guide/', activeMatch: '/guide/' }
    ],

    // Sidebar keeps only generic, always-present sections by default
    sidebar: {
      '/': [
        {
          text: '🚀 Getting Started',
          collapsed: false,
          items: [
            { text: 'Introduction', link: '/guide/' },
            { text: 'Installation', link: '/guide/#installation' },
            { text: 'Quick Start', link: '/guide/#quick-start' }
          ]
        }
      ],
      '/guide/': [
        {
          text: '🚀 Getting Started',
          collapsed: false,
          items: [
            { text: 'Introduction', link: '/guide/' },
            { text: 'Installation', link: '/guide/#installation' },
            { text: 'Quick Start', link: '/guide/#quick-start' }
          ]
        }
      ]
    },

    // Enhanced social links (left empty by default; generator may populate)
    socialLinks: [],

    // Footer configuration
    footer: {
      message: 'Generated with Claudux',
      copyright: 'Copyright © 2024 {{PROJECT_NAME}}'
    },

    // Enhanced search
    search: {
      provider: 'local',
      options: {
        locales: {
          root: {
            translations: {
              button: {
                buttonText: 'Search documentation',
                buttonAriaLabel: 'Search documentation'
              },
              modal: {
                displayDetails: 'Display detailed list',
                resetButtonTitle: 'Reset search',
                backButtonTitle: 'Close search',
                noResultsText: 'No results for',
                footer: {
                  selectText: 'to select',
                  selectKeyAriaLabel: 'enter',
                  navigateText: 'to navigate',
                  navigateUpKeyAriaLabel: 'up arrow',
                  navigateDownKeyAriaLabel: 'down arrow',
                  closeText: 'to close',
                  closeKeyAriaLabel: 'escape'
                }
              }
            }
          }
        }
      }
    },

    // Enhanced edit link
    editLink: {
      pattern: '#',
      text: 'Edit this page'
    },

    // Last updated timestamp
    lastUpdated: {
      text: 'Last updated',
      formatOptions: {
        dateStyle: 'short',
        timeStyle: 'short'
      }
    },

    // Document outline in right sidebar
    outline: {
      level: [2, 3],
      label: 'On this page'
    },

    // Previous/next page navigation
    docFooter: {
      prev: 'Previous page',
      next: 'Next page'
    },

    // Return to top
    returnToTopLabel: 'Return to top',

    // External link icon
    externalLinkIcon: true,

    // Dark mode toggle
    darkModeSwitchLabel: 'Appearance',
    lightModeSwitchTitle: 'Switch to light theme',
    darkModeSwitchTitle: 'Switch to dark theme',

    // Enhanced carbon ads (if needed)
    // carbonAds: {
    //   code: 'your-carbon-code',
    //   placement: 'your-placement'
    // }
  },

  // Sitemap generation
  sitemap: {
    hostname: 'https://localhost:5173'
  },

  // PWA support
  // pwa: {
  //   mode: 'production',
  //   base: '/',
  //   scope: '/',
  //   includeAssets: ['favicon.ico'],
  //   manifest: {
  //     name: '{{PROJECT_NAME}} Documentation',
  //     short_name: '{{PROJECT_NAME}} Docs',
  //     theme_color: '#5f67ee',
  //     icons: [
  //       {
  //         src: '/icon-192.png',
  //         sizes: '192x192',
  //         type: 'image/png'
  //       }
  //     ]
  //   }
  // }
}) 