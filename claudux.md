# Claudux - Coding Patterns & Conventions

## Project Overview

Claudux is a Bash-based CLI tool that leverages Claude AI to automatically generate comprehensive documentation for software projects. It follows a modular shell scripting architecture with clear separation of concerns across functionality-specific library modules.

### What this file is (and isn't)

- This is a developer-facing reference for the Claudux repository itself (architecture, patterns, and conventions).
- It is not the `CLAUDE.md` that Claudux generates for your projects. That file is an AI instruction contract for a target repository.
- Claudux does not read this file at runtime. It is safe to ignore if you are only using the tool.

### How `CLAUDE.md` is actually used

- If a project contains a top-level `CLAUDE.md`, Claudux will read it during generation to tailor docs to that project's conventions (see `lib/docs-generation.sh`, where `CLAUDE.md` is included in the prompt when present).
- To create one for your project: `claudux template` (alias: `create-template`).
- During `claudux update`, the presence of `CLAUDE.md` makes the output more project-specific; if absent, Claudux falls back to templates and code analysis.

### Quick usage (most users)

```bash
claudux update            # Generate/update docs
claudux serve             # Preview locally
claudux template          # Generate a project-specific CLAUDE.md
```

## Architecture Patterns

### 1. Modular Library Architecture

The project uses a **source-based module system** where functionality is divided into focused library modules:

```bash
# Main entry point (bin/claudux)
LIB_DIR="$SCRIPT_DIR/../lib"

# Source all library modules
source "$LIB_DIR/colors.sh"
source "$LIB_DIR/project.sh"
source "$LIB_DIR/content-protection.sh"
source "$LIB_DIR/claude-utils.sh"
source "$LIB_DIR/git-utils.sh"
source "$LIB_DIR/docs-generation.sh"
source "$LIB_DIR/cleanup.sh"
source "$LIB_DIR/server.sh"
source "$LIB_DIR/ui.sh"
```

**Why this pattern?** 
- Shell scripts don't have native module systems, so sourcing provides code reuse
- Each module handles a specific concern (colors, project detection, AI integration)
- Dependencies are loaded in order, allowing modules to use functions from previously loaded modules

### 2. Command Dispatcher Pattern

The main script uses a **case-based command dispatcher** for routing CLI commands:

```bash
# bin/claudux:47-101
main() {
    case "${1:-}" in
        "update")
            show_header
            check_claude
            shift
            update "$@"
            ;;
        "clean"|"cleanup")
            show_header
            cleanup_docs
            ;;
        # ... more commands
        "")
            # Default action: show interactive menu
            show_header
            check_claude
            show_menu
            ;;
        *)
            # Unknown command
            show_header
            print_color "RED" "❌ Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}
```

**Why this pattern?**
- Simple and readable command routing
- Supports command aliases (e.g., "clean" and "cleanup")
- Provides default behavior for no arguments
- Clear error handling for unknown commands

## State Management

### 1. Environment Variables for Global State

The project uses **exported environment variables** for cross-module state sharing:

```bash
# lib/project.sh:28-29
export PROJECT_NAME
export PROJECT_TYPE

# bin/claudux:25-27
export SCRIPT_DIR
export WORKING_DIR
```

**Why this pattern?**
- Bash functions run in the same process, so exports are visible across sourced modules
- Avoids passing common parameters through every function call
- Maintains state throughout the script execution

### 2. Configuration Loading Pattern

Configuration is loaded from JSON files with **graceful fallbacks**:

```bash
# lib/project.sh:9-21
if [[ -f "claudux.json" ]] && command -v jq &> /dev/null; then
    PROJECT_NAME=$(jq -r '.project.name // "Your Project"' claudux.json 2>/dev/null || echo "Your Project")
    PROJECT_TYPE=$(jq -r '.project.type // "generic"' claudux.json 2>/dev/null || echo "generic")
elif [[ -f ".claudux.json" ]]; then
    # Fallback to alternative config
    # ...
fi
```

**Why this pattern?**
- Supports multiple configuration formats
- Graceful degradation when jq is not available
- Default values prevent undefined variable errors

## Error Handling Patterns

### 1. Unified Error Reporting Functions

