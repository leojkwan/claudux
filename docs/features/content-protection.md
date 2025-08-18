[Home](/) > [Features](/features/) > Content Protection

# Content Protection

Claudux provides multiple layers of protection to ensure your sensitive content, custom documentation, and important files are never modified or deleted during documentation generation or cleanup.

## Protection Mechanisms

### 1. Built-in Protected Patterns

Automatically protected directories and files:

```bash
# Always protected
.git/
.env*
node_modules/
private/
secret/
internal/
notes/
credentials/
*.key
*.pem
*.p12
*.cert
*.crt
```

### 2. Protection Markers

Protect custom content within files:

```markdown
<!-- CLAUDUX:PROTECTED:START -->
This content will NEVER be modified or deleted by Claudux.
Add your custom documentation, notes, or special content here.
It will be preserved across all updates and regenerations.
<!-- CLAUDUX:PROTECTED:END -->
```

### 3. .clauduxignore File

Define custom protection patterns:

```gitignore
# .clauduxignore
# Custom protected directories
internal-docs/
architecture-decisions/
meeting-notes/

# Protected file patterns
*-manual.md
*-custom.md
CHANGELOG.md
ROADMAP.md

# Protect by path
docs/archive/**
docs/legacy/**
docs/decisions/**
```

### 4. .gitignore Integration

Respects your `.gitignore` patterns:

```bash
# Automatically protected if in .gitignore
.env.local
.env.production
secrets/
config/private/
```

## Implementation

### Core Protection Logic

From `lib/content-protection.sh`:

```bash
is_protected_path() {
    local path="$1"
    
    # Check built-in patterns
    for pattern in "${PROTECTED_PATTERNS[@]}"; do
        if [[ "$path" =~ $pattern ]]; then
            return 0  # Protected
        fi
    done
    
    # Check .clauduxignore
    if [[ -f ".clauduxignore" ]]; then
        if grep -q "$path" .clauduxignore; then
            return 0  # Protected
        fi
    fi
    
    # Check .gitignore
    if [[ -f ".gitignore" ]]; then
        if git check-ignore "$path" 2>/dev/null; then
            return 0  # Protected
        fi
    fi
    
    return 1  # Not protected
}
```

### Protection Markers

Extract and preserve protected content:

```bash
get_protection_markers() {
    cat <<'EOF'
# Protection Marker Patterns
CLAUDUX:PROTECTED:START
CLAUDUX:PROTECTED:END
CLAUDUX:PRESERVE:START
CLAUDUX:PRESERVE:END
CUSTOM:KEEP:START
CUSTOM:KEEP:END
EOF
}

strip_protected_content() {
    local file="$1"
    local content=$(cat "$file")
    
    # Extract protected sections
    local protected=$(echo "$content" | \
        sed -n '/CLAUDUX:PROTECTED:START/,/CLAUDUX:PROTECTED:END/p')
    
    # Store for later restoration
    echo "$protected" > "$file.protected"
    
    # Remove from main content
    echo "$content" | \
        sed '/CLAUDUX:PROTECTED:START/,/CLAUDUX:PROTECTED:END/d'
}
```

## Usage Examples

### Protecting Custom Documentation

Add protection markers to preserve custom content:

```markdown
# API Documentation

## Auto-Generated Section
This will be updated by Claudux.

<!-- CLAUDUX:PROTECTED:START -->
## Custom Implementation Notes

These are internal notes that should never be modified:
- Our API uses custom authentication
- Rate limiting is set to 100 req/min
- Contact backend team for access
<!-- CLAUDUX:PROTECTED:END -->

## More Auto-Generated Content
This section will be updated.
```

### Protecting Entire Files

Add to `.clauduxignore`:

```gitignore
# Protect specific files
docs/internal/api-keys.md
docs/decisions/adr-*.md
docs/manual/deployment-guide.md

# Protect by pattern
*-protected.md
*-manual.md
*-custom.md
```

### Protecting Directories

```gitignore
# Protect entire directories
docs/archive/
docs/internal/
docs/decisions/
private/
notes/
```

## Advanced Protection

### Conditional Protection

Protect based on content:

```bash
# Custom protection script
should_protect() {
    local file="$1"
    
    # Protect if contains sensitive keywords
    if grep -q "CONFIDENTIAL\|SECRET\|PRIVATE" "$file"; then
        return 0
    fi
    
    # Protect if has custom header
    if head -n 1 "$file" | grep -q "MANUAL"; then
        return 0
    fi
    
    return 1
}
```

### Environment-Based Protection

```bash
# Production protection
if [[ "$ENVIRONMENT" == "production" ]]; then
    PROTECTED_PATTERNS+=("docs/staging/")
    PROTECTED_PATTERNS+=("docs/development/")
fi
```

### Dynamic Protection Rules

```json
// docs-ai-config.json
{
  "protection": {
    "patterns": [
      "docs/client-*/**",
      "docs/proprietary/**"
    ],
    "rules": {
      "protectByAge": "30d",
      "protectByAuthor": ["john", "jane"],
      "protectByTag": ["manual", "reviewed"]
    }
  }
}
```

## Protection Validation

### Check Protected Files

List all protected files:

```bash
# Find files with protection markers
grep -r "CLAUDUX:PROTECTED" docs/

# Check .clauduxignore patterns
while read pattern; do
    find docs -path "$pattern" 2>/dev/null
done < .clauduxignore
```

### Validate Protection

Test if a file is protected:

```bash
# Custom validation script
validate_protection() {
    local file="$1"
    
    if is_protected_path "$file"; then
        echo "✓ $file is protected"
    else
        echo "⚠ $file is NOT protected"
    fi
}
```

## Best Practices

### 1. Use Markers for Inline Protection

When you need to protect specific sections:

```markdown
## Configuration

<!-- CLAUDUX: