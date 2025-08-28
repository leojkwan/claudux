[Home](/) > [Examples](/examples/) > Advanced Usage

# Advanced Usage Examples

This guide covers advanced techniques, workflows, and customization patterns for power users of Claudux. Learn how to integrate Claudux into complex development workflows and leverage its full potential.

## CLAUDE.md Context Files

The `CLAUDE.md` file is Claudux's secret weapon for generating high-quality, project-specific documentation.

### Creating CLAUDE.md

Generate a project-specific context file:

```bash
claudux create-template
```

This analyzes your codebase and creates a `CLAUDE.md` file with:
- Detected coding patterns
- Architecture decisions
- Project-specific terminology
- Important constraints and gotchas

### Example CLAUDE.md Structure

Here's what gets generated for a Next.js project:

```markdown
# MyApp - AI Assistant Instructions

## Project Context
This is a Next.js 14 application using App Router with TypeScript, 
PostgreSQL, and Prisma ORM for a SaaS platform.

## CRITICAL RULES - MUST FOLLOW

### Next.js Patterns
- ALWAYS use Server Components by default
- NEVER use "use client" unless interactivity required
- FOLLOW app router conventions (page.tsx, layout.tsx, route.ts)
- USE proper metadata API for SEO

### Database Patterns  
- ALWAYS use Prisma for database operations
- NEVER write raw SQL unless absolutely necessary
- FOLLOW the schema in prisma/schema.prisma
- USE transactions for multi-table operations

### Authentication
- ALWAYS check user sessions in Server Components
- USE the auth helper from lib/auth.ts
- PROTECT API routes with middleware
- FOLLOW the session pattern in app/api/auth/

## Code Organization
- PLACE reusable UI in components/ui/
- KEEP business logic in lib/
- FOLLOW the feature-based folder structure
- USE barrel exports from index.ts files

## Testing Requirements
- ALWAYS write unit tests for utility functions
- USE Jest and React Testing Library
- FOLLOW the test patterns in __tests__/
- RUN npm test before committing
```

### Using CLAUDE.md Effectively

The `CLAUDE.md` file dramatically improves documentation quality:

**Before CLAUDE.md (generic):**
```markdown
# API Reference

## Authentication
This API uses authentication tokens.
```

**After CLAUDE.md (project-specific):**
```markdown  
# API Reference

## Authentication
This API uses JWT tokens with RS256 signing. Tokens are issued by 
the `/api/auth/login` endpoint and must be included in the 
`Authorization: Bearer <token>` header.

### Token Structure
```typescript
interface AuthToken {
  sub: string;        // User ID
  role: 'admin' | 'user';
  exp: number;        // Unix timestamp
  permissions: string[];
}
```
```

## Custom Model Selection

Control which Claude model to use for different scenarios:

### Model Comparison

| Model | Speed | Quality | Cost | Best For |
|-------|-------|---------|------|----------|
| Sonnet | Fast | Good | Low | Quick updates, CI/CD |
| Opus | Slow | Excellent | High | Initial generation, complex projects |

### Using --force-model Flag

```bash
# Use Sonnet for quick updates
claudux update --force-model sonnet -m "Fix broken links"

# Use Opus for comprehensive generation
claudux update --force-model opus -m "Create complete API documentation"
```

### Environment Variable Override

```bash
# Set default model for session
export FORCE_MODEL=sonnet

# All commands use Sonnet until session ends
claudux update
claudux recreate
claudux create-template
```

### Model Selection Strategy

**Use Sonnet for:**
- Regular documentation updates
- CI/CD automation
- Quick fixes and link validation
- Iterative improvements

**Use Opus for:**
- Initial documentation generation
- Complex architecture documentation  
- Comprehensive rewrites
- Projects with intricate business logic

## CI/CD Integration

Integrate Claudux into your continuous integration pipeline.

### GitHub Actions Example

Create `.github/workflows/docs.yml`:

```yaml
name: Update Documentation

on:
  push:
    branches: [main, develop]
    paths:
      - 'src/**'
      - 'lib/**'
      - 'components/**'
      - 'package.json'
  pull_request:
    branches: [main]

jobs:
  update-docs:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    
    steps:
    - uses: actions/checkout@v4
      with:
        token: ${{ secrets.GITHUB_TOKEN }}
        fetch-depth: 0

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'

    - name: Install dependencies
      run: |
        npm ci
        npm install -g claudux

    - name: Configure Claude CLI
      env:
        ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
      run: |
        claude config set api-key $ANTHROPIC_API_KEY
        claude config set model claude-3-5-sonnet-20241022

    - name: Update documentation
      env:
        FORCE_MODEL: sonnet
        CLAUDUX_VERBOSE: 1
      run: |
        claudux update -m "Update documentation for latest changes"

    - name: Commit documentation changes
      run: |
        git config --local user.email "action@github.com"
        git config --local user.name "GitHub Action"
        git add docs/
        git diff --staged --quiet || git commit -m "📚 Update documentation [skip ci]"
        git push
```

### GitLab CI Example

Add to `.gitlab-ci.yml`:

```yaml
update-docs:
  stage: deploy
  image: node:18
  variables:
    FORCE_MODEL: "sonnet"
    CLAUDUX_VERBOSE: "1"
  before_script:
    - npm install -g claudux
    - claude config set api-key $ANTHROPIC_API_KEY
  script:
    - claudux update -m "Update documentation for release"
    - git add docs/
    - git commit -m "📚 Update documentation [skip ci]" || true
    - git push origin $CI_COMMIT_REF_NAME
  only:
    - main
    - develop
  when: manual
```

### Pre-commit Hook Integration

Update documentation before every commit:

```bash
# Install pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
set -e

# Check if docs are out of sync
if [ -d "docs" ]; then
    echo "🔍 Checking if documentation needs updates..."
    
    # Quick update with Sonnet
    FORCE_MODEL=sonnet claudux update -m "Update docs for committed changes"
    
    # Stage any doc changes
    git add docs/
fi
EOF

chmod +x .git/hooks/pre-commit
```

## Focused Updates with -m Flag

The `-m` flag provides surgical control over documentation generation.

### Strategic Update Patterns

**Architecture Focus:**
```bash
claudux update -m "Explain the microservices architecture and service communication patterns"
```

**API Documentation:**
```bash
claudux update -m "Document all REST endpoints with request/response examples and error codes"
```

**Onboarding Focus:**
```bash
claudux update -m "Create comprehensive developer onboarding documentation for new team members"
```

**Security Documentation:**
```bash
claudux update -m "Document authentication, authorization, and security best practices"
```

**Deployment Focus:**
```bash
claudux update -m "Create detailed deployment guides for staging and production environments"
```

### Multi-Step Documentation Strategy

Complex projects benefit from iterative documentation:

```bash
# Step 1: Architecture overview
claudux update -m "Create high-level architecture documentation"

# Step 2: API reference
claudux update -m "Add comprehensive API documentation with examples"

# Step 3: Developer guides
claudux update -m "Add developer setup and contribution guides"

# Step 4: Deployment
claudux update -m "Document deployment and operations procedures"
```

### Contextual Updates

Use surrounding context for better results:

```bash
# After adding authentication
claudux update -m "Document the new JWT authentication system including token structure and middleware"

# After database changes
claudux update -m "Update database documentation to reflect the new user profile schema changes"

# After UI refactor
claudux update -m "Document the updated component library with new design system patterns"
```

## Advanced Workflow Combinations

Combine multiple Claudux commands for powerful workflows.

### Complete Refresh Workflow

```bash
#!/bin/bash
# refresh-docs.sh - Complete documentation refresh

echo "🔄 Starting complete documentation refresh..."

# 1. Create/update project context
echo "📋 Updating project context..."
claudux create-template

# 2. Clean slate generation  
echo "🧹 Recreating documentation from scratch..."
claudux recreate --force-model opus -m "Create comprehensive documentation covering architecture, API, and developer guides"

# 3. Validate and fix links
echo "🔗 Validating and fixing links..."
claudux validate --auto-fix

# 4. Start server for review
echo "🌐 Starting development server..."
claudux serve
```

### Release Documentation Workflow

```bash
#!/bin/bash
# release-docs.sh - Prepare documentation for release

VERSION=${1:-"latest"}

echo "📦 Preparing documentation for release $VERSION..."

# Update with release focus
claudux update --force-model opus -m "Prepare comprehensive release documentation including changelog, migration guide, and updated API reference for version $VERSION"

# Validate everything is working
claudux validate || {
    echo "❌ Link validation failed"
    exit 1
}

# Build static site
cd docs && npm run docs:build

echo "✅ Documentation ready for release $VERSION"
```

