[Home](/) > [Guide](/guide/) > Configuration

# Configuration Guide

Customize Claudux to work perfectly with your project. This guide covers all configuration options, from basic settings to advanced customization.

## Configuration Overview

Claudux uses multiple configuration methods:

1. **[Project Configuration](#project-configuration)** - `docs-ai-config.json` for project settings
2. **[Environment Variables](#environment-variables)** - Runtime behavior control
3. **[AI Context File](#ai-context-file)** - `CLAUDE.md` for AI instructions
4. **[VitePress Configuration](#vitepress-configuration)** - Documentation site customization

## Project Configuration

### Configuration File Location

Claudux looks for configuration files in this order:

1. **`docs-ai-config.json`** (recommended)
2. **`.claudux.json`** (legacy support)

Place the configuration file in your project root directory.

### Basic Configuration

Create `docs-ai-config.json` with your project settings:

```json
{
  "project": {
    "name": "My Awesome Project",
    "type": "nextjs"
  }
}
```

### Complete Configuration Schema

```json
{
  "project": {
    "name": "Your Project Name",
    "type": "nextjs|react|nodejs|ios|python|rust|go|generic",
    "description": "Brief project description",
    "version": "1.0.0",
    "primaryLanguage": "typescript|javascript|swift|python|rust|go"
  },
  "documentation": {
    "title": "Custom Documentation Title", 
    "subtitle": "Custom subtitle for docs",
    "logo": "./assets/logo.png",
    "favicon": "./assets/favicon.ico"
  },
  "features": {
    "apiDocs": true,
    "examples": true,
    "tutorials": true,
    "troubleshooting": true,
    "deployment": true
  },
  "structure": {
    "sections": [
      "guide",
      "api", 
      "examples",
      "technical"
    ],
    "customPages": [
      {
        "path": "deployment.md",
        "title": "Deployment Guide"
      }
    ]
  },
  "protection": {
    "preservePaths": [
      "docs/custom/",
      "docs/manual/"
    ],
    "skipPatterns": [
      "**/*.private.md",
      "**/temp-*.md"
    ]
  },
  "generation": {
    "model": "opus|sonnet",
    "focusAreas": [
      "API documentation",
      "Getting started guides",
      "Code examples"
    ]
  }
}
```

### Configuration Options Explained

#### Project Section

```json
{
  "project": {
    "name": "My Project",           // Used in headers and titles
    "type": "nextjs",              // Affects templates and analysis
    "description": "...",          // Used in homepage and metadata
    "version": "1.0.0",           // Displayed in documentation
    "primaryLanguage": "typescript" // Influences code examples
  }
}
```

**Supported Project Types:**
- `nextjs` - Next.js applications
- `react` - React applications
- `nodejs` - Node.js projects  
- `ios` - iOS/Swift projects
- `python` - Python projects
- `rust` - Rust projects
- `go` - Go projects
- `generic` - Any other project type

#### Documentation Section

```json
{
  "documentation": {
    "title": "Custom Title",        // Override auto-detected title
    "subtitle": "Project docs",     // Subtitle for homepage  
    "logo": "./logo.png",          // Logo path (relative to project root)
    "favicon": "./favicon.ico"     // Favicon path
  }
}
```

#### Features Section

```json
{
  "features": {
    "apiDocs": true,        // Generate API documentation
    "examples": true,       // Include code examples
    "tutorials": true,      // Create tutorial sections
    "troubleshooting": true, // Add troubleshooting guides
    "deployment": true      // Include deployment instructions
  }
}
```

#### Structure Section

```json
{
  "structure": {
    "sections": [           // Main navigation sections
      "guide",
      "api", 
      "examples",
      "technical"
    ],
    "customPages": [        // Additional custom pages
      {
        "path": "deployment.md",
        "title": "Deployment Guide",
        "section": "guide"   // Optional: assign to section
      }
    ]
  }
}
```

#### Protection Section

```json
{
  "protection": {
    "preservePaths": [      // Never delete these paths
      "docs/custom/",
      "docs/manual/",
      "docs/important.md"
    ],
    "skipPatterns": [       // Skip files matching these patterns
      "**/*.private.md",
      "**/temp-*.md",
      "**/.draft.*"
    ]
  }
}
```

#### Generation Section

```json
{
  "generation": {
    "model": "opus",        // Preferred Claude model
    "focusAreas": [         // Guide AI generation focus
      "API documentation",
      "Getting started guides", 
      "Code examples",
      "Architecture overview"
    ],
    "style": "comprehensive|concise|tutorial"  // Documentation style
  }
}
```

### Auto-Generated Configuration

When you first run `claudux update`, it creates a basic configuration:

```json
{
  "project": {
    "name": "Detected Project Name",
    "type": "detected-type"
  },
  "generation": {
    "lastUpdated": "2024-01-15T10:30:00Z",
    "version": "1.0.0"
  }
}
```

You can customize this file after initial generation.

## Environment Variables

Control Claudux runtime behavior with environment variables:

### Model Selection

```bash
# Force specific Claude model
export FORCE_MODEL=opus     # Most powerful (default)
export FORCE_MODEL=sonnet   # Faster and cheaper

# Use in commands
FORCE_MODEL=sonnet claudux update
```

### Verbosity Control

```bash
# Set default verbosity level  
export CLAUDUX_VERBOSE=0    # Quiet (default)
export CLAUDUX_VERBOSE=1    # Verbose
export CLAUDUX_VERBOSE=2    # Debug mode

# Use per-command
CLAUDUX_VERBOSE=2 claudux update
```

### Default Messages

```bash
# Set default update directive
export CLAUDUX_MESSAGE="Weekly documentation sync"

# This message will be used when no -m flag is provided
claudux update  # Uses CLAUDUX_MESSAGE
```

### Output Control

```bash
# Disable colored output
export NO_COLOR=1

# Useful for CI/CD or log parsing
NO_COLOR=1 claudux update > build.log
```

### Temporary Directory

```bash
# Custom temp directory for large projects
export TMPDIR=/path/to/large/tmp

# Claudux uses this for temporary files during generation
```

### Authentication

```bash
# Claude CLI authentication (if needed)
export ANTHROPIC_API_KEY=your-api-key
```

### Making Variables Persistent

Add to your shell profile (`~/.bashrc`, `~/.zshrc`):

```bash
# Claudux Configuration
export FORCE_MODEL=sonnet
export CLAUDUX_VERBOSE=1
export CLAUDUX_MESSAGE="Regular documentation update"
```

## AI Context File

### CLAUDE.md Purpose

The `CLAUDE.md` file provides project-specific context to help Claude understand:

- **Coding conventions** and style guides
- **Architecture patterns** and design decisions
- **Project terminology** and domain concepts  
- **Important constraints** and requirements
- **Anti-patterns** to avoid

### Generating CLAUDE.md

```bash
# Auto-generate based on your codebase
claudux create-template
```

This analyzes your actual code patterns and creates tailored instructions.

### Manual CLAUDE.md Structure

```markdown
# My Project AI Assistant Instructions

## Project Context
Brief description of the project, its purpose, and key technologies.

## CRITICAL RULES - MUST FOLLOW

### Code Style
- **ALWAYS use TypeScript strict mode**
- **NEVER use 'any' type without justification**
- **FOLLOW naming convention**: PascalCase for components, camelCase for functions

### Architecture Patterns
- **ALWAYS place API routes** in src/app/api/ directory
- **USE the repository pattern** for data access (see src/lib/repositories/)
- **FOLLOW component composition** over inheritance

### Testing Requirements
- **WRITE tests for all public APIs** using Jest
- **USE React Testing Library** for component tests
- **FOLLOW the AAA pattern**: Arrange, Act, Assert

### Anti-Patterns - NEVER DO
- **DON'T access database directly** from React components
- **DON'T use console.log** in production code
- **DON'T ignore TypeScript errors**

## Project-Specific Patterns

### Authentication Flow
When documenting auth, always mention:
- NextAuth.js configuration in src/lib/auth.ts
- Protected route patterns in middleware.ts
- Session handling in components

### API Documentation
For API endpoints, always include:
- Request/response TypeScript interfaces
- Error handling examples  
- Authentication requirements
- Rate limiting information
```

### CLAUDE.md Best Practices

1. **Be Specific** - Include actual file paths and function names
2. **Use Imperatives** - "ALWAYS do this", "NEVER do that"  
3. **Include Examples** - Show actual code patterns from your project
4. **Update Regularly** - Keep in sync with evolving codebase
5. **Focus on Uniqueness** - Emphasize what's special about your project

### Template Customization

After generating with `claudux create-template`, customize for:

- **Team conventions** not detected automatically
- **Business logic** constraints
- **Deployment considerations**
- **Performance requirements**
- **Security policies**

## VitePress Configuration

Claudux automatically generates VitePress configuration, but you can customize it.

### Configuration Location

```
docs/.vitepress/config.ts
```

### Auto-Generated Structure

```typescript
import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'My Project Documentation',
  description: 'Comprehensive project documentation',
  
  themeConfig: {
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
            { text: 'Quick Start', link: '/guide/quickstart' }
          ]
        }
      ],
      '/api/': [
        // Auto-generated API navigation
      ]
    },
    
    socialLinks: [
      { icon: 'github', link: 'https://github.com/user/repo' }
    ],
    
    search: {
      provider: 'local'
    }
  }
})
```

### Custom Themes

You can customize the VitePress theme:

```typescript
// docs/.vitepress/theme/index.ts
import { h } from 'vue'
import DefaultTheme from 'vitepress/theme'
import './custom.css'

export default {
  ...DefaultTheme,
  Layout: () => {
    return h(DefaultTheme.Layout, null, {
      // Custom layout slots
    })
  },
  enhanceApp({ app, router, siteData }) {
    // Custom app enhancements
  }
}
```

### Custom CSS

```css
/* docs/.vitepress/theme/custom.css */
:root {
  --vp-c-brand-1: #646cff;
  --vp-c-brand-2: #747bff;
}

.VPHero .name {
  color: var(--vp-c-brand-1);
}
```

## Project Type Templates

Claudux uses different templates based on your project type:

### iOS Projects

```json
{
  "project": {
    "type": "ios"
  }
}
```

**Special features:**
- SwiftUI component documentation
- Xcode project structure analysis
- App icon detection and usage
- iOS-specific deployment guides

### Next.js Projects

```json
{
  "project": {
    "type": "nextjs"
  }
}
```

**Special features:**
- App Router vs Pages Router detection
- API routes documentation
- Server/Client component analysis
- Deployment (Vercel) instructions

### Node.js Projects

```json
{
  "project": {
    "type": "nodejs"
  }
}
```

**Special features:**
- Package.json script documentation
- Module structure analysis
- Environment variable documentation
- NPM publishing guides

## Advanced Configuration

### Multi-Language Projects

```json
{
  "project": {
    "primaryLanguage": "typescript",
    "additionalLanguages": ["python", "rust"]
  },
  "documentation": {
    "i18n": {
      "locales": ["en", "es", "fr"],
      "defaultLocale": "en"
    }
  }
}
```

### Custom Documentation Structure

```json
{
  "structure": {
    "sections": [
      {
        "name": "guide",
        "title": "User Guide",
        "weight": 1
      },
      {
        "name": "api",
        "title": "API Reference", 
        "weight": 2
      },
      {
        "name": "internals",
        "title": "Internal Architecture",
        "weight": 3
      }
    ],
    "customPages": [
      {
        "path": "changelog.md",
        "title": "Changelog",
        "section": "guide"
      },
      {
        "path": "migration-guide.md", 
        "title": "Migration Guide",
        "section": "guide"
      }
    ]
  }
}
```

### Content Protection Rules

```json
{
  "protection": {
    "preservePaths": [
      "docs/custom/",           // Custom written content
      "docs/legal/",           // Legal documents
      "docs/manual/*.md"       // Manual documentation
    ],
    "skipPatterns": [
      "**/*.draft.md",         // Draft files
      "**/*.template.md",      // Template files
      "**/private-*.md"        // Private notes
    ],
    "protectedSections": [
      "<!-- CUSTOM_CONTENT_START -->",
      "<!-- CUSTOM_CONTENT_END -->"
    ]
  }
}
```

## Configuration Validation

### Checking Configuration

```bash
# Validate your configuration
claudux check
```

This verifies:
- Configuration file syntax
- Project type detection
- Template availability
- Path accessibility

### Common Configuration Issues

#### Invalid Project Type
```json
{
  "project": {
    "type": "invalid-type"  // ❌ Not supported
  }
}
```

**Fix:**
```json
{
  "project": {
    "type": "generic"       // ✅ Use generic for unsupported types
  }
}
```

#### Invalid Path References
```json
{
  "documentation": {
    "logo": "./nonexistent/logo.png"  // ❌ File doesn't exist
  }
}
```

**Fix:**
```json
{
  "documentation": {
    "logo": "./assets/logo.png"       // ✅ Verify file exists
  }
}
```

#### Malformed JSON
```json
{
  "project": {
    "name": "My Project",
    "type": "nextjs",  // ❌ Trailing comma
  }
}
```

**Fix:**
```json
{
  "project": {
    "name": "My Project",
    "type": "nextjs"   // ✅ No trailing comma
  }
}
```

## Configuration Examples

### Minimal Configuration

```json
{
  "project": {
    "name": "Simple API",
    "type": "nodejs"
  }
}
```

### Comprehensive Configuration

```json
{
  "project": {
    "name": "Enterprise App",
    "type": "nextjs",
    "description": "Full-stack enterprise application",
    "version": "2.1.0",
    "primaryLanguage": "typescript"
  },
  "documentation": {
    "title": "Enterprise App Documentation",
    "subtitle": "Complete developer reference",
    "logo": "./assets/logo.svg",
    "favicon": "./assets/favicon.ico"
  },
  "features": {
    "apiDocs": true,
    "examples": true,
    "tutorials": true,
    "troubleshooting": true,
    "deployment": true
  },
  "structure": {
    "sections": ["guide", "api", "examples", "architecture", "deployment"],
    "customPages": [
      {
        "path": "security.md",
        "title": "Security Guide",
        "section": "guide"
      },
      {
        "path": "performance.md",
        "title": "Performance Guidelines", 
        "section": "architecture"
      }
    ]
  },
  "protection": {
    "preservePaths": [
      "docs/company-specific/",
      "docs/legal/",
      "docs/custom-integrations/"
    ],
    "skipPatterns": [
      "**/*.internal.md",
      "**/draft-*.md"
    ]
  },
  "generation": {
    "model": "opus",
    "focusAreas": [
      "Comprehensive API documentation",
      "Step-by-step tutorials",
      "Architecture decision records",
      "Deployment automation"
    ],
    "style": "comprehensive"
  }
}
```

### Team Collaboration Configuration

```json
{
  "project": {
    "name": "Team Project",
    "type": "react"
  },
  "features": {
    "apiDocs": true,
    "examples": true,
    "tutorials": true
  },
  "structure": {
    "sections": ["guide", "api", "examples", "contributing"],
    "customPages": [
      {
        "path": "team-guide.md",
        "title": "Team Guidelines",
        "section": "contributing"
      },
      {
        "path": "code-review.md",
        "title": "Code Review Process",
        "section": "contributing"
      }
    ]
  },
  "protection": {
    "preservePaths": [
      "docs/team/",
      "docs/processes/"
    ]
  },
  "generation": {
    "focusAreas": [
      "Onboarding documentation",
      "Development workflows",
      "Code style guides",
      "Testing strategies"
    ]
  }
}
```

## Configuration Best Practices

### 1. Start Simple

Begin with minimal configuration and add complexity as needed:

```json
{
  "project": {
    "name": "My Project",
    "type": "auto-detected-type"
  }
}
```

### 2. Use Project Detection

Let Claudux detect your project type automatically when possible:

```bash
# Run without configuration first
claudux update

# Then customize the generated config
```

### 3. Protect Important Content

Always specify paths you want to preserve:

```json
{
  "protection": {
    "preservePaths": [
      "docs/important-manual-content/",
      "docs/legal/",
      "docs/company-specific/"
    ]
  }
}
```

### 4. Version Control Configuration

Commit your configuration to version control:

```bash
# Add to git
git add docs-ai-config.json
git add CLAUDE.md  # If using AI context file
git commit -m "Add Claudux configuration"
```

### 5. Regular Updates

Keep your configuration current:

- Update project version regularly
- Review and update CLAUDE.md after architectural changes
- Add new protected paths as you create custom content
- Adjust focus areas based on documentation needs

## Troubleshooting Configuration

### Debug Configuration Loading

```bash
# Check which config is being used
CLAUDUX_VERBOSE=2 claudux update
```

### Common Issues

1. **Config not loading**: Check file location and JSON syntax
2. **Project type not detected**: Set explicit type in config
3. **Custom paths ignored**: Verify path syntax and existence
4. **Template not applied**: Check project type spelling

### Reset to Defaults

```bash
# Delete config and let Claudux regenerate
rm docs-ai-config.json
claudux update
```

---

<p align="center">
  <strong>Perfect configuration leads to perfect documentation.</strong><br/>
  <a href="/guide/quickstart">Try it out →</a> | 
  <a href="/features/">Explore features →</a>
</p>