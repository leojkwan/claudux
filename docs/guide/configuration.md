[Home](/) > [Guide](/guide/) > Configuration

# Configuration

Claudux offers multiple ways to customize documentation generation to match your project's needs.

## Configuration Methods

### 1. Project Configuration File

Create `docs-ai-config.json` in your project root:

```json
{
  "projectName": "Your Project Name",
  "projectType": "auto",
  "primaryLanguage": "typescript",
  "frameworks": ["react", "nextjs", "tailwind"],
  "features": {
    "apiDocs": true,
    "tutorials": true,
    "examples": true,
    "testing": true,
    "deployment": true
  },
  "documentation": {
    "outputDir": "docs",
    "framework": "vitepress",
    "includePrivate": false,
    "generateChangelog": true
  },
  "ai": {
    "model": "opus",
    "temperature": 0.7,
    "maxTokens": 200000
  }
}
```

### 2. AI Instructions File

Create `CLAUDE.md` for project-specific AI guidance:

```markdown
# Project Instructions for Claude

## Project Context
This is a React-based e-commerce platform using TypeScript and Redux.

## Code Conventions
- Use functional components with hooks
- Follow Airbnb JavaScript style guide
- Prefer composition over inheritance
- Use absolute imports from 'src/'

## Documentation Requirements
- Include TypeScript type definitions
- Provide runnable examples
- Document all public APIs
- Add architecture diagrams where helpful

## Special Considerations
- We use custom authentication middleware
- The API is GraphQL-based
- State management uses Redux Toolkit
```

### 3. Environment Variables

Configure runtime behavior:

```bash
# Enable verbose output
export CLAUDUX_VERBOSE=1

# Force specific Claude model
export FORCE_MODEL=sonnet

# Disable colored output
export NO_COLOR=1

# Set custom timeout (seconds)
export CLAUDE_TIMEOUT=120
```

### 4. Command-Line Options

Override settings per command:

```bash
# Force model for this run
claudux update --force-model opus

# Update with specific focus
claudux update -m "Focus on API documentation and TypeScript interfaces"

# Verbose output
claudux update -v

# Very verbose (debug level)
claudux update -vv

# Quiet mode
claudux update -q
```

## Configuration Options

### Project Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `projectName` | string | auto-detected | Display name for documentation |
| `projectType` | string | `"auto"` | Project type: `react`, `nextjs`, `ios`, `python`, etc. |
| `primaryLanguage` | string | auto-detected | Main programming language |
| `frameworks` | array | auto-detected | List of frameworks used |
| `repository` | string | auto-detected | GitHub repository URL |

### Feature Flags

Control which documentation sections to generate:

```json
{
  "features": {
    "apiDocs": true,        // API reference documentation
    "tutorials": true,      // Step-by-step tutorials
    "examples": true,       // Code examples
    "testing": true,        // Testing documentation
    "deployment": true,     // Deployment guides
    "contributing": true,   // Contribution guidelines
    "changelog": true,      // Changelog generation
    "architecture": true    // Architecture documentation
  }
}
```

### Documentation Settings

```json
{
  "documentation": {
    "outputDir": "docs",           // Output directory
    "framework": "vitepress",      // Documentation framework
    "includePrivate": false,       // Include private APIs
    "generateChangelog": true,     // Auto-generate changelog
    "preserveCustom": true,        // Preserve custom content
    "cleanupThreshold": 0.95       // Obsolescence confidence
  }
}
```

### AI Model Settings

```json
{
  "ai": {
    "model": "opus",           // Claude model: opus, sonnet, haiku
    "temperature": 0.7,        // Creativity level (0-1)
    "maxTokens": 200000,       // Maximum tokens per request
    "retryAttempts": 3,        // Retry failed requests
    "timeout": 90              // Request timeout (seconds)
  }
}
```

## Protected Content

### Protection Markers

Protect custom content from being overwritten:

```markdown
<!-- CLAUDUX:PROTECTED:START -->
This content will never be modified or deleted by Claudux.
Add your custom documentation here.
<!-- CLAUDUX:PROTECTED:END -->
```

### Protected Directories

