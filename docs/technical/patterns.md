# Code Patterns and Conventions

[Home](/) > [Technical](/technical/) > Code Patterns and Conventions

This document outlines the established code patterns, conventions, and best practices used throughout the Claudux codebase. These patterns are derived from the project's `CLAUDE.md` instructions and implemented consistently across all modules.

## Core Language and Style Conventions

### Bash-First Philosophy

Claudux is fundamentally a Bash-based project with strict adherence to shell scripting best practices:

```bash
#!/bin/bash
# Always use explicit Bash shebang
# NEVER introduce Python, Ruby, or other scripting languages for core features

# Script safety headers - ALWAYS include these
set -u                    # Error on undefined variables
set -o pipefail          # Pipe failure propagates
```

### Naming Conventions

**Always use snake_case** for all Bash functions and variables:

```bash
# ✅ Correct - snake_case
detect_project_type() {
    local project_name="$1"
    local config_file="docs-ai-config.json"
}

# ❌ Incorrect - camelCase
detectProjectType() {
    local projectName="$1"
    local configFile="docs-ai-config.json"
}
```

### Variable Declaration Patterns

**Always use proper variable scoping:**

```bash
# ✅ Correct - explicit scoping
readonly SCRIPT_DIR="$(resolve_script_path)"
local temp_file="$(mktemp)"
export PROJECT_TYPE

# ❌ Incorrect - global variables without declaration
script_dir="$(resolve_script_path)"
temp_file="$(mktemp)"
```

## Error Handling Patterns

### Standardized Error Functions

**Always use the established error handling pattern:**

```bash
# From lib/colors.sh - the canonical error pattern
error_exit() {
    print_color "RED" "❌ $1" >&2
    exit "${2:-1}"
}

# Usage throughout codebase
[[ -f "$config_file" ]] || error_exit "Configuration file not found: $config_file"
command -v jq >/dev/null 2>&1 || error_exit "jq is required but not installed"
```

### Function Validation Pattern

**Always validate function existence** before calling:

```bash
# From bin/claudux - function validation pattern
check_function() {
    local func_name="$1"
    if ! declare -F "$func_name" >/dev/null 2>&1; then
        error_exit "Required function '$func_name' not found. Library loading may have failed."
    fi
}

# Usage before function calls
check_function "show_header"
check_function "update"
show_header
update "$@"
```

### Graceful Degradation Pattern

**Always check for command availability** before using:

```bash
# From lib/project.sh - command availability check
if command -v jq &> /dev/null; then
    PROJECT_NAME=$(jq -r '.project.name // "Your Project"' docs-ai-config.json)
else
    # Fallback to sed/grep parsing
    PROJECT_NAME=$(grep '"name"' docs-ai-config.json | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi
```

## Path and File Handling Patterns

### Absolute Path Resolution

**Always use absolute paths** via `resolve_script_path()`:

```bash
# From bin/claudux - canonical path resolution
resolve_script_path() {
    local source="${BASH_SOURCE[0]}"
    local count=0
    
    while [[ -L "$source" ]] && [[ $count -lt 10 ]]; do
        local dir="$(cd -P "$(dirname "$source")" 2>/dev/null && pwd)"
        [[ -z "$dir" ]] && return 1
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
        ((count++))
    done
    
    [[ $count -eq 10 ]] && return 1
    cd -P "$(dirname "$source")" 2>/dev/null && pwd
}
```

**Never use relative paths** in sourced files:

```bash
# ✅ Correct - absolute path resolution
SCRIPT_DIR="$(resolve_script_path)"
LIB_DIR="$SCRIPT_DIR/../lib"
source "$LIB_DIR/colors.sh"

# ❌ Incorrect - relative paths
source "../lib/colors.sh"
```

### Temporary File Management

**Use `mktemp` for temporary files** and ensure cleanup:

```bash
# ✅ Correct - proper temp file handling
local temp_file="$(mktemp)"
trap "rm -f '$temp_file'" EXIT

process_content > "$temp_file"
validate_content "$temp_file"

# ❌ Incorrect - hardcoded paths
echo "data" > /tmp/claudux-temp.txt
```

### Background Process Cleanup

**Always clean up background processes** in trap handlers:

```bash
# From bin/claudux - cleanup pattern
cleanup_on_exit() {
    local exit_code=$?
    jobs -p 2>/dev/null | xargs -r kill 2>/dev/null || true
    exit $exit_code
}

trap cleanup_on_exit EXIT
```

