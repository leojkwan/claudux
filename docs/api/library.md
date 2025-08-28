# Library Functions

[Home](/) > [API](/api/) > Library Functions

Reference documentation for Claudux's internal library functions organized by module.

## Overview

Claudux uses a modular architecture with specialized libraries in `lib/` directory. Each module handles specific functionality and follows consistent patterns for error handling, logging, and validation.

## Core Modules

### `colors.sh` - Output & Logging

#### `print_color(color, text)`
Print colored text to stdout.

**Parameters:**
- `color` - Color name: `"GREEN"`, `"YELLOW"`, `"BLUE"`, `"RED"`
- `text` - Text to print

**Example:**
```bash
print_color "GREEN" "✅ Success message"
print_color "RED" "❌ Error message"
```

#### `error_exit(message, [exit_code])`
Print error message and exit with specified code.

**Parameters:**
- `message` - Error message to display
- `exit_code` - Exit code (default: 1)

**Example:**
```bash
error_exit "Configuration file not found" 2
```

#### `warn(message)`
Print warning message to stderr.

**Parameters:**
- `message` - Warning message

#### `info(message)`
Print informational message in blue.

**Parameters:**
- `message` - Info message

#### `success(message)`
Print success message in green.

**Parameters:**
- `message` - Success message

### `project.sh` - Project Detection & Configuration

#### `detect_project_type()`
Auto-detect project type from file patterns.

**Returns:** Project type string (`ios`, `nextjs`, `react`, `nodejs`, `javascript`, `rust`, `python`, `go`, `java`, `generic`)

**Detection Logic:**
- iOS: `*.xcodeproj`, `*.xcworkspace`, `Project.swift`
- Next.js: `next.config.*`, `"next"` in `package.json`
- React: `"react"` in `package.json`
- Node.js: `"@types/node"` in `package.json`
- JavaScript: `package.json` exists
- Rust: `Cargo.toml` exists
- Python: `pyproject.toml`, `setup.py`, `requirements.txt`
- Go: `go.mod` exists  
- Java: `pom.xml`, `build.gradle*`

#### `load_project_config()`
Load project configuration from `docs-ai-config.json` or `.claudux.json`.

**Side Effects:**
- Sets `PROJECT_NAME` environment variable
- Sets `PROJECT_TYPE` environment variable

#### `find_project_logo()`
Find project logo/icon file.

**Returns:** Path to logo file or empty string

**Search Patterns:**
- iOS: App icons in `Assets.xcassets/AppIcon.appiconset/`
- Generic: `logo*`, `icon*` files (PNG, JPG, SVG)

### `docs-generation.sh` - Documentation Generation

#### `build_generation_prompt(project_type, project_name, [user_directive])`
Build comprehensive prompt for Claude documentation generation.

**Parameters:**
- `project_type` - Project type from detection
- `project_name` - Human-readable project name
- `user_directive` - Optional focused directive

**Returns:** Complete prompt string for two-phase generation

#### `update([options...])`
Main documentation update function with two-phase generation.

**Options:**
- `-m, --message, --with <directive>` - Focused directive
- `--strict` - Fail on broken links

**Process:**
1. Clean obsolete files
2. Build generation prompt
3. Run Claude with two-phase approach
4. Validate links and auto-fix if needed
5. Show detailed change summary

### `cleanup.sh` - Documentation Cleanup

#### `cleanup_docs()`
AI-powered cleanup of obsolete documentation files.

Uses Claude to semantically analyze documentation against codebase and remove files with 95%+ confidence of obsolescence.

#### `cleanup_docs_silent()`
Silent version for use during main update process.

#### `recreate_docs([options...])`
Completely regenerate documentation from scratch.

**Parameters:**
- `options` - Passed through to subsequent `update` call

**Warning:** Deletes entire `docs/` directory before regeneration.

### `server.sh` - Development Server

#### `serve()`
Start VitePress development server.

**Process:**
1. Check for existing documentation
2. Set up VitePress if needed
3. Install dependencies
4. Start dev server on localhost:5173

### `ui.sh` - User Interface

#### `show_header()`
Display main application header with project name.

#### `show_help()`
Display comprehensive help and usage information.

#### `show_menu()`
Interactive menu system with context-aware options.

**Menu Behavior:**
- First run: Generate, Serve, Create template, Exit
- Existing docs: Update, Focused update, Serve, Template, Recreate, Exit

#### `create_claudux_md()`
Analyze codebase and generate project-specific `CLAUDE.md` file.

Uses Claude to examine actual code patterns and create AI coding assistant instructions.

#### `validate_links([options...])`
Validate documentation links to prevent 404 errors.

**Options:**
- `--auto-fix` - Automatically create missing files
- `-m, --message <directive>` - Custom directive for auto-fix