The project centralizes error handling through **dedicated utility functions**:

```bash
# lib/colors.sh:27-44
error_exit() {
    print_color "RED" "❌ $1" >&2
    exit "${2:-1}"
}

warn() {
    print_color "YELLOW" "⚠️  $1" >&2
}

info() {
    print_color "BLUE" "$1"
}

success() {
    print_color "GREEN" "✅ $1"
}
```

**Why this pattern?**
- Consistent error messaging across all modules
- Visual feedback with colors and emoji indicators
- Proper stderr routing for errors and warnings
- Exit code control for proper CLI behavior

### 2. Command Availability Checking

The project validates dependencies before use:

```bash
# lib/claude-utils.sh:6-8
if ! command -v claude &> /dev/null; then
    error_exit "Claude Code CLI not found. Install: npm install -g @anthropic-ai/claude-code"
fi
```

**Why this pattern?**
- Early failure with helpful error messages
- Prevents cryptic errors from missing dependencies
- Guides users to installation instructions

### 3. Safe Variable Expansion

The project uses **strict mode for undefined variables**:

```bash
# bin/claudux:8
set -u  # Only check for undefined variables, not exit codes
```

**Why this pattern?**
- Catches typos and undefined variables early
- Prevents subtle bugs from empty expansions
- Does not use `set -e` to allow flexible error handling

## Code Organization

### 1. Directory Structure

```
claudux/
├── bin/
│   └── claudux              # Main entry point
├── lib/
│   ├── colors.sh            # Terminal colors and output utilities
│   ├── project.sh           # Project detection and configuration
│   ├── content-protection.sh # Protected content handling
│   ├── claude-utils.sh      # Claude AI integration
│   ├── git-utils.sh         # Git operations and status
│   ├── docs-generation.sh   # Documentation generation logic
│   ├── cleanup.sh           # Obsolete file cleanup
│   ├── server.sh            # VitePress dev server
│   ├── ui.sh                # Interactive menu system
│   └── validate-links.sh    # Link validation utilities
└── lib/templates/           # Project-type specific templates
```

### 2. Function Naming Conventions

The project uses **snake_case with descriptive verb prefixes**:

```bash
# Action functions
check_claude()      # Verify state
load_project_config() # Load data
detect_project_type() # Compute/determine
show_header()       # Display output
build_generation_prompt() # Construct data

# Utility functions
print_color()       # Generic utilities
error_exit()        # Error handling
```

**Why this pattern?**
- Clear intent from function names
- Consistent with Bash conventions
- Verb prefixes indicate function behavior

## AI Integration Patterns

### 1. Two-Phase Documentation Generation

The project uses a **structured two-phase approach** for AI generation:

```bash
# lib/docs-generation.sh:80-105
"==== PHASE 1: COMPREHENSIVE ANALYSIS & PLANNING ===="
# 1. Read Configuration & Templates
# 2. Analyze Codebase Structure  
# 3. Audit Existing Documentation
# 4. Create Documentation Plan

"==== PHASE 2: DOCUMENTATION GENERATION ===="
# Execute the plan from Phase 1
# Generate/update documentation files
```

**Why this pattern?**
- Better context understanding before generation
- More coherent and consistent documentation
- Reduces AI hallucination by planning first

### 2. Claude CLI Integration

The project wraps Claude API calls with **structured parameters**:

```bash
# lib/cleanup.sh:41-46
claude api "$cleanup_prompt" \
    --print \
    --permission-mode acceptEdits \
    --allowedTools "Read,Write,Bash" \
    --verbose \
    --model "${FORCE_MODEL:-opus}"
```

**Why this pattern?**
- Consistent Claude invocation across features
- Controlled tool permissions for safety
- Visual feedback with --print and --verbose
- Model selection flexibility

## Performance Considerations

### 1. Lazy Command Checking

Dependencies are checked only when needed:

```bash
# lib/project.sh:10
if [[ -f "claudux.json" ]] && command -v jq &> /dev/null; then
    # Only use jq if it exists
```

### 2. Early Returns and Short Circuits

The project uses early returns to avoid unnecessary work:

