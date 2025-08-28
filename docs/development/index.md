[Home](/) > Development

# Development Guide

Welcome to the Claudux development guide! This section provides everything you need to know to contribute to and extend Claudux.

## Getting Started

Claudux is a Bash-first project that prioritizes Unix compatibility, modular architecture, and semantic content analysis. Our development philosophy follows the Unix principle: do one thing well, make it modular, and handle errors gracefully.

### Prerequisites

- **Bash 4.0+** - Core functionality is written in Bash
- **Node.js 18+** - Required for VitePress integration
- **Claude CLI** - AI functionality through `@anthropic-ai/claude-code`
- **Git** - Version control and project detection
- Basic Unix utilities (`mktemp`, `md5sum`/`md5`, `jq`)

### Project Structure

```
claudux/
├── bin/claudux           # Main CLI router (no business logic)
├── lib/                  # All business logic goes here
│   ├── colors.sh         # Terminal color utilities
│   ├── project.sh        # Project detection and config
│   ├── claude-utils.sh   # Claude AI integration layer
│   ├── docs-generation.sh # Two-phase documentation generation
│   ├── content-protection.sh # Sensitive content protection
│   ├── cleanup.sh        # Safe file cleanup operations
│   ├── server.sh         # VitePress development server
│   ├── ui.sh             # User interface and menus
│   ├── templates/        # Project-specific templates
│   └── vitepress/        # VitePress configuration
├── docs/                 # Generated documentation
└── package.json          # VitePress and dependencies
```

## Core Principles

### 1. Bash-First Architecture

- **All core functionality** must be written in Bash
- **Never introduce** Python, Ruby, or other scripting languages for core features
- **Always check command availability** before using external tools
- **Use `set -u` and `set -o pipefail`** in all new scripts

### 2. Modular Design

- **Business logic** belongs in `lib/*.sh` files, not in `bin/claudux`
- **Each module** should have a specific responsibility
- **Source dependencies** using: `source "$SCRIPT_DIR/../lib/module.sh"`
- **Follow established patterns** from `lib/colors.sh`

### 3. Error Handling

- **Never fail silently** - always report errors
- **Use consistent error patterns**:
  ```bash
  error_exit() {
      print_color "RED" "❌ $1" >&2
      exit "${2:-1}"
  }
  ```
- **Always use `set -o pipefail`** to propagate pipe failures
- **Check function existence** before calling with `check_function`

### 4. Path and File Safety

- **Always use absolute paths** via `resolve_script_path()`
- **Never use relative paths** in sourced files
- **Use `mktemp`** for temporary files
- **Clean up background processes** in trap handlers

## Development Workflow

### Setting Up Development Environment

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd claudux
   ```

2. **Test basic functionality:**
   ```bash
   ./bin/claudux version
   ```

3. **Set up a test project:**
   ```bash
   cd /path/to/test-project
   /path/to/claudux/bin/claudux update
   ```

### Before Committing

Always run these verification steps:

1. **Basic functionality check:**
   ```bash
   ./bin/claudux version
   ```

2. **Test with a sample project:**
   ```bash
   claudux update
   ```

3. **Verify VitePress serves:**
   ```bash
   claudux serve
   ```

4. **Check cleanup safety:**
   ```bash
   claudux clean --dry-run
   ```

### Cross-Platform Testing

Test on both macOS and Linux due to differences in:
- **Hash commands**: `md5` vs `md5sum`
- **sed syntax**: Different `-i` flag behavior
- **Process handling**: Signal trapping variations

## Code Standards

### Naming Conventions

- **Use snake_case** for all Bash functions and variables
- **Never use camelCase** in Bash scripts
- **Use descriptive names** that explain purpose

### Function Patterns

- **Validate parameters** at function start
- **Use local variables** to avoid global scope pollution
- **Return meaningful exit codes**
- **Document complex functions** with comments

### Output Standards

- **Use `print_color`** instead of `echo` for user output
- **Follow logging patterns**:
  ```bash
  log_verbose "Debug message"          # Verbose output
  print_color "GREEN" "✓ Success"      # Success messages
  print_color "YELLOW" "⚠️ Warning"    # Warnings
  print_color "RED" "❌ Error"         # Errors
  ```

## Environment Variables

### Standard Variables

- `CLAUDUX_VERBOSE`: Set to 1 or 2 for verbose output
- `FORCE_MODEL`: Override default Claude model
- `NO_COLOR`: Disable colored output
- `SCRIPT_DIR`: Auto-set to script directory
- `WORKING_DIR`: Auto-set to user's project directory

### Configuration Files

- **Project config**: `docs-ai-config.json` in project root
- **Docs structure**: `docs-map.md` for planning
- **VitePress config**: `docs/.vitepress/config.ts`

## Security Considerations

- **Never log sensitive information** from analyzed code
- **Always respect `.gitignore`** patterns
- **Protect private directories**: `private/`, `secret/`, `notes/`
- **Sanitize user input** in prompts and file paths
- **Validate JSON** before parsing

## Common Gotchas

1. **macOS vs Linux differences**: Hash commands, sed syntax
2. **Symlink loops**: Max depth 10 in path resolution
3. **Lock file races**: Use `flock` when available
4. **VitePress port conflicts**: Auto-scan 3000-3100 range
5. **Claude context limits**: 200K tokens max per request
6. **Background process cleanup**: Must trap all exit signals

## Debugging

### Enable Verbose Mode
```bash
CLAUDUX_VERBOSE=1 claudux update
```

### Check Dependencies
```bash
claudux check
```

### Test Specific Model
```bash
claudux update --force-model sonnet
```

## Next Steps

- [Contributing Guidelines →](contributing)
- [Testing Approach →](testing) 
- [Adding New Features →](adding-features)

---

<p align="center">
  Ready to contribute? Check out our <a href="contributing">contributing guidelines</a> to get started.
</p>