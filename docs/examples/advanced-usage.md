[Home](/) > [Examples](/examples/) > Advanced Usage

# Advanced Usage Examples

Advanced techniques and workflows for power users of Claudux.

## Complex Project Configurations

### Monorepo with Multiple Packages

Structure:
```
my-monorepo/
├── packages/
│   ├── core/
│   ├── ui/
│   └── utils/
├── apps/
│   ├── web/
│   └── mobile/
└── lerna.json
```

Strategy:
```bash
# Document entire monorepo with cross-references
cd my-monorepo
cat > CLAUDE.md << 'EOF'
# Monorepo Documentation

## Structure
- packages/core: Core business logic
- packages/ui: Shared UI components
- packages/utils: Utility functions
- apps/web: Web application
- apps/mobile: React Native app

## Documentation Requirements
- Create cross-package references
- Document package dependencies
- Show usage examples across packages
- Include workspace commands
EOF

claudux update
```

### Microservices Architecture

```bash
# Document each service with API contracts
for service in services/*; do
  (
    cd "$service"
    cat > CLAUDE.md << 'EOF'
# Microservice Documentation

## Service Responsibilities
Document this service's specific role

## API Contracts
Document all endpoints with request/response

## Inter-service Communication
Document dependencies on other services
EOF
    claudux update
  )
done

# Generate overview documentation
cat > CLAUDE.md << 'EOF'
# Microservices Overview

Create architecture overview linking all services
EOF
claudux update
```

## Advanced AI Instructions

### Domain-Specific Documentation

Financial application example:

```markdown
# CLAUDE.md for FinTech Application

## Domain Context
This is a financial services application handling:
- Payment processing
- Transaction history
- Account management
- Compliance reporting

## Regulatory Requirements
- Document PCI compliance measures
- Include data retention policies
- Document audit logging
- Explain encryption methods

## Security Documentation
- Document authentication flows
- Explain authorization levels
- Document API security measures
- Include penetration test considerations

## Business Logic
- Document calculation methods with examples
- Explain business rules clearly
- Include edge cases and error handling
- Document compliance checks

## Sensitive Information
- Never document actual API keys
- Don't include real customer data
- Mask sensitive configuration
- Use example data only
```

### Technical Debt Documentation

```markdown
# CLAUDE.md - Technical Debt Focus

## Documentation Requirements

### Identify Technical Debt
- Mark deprecated functions with warnings
- Document workarounds and their reasons
- Highlight areas needing refactoring
- Note performance bottlenecks

### Migration Paths
- Document upgrade paths for deprecated features
- Include migration guides
- Show before/after examples
- List breaking changes

### Future Improvements
- Document planned enhancements
- Note architectural improvements needed
- List known limitations
- Include optimization opportunities
```

## Workflow Automation

### Git Hooks Integration

`.git/hooks/pre-commit`:
```bash
#!/bin/bash
# Update docs before commit

# Check if source files changed
if git diff --cached --name-only | grep -q "^src/"; then
  echo "Source files changed, updating documentation..."
  
  # Update docs
  claudux update -q
  
  # Add updated docs to commit
  git add docs/
  
  echo "Documentation updated and staged"
fi
```

### Continuous Documentation

GitHub Actions workflow:

```yaml
name: Continuous Documentation

on:
  push:
    branches: [main, develop]
  pull_request:
    types: [opened, synchronize]

jobs:
  update-docs:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Full history for better analysis
      
      - uses: actions/setup-node@v3
        with:
          node-version: 18
          cache: npm
      
      - name: Install Claudux
        run: npm install -g claudux
      
      - name: Configure Claudux
        run: |
          cat > CLAUDE.md << 'EOF'
          # CI Documentation Generation
          
          ## Context
          Branch: ${{ github.ref_name }}
          Commit: ${{ github.sha }}
          Author: ${{ github.actor }}
          
          ## Requirements
          - Document changes since last release
          - Focus on modified files
          - Include PR context if available
          EOF
      
      - name: Generate Documentation
        env:
          CLAUDE_API_KEY: ${{ secrets.CLAUDE_API_KEY }}
        run: |
          # Detect what changed
          CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD | grep -E '\.(js|jsx|ts|tsx)$' || true)
          
          if [ -n "$CHANGED_FILES" ]; then
            claudux update -m "Update documentation for changed files: $CHANGED_FILES"
          else
            echo "No source changes detected"
          fi
      
      - name: Check Documentation Quality
        run: |
          # Validate links
          claudux validate
          
          # Check for missing docs
          for src_file in src/**/*.{js,jsx,ts,tsx}; do
            doc_file="docs/${src_file#src/}"
            doc_file="${doc_file%.*}.md"
            
            if [ ! -f "$doc_file" ]; then
              echo "Warning: No documentation for $src_file"
            fi
          done
      
      - name: Deploy to GitHub Pages
        if: github.ref == 'refs/heads/main'
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./docs/.vitepress/dist
          cname: docs.example.com
```

## Performance Optimization

### Large Codebase Handling

```bash
# Split generation by directory
DIRECTORIES=("src/core" "src/features" "src/utils")

for dir in "${DIRECTORIES[@]}"; do
  echo "Documenting $dir..."
  
  # Create focused configuration
  cat > temp-claude.md << EOF
# Documentation for $dir

Focus only on files in $dir
Ignore other directories
Generate detailed documentation
EOF
  
  # Generate with timeout
  timeout 300 claudux update -m "Document $dir only"
  
  # Clean up
  rm temp-claude.md
done
```

### Caching Strategy

```bash
# Cache analysis results
CACHE_DIR="$HOME/.claudux-cache"
mkdir -p "$CACHE_DIR"

# Generate cache key from codebase
CACHE_KEY=$(find src -type f -name "*.js" -exec md5sum {} \; | md5sum | cut -d' ' -f1)
CACHE_FILE="$CACHE_DIR/$CACHE_KEY.json"

if [ -f "$CACHE_FILE" ]; then
  echo "Using cached analysis"
  cp "$CACHE_FILE" .claudux-analysis.json
  claudux update --use-cache
else
  echo "Generating fresh analysis"
  claudux update --save-cache "$CACHE_FILE"
fi
```

## Custom Integrations

### Slack Notifications

```bash
#!/bin/bash
# notify-docs-update.sh

# Generate documentation
output=$(claudux update 2>&1)
status=$?

# Prepare Slack message
if [ $status -eq 0 ]; then
  message="✅ Documentation updated successfully"
  color="good"
else
  message="❌ Documentation update failed"
  color="danger"
fi

# Send to Slack
curl -X POST "$SLACK_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d "{
    \"attachments\": [{
      \"color\": \"$color\",
      \"text\": \"$message\",
      \"fields\": [{
        \"title\": \"Project\",
        \"value\": \"$(basename $(pwd))\"
      }, {
        \"title\": \"Branch\",
        \"value\": \"$(git branch --show-current)\"
      }]
    }]
  }"
```

### Documentation Metrics

```bash
#!/bin/bash
# doc-metrics.sh

# Generate metrics
echo "📊 Documentation Metrics Report"
echo "================================"

# Coverage metric
total_source=$(find src -name "*.js" | wc -l)
total_docs=$(find docs -name "*.md" | wc -l)
coverage=$((total_docs * 100 / total_source))
echo "Coverage: $coverage% ($total_docs/$total_source files)"

# Quality metrics
echo ""
echo "Quality Indicators:"

# Check for examples
examples=$(grep -r "## Example\|## Usage" docs/ | wc -l)
echo "- Files with examples: $examples"

# Check for API documentation
api_docs=$(grep -r "## API\|## Props\|## Parameters" docs/ | wc -l)
echo "- Files with API docs: $api_docs"

# Check for broken links
broken=$(claudux validate 2>/dev/null | grep "broken" | wc -l)
echo "- Broken links: $broken"

# Freshness
latest_update=$(find docs -name "*.md" -type f -exec stat -f "%m" {} \; | sort -n | tail -1)
current_time=$(date +%s)
days_old=$(( (current_time - latest_update) / 86400 ))
echo "- Last updated: $days_old days ago"

# Size
size=$(du -sh docs | cut -f1)
echo "- Total size: $size"
```