### `claude-utils.sh` - Claude Integration

#### `check_claude()`
Verify Claude CLI installation and configuration.

**Validation:**
- Claude CLI availability
- Model configuration
- Project type detection

#### `get_model_settings()`
Get model configuration and cost estimates.

**Returns:** Pipe-separated string: `model|model_name|timeout_msg|cost_estimate`

#### `show_progress(phase1_delay, phase2_delay)`
Display progress indicator for long-running operations.

**Parameters:**
- `phase1_delay` - Seconds before Phase 1 messages (default: 15)
- `phase2_delay` - Seconds before Phase 2 messages (default: 45)

**Returns:** Background process PID for cleanup

#### `format_claude_output()`
Format Claude's output for better readability.

**Features:**
- File operation detection and counting
- Phase transition markers
- Error/warning highlighting
- Verbosity level support

### `content-protection.sh` - Content Security

#### `get_protection_markers(file)`
Get appropriate protection markers for file type.

**Parameters:**
- `file` - File path to analyze

**Returns:** Space-separated start and end markers

**Supported Formats:**
- Markdown: `<!-- skip -->` `<!-- /skip -->`
- Code files: `// skip` `// /skip`
- Python/Shell: `# skip` `# /skip`
- CSS: `/* skip */` `/* /skip */`
- SQL: `-- skip` `-- /skip`

#### `strip_protected_content(file)`
Remove protected content sections from file.

**Parameters:**
- `file` - Path to source file

**Returns:** Path to temporary file with protected content removed

#### `is_protected_path(path)`
Check if path should be protected from analysis.

**Parameters:**
- `path` - File or directory path

**Returns:** Exit code 0 if protected, 1 if not

**Protected Patterns:**
- Directories: `notes/`, `private/`, `.git/`, `node_modules/`, `vendor/`, `target/`, `build/`, `dist/`
- Files: `*.env`, `*.key`, `*.pem`, `*.p12`, `*.keystore`

### `validate-links.sh` - Link Validation

#### `validate_links([options...])`
Validate internal links in VitePress configuration.

**Options:**
- `--output <file>` - Write missing files list to file

**Validation Rules:**
- `/` → `docs/index.md`
- `/path/` → `docs/path/index.md`
- `/path` → `docs/path.md`
- External URLs skipped
- Hash anchors removed for file checking

**Exit Codes:**
- 0: All links valid
- 1: Broken links found

### `git-utils.sh` - Git Integration

#### `show_git_status()`
Display current repository status summary.

Shows first 10 changed files with count indicator.

#### `show_detailed_changes()`
Show detailed documentation changes with semantic descriptions.

**Features:**
- Filters out non-documentation files
- Explains reason for each change
- Provides next steps guidance

#### `ensure_git_repo()`
Check if current directory is a git repository.

**Returns:** Exit code 0 if git repo, 1 if not

## Function Patterns

### Error Handling
All functions follow consistent error handling:

```bash
# Check function existence
check_function "function_name" || error_exit "Function not found"

# Validate parameters  
[[ -z "$param" ]] && error_exit "Parameter required"

# Clean exit on errors
trap 'cleanup_function' EXIT
```

### Logging
Standard logging functions used throughout:

```bash
info "Starting operation..."
success "✅ Operation completed"
warn "⚠️  Warning message"
error_exit "❌ Fatal error occurred"
```

### Environment Variables
Functions respect these environment variables:

- `CLAUDUX_VERBOSE` (0-2) - Controls output verbosity
- `FORCE_MODEL` - Overrides default Claude model
- `CLAUDUX_MESSAGE` - Default directive for updates
- `SCRIPT_DIR` - Directory containing claudux script
- `WORKING_DIR` - User's project directory

### Temporary Files
Consistent temporary file handling:

```bash
local temp_file=$(mktemp /tmp/claudux-XXXXXX || mktemp)
trap "rm -f '$temp_file'" EXIT
```

### Path Resolution
All paths resolved to absolute paths:

```bash
local abs_path=$(cd "$(dirname "$file")" && pwd)/$(basename "$file")
```

## Extension Guidelines

When adding new library functions:

1. **Follow naming convention** - Use `snake_case`
2. **Add parameter validation** - Check required parameters
3. **Use consistent logging** - Use `info()`, `warn()`, `error_exit()`
4. **Handle cleanup** - Use trap handlers for temp files
5. **Document thoroughly** - Include function signature and examples
6. **Test edge cases** - Handle missing files, network issues, etc.

## Dependencies

Library functions may require these external tools:

**Required:**
- `bash` (v4+)
- `mktemp`
- `grep`, `sed`, `awk`

**Optional:**
- `git` - For change tracking
- `jq` - For JSON parsing  
- `stdbuf` - For real-time output
- `md5sum` / `md5` - For lock files