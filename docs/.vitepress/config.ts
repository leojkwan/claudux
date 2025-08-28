import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Claudux',
  description: 'AI-powered documentation generator for your codebase using Claude Code and VitePress',
  base: '/',
  
  // Ignore localhost links during static builds (they work fine in dev)
  ignoreDeadLinks: [
    /^https?:\/\/localhost/
  ],
  
  head: [
    ['meta', { name: 'viewport', content: 'width=device-width, initial-scale=1.0' }],
    ['meta', { name: 'keywords', content: 'documentation, AI, Claude, VitePress, developer tools, docs generator' }],
    ['meta', { name: 'theme-color', content: '#5f67ee' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:locale', content: 'en' }],
    ['meta', { property: 'og:title', content: 'Claudux - AI-Powered Documentation Generator' }],
    ['meta', { property: 'og:description', content: 'Stop fighting stale documentation. Claudux analyzes your codebase and generates comprehensive docs that stay in sync.' }],
    ['meta', { property: 'og:site_name', content: 'Claudux Docs' }],
    ['meta', { property: 'og:image', content: '/og-image.png' }],
    ['meta', { property: 'og:url', content: 'https://leojkwan.github.io/claudux/' }],
  ],

  cleanUrls: true,

  markdown: {
    theme: { light: 'github-light', dark: 'github-dark' },
    lineNumbers: false,
    codeTransformers: []
  },

  themeConfig: {
    siteTitle: 'Claudux',

    nav: [
      { text: 'Home', link: '/', activeMatch: '^/$' },
      { text: 'Guide', link: '/guide/', activeMatch: '/guide/' },
      { text: 'Features', link: '/features/', activeMatch: '/features/' },
      { text: 'API', link: '/api/', activeMatch: '/api/' },
      { text: 'Examples', link: '/examples/', activeMatch: '/examples/' }
    ],

    sidebar: {
      '/': [
        {
          text: 'Getting Started',
          collapsed: false,
          items: [
            { text: 'Overview', link: '/guide/' },
            { text: 'Installation', link: '/guide/installation' },
            { text: 'Quick Start', link: '/guide/quickstart' }
          ]
        },
        {
          text: 'User Guide',
          collapsed: false,
          items: [
            { text: 'Commands', link: '/guide/commands' },
            { text: 'Configuration', link: '/guide/configuration' }
          ]
        },
        {
          text: 'Features',
          collapsed: true,
          items: [
            { text: 'Core Features', link: '/features/' },
            { text: 'Two-Phase Generation', link: '/features/two-phase-generation' },
            { text: 'VitePress Integration', link: '/features/vitepress-integration' },
            { text: 'Smart Cleanup', link: '/features/smart-cleanup' },
            { text: 'Content Protection', link: '/features/content-protection' },
            { text: 'Project Detection', link: '/features/project-detection' }
          ]
        },
        {
          text: 'Technical Documentation',
          collapsed: true,
          items: [
            { text: 'Architecture', link: '/technical/' },
            { text: 'Coding Patterns', link: '/technical/patterns' },
            { text: 'Module Reference', link: '/technical/modules' }
          ]
        },
        {
          text: 'API Reference',
          collapsed: true,
          items: [
            { text: 'Overview', link: '/api/' },
            { text: 'CLI Reference', link: '/api/cli' },
            { text: 'Library Functions', link: '/api/library' }
          ]
        },
        {
          text: 'Development',
          collapsed: true,
          items: [
            { text: 'Development Guide', link: '/development/' },
            { text: 'Contributing', link: '/development/contributing' },
            { text: 'Adding Features', link: '/development/adding-features' },
            { text: 'Testing', link: '/development/testing' }
          ]
        },
        {
          text: 'Examples',
          collapsed: true,
          items: [
            { text: 'Examples Overview', link: '/examples/' },
            { text: 'Basic Setup', link: '/examples/basic-setup' },
            { text: 'Advanced Usage', link: '/examples/advanced-usage' }
          ]
        },
        {
          text: 'Resources',
          collapsed: true,
          items: [
            { text: 'FAQ', link: '/faq' },
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
            { text: 'Quick Start', link: '/guide/quickstart' }
          ]
        },
        {
          text: 'User Guide',
          collapsed: false,
          items: [
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
            { text: 'Core Features', link: '/features/' },
            { text: 'Two-Phase Generation', link: '/features/two-phase-generation' },
            { text: 'VitePress Integration', link: '/features/vitepress-integration' },
            { text: 'Smart Cleanup', link: '/features/smart-cleanup' },
            { text: 'Content Protection', link: '/features/content-protection' },
            { text: 'Project Detection', link: '/features/project-detection' }
          ]
        }
      ],
      '/technical/': [
        {
          text: 'Technical Documentation',
          collapsed: false,
          items: [
            { text: 'Architecture', link: '/technical/' },
            { text: 'Coding Patterns', link: '/technical/patterns' },
            { text: 'Module Reference', link: '/technical/modules' }
          ]
        }
      ],
      '/api/': [
        {
          text: 'API Reference',
          collapsed: false,
          items: [
            { text: 'Overview', link: '/api/' },
            { text: 'CLI Reference', link: '/api/cli' },
            { text: 'Library Functions', link: '/api/library' }
          ]
        }
      ],
      '/development/': [
        {
          text: 'Development',
          collapsed: false,
          items: [
            { text: 'Development Guide', link: '/development/' },
            { text: 'Contributing', link: '/development/contributing' },
            { text: 'Adding Features', link: '/development/adding-features' },
            { text: 'Testing', link: '/development/testing' }
          ]
        }
      ],
      '/examples/': [
        {
          text: 'Examples',
          collapsed: false,
          items: [
            { text: 'Examples Overview', link: '/examples/' },
            { text: 'Basic Setup', link: '/examples/basic-setup' },
            { text: 'Advanced Usage', link: '/examples/advanced-usage' }
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/leojkwan/claudux' },
      { icon: 'npm', link: 'https://www.npmjs.com/package/claudux' }
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2024 Leo Kwan'
    },

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

    editLink: {
      pattern: 'https://github.com/leojkwan/claudux/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
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
    },

    returnToTopLabel: 'Return to top',
    externalLinkIcon: true,

    darkModeSwitchLabel: 'Appearance',
    lightModeSwitchTitle: 'Switch to light theme',
    darkModeSwitchTitle: 'Switch to dark theme',
  },

  sitemap: {
    hostname: 'https://leojkwan.github.io/claudux/'
  }
}) 