## VitePress Advanced Customization

### Custom Theme with Components

`docs/.vitepress/theme/index.ts`:
```typescript
import DefaultTheme from 'vitepress/theme'
import ApiTable from './components/ApiTable.vue'
import CodePlayground from './components/CodePlayground.vue'
import VersionSelector from './components/VersionSelector.vue'
import './custom.css'

export default {
  extends: DefaultTheme,
  enhanceApp({ app, router, siteData }) {
    // Register custom components
    app.component('ApiTable', ApiTable)
    app.component('CodePlayground', CodePlayground)
    app.component('VersionSelector', VersionSelector)
    
    // Add global properties
    app.config.globalProperties.$version = '2.0.0'
    
    // Router guards
    router.onBeforeRouteChange = (to) => {
      console.log('Navigating to:', to)
    }
  }
}
```

### Multi-Version Documentation

```bash
# Generate docs for multiple versions
VERSIONS=("v1.0" "v2.0" "main")

for version in "${VERSIONS[@]}"; do
  echo "Generating docs for $version..."
  
  # Checkout version
  git checkout "$version"
  
  # Generate docs
  claudux update
  
  # Move to version directory
  mkdir -p "docs-versions/$version"
  cp -r docs/* "docs-versions/$version/"
done

# Create version selector
cat > docs/.vitepress/config.ts << 'EOF'
export default {
  themeConfig: {
    nav: [
      {
        text: 'Version',
        items: [
          { text: 'v2.0', link: '/v2.0/' },
          { text: 'v1.0', link: '/v1.0/' },
          { text: 'Latest', link: '/main/' }
        ]
      }
    ]
  }
}
EOF
```

## Security and Compliance

### Audit Documentation

```bash
# Security audit documentation
cat > CLAUDE.md << 'EOF'
# Security Audit Documentation

## Requirements
- Document all authentication endpoints
- List authorization levels
- Document data encryption methods
- Include security headers
- Document rate limiting
- List OWASP compliance measures

## Sensitive Information
- Mask all secrets
- Use placeholder values
- Don't expose internal IPs
- Redact sensitive configurations
EOF

claudux update -m "Generate security audit documentation"
```

### Compliance Documentation

```bash
# GDPR compliance example
cat > docs-ai-config.json << 'EOF'
{
  "compliance": {
    "gdpr": {
      "document_data_flows": true,
      "include_retention_policies": true,
      "document_user_rights": true,
      "mask_personal_data": true
    },
    "security": {
      "document_encryption": true,
      "include_security_measures": true,
      "audit_logging": true
    }
  }
}
EOF
```

## Troubleshooting Advanced Scenarios

### Memory Issues with Large Repos

```bash
# Process in chunks
find src -type f -name "*.js" | split -l 100 - chunk_

for chunk in chunk_*; do
  files=$(cat "$chunk")
  claudux update -m "Document files: $files"
  rm "$chunk"
done
```

### Rate Limit Management

```bash
# Implement exponential backoff
attempt=0
max_attempts=5

while [ $attempt -lt $max_attempts ]; do
  if claudux update; then
    echo "Success!"
    break
  else
    attempt=$((attempt + 1))
    wait_time=$((2 ** attempt * 60))
    echo "Rate limited. Waiting $wait_time seconds..."
    sleep $wait_time
  fi
done
```

## Best Practices Summary

1. **Use Specific Instructions**: Detailed CLAUDE.md improves quality
2. **Automate Updates**: CI/CD integration maintains fresh docs
3. **Monitor Quality**: Track metrics and coverage
4. **Protect Custom Content**: Use markers for manual sections
5. **Optimize Performance**: Cache and batch for large projects
6. **Version Documentation**: Keep docs for multiple versions
7. **Security First**: Never expose sensitive information
8. **Regular Maintenance**: Schedule periodic full regeneration

## Next Steps

- Implement [CI/CD integration](#)
- Set up [monitoring](#)
- Configure [multi-language support](#)
- Explore [plugin development](#)