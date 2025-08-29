# Configuration

## Project Configuration

Create a `claudux.json` in your project root to configure project-specific settings:

```json
{
  "project": {
    "name": "Your Awesome Project",
    "type": "javascript"
  }
}
```

### Supported Project Types

Claudux auto-detects project types, but you can override detection:

| Type | Detection Pattern | Example |
|------|------------------|---------|
| `ios` | `*.xcodeproj`, `Project.swift` | iOS/macOS apps |
| `nextjs` | `next.config.js`, `"next"` in package.json | Next.js apps |
| `react` | `"react"` in package.json | React apps |
| `nodejs` | `"@types/node"` in package.json | Node.js backends |
| `javascript` | `package.json` exists | JavaScript projects |
| `rust` | `Cargo.toml` | Rust projects |
| `python` | `pyproject.toml`, `setup.py` | Python projects |
| `go` | `go.mod` | Go projects |
| `java` | `pom.xml`, `build.gradle` | Java projects |
| `generic` | Default fallback | Any project |

## Documentation Preferences

Generate a `claudux.md` file to capture documentation preferences:

```bash
claudux template
```

This creates a preferences file that guides documentation generation. Example structure:

```markdown
# Site
- title: My Project
- description: A brief project description
- nav items: Guide, Features, API
- logo: auto-detect

# Structure  
- include: guide, features, api, examples
- omit: advanced, enterprise
- sidebar: unified across all pages

# Pages
- must-have: /guide/, /guide/installation, /api/
- ordering: custom groups
- naming: Title Case, emojis enabled

# Links
- external: GitHub, npm (auto-detected)
- base path: local '/' with CI override
```

## Environment Variables

### Model Selection

Control which Claude model to use:

```bash
# Force Opus (more capable, slower)
FORCE_MODEL=opus claudux update

# Force Sonnet (default, faster)  
FORCE_MODEL=sonnet claudux update
```

### Verbosity Control

Claudux is verbose by default. Control output level:

```bash
# Quiet mode (errors only)
claudux -q update

# Default verbose mode
claudux update
```

### Pre-set Directives

Set a default message for documentation updates:

```bash
CLAUDUX_MESSAGE="Focus on API documentation" claudux update
```

## Content Protection

### Protected Paths

Claudux automatically protects sensitive directories and files:

**Protected directories:**
- `notes/`, `private/`
- `.git/`, `node_modules/`, `vendor/`
- `target/`, `build/`, `dist/`

**Protected file patterns:**
- `*.env`, `*.key`, `*.pem`
- `*.p12`, `*.keystore`

### Skip Markers

Protect specific content sections with skip markers:

**Markdown files:**
```markdown
<!-- skip -->
This content will never be modified by claudux
<!-- /skip -->
```

**Code files:**
```javascript
// skip
const SECRET_CONFIG = {
  apiKey: "secret"
};
// /skip
```

**Supported languages:**
- JavaScript/TypeScript: `// skip` ... `// /skip`
- Python: `# skip` ... `# /skip`  
- Swift: `// skip` ... `// /skip`
- Go: `// skip` ... `// /skip`
- Rust: `// skip` ... `// /skip`

## VitePress Configuration

The generated `docs/.vitepress/config.ts` uses these patterns:

### Base Path Policy

**Local development:**
```typescript
base: '/'  // Always use root for local
```

**CI deployment:**
```bash
export DOCS_BASE='/claudux/'  # Set in CI environment
```

### Sidebar Configuration

Claudux generates unified sidebars that appear on all pages:

```typescript
sidebar: {
  '/': [...items],        // Root path (homepage)
  '/guide/': [...items],  // Guide section  
  '/features/': [...items] // Features section
}
```

### Auto-detected Features

- **Social links**: GitHub repo, npm package
- **Logo**: Searches for logo/icon files
- **Edit links**: Points to GitHub source
- **Search**: Local full-text search enabled

## Advanced Configuration

### Custom Templates

Override default templates by project type:

1. Copy from `lib/templates/{type}/config.json`
2. Modify documentation structure
3. Place in your project root as `claudux.json`

### Link Validation

Control link checking behavior:

```bash
claudux update --strict  # Fail on any broken links
```

Built-in validation checks:
- Internal page links
- Anchor links within pages  
- External URL accessibility
- Asset references

### CI/CD Integration

**GitHub Actions example:**

```yaml
- name: Generate Documentation
  run: |
    npm install -g claudux
    export DOCS_BASE='/my-project/'
    claudux update --strict
    
- name: Deploy to Pages
  uses: actions/deploy-pages@v1
  with:
    artifact_name: docs
    path: docs/.vitepress/dist
```

## Troubleshooting Configuration

**Permission errors:**
```bash
sudo chown -R $(whoami) ~/.npm
```

**Missing dependencies:**
```bash
claudux check  # Diagnose issues
```

**Model authentication:**
```bash
claude config get  # Verify auth status
claude config      # Re-authenticate if needed
```