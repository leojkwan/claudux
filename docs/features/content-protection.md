# Content Protection

[Home](/) > [Features](/features/) > Content Protection

Claudux provides robust content protection mechanisms to safeguard sensitive information and preserve valuable content during AI-powered documentation generation. The protection system is file-type aware and automatically detects sensitive patterns.

## Overview

Content protection operates on multiple levels:
- **Inline protection markers** for granular content control
- **Protected directory detection** for bulk sensitivity management
- **Sensitive file pattern recognition** for automatic exclusion
- **Content stripping utilities** for safe AI analysis

## Technical Implementation

The content protection system is implemented in `/Users/lkwan/Snapchat/Dev/claudux/lib/content-protection.sh` with three core functions:

### Protection Marker System

The `get_protection_markers()` function provides file-type aware comment markers:

```bash
# From lib/content-protection.sh:5-33
get_protection_markers() {
    local file="$1"
    local ext="${file##*.}"
    
    case "$ext" in
        md|markdown)
            echo "<!-- skip -->" "<!-- /skip -->"
            ;;
        swift|js|ts|jsx|tsx|java|c|cpp|h|hpp|rs|go)
            echo "// skip" "// /skip"
            ;;
        py|sh|bash|zsh|rb|pl)
            echo "# skip" "# /skip"
            ;;
        html|xml|vue)
            echo "<!-- skip -->" "<!-- /skip -->"
            ;;
        css|scss|sass|less)
            echo "/* skip */" "/* /skip */"
            ;;
        sql)
            echo "-- skip" "-- /skip"
            ;;
        *)
            # Default to hash comment
            echo "# skip" "# /skip"
            ;;
    esac
}
```

### Supported File Types

| Language/Format | Start Marker | End Marker |
|----------------|--------------|------------|
| Markdown | `<!-- skip -->` | `<!-- /skip -->` |
| JavaScript/TypeScript/Swift/C/C++/Rust/Go/Java | `// skip` | `// /skip` |
| Python/Shell/Bash/Ruby/Perl | `# skip` | `# /skip` |
| HTML/XML/Vue | `<!-- skip -->` | `<!-- /skip -->` |
| CSS/SCSS/SASS/LESS | `/* skip */` | `/* /skip */` |
| SQL | `-- skip` | `-- /skip` |

### Content Stripping Function

The `strip_protected_content()` function removes protected sections before AI analysis:

```bash
# From lib/content-protection.sh:36-58
strip_protected_content() {
    local file="$1"
    local temp_file=$(mktemp)
    
    if [[ ! -f "$file" ]]; then
        echo "$file"
        return 1
    fi
    
    # Get appropriate comment markers for this file type
    local markers=($(get_protection_markers "$file"))
    local start_marker="${markers[0]}"
    local end_marker="${markers[1]}"
    
    # Remove protected sections using awk
    awk -v start="$start_marker" -v end="$end_marker" '
        $0 ~ start { skip=1; next }
        $0 ~ end { skip=0; next }
        !skip { print }
    ' "$file" > "$temp_file"
    
    echo "$temp_file"
}
```

#### AWK Processing Logic

The AWK script implements a state machine:
1. **Normal state**: Print all lines (default)
2. **Skip state**: When start marker detected, begin skipping
3. **End skip**: When end marker detected, return to normal state

This approach ensures:
- Nested protection markers are handled correctly
- Empty lines and formatting are preserved outside protected sections
- The original file remains untouched

### Protected Path Detection

The `is_protected_path()` function identifies sensitive directories and files:

```bash
# From lib/content-protection.sh:61-75
is_protected_path() {
    local path="$1"
    
    # Protected directories
    if [[ "$path" =~ ^(notes|private|.git|node_modules|vendor|target|build|dist)/ ]]; then
        return 0
    fi
    
    # Protected files
    if [[ "$path" =~ \.(env|key|pem|p12|keystore)$ ]]; then
        return 0
    fi
    
    return 1
}
```

#### Protected Directories

- **`notes/`** - Personal notes and documentation drafts
- **`private/`** - Explicitly private content
- **`.git/`** - Version control internals
- **`node_modules/`** - Package dependencies
- **`vendor/`** - Third-party libraries
- **`target/`** - Build artifacts (Rust, Java)
- **`build/`** - Build outputs
- **`dist/`** - Distribution files

#### Protected File Extensions

- **`.env`** - Environment variables and secrets
- **`.key`** - Private keys
- **`.pem`** - Certificate files
- **`.p12`** - PKCS#12 certificate bundles
- **`.keystore`** - Java keystores

## Usage Examples

### Inline Content Protection

#### Markdown Files
```markdown
# Public Documentation

This section will be included in AI analysis.

<!-- skip -->
Internal notes about implementation details that should not be documented.
Contains sensitive information about internal APIs.
<!-- /skip -->

This section will be included in AI analysis.
```

#### JavaScript/TypeScript Files
```javascript
// This function will be analyzed for documentation
function publicAPI() {
    // skip
    // Internal implementation details
    // Sensitive business logic
    // /skip
    
    return result;
}
```

#### Python Files
```python
def public_function():
    """This docstring will be analyzed."""
    
    # skip
    # Sensitive implementation details
    # Database connection strings
    # /skip
    
    return processed_data
```

#### Shell Scripts
```bash
#!/bin/bash
# This script header will be included

function public_utility() {
    # skip
    # Sensitive configuration
    # Internal server details
    # /skip
    
    echo "Public functionality"
}
```

### Directory-Level Protection

Protected directories are automatically excluded from analysis:

```
project/
├── docs/                 # ✅ Analyzed
├── src/                  # ✅ Analyzed
├── notes/                # ❌ Protected (excluded)
├── private/              # ❌ Protected (excluded)
├── .env                  # ❌ Protected (excluded)
└── config.key           # ❌ Protected (excluded)
```

## Integration with AI Generation

### During Analysis Phase

When Claudux analyzes your codebase, it automatically:

1. **Identifies protected paths** using `is_protected_path()`
2. **Strips protected content** from files using `strip_protected_content()`
3. **Creates temporary clean files** for AI analysis
4. **Preserves original files** unchanged

### Temporary File Management

```bash
# Example of safe content processing
local temp_file=$(mktemp)
local clean_file=$(strip_protected_content "$source_file")

# AI processes the clean version
analyze_with_ai "$clean_file"

# Cleanup temporary files
rm -f "$temp_file" "$clean_file"
```

## Security Considerations

### What Gets Protected

✅ **Protected Content**:
- Environment variables and API keys
- Internal implementation details
- Sensitive business logic
- Personal notes and drafts
- Authentication tokens
- Database schemas
- Private configuration

### What Remains Visible

✅ **Still Analyzed**:
- Public API interfaces
- Function signatures
- Class definitions
- Documentation comments
- Example usage code
- Configuration templates

## Best Practices

### 1. Granular Protection
Use inline markers for specific sensitive sections rather than protecting entire files when possible:

```javascript
// Good: Protect only sensitive parts
function userAuthentication() {
    // skip
    const SECRET_KEY = process.env.JWT_SECRET;
    // /skip
    
    // This public interface documentation is valuable
    return validateToken(token);
}
```

### 2. Consistent Marker Placement
Place markers on separate lines for clear boundaries:

```python
# Good: Clear boundaries
def process_payment():
    # skip
    sensitive_payment_logic()
    # /skip
    
    return success_response()

# Avoid: Inline markers
def process_payment():
    result = sensitive_payment_logic()  # skip
    return success_response()
```

### 3. Document Protection Strategy
Add comments explaining why content is protected:

```bash
# skip
# Internal API endpoints - not for public documentation
# Contains staging server URLs and internal service names
API_INTERNAL="https://internal-api.company.com"
# /skip
```

### 4. Regular Protection Audits
Periodically review protected content to ensure:
- Protection is still necessary
- New sensitive content is properly marked
- Public interfaces aren't accidentally protected

## Troubleshooting

### Common Issues

#### Protection Markers Not Working
- Verify correct marker syntax for file type
- Check that markers are on separate lines
- Ensure no extra whitespace in markers

#### Content Still Appearing in Documentation
- Confirm file extension is recognized
- Check path-based protection rules
- Verify temporary file cleanup

#### Over-Protection
- Review protected directories list
- Use granular inline protection instead of broad exclusions
- Consider if content should be documented

### Debug Mode

Enable verbose logging to see protection decisions:

```bash
CLAUDUX_VERBOSE=1 claudux update
```

This will show:
- Which files are being protected
- Content stripping operations
- Temporary file creation and cleanup

## Future Enhancements

Planned improvements to the content protection system:

- **Custom protection patterns** via configuration files
- **Encryption of protected content** in temporary files
- **Audit logging** of protection decisions
- **Integration with .gitignore patterns** for automatic exclusion
- **Visual indicators** in generated documentation for protected areas

The content protection system ensures that sensitive information remains secure while still enabling comprehensive AI-powered documentation generation for public interfaces and functionality.