### Team Onboarding Workflow

```bash
#!/bin/bash
# onboarding-docs.sh - Create onboarding documentation

echo "👥 Creating team onboarding documentation..."

# Focus on onboarding content
claudux update -m "Create detailed onboarding documentation for new developers including setup, architecture overview, coding standards, and first contribution guide"

# Create CLAUDE.md if it doesn't exist
if [[ ! -f "CLAUDE.md" ]]; then
    claudux create-template
fi

# Start server for team review
claudux serve --host 0.0.0.0 # Allow access from network
```

## Environment Variable Mastery

Advanced control through environment variables.

### Complete Environment Setup

```bash
# .env.claudux - Claudux environment configuration
export FORCE_MODEL=sonnet
export CLAUDUX_VERBOSE=1
export CLAUDUX_MESSAGE="Focus on practical examples and clear explanations"
export NO_COLOR=false
```

Load environment:
```bash
source .env.claudux
claudux update
```

### Dynamic Model Selection

```bash
#!/bin/bash
# smart-update.sh - Choose model based on project size

PROJECT_SIZE=$(find . -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" | wc -l)

if [ "$PROJECT_SIZE" -gt 100 ]; then
    echo "🔥 Large project detected, using Opus for quality"
    FORCE_MODEL=opus claudux update "$@"
else  
    echo "⚡ Small project detected, using Sonnet for speed"
    FORCE_MODEL=sonnet claudux update "$@"
fi
```

### Context-Aware Updates

```bash
#!/bin/bash
# context-update.sh - Update based on git changes

CHANGED_FILES=$(git diff --name-only HEAD~1)

if echo "$CHANGED_FILES" | grep -q "package.json"; then
    MESSAGE="Update documentation to reflect dependency changes"
elif echo "$CHANGED_FILES" | grep -q "src/api/"; then
    MESSAGE="Update API documentation for modified endpoints" 
elif echo "$CHANGED_FILES" | grep -q "components/"; then
    MESSAGE="Update component documentation for UI changes"
else
    MESSAGE="Update documentation for recent code changes"
fi

echo "📝 Updating docs: $MESSAGE"
claudux update -m "$MESSAGE"
```

## Advanced Configuration Patterns

Sophisticated project configuration techniques.

### Multi-Environment Configuration

**Development config (`docs-ai-config.dev.json`):**
```json
{
  "project": {
    "name": "MyApp (Development)",
    "type": "nextjs"
  },
  "claude": {
    "model": "sonnet",
    "verbose": true
  },
  "features": {
    "apiDocs": true,
    "examples": true,
    "debugInfo": true
  }
}
```

**Production config (`docs-ai-config.prod.json`):**
```json
{
  "project": {
    "name": "MyApp",
    "type": "nextjs"
  },
  "claude": {
    "model": "opus",
    "verbose": false
  },
  "features": {
    "apiDocs": true,
    "examples": true,
    "debugInfo": false,
    "deploymentGuides": true
  }
}
```

**Use with environment switching:**
```bash
# Development
cp docs-ai-config.dev.json docs-ai-config.json
claudux update

# Production  
cp docs-ai-config.prod.json docs-ai-config.json
claudux update -m "Prepare production documentation"
```

### Feature Flag Configuration

```json
{
  "project": {
    "name": "Enterprise API",
    "type": "nodejs"
  },
  "features": {
    "apiDocs": true,
    "examples": true,
    "tutorials": true,
    "architecture": true,
    "security": true,
    "deployment": true,
    "troubleshooting": true,
    "changelog": false,
    "contributing": false
  },
  "sections": {
    "api": {
      "includeExamples": true,
      "includeErrorCodes": true,
      "includeRateLimiting": true
    },
    "guide": {
      "includeQuickstart": true,
      "includeAdvanced": true,
      "includeBestPractices": true
    }
  }
}
```

## Performance Optimization

Techniques for faster documentation generation.

### Incremental Updates

Instead of full regeneration:

```bash
# Only update specific sections
claudux update -m "Update only the API reference section"

# Focus on changed areas
claudux update -m "Update documentation for files modified in the last commit"
```