These directories are always protected:
- `.git/`
- `node_modules/`
- `.env*`
- `private/`
- `secret/`
- `notes/`
- `*.key`
- `*.pem`

Add custom patterns in `.clauduxignore`:

```
# Custom protected patterns
internal-docs/
*.draft.md
temp-*.md
```

## Project Type Templates

Claudux includes specialized templates for common project types:

### React Projects

Auto-detected when finding:
- `package.json` with `react` dependency
- `.jsx` or `.tsx` files
- `src/App.js` or `src/App.tsx`

Template includes:
- Component documentation
- Hooks reference
- State management guides
- Testing with React Testing Library

### Next.js Projects

Auto-detected when finding:
- `next.config.js` or `next.config.ts`
- `pages/` or `app/` directory

Template includes:
- Page routing documentation
- API routes reference
- SSR/SSG guides
- Deployment to Vercel

### iOS Projects

Auto-detected when finding:
- `.xcodeproj` or `.xcworkspace`
- `Package.swift`
- `*.swift` files

Template includes:
- SwiftUI/UIKit documentation
- Core Data guides
- Testing with XCTest
- App Store deployment

### Python Projects

Auto-detected when finding:
- `setup.py` or `pyproject.toml`
- `requirements.txt`
- `__init__.py`

Template includes:
- Module documentation
- Class and function reference
- Testing with pytest
- Package distribution

## VitePress Configuration

Claudux generates a complete VitePress configuration. Customize in `docs/.vitepress/config.ts`:

```typescript
export default defineConfig({
  title: 'Your Project',
  description: 'Your project description',
  
  themeConfig: {
    nav: [
      // Navigation items
    ],
    
    sidebar: {
      // Sidebar structure
    },
    
    socialLinks: [
      { icon: 'github', link: 'https://github.com/yourproject' }
    ],
    
    // Customize theme settings
    outline: {
      level: [2, 3],
      label: 'On this page'
    }
  }
})
```

## Advanced Configuration

### Custom Templates

Create project-specific templates in `lib/templates/`:

```bash
lib/templates/
├── myproject-claudux.md    # AI instructions
├── myproject-config.json   # Configuration
└── myproject/
    └── sidebar.json        # Custom sidebar
```

### Multi-Language Support

Configure for multi-language documentation:

```json
{
  "documentation": {
    "locales": {
      "root": {
        "label": "English",
        "lang": "en"
      },
      "es": {
        "label": "Español",
        "lang": "es"
      }
    }
  }
}
```

### CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: Update Documentation

on:
  push:
    branches: [main]
    paths:
      - 'src/**'
      - 'lib/**'

jobs:
  update-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '18'
      
      - name: Install Claudux
        run: npm install -g claudux
      
      - name: Update Documentation
        run: claudux update
        env:
          CLAUDE_API_KEY: ${{ secrets.CLAUDE_API_KEY }}
      
      - name: Commit Changes
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add docs/
          git commit -m "Update documentation [skip ci]"
          git push
```

## Best Practices

### 1. Start with Defaults
Begin with minimal configuration and add customizations as needed.

### 2. Use CLAUDE.md for Context
Provide project-specific context that helps AI understand your codebase better.

### 3. Review Generated Config
After first run, review and customize `docs/.vitepress/config.ts`.

### 4. Protect Custom Content
Use protection markers for hand-written documentation sections.

### 5. Version Control Config
Commit `docs-ai-config.json` and `CLAUDE.md` to share settings with your team.

### 6. Regular Updates
Schedule regular documentation updates to keep content current.

## Troubleshooting Configuration

### Config Not Loading

Check file location and JSON syntax:
```bash
# Validate JSON
cat docs-ai-config.json | jq .

# Check for file
ls -la docs-ai-config.json
```

### Model Override Not Working

Ensure environment variable is exported:
```bash
export FORCE_MODEL=opus
claudux update
```

### Protected Content Deleted

Verify protection markers are properly formatted:
```markdown
<!-- CLAUDUX:PROTECTED:START -->
<!-- CLAUDUX:PROTECTED:END -->
```

## Next Steps

- Explore [Commands](/guide/commands) for all CLI options
- Learn about [Two-Phase Generation](/features/two-phase-generation)
- Read [Development Guide](/development/) for contributing