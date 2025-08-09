import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Resplit',
  description: 'Resplit - iOS app documentation',
  
  // Enhanced head configuration
  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/icon.svg' }],
    ['meta', { name: 'theme-color', content: '#5f67ee' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:locale', content: 'en' }],
    ['meta', { property: 'og:title', content: 'Resplit iOS | Receipt Splitting Made Simple' }],
    ['meta', { property: 'og:site_name', content: 'Resplit iOS Docs' }],
    ['meta', { property: 'og:image', content: '/og-image.png' }],
    ['meta', { property: 'og:url', content: 'https://resplit-docs.dev/' }],
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
    logo: { src: '/logo.jpg', width: 24, height: 24 },
    siteTitle: 'Resplit',

    // Enhanced navigation bar
    nav: [
      { text: 'Guide', link: '/guide/', activeMatch: '/guide/' },
      { text: 'Technical', link: '/technical/', activeMatch: '/technical/' },
      { text: 'Features', link: '/features/', activeMatch: '/features/' },
      {
        text: 'Resources',
        items: [
          { text: 'GitHub', link: 'https://github.com/your-org/resplit-ios' },
          { text: 'App Store', link: 'https://apps.apple.com/app/resplit' },
          { text: 'TestFlight', link: 'https://testflight.apple.com/join/resplit' }
        ]
      }
    ],

    // Comprehensive sidebar with proper grouping
    sidebar: {
      '/guide/': [
        {
          text: '🚀 Getting Started',
          collapsed: false,
          items: [
            { text: 'Introduction', link: '/guide/' },
            { text: 'Installation', link: '/guide/#installation' },
            { text: 'Quick Start', link: '/guide/#quick-start' }
          ]
        },
        {
          text: '🔧 Development Setup',
          collapsed: false,
          items: [
            { text: 'Tuist Build System', link: '/guide/tuist-setup' },
            { text: 'Environment Setup', link: '/guide/tuist-setup#environment-setup' },
            { text: 'Project Generation', link: '/guide/tuist-setup#project-generation' }
          ]
        }
      ],
      '/technical/': [
        {
          text: '📊 Core Architecture',
          collapsed: false,
          items: [
            { text: 'Overview', link: '/technical/' },
            { text: 'Data Models', link: '/technical/data-models' },
            { text: 'SwiftData Schema', link: '/technical/data-models#swiftdata-schema' },
            { text: 'CloudKit Integration', link: '/technical/data-models#cloudkit-sync' }
          ]
        },
        {
          text: '🧪 Testing & Quality',
          collapsed: false,
          items: [
            { text: 'Testing Overview', link: '/technical/testing/' },
            { text: 'Emerge Tools', link: '/technical/testing/emerge-tools' },
            { text: 'Snapshot Testing', link: '/technical/testing/emerge-tools#snapshot-testing' },
            { text: 'Performance Testing', link: '/technical/testing/emerge-tools#performance-testing' }
          ]
        }
      ]
    },

    // Enhanced social links
    socialLinks: [
      { icon: 'github', link: 'https://github.com/your-org/resplit-ios' },
      { icon: 'twitter', link: 'https://twitter.com/resplit_app' },
      { icon: 'discord', link: 'https://discord.gg/resplit' }
    ],

    // Footer configuration
    footer: {
      message: 'Built with ❤️ for the iOS community',
      copyright: 'Copyright © 2024 Resplit Team'
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
      pattern: 'https://github.com/your-org/resplit-ios/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
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
    hostname: 'https://resplit-docs.dev'
  },

  // PWA support
  // pwa: {
  //   mode: 'production',
  //   base: '/',
  //   scope: '/',
  //   includeAssets: ['favicon.ico'],
  //   manifest: {
  //     name: 'Resplit iOS Documentation',
  //     short_name: 'Resplit Docs',
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