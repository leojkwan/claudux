[Home](/) > Examples

# Examples

Real-world examples of using Claudux with different project types and configurations.

## Quick Examples

### Basic React App

```bash
# Navigate to React project
cd my-react-app

# Generate documentation
claudux update

# Preview
claudux serve
```

Generated structure:
```
docs/
├── guide/
│   ├── getting-started.md
│   └── components.md
├── api/
│   └── hooks.md
└── examples/
    └── usage.md
```

### Python Package

```bash
cd my-python-package
claudux update -m "Focus on API documentation and type hints"
```

### Next.js Application

```bash
cd my-nextjs-app
claudux update --force-model opus  # Use best model for complex app
```

## Configuration Examples

### Custom Project Configuration

`docs-ai-config.json`:
```json
{
  "projectName": "My Awesome Project",
  "projectType": "react",
  "primaryLanguage": "typescript",
  "frameworks": ["react", "redux", "tailwind"],
  "features": {
    "apiDocs": true,
    "tutorials": true,
    "examples": true,
    "testing": true,
    "deployment": true
  },
  "documentation": {
    "outputDir": "docs",
    "includePrivate": false,
    "generateChangelog": true
  }
}
```

### AI Instructions Template

`CLAUDE.md`:
```markdown
# Project Documentation Instructions

## Project Context
This is an e-commerce platform built with React and Node.js.

## Key Features
- Product catalog with search
- Shopping cart with persistence
- User authentication via JWT
- Payment processing with Stripe
- Admin dashboard

## Documentation Style
- Include practical examples
- Document all public APIs
- Add TypeScript interfaces
- Include testing examples
- Explain business logic

## Code Patterns
- Functional components with hooks
- Redux Toolkit for state
- React Query for data fetching
- Styled-components for styling

## Important Notes
- API keys are stored in environment variables
- Database migrations in /migrations
- Custom hooks in /src/hooks
```

## Project Type Examples

### React + TypeScript

```bash
# Project structure
src/
├── components/
├── hooks/
├── services/
├── types/
└── utils/

# Generate with TypeScript focus
claudux update -m "Document TypeScript interfaces and types thoroughly"
```

### iOS Swift Project

```bash
# Project with SwiftUI
MyApp/
├── Models/
├── Views/
├── ViewModels/
└── Services/

# Generate iOS documentation
claudux update -m "Focus on SwiftUI views and Combine publishers"
```

### Python FastAPI

```bash
# API project
app/
├── routers/
├── models/
├── schemas/
└── services/

# Generate API docs
claudux update -m "Document all endpoints with request/response schemas"
```

## Advanced Configurations

### Monorepo Documentation

```bash
# Document entire monorepo
cd monorepo-root
claudux update

# Or document packages separately
for package in packages/*; do
  (cd "$package" && claudux update)
done
```

### Protected Content

```markdown
<!-- docs/deployment.md -->
# Deployment Guide

## Public Information
This will be updated by Claudux.

<!-- CLAUDUX:PROTECTED:START -->
## Internal Deployment Steps

1. SSH to production: ssh prod.internal
2. API Key: Check 1Password vault
3. Database password: In AWS Secrets Manager
4. Deploy command: ./deploy.sh --prod
<!-- CLAUDUX:PROTECTED:END -->

## More Public Info
This will also be updated.
```

### Custom Cleanup Rules

`.clauduxignore`:
```
# Protect these files/directories
docs/internal/
docs/decisions/
docs/archive/

# Protect by pattern
*-manual.md
*-protected.md
CHANGELOG.md
MIGRATION.md

# Protect specific files
docs/deployment/secrets.md
docs/api/internal-api.md
```

## CI/CD Integration

### GitHub Actions

`.github/workflows/docs.yml`:
```yaml
name: Update Documentation

on:
  push:
    branches: [main]
    paths:
      - 'src/**'
      - 'lib/**'
      - 'package.json'

jobs:
  update-docs:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      
      - name: Install Claudux
        run: npm install -g claudux
      
      - name: Update Documentation
        env:
          CLAUDE_API_KEY: ${{ secrets.CLAUDE_API_KEY }}
        run: |
          claudux update --force-model sonnet
      
      - name: Commit Changes
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add docs/
          git diff --staged --quiet || git commit -m "docs: update documentation [skip ci]"
          git push
```

### GitLab CI

`.gitlab-ci.yml`:
```yaml
update-docs:
  stage: documentation
  image: node:18
  script:
    - npm install -g claudux
    - claudux update
  artifacts:
    paths:
      - docs/
  only:
    changes:
      - src/**/*
      - lib/**/*
```

## VitePress Customization

### Custom Theme

`docs/.vitepress/theme/index.ts`:
```typescript
import DefaultTheme from 'vitepress/theme'
import CustomComponent from './CustomComponent.vue'
import './custom.css'

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component('CustomComponent', CustomComponent)
  }
}
```

### Custom Styles

`docs/.vitepress/theme/custom.css`:
```css
:root {
  --vp-c-brand: #00a8cc;
  --vp-c-brand-light: #00c3e6;
  --vp-c-brand-dark: #0095b8;
}

.vp-doc h2 {
  border-top: 2px solid var(--vp-c-divider);
  padding-top: 24px;
  margin-top: 32px;
}
```

## Workflow Examples

### Daily Development

```bash
# Morning: pull latest
git pull

# Generate fresh docs
claudux update

# Work on features
# ... make changes ...

# Update docs before commit
claudux update -m "Update API documentation"

# Commit everything
git add .
git commit -m "feat: add new feature with docs"
git push
```

### Pre-Release

```bash
# 1. Clean obsolete docs
claudux clean

# 2. Full regeneration
claudux recreate -m "Prepare for v2.0 release"

# 3. Validate all links
claudux validate --external

# 4. Build and test
cd docs
npm run build

# 5. Deploy
npm run deploy
```

### Documentation Review

```bash
# Generate docs
claudux update

# Serve locally
claudux serve

# Review in browser
open http://localhost:5173

# Make manual adjustments
vi docs/guide/setup.md

# Add protection markers
echo "<!-- CLAUDUX:PROTECTED:START -->" >> docs/custom.md
echo "Custom content" >> docs/custom.md
echo "<!-- CLAUDUX:PROTECTED:END -->" >> docs/custom.md

# Re-generate to test protection
claudux update
```

## Troubleshooting Examples

### Fix Broken Links

```bash
# Check for broken links
claudux validate

# Auto-repair
claudux repair

# Or manually fix and validate
vi docs/broken-link.md
claudux validate
```

### Recover Deleted Files

```bash
# Accidentally deleted important file
claudux clean  # Oops!

# Recover from git
git checkout -- docs/important.md

# Protect for future
echo "docs/important.md" >> .clauduxignore
```

## Performance Optimization

### Large Codebases

```bash
# Use faster model for large projects
claudux update --force-model haiku

# Or focus on specific areas
claudux update -m "Only update src/components documentation"
```

### Incremental Updates

```bash
# Daily quick update
claudux update -m "Update changed files only"

# Weekly full update
claudux recreate
```

## Next Steps

- Try [Basic Setup](/examples/basic-setup) tutorial
- Explore [Advanced Usage](/examples/advanced-usage)
- Read [Configuration Guide](/guide/configuration)
- Check [Commands Reference](/api/cli)