### Parallel Workflows

For large projects, split documentation tasks:

```bash
#!/bin/bash
# parallel-docs.sh - Parallel documentation generation

# API docs in background
(
    CLAUDUX_MESSAGE="Focus on API documentation" claudux update --force-model sonnet
    echo "✅ API docs complete"
) &

# Component docs in background  
(
    CLAUDUX_MESSAGE="Focus on component documentation" claudux update --force-model sonnet
    echo "✅ Component docs complete"
) &

# Wait for both
wait
echo "🎉 All documentation complete!"
```

### Caching Strategy

Cache Claude responses for repeated patterns:

```bash
#!/bin/bash
# smart-cache.sh - Simple caching for similar projects

CACHE_DIR="$HOME/.claudux-cache"
PROJECT_HASH=$(find . -name "*.js" -o -name "*.ts" | xargs md5sum | md5sum | cut -d' ' -f1)

if [[ -f "$CACHE_DIR/$PROJECT_HASH.docs.tar.gz" ]]; then
    echo "📦 Using cached documentation..."
    tar -xzf "$CACHE_DIR/$PROJECT_HASH.docs.tar.gz"
else
    echo "🔄 Generating fresh documentation..."
    claudux update
    
    # Cache the results
    mkdir -p "$CACHE_DIR"
    tar -czf "$CACHE_DIR/$PROJECT_HASH.docs.tar.gz" docs/
fi
```

## Monitoring and Analytics

Track documentation quality and usage.

### Link Validation Monitoring

```bash
#!/bin/bash
# monitor-docs.sh - Continuous documentation monitoring

while true; do
    echo "🔍 Checking documentation health..."
    
    if claudux validate; then
        echo "✅ All links valid at $(date)"
    else
        echo "❌ Broken links found at $(date)"
        claudux validate --auto-fix
    fi
    
    sleep 3600  # Check every hour
done
```

### Quality Metrics

```bash
#!/bin/bash
# doc-metrics.sh - Documentation quality metrics

echo "📊 Documentation Metrics"
echo "========================"

# File count
echo "📄 Total files: $(find docs -name "*.md" | wc -l)"

# Word count  
echo "📝 Total words: $(find docs -name "*.md" -exec cat {} \; | wc -w)"

# Link count
echo "🔗 Total links: $(find docs -name "*.md" -exec grep -o '\[.*\](.*)' {} \; | wc -l)"

# Code block count
echo "💻 Code blocks: $(find docs -name "*.md" -exec grep -c '```' {} \; | paste -sd+ | bc)"

# Last update
echo "🕐 Last updated: $(stat -c %y docs/index.md)"
```

## Advanced Troubleshooting

Solutions for complex issues.

### Debug Mode Investigation

```bash
# Maximum verbosity
CLAUDUX_VERBOSE=2 claudux -vv update -m "Debug generation issues"

# Focus on specific problems
claudux update -m "Investigate why API documentation is incomplete and fix missing endpoints"
```

### Custom Error Recovery

```bash
#!/bin/bash
# recovery.sh - Automated error recovery

claudux update || {
    echo "❌ Update failed, trying recovery steps..."
    
    # Step 1: Clean and retry
    claudux clean
    claudux update --force-model sonnet
    
    # Step 2: Recreate if still failing
    if [ $? -ne 0 ]; then
        echo "🔄 Recreating from scratch..."
        claudux recreate --force-model sonnet
    fi
    
    # Step 3: Manual intervention needed
    if [ $? -ne 0 ]; then
        echo "🚨 Manual intervention required"
        exit 1
    fi
}
```

### Memory and Token Optimization

For large projects hitting Claude's token limits:

```bash
# Break large projects into chunks
claudux update -m "Document only the core API endpoints"
claudux update -m "Document only the UI components" 
claudux update -m "Document only the database layer"
claudux update -m "Document only the authentication system"
```

## Next Steps

You've mastered advanced Claudux techniques! Consider:

- **[API Reference →](/api/)** - Programmatic integration options
- **[Contributing →](/development/contributing)** - Help improve Claudux
- **[Technical Details →](/technical/)** - Understanding the internals

---

<p align="center">
  <strong>Ready to push the boundaries?</strong><br/>
  <a href="/api/">Explore the API →</a> | 
  <a href="/development/">Join development →</a>
</p>