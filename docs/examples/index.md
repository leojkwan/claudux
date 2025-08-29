# Usage Examples

Real-world examples of using claudux across different project types and workflows.

## Basic Usage

### First-Time Setup

```bash
# Navigate to your project
cd my-awesome-app

# Generate documentation  
claudux update

# Preview the results
claudux serve  # Opens http://localhost:5173
```

**Expected output:**
```
📚 claudux - my-awesome-app Documentation
Powered by Claude AI - Everything stays local

📊 Starting documentation update and cleanup...

🚀 Generating documentation...
🧠 Model: Claude 3.5 Sonnet

📝 Building prompt for react project...
   Project: my-awesome-app (type: react)

✅ Prompt built successfully (15,247 chars)

🚀 Starting documentation generation...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[AI generation process...]

✅ Documentation update complete!
```

## Project-Specific Examples

### React Application

**Project structure:**
```
src/
├── components/Button.jsx
├── hooks/useAuth.js  
├── pages/Home.jsx
└── utils/api.js
```

**Generated documentation:**
```bash
claudux update
# Creates:
# docs/guide/ - Setup and configuration
# docs/components/ - Component API reference  
# docs/hooks/ - Custom hooks documentation
# docs/api/ - API utility documentation
```

### Node.js API

**Project structure:**
```
src/
├── routes/auth.js
├── middleware/cors.js
├── models/User.js
└── app.js
```

**Generated documentation:**
```bash
claudux update  
# Creates:
# docs/guide/ - Server setup and configuration
# docs/api/ - Endpoint reference with examples
# docs/middleware/ - Middleware documentation  
# docs/deployment/ - Production deployment guide
```

### Python Package

**Project structure:**
```
mypackage/
├── __init__.py
├── core.py
├── utils.py
└── cli.py
```

**Generated documentation:**
```bash
claudux update
# Creates:  
# docs/guide/ - Installation and quickstart
# docs/api/ - Function and class reference
# docs/cli/ - Command-line interface docs
# docs/examples/ - Usage examples
```

## Focused Updates

### Adding New Features

When you add a new feature to your codebase:

```bash
claudux update -m "Document the new payment processing module"
```

**Result**: Focuses on the payment module while updating related documentation.

### API Documentation

For backend services, focus on API endpoints:

```bash
claudux update --with "Comprehensive API documentation with request/response examples"
```

### Configuration Changes

After updating configuration options:

```bash
claudux update -m "Update configuration documentation for new environment variables"
```

## Maintenance Workflows

### Weekly Documentation Sync

```bash
#!/bin/bash
# weekly-docs-update.sh

echo "🔄 Weekly documentation sync..."

# Update documentation
claudux update

# Check for broken links  
if claudux update --strict; then
    echo "✅ Documentation is up to date"
else
    echo "❌ Found issues - manual review needed"
    exit 1
fi
```

### Pre-Release Documentation

Before releasing a new version:

```bash
# Comprehensive documentation review
claudux recreate  # Start fresh
claudux update -m "Complete documentation for v2.0 release"

# Validate everything works
claudux serve     # Manual review at localhost:5173
```

### CI/CD Integration

**GitHub Actions workflow:**

```yaml
name: Documentation

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install Claude CLI
        run: npm install -g @anthropic-ai/claude-cli
        
      - name: Configure Claude
        env:
          CLAUDE_API_KEY: ${{ secrets.CLAUDE_API_KEY }}
        run: echo "$CLAUDE_API_KEY" | claude auth login
        
      - name: Install claudux
        run: npm install -g claudux
        
      - name: Generate documentation
        env:
          DOCS_BASE: '/my-project/'
        run: claudux update --strict
        
      - name: Deploy to GitHub Pages
        if: github.ref == 'refs/heads/main'
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./docs/.vitepress/dist
```

## Advanced Examples

### Multi-Language Projects

For projects with multiple language components:

```bash
# Focus on specific language documentation
claudux update -m "Document Python API client library"
claudux update -m "Document JavaScript frontend components"
```

### Monorepo Documentation

For monorepo projects, run claudux from the root:

```bash
# Document entire monorepo
claudux update

# Focus on specific packages
claudux update -m "Document the shared-ui package components"
```

### Migration Documentation

When migrating between major versions:

```bash
claudux update -m "Add migration guide from v1 to v2, preserve legacy docs for reference"
```

## Troubleshooting Examples

### Missing Dependencies

```bash
$ claudux update
ERROR: Claude Code CLI not found. Install: npm install -g @anthropic-ai/claude-code

# Solution:
npm install -g @anthropic-ai/claude-cli
claude config  # Follow authentication prompts
claudux update
```

### Permission Issues

```bash
$ claudux update  
ERROR: Permission denied writing to docs/.vitepress/config.ts

# Solution:
sudo chown -R $(whoami) docs/
claudux update
```

### Model Authentication

```bash
$ claudux update
ERROR: Claude authentication failed

# Solution:
claude config     # Re-authenticate
claudux check     # Verify setup
claudux update
```

### Broken Links

```bash
$ claudux update
⚠️  Link validation found issues. Some documentation links may be broken.

# Solution (automatic):
claudux update -m "Fix broken links and create missing pages"

# Solution (manual):
claudux serve  # Review at localhost:5173
# Edit specific files to fix links
claudux update
```

## Performance Examples

### Large Codebases

For projects with extensive source code:

```bash
# Use faster model for large projects
FORCE_MODEL=sonnet claudux update

# Use more capable model for complex analysis
FORCE_MODEL=opus claudux update
```

### Incremental Updates

For frequent small changes:

```bash
# Quick updates for specific changes
claudux update -m "Update installation instructions for new Node requirement" 
```

This focused approach minimizes generation time while keeping docs current.

## Custom Integration Examples

### Documentation-Driven Development

Use claudux in development workflow:

```bash
# 1. Write failing test
npm test

# 2. Implement feature  
# ... code changes ...

# 3. Update docs
claudux update -m "Document new feature with examples"

# 4. Review docs and code together
claudux serve
```

### Code Review Integration

Include documentation review in PR process:

```bash
# Before code review
claudux update
git add docs/
git commit -m "Update docs for new feature"

# Reviewers can check both code and docs changes
```

These examples demonstrate claudux's flexibility across different project types, team sizes, and development workflows.