```bash
# lib/cleanup.sh:10-13
if [[ ! -d "docs" ]] || [[ -z "$(find docs -name "*.md" -not -path "*/node_modules/*" 2>/dev/null | head -1)" ]]; then
    warn "📄 No documentation files found to clean"
    return
fi
```

## Security Patterns

### 1. Protected Content Handling

The project implements **content protection markers**:

```bash
# lib/content-protection.sh:9-32
case "$ext" in
    md|markdown)
        echo "<!-- skip -->" "<!-- /skip -->"
        ;;
    swift|js|ts|jsx|tsx|java|c|cpp|h|hpp|rs|go)
        echo "// skip" "// /skip"
        ;;
    # ... more file types
esac
```

**Why this pattern?**
- Prevents AI from modifying sensitive sections
- Language-aware comment styles
- Preserves manually curated content

### 2. Path Protection

The project checks for sensitive paths:

```bash
# lib/content-protection.sh:61-74
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
}
```

## Testing and Debugging

### 1. Verbose Output Mode

The project provides detailed output for debugging:

```bash
# All Claude API calls include:
--verbose  # Detailed operation logging
--print    # Show AI responses
```

### 2. Exit Code Handling

Proper exit code propagation for scripting:

```bash
# lib/cleanup.sh:48-55
local exit_code=$?
if [[ $exit_code -eq 0 ]]; then
    success "🎉 AI-powered cleanup complete!"
else
    error_exit "Claude cleanup failed with exit code $exit_code"
fi
```

### 3. Debug Prompt Saving

The project saves prompts for debugging:

```bash
# lib/docs-generation.sh:282-283
# Save prompt for debugging
echo "$prompt" > .claudux-last-prompt.txt 2>/dev/null || true
```

## Common Utilities

### 1. Color Output System

Centralized color management with safe expansion:

```bash
# lib/colors.sh:11-23
print_color() {
    local color=$1
    local text=$2
    
    # Safe indirect variable expansion
    case "$color" in
        "GREEN") printf "${GREEN}%s${NC}\n" "$text" ;;
        "YELLOW") printf "${YELLOW}%s${NC}\n" "$text" ;;
        # ...
        *) printf "%s\n" "$text" ;;
    esac
}
```

### 2. Project Type Detection

Intelligent project detection based on file patterns:

```bash
# lib/project.sh:33-63
detect_project_type() {
    # iOS/Swift project
    if [[ -f "Project.swift" ]] || [[ -n "$(find . -maxdepth 1 -name "*.xcodeproj" -o -name "*.xcworkspace" 2>/dev/null | head -1)" ]]; then
        echo "ios"
    # Next.js project (check before React)
    elif [[ -f "next.config.js" ]] || [[ -f "next.config.mjs" ]] || [[ -f "next.config.ts" ]] || ([[ -f "package.json" ]] && grep -q '"next"' package.json 2>/dev/null); then
        echo "nextjs"
    # ... more project types
}
```

**Why this pattern?**
- Order matters (Next.js before React)
- Multiple indicators increase accuracy
- Fallback to generic for unknown projects

## Best Practices Applied

1. **Fail Fast with Clear Messages**: Early validation with helpful error messages
2. **Modular Design**: Single responsibility per module
3. **Defensive Programming**: Check dependencies, validate inputs, handle errors
4. **User Feedback**: Visual indicators (colors, emojis) for operation status
5. **Configuration Over Code**: JSON configs for customization without code changes
6. **Safe Defaults**: Sensible fallbacks when configuration is missing
7. **Progressive Enhancement**: Features degrade gracefully (e.g., jq not required)

---

*This document reflects the actual implementation patterns in the Claudux codebase, demonstrating practical Bash scripting patterns for building robust CLI tools.*

## Documentation Structure (reference only)

- **Home**: landing overview, value prop, quick CTA
- **Guide**: installation, quickstart, configuration, commands
- **Features**: two-phase generation, smart cleanup, project detection, VitePress integration, content protection
- **CLI**: commands reference and interactive menu behavior
- **Technical**: architecture, templates, VitePress theme, environment variables
- **Contributing**: contribution guide and release process pointers

> Note: This section outlines the intended information architecture only. Actual content lives in generated docs and should not be duplicated here to avoid drift.

---

*End of reference.*