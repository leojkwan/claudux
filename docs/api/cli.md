# CLI Interface

[Home](/) > [API](/api/) > CLI Interface

Complete reference for the `claudux` command-line interface.

## Usage

```bash
claudux [command] [options]
```

## Commands

### `update`
Generate or update project documentation using Claude AI.

```bash
claudux update [options]
```

**Options:**
- `-m, --message, --with <directive>` - Provide focused directive for generation
- `--strict` - Exit with error if links remain broken after auto-fix

**Examples:**
```bash
# Standard documentation update
claudux update

# Focused update with specific directive
claudux update -m "Add API documentation for all endpoints"
claudux update --with "Focus on installation and setup guides"

# Strict mode (fails on broken links)
claudux update --strict
```

### `serve`
Start the VitePress development server for documentation.

```bash
claudux serve
```

Starts server at `http://localhost:5173` with hot-reload enabled.

### `clean` / `cleanup`
Remove obsolete documentation files using AI analysis.

```bash
claudux clean
```

Uses semantic analysis to identify and remove outdated content with 95%+ confidence.

### `recreate`
Completely regenerate documentation from scratch.

```bash
claudux recreate [options]
```

**Warning:** This deletes all existing documentation before regeneration.

Accepts same options as `update` command for the regeneration phase.

### `create-template` / `template`
Analyze codebase and generate project-specific `CLAUDE.md` file.

```bash
claudux create-template
```

Creates AI context file with coding patterns and conventions from your codebase.

### `validate` / `check-links`
Validate documentation links to prevent 404 errors.

```bash
claudux validate [options]
```

**Options:**
- `--auto-fix` - Automatically create missing files
- `-m, --message <directive>` - Custom directive for auto-fix

### `repair`
Automatically fix broken links in documentation.

```bash
claudux repair [options]
```

Equivalent to `claudux validate --auto-fix`.

### `version` / `--version` / `-V`
Display claudux version information.

```bash
claudux version
```

### `check` / `--check`
Perform environment and dependency checks.

```bash
claudux check
```

Validates:
- Node.js installation (v18+)
- Claude CLI availability
- Project structure

### `help` / `-h` / `--help`
Display help information and usage examples.

```bash
claudux help
```

## Global Options

These options can be used with any command:

### Verbosity
- `-v` - Verbose output (set `CLAUDUX_VERBOSE=1`)
- `-vv` - Very verbose output (set `CLAUDUX_VERBOSE=2`) 
- `-q` - Quiet mode (errors only)

### Model Selection
Use environment variable to override default Claude model:

```bash
FORCE_MODEL=sonnet claudux update
FORCE_MODEL=opus claudux update
```

## Interactive Mode

Running `claudux` without arguments launches interactive menu:

```bash
claudux
```

Menu options vary based on whether documentation already exists.

## Exit Codes

| Code | Description |
|------|-------------|
| 0 | Success |
| 1 | General error |  
| 2 | Invalid arguments |
| 130 | Interrupted (Ctrl+C) |

## File Locking

Claudux uses file locking to prevent concurrent execution:

- Lock file: `${TMPDIR:-/tmp}/claudux-$(pwd | md5).lock`
- Automatic cleanup on exit
- Process validation to handle stale locks

## Environment Integration

### Git Integration
- Shows git status before operations
- Detailed change summaries after updates
- Respects `.gitignore` patterns

### Project Detection
Automatically detects project type from:
- `package.json` (JavaScript/Node.js/React/Next.js)
- `Cargo.toml` (Rust)
- `go.mod` (Go)
- `*.xcodeproj` (iOS/Swift)
- `pom.xml` / `build.gradle` (Java)
- `pyproject.toml` / `setup.py` (Python)

### Configuration Files
- `docs-ai-config.json` - Project configuration
- `.claudux.json` - Alternative configuration
- `CLAUDE.md` - AI coding patterns
- `docs-map.md` - Documentation structure guide

## Security & Privacy

- All processing happens locally
- Sensitive paths automatically protected (`notes/`, `private/`, `.git/`)
- Content protection markers: `<!-- skip -->` / `<!-- /skip -->`
- No data sent to external services except Claude API

## Dependencies

Required:
- Node.js v18+
- Claude CLI (`@anthropic-ai/claude-code`)
- Standard Unix tools (`bash`, `mktemp`, etc.)

Optional:
- `git` (for change tracking)
- `jq` (for JSON parsing)
- `stdbuf` (for real-time output)

## Examples

### Basic Workflow
```bash
# Check environment
claudux check

# Generate documentation
claudux update

# Start development server  
claudux serve

# Validate links
claudux validate
```

### Advanced Usage
```bash
# Focused updates
claudux update -m "Document new authentication system"
claudux update --with "Add troubleshooting section"

# Strict validation
claudux update --strict

# Clean rebuild
claudux recreate

# Custom model
FORCE_MODEL=sonnet claudux update

# Verbose output
claudux update -vv
```

### Automation
```bash
# Environment-driven updates
CLAUDUX_MESSAGE="Weekly docs update" claudux update

# CI/CD integration
claudux update --strict || exit 1
claudux validate || exit 1
```