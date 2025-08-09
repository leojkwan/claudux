# VitePress Sidebar Configuration Example

To ensure the sidebar appears on ALL pages including the root/home page, configure your sidebar like this:

```typescript
sidebar: {
  // Root path - this makes sidebar appear on homepage
  '/': [
    {
      text: 'Getting Started',
      items: [
        { text: 'Overview', link: '/guide/' },
        { text: 'Quick Start', link: '/guide/quickstart' },
        { text: 'Installation', link: '/guide/installation' }
      ]
    },
    {
      text: 'Features',
      items: [
        { text: 'Core Features', link: '/features/' },
        { text: 'Advanced', link: '/features/advanced' }
      ]
    }
  ],
  
  // Guide section - same structure for consistency
  '/guide/': [
    {
      text: 'Getting Started',
      items: [
        { text: 'Overview', link: '/guide/' },
        { text: 'Quick Start', link: '/guide/quickstart' },
        { text: 'Installation', link: '/guide/installation' }
      ]
    }
  ],
  
  // Other sections follow same pattern...
}
```

## Key Points:
1. The `'/'` root path MUST be included to show sidebar on homepage
2. You can duplicate the same sidebar structure across paths for consistency
3. Or have a unified sidebar by only defining `'/'` path items