## Module Organization Patterns

### Library Loading Pattern

**Follow the established library sourcing pattern:**

```bash
# From bin/claudux - canonical library loading
REQUIRED_LIBS=("colors.sh" "project.sh" "content-protection.sh" "claude-utils.sh" ...)

for lib in "${REQUIRED_LIBS[@]}"; do
    lib_path="$LIB_DIR/$lib"
    [[ ! -f "$lib_path" ]] && error_exit "Required library file not found: $lib_path"
    source "$lib_path" || error_exit "Failed to source library: $lib_path"
done
```

### Module Structure Pattern

**Follow the pattern** established in `lib/colors.sh` for new utility modules:

```bash
#!/bin/bash
# Brief description of module purpose

# Constants and exports
export CONSTANT_NAME="value"

# Core functions
function_name() {
    local param="$1"
    # Implementation
}

# Error handling follows patterns
some_operation() {
    local result
    if ! result=$(command_that_might_fail); then
        error_exit "Operation failed: $result"
    fi
}
```

### Business Logic Separation

**Never put business logic in `bin/claudux`** - it's a router only:

```bash
# ✅ Correct - router delegates to modules
case "${1:-}" in
    "update")
        check_function "update"
        shift
        update "$@"
        ;;
    "serve")
        check_function "serve"
        serve
        ;;
esac

# ❌ Incorrect - business logic in router
case "${1:-}" in
    "update")
        echo "Updating documentation..."
        # 50 lines of update logic here
        ;;
esac
```

## Logging and Output Patterns

### Structured Logging

**Use the established logging pattern:**

```bash
# From lib/colors.sh - standard logging functions
log_verbose() {
    [[ "${CLAUDUX_VERBOSE:-0}" -gt 0 ]] && info "$1"
}

# Usage throughout codebase
log_verbose "Loading project configuration"
info "🧠 Checking available models..."
success "✅ Configuration loaded successfully"
warn "⚠️ Node.js version is below recommended"
```

### Output Formatting

**Never use `echo` for user output** - use `print_color` or `printf`:

```bash
# ✅ Correct - structured output
print_color "GREEN" "✓ Success message"
printf "Processing %s...\n" "$filename"

# ❌ Incorrect - plain echo
echo "Success message"
echo "Processing $filename..."
```

## Configuration and Template Patterns

### Configuration Cascade Pattern

**Follow the priority cascade** for configuration loading:

```bash
# From lib/project.sh - configuration cascade
load_project_config() {
    # 1. Primary configuration
    if [[ -f "docs-ai-config.json" ]] && command -v jq &> /dev/null; then
        PROJECT_NAME=$(jq -r '.project.name // "Your Project"' docs-ai-config.json)
    # 2. Legacy configuration
    elif [[ -f ".claudux.json" ]]; then
        # Legacy handling
    fi
    
    # 3. Auto-detection fallback
    if [[ -z "$PROJECT_TYPE" ]] || [[ "$PROJECT_TYPE" == "generic" ]]; then
        PROJECT_TYPE=$(detect_project_type)
    fi
}
```

### Template Resolution Pattern

**Follow the template priority system:**

```bash
# From lib/docs-generation.sh - template resolution
if [[ -f "$LIB_DIR/templates/${project_type}/config.json" ]]; then
    template_config="$LIB_DIR/templates/${project_type}/config.json"
elif [[ -f "$LIB_DIR/templates/${project_type}-project-config.json" ]]; then
    template_config="$LIB_DIR/templates/${project_type}-project-config.json"
elif [[ -f "$LIB_DIR/templates/generic/config.json" ]]; then
    template_config="$LIB_DIR/templates/generic/config.json"
fi
```

## Claude AI Integration Patterns

### Model Selection Pattern

**Always respect model selection hierarchy:**

```bash
# From lib/claude-utils.sh - model selection
get_model_settings() {
    local model="${FORCE_MODEL:-opus}"  # Environment override or default
    
    case "$model" in
        "opus")
            model_name="Claude Opus (most powerful)"
            timeout_msg="⏳ This may take 60-120 seconds..."
            ;;
        "sonnet")
            model_name="Claude Sonnet (fast & capable)"
            timeout_msg="⏳ This should take 30-60 seconds..."
            ;;
    esac
}
```

### Prompt Building Pattern

**Use the multi-part structure** for Claude prompts:

```bash
# From lib/docs-generation.sh - prompt structure
build_generation_prompt() {
    local prompt="Analyze this ${project_type} project (${project_name}) and update documentation:

**STEP 1: Read Configuration Files**
- Read $template_config for ${project_type}-specific patterns
- Read $style_guide for universal principles

**STEP 2: Analyze Codebase**
- Examine source files and architecture
- Identify documentation needs

**STEP 3: Two-Phase Generation**
==== PHASE 1: ANALYSIS & PLANNING ====
..."
}
```

## Security and Safety Patterns

### Content Protection Pattern

**Always respect content protection markers:**

```bash
# From lib/content-protection.sh - protection markers
get_protection_markers() {
    local file="$1"
    local ext="${file##*.}"
    
    case "$ext" in
        md|markdown) echo "<!-- skip -->" "<!-- /skip -->" ;;
        swift|js|ts) echo "// skip" "// /skip" ;;
        py|sh|bash) echo "# skip" "# /skip" ;;
    esac
}
```

### File Locking Pattern

**Implement process isolation** for concurrent execution safety:

```bash
# From bin/claudux - file locking pattern
acquire_lock() {
    local lock_file="${TMPDIR:-/tmp}/claudux-$(pwd | md5sum).lock"
    
    if [[ -f "$lock_file" ]]; then
        local lock_pid=$(cat "$lock_file")
        if kill -0 "$lock_pid" 2>/dev/null; then
            error_exit "Another instance is running (PID: $lock_pid)"
        fi
    fi
    
    echo $$ > "$lock_file"
    trap "rm -f '$lock_file'" EXIT
}
```

## Anti-Patterns to Avoid

### Code Style Anti-Patterns

```bash
# ❌ DON'T use camelCase in Bash
getUserConfig() { ... }

# ❌ DON'T use echo for user output
echo "Processing files..."

# ❌ DON'T parse JSON with sed when jq is available
version=$(cat package.json | sed 's/.*"version": "\([^"]*\)".*/\1/')

# ❌ DON'T use global variables without declaration
project_name="My Project"
```

### Error Handling Anti-Patterns

```bash
# ❌ DON'T silently fail
command_that_might_fail > /dev/null 2>&1

# ❌ DON'T use exit directly
[[ -f "$file" ]] || exit 1

# ❌ DON'T ignore pipe failures (missing set -o pipefail)
cat file | grep pattern | head -1

# ❌ DON'T assume commands exist
jq '.version' package.json
```

### AI Integration Anti-Patterns

```bash
# ❌ DON'T call Claude directly
claude generate "Create documentation"

# ❌ DON'T exceed context limits without checking
cat huge_file.txt | claude process

# ❌ DON'T ignore rate limits
for file in *.md; do claude process "$file"; done
```

## Testing and Validation Patterns

### Pre-Commit Testing Pattern

**Always run these checks** before committing:

```bash
# Basic functionality test
./bin/claudux version

# Sample project test
cd sample_project && claudux update

# VitePress serving test
claudux serve

# Cleanup safety test
claudux clean --dry-run
```

### Cross-Platform Compatibility

**Test on both macOS and Linux** due to command differences:

```bash
# macOS vs Linux differences to handle
if command -v md5sum >/dev/null 2>&1; then
    hash=$(md5sum <<< "$content")
else
    hash=$(md5 -s "$content")  # macOS
fi

# sed -i syntax differences
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/pattern/replacement/' file
else
    sed -i 's/pattern/replacement/' file
fi
```

## Performance Patterns

### Incremental Processing

**Use content hashing** to detect changes:

```bash
# Generate hash for change detection
get_content_hash() {
    local file="$1"
    if command -v md5sum >/dev/null 2>&1; then
        md5sum "$file" | cut -d' ' -f1
    else
        md5 -q "$file"
    fi
}
```

### Resource Efficiency

**Process files efficiently:**

```bash
# ✅ Stream processing for large files
process_large_file() {
    while IFS= read -r line; do
        process_line "$line"
    done < "$file"
}

# ✅ Batch operations when possible
find . -name "*.md" -exec process_file {} +
```

This comprehensive pattern guide ensures consistency, maintainability, and reliability across the entire Claudux codebase. All new code should follow these established patterns to maintain the project's architectural integrity.