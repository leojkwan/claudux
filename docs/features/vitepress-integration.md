# VitePress Integration

Claudux automatically sets up and configures VitePress to create beautiful, fast documentation sites with zero manual configuration required.

## What is VitePress?

VitePress is a modern static site generator built on Vite, designed specifically for documentation. It provides:

- **Fast development** with hot module replacement
- **Beautiful themes** with built-in search
- **Excellent performance** with optimized builds
- **Mobile responsive** design out of the box
- **SEO friendly** with proper meta tags

Claudux handles all VitePress configuration automatically while allowing full customization.

## Automatic Setup

### Zero-Config Experience

When you run `claudux serve` for the first time:

```bash
claudux serve

🌐 Starting documentation server...
📦 Setting up VitePress...
   ✅ config.ts created
   ✅ theme/ directory copied  
   ✅ vite.config.js copied (PostCSS isolation)
   ✅ postcss.config.js copied (prevents parent config loading)
📦 Installing docs dependencies...
✅ Dependencies already installed

  vitepress v1.0.0-rc.44
  ➜  Local:   http://localhost:5173/
```

### What Gets Created

Claudux sets up a complete VitePress environment:

```
docs/
├── .vitepress/
│   ├── config.ts              # Main configuration
│   └── theme/                 # Custom theme components
├── package.json               # VitePress dependencies  
├── vite.config.js             # Vite configuration
├── postcss.config.js          # CSS processing
└── [documentation files]     # Your content
```

## Dynamic Configuration

### Intelligent Config Generation

Claudux generates VitePress configuration based on your actual documentation structure:

```typescript
// docs/.vitepress/config.ts (auto-generated)
import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Your Project Documentation',
  description: 'Comprehensive project documentation',
  
  themeConfig: {
    outline: { level: [2, 3], label: 'On this page' },
    
    nav: [
      { text: 'Guide', link: '/guide/' },
      { text: 'API', link: '/api/' },
      { text: 'Examples', link: '/examples/' }
    ],
    
    sidebar: {
      '/guide/': [
        {
          text: 'Getting Started',
          items: [
            { text: 'Installation', link: '/guide/installation' },
            { text: 'Quick Start', link: '/guide/quickstart' },
            { text: 'Configuration', link: '/guide/configuration' }
          ]
        }
      ],
      
      '/api/': [
        {
          text: 'API Reference', 
          items: [
            { text: 'Overview', link: '/api/' },
            { text: 'CLI Commands', link: '/api/cli' },
            { text: 'Library Functions', link: '/api/library' }
          ]
        }
      ]
    },
    
    socialLinks: [
      { icon: 'github', link: 'https://github.com/your/repo' }
    ]
  }
})
```

### Adaptive Navigation

The sidebar and navigation are automatically generated based on:

- **Directory structure** of your documentation
- **File organization** and naming patterns  
- **Cross-references** between documents
- **Project type** and conventions

## Theme Customization

### Logo Detection

Claudux automatically detects and configures project logos:

**iOS Projects:**
- Searches `Assets.xcassets/AppIcon.appiconset/` for app icons
- Prefers high-resolution versions (1024x1024, 512x512)

**General Projects:**
- Looks for `logo.png`, `logo.svg`, `icon.png` in common locations
- Checks `docs/public/`, project root, and `assets/` directories

**Manual Logo:**
```bash
# Place your logo here for automatic detection
docs/public/logo.png
```

### Custom Theme Components

Claudux includes a custom theme with enhancements:

```
docs/.vitepress/theme/
├── index.ts               # Theme entry point
├── custom.css             # Additional styles
└── components/            # Custom Vue components
```

**Custom styling:**
```css
/* docs/.vitepress/theme/custom.css */
:root {
  --vp-c-brand-1: #10b981;
  --vp-c-brand-2: #059669;
}

.VPNav {
  border-bottom: 1px solid var(--vp-c-divider);
}
```

## Development Experience

### Hot Reload

VitePress provides instant feedback during documentation editing:

```bash
claudux serve  # Start development server

# Edit any .md file
# Changes appear instantly in browser
# No build step required
```

### Port Management

Claudux handles port conflicts automatically:

- **Default port**: 5173
- **Auto-detection**: Scans ports 3000-3100 if 5173 is busy
- **Clean URLs**: No port shown when using standard HTTP ports

### Process Isolation

VitePress runs in isolated environment to prevent conflicts:

- **Separate package.json** in docs/ directory
- **Isolated PostCSS config** to prevent parent project conflicts  
- **Independent Vite config** for docs-specific optimizations

## Production Features

### Optimized Builds

When building for production:

```bash
cd docs
npm run build
```

VitePress creates highly optimized static sites:
- **Code splitting** for efficient loading
- **Minified assets** for fast download
- **Service worker** for offline support
- **Prefetching** for instant navigation

### SEO Optimization

Automatic SEO enhancements:
- **Meta descriptions** from file frontmatter
- **Open Graph tags** for social sharing
- **Structured data** for search engines
- **Sitemap generation** for indexing

### Performance Features

- **Lazy loading** of images and components
- **Resource preloading** for critical assets
- **Efficient caching** strategies
- **Mobile optimization** with responsive design

## Customization Options

### Configuration Override

While Claudux generates configuration automatically, you can customize:

```typescript
// docs/.vitepress/config.ts
import { defineConfig } from 'vitepress'

export default defineConfig({
  // Claudux will preserve your customizations
  title: 'My Custom Title',
  
  themeConfig: {
    logo: '/custom-logo.png',
    
    // Add custom navigation items
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Custom', link: '/custom/' },
      // Claudux-generated items will be merged
    ],
    
    // Custom footer
    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2024 Your Company'
    }
  }
})
```

### Advanced Theming

Create custom components:

```vue
<!-- docs/.vitepress/theme/components/CustomHero.vue -->
<template>
  <div class="custom-hero">
    <h1>{{ title }}</h1>
    <p>{{ description }}</p>
  </div>
</template>

<script setup>
defineProps<{
  title: string
  description: string
}>()
</script>
```

Use in your theme:

```typescript
// docs/.vitepress/theme/index.ts
import DefaultTheme from 'vitepress/theme'
import CustomHero from './components/CustomHero.vue'

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component('CustomHero', CustomHero)
  }
}
```

## Integration Features

### Search Integration

Built-in client-side search:
- **Full-text search** across all documentation
- **Instant results** with highlighting
- **Keyboard navigation** with ⌘K/Ctrl+K
- **Mobile optimized** search interface

### Git Integration

Automatic Git integration features:
- **Edit links** pointing to source files
- **Last updated** timestamps from git history
- **Contributors** from git commit history

### Markdown Enhancements

VitePress + Claudux support:

**Code blocks with syntax highlighting:**
```bash
FORCE_MODEL=sonnet claudux update
```

**Custom containers:**
```markdown
::: tip
This is automatically generated by Claudux
:::

::: warning
Make sure to backup your docs before regenerating
:::
```

**Tables and task lists:**
- [x] Automatic project detection
- [x] VitePress configuration  
- [ ] Custom theme development

## Deployment

### Static Site Generation

Build production-ready sites:

```bash
cd docs
npm run build
```

Output goes to `docs/.vitepress/dist/`:
- **Optimized HTML** files for each page
- **Bundled assets** with cache-busting
- **Service worker** for offline support

### Deployment Options

**GitHub Pages (env-based base path):**
```yaml
# .github/workflows/docs.yml
name: Docs (VitePress) to GitHub Pages
on:
  push:
    branches: [ main ]

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
          cache-dependency-path: docs/package-lock.json

      - name: Install deps
        working-directory: docs
        run: npm ci

      - name: Build
        working-directory: docs
        env:
          DOCS_BASE: /<repo>/
        run: npx vitepress build

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: docs/.vitepress/dist

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

#### Base path policy
- Local/dev `docs/.vitepress/config.ts` uses `base: process.env.DOCS_BASE || '/'` so local works by default.
- For GitHub Pages, set `DOCS_BASE=/<repo>/` in CI. No file mutation needed.

**Netlify:**
```toml
# netlify.toml
[build]
  base = "docs"
  command = "npm run build"
  publish = ".vitepress/dist"
```

**Vercel:**
```json
{
  "builds": [
    {
      "src": "docs/package.json",
      "use": "@vercel/static-build",
      "config": { "distDir": ".vitepress/dist" }
    }
  ]
}
```

## Maintenance

### Keeping VitePress Updated

Claudux manages VitePress versions:

```bash
# Update documentation dependencies
cd docs
npm update

# Verify everything still works
claudux serve
```

### Configuration Regeneration

Force config regeneration:

```bash
# Remove old config and regenerate
rm docs/.vitepress/config.ts
claudux update
```

### Troubleshooting VitePress

Common issues and solutions:

**Port conflicts:**
```bash
# Claudux handles this automatically
claudux serve  # Will find available port
```

**Build failures:**
```bash
# Check for syntax errors in markdown
cd docs
npm run build  # Shows detailed error messages
```

**Theme issues:**
```bash
# Regenerate theme files
rm -rf docs/.vitepress/theme
claudux serve  # Recreates theme directory
```

## Advanced Features

### Multi-Language Support

Configure multiple languages:

```typescript
export default defineConfig({
  locales: {
    root: {
      label: 'English',
      lang: 'en'
    },
    es: {
      label: 'Español',
      lang: 'es',
      link: '/es/'
    }
  }
})
```

### Plugin System

Add VitePress plugins:

```typescript
export default defineConfig({
  vite: {
    plugins: [
      // Custom Vite plugins
    ]
  },
  
  markdown: {
    // Markdown-it plugins
  }
})
```

### Analytics Integration

Add analytics:

```typescript
export default defineConfig({
  head: [
    ['script', { 
      async: '', 
      src: 'https://www.googletagmanager.com/gtag/js?id=GA_TRACKING_ID' 
    }]
  ]
})
```

VitePress integration makes Claudux documentation sites fast, beautiful, and maintainable with minimal configuration required. The automatic setup and intelligent configuration generation mean you can focus on content while getting a professional documentation site.