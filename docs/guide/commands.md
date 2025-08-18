[Home](/) > [Guide](/guide/) > Commands

# Commands Reference

Complete reference for all Claudux CLI commands and options.

## Command Overview

```bash
claudux [command] [options]
```

| Command | Description |
|---------|-------------|
| `update` | Generate or update documentation |
| `serve` | Start local preview server |
| `clean` | Remove obsolete documentation |
| `recreate` | Delete all docs and regenerate |
| `validate` | Check for broken links |
| `repair` | Fix broken links automatically |
| `template` | Generate CLAUDE.md template |
| `check` | Verify environment setup |
| `version` | Display version information |
| `help` | Show help information |

## Interactive Mode

Run without arguments to launch interactive menu:

```bash
claudux
```

## Core Commands

### `claudux update`

Generate or update documentation for your project.

```bash
claudux update [options]
```

**Options:**
- `-m, --message <message>` - Provide specific instructions for AI
- `--force-model <model>` - Override default model (opus/sonnet/haiku)
- `-v, --verbose` - Enable verbose output
- `-vv` - Enable very verbose (debug) output
- `-q, --quiet` - Suppress output

**Examples:**

```bash
# Basic update
claudux update

# Update with specific focus
claudux update -m "Focus on API documentation and add more examples"

# Force specific model
claudux update --force-model opus

# Verbose output for debugging
claudux update -v
```

**What it does:**
1. Detects project type and structure
2. Analyzes codebase with AI
3. Generates documentation plan
4. Creates/updates documentation files
5. Sets up VitePress configuration
6. Cleans obsolete files

### `claudux serve`

Start VitePress development server for local preview.

```bash
claudux serve
```

**Aliases:** `server`, `dev`

**What it does:**
1. Checks for VitePress installation
2. Installs dependencies if needed
3. Starts dev server (default port 5173)
4. Enables hot-reload for changes
5. Opens browser automatically

**Output:**
```
🚀 Starting VitePress development server...
✓ Server running at http://localhost:5173
Press Ctrl+C to stop
```

### `claudux clean`

Remove obsolete documentation files using semantic analysis.

```bash
claudux clean [options]
```

**Aliases:** `cleanup`

**Options:**
- `--dry-run` - Preview what would be deleted without removing
- `--force` - Skip confirmation prompts
- `--threshold <value>` - Set confidence threshold (0.0-1.0, default: 0.95)

**Examples:**

```bash
# Interactive cleanup
claudux clean

# Preview changes without deleting
claudux clean --dry-run

# Force cleanup without prompts
claudux clean --force

# Adjust confidence threshold
claudux clean --threshold 0.9
```

**What it does:**
1. Analyzes current codebase
2. Identifies obsolete documentation
3. Shows files to be removed
4. Confirms before deletion
5. Preserves protected content

### `claudux recreate`

Delete all documentation and regenerate from scratch.

```bash
claudux recreate [options]
```

**Options:**
- `-m, --message <message>` - Instructions for regeneration
- `--force` - Skip confirmation prompt

**Examples:**

```bash
# Interactive recreation
claudux recreate

# Force recreation
claudux recreate --force

# Recreate with specific focus
claudux recreate -m "Generate detailed API documentation"
```

**Warning:** This deletes ALL files in `docs/` directory except protected content.

### `claudux validate`

Check documentation for broken links and references.

```bash
claudux validate [options]
```

**Aliases:** `check-links`

**Options:**
- `--fix` - Automatically fix broken links
- `--external` - Also check external links
- `--timeout <ms>` - Timeout for external checks (default: 5000)

**Examples:**

```bash
# Check internal links
claudux validate

# Check all links including external
claudux validate --external

# Check with custom timeout
claudux validate --external --timeout 10000
```

**Output:**
```
🔍 Validating documentation links...

✓ Internal links: 47/47 valid
⚠ External links: 12/14 valid

Broken links found:
- docs/api/deprecated.md -> /api/old-function (404)
- docs/guide/setup.md -> https://example.com/broken (timeout)

Run 'claudux repair' to fix automatically
```

### `claudux repair`

Automatically fix broken links in documentation.

```bash
claudux repair [options]
```

**Options:**
- `--create-missing` - Create missing target files
- `--update-links` - Update incorrect link paths
- `--dry-run` - Preview fixes without applying

**Examples:**

```bash
# Auto-repair all issues
claudux repair

# Create missing files
claudux repair --create-missing

# Preview repairs
claudux repair --dry-run
```

### `claudux template`

Generate or update CLAUDE.md template for your project.

```bash
claudux template
```

**Aliases:** `create-template`

**What it does:**
1. Analyzes project structure
2. Detects frameworks and patterns
3. Generates customized CLAUDE.md
4. Includes project-specific instructions

**Output creates:** `CLAUDE.md` or `claudux.md`

Example generated template:
```markdown
# Project Instructions for Claude

## Project Type
React application with TypeScript

## Key Technologies
- React 18
- TypeScript
- Redux Toolkit
- React Router

## Code Patterns
- Functional components with hooks
- Custom hooks in hooks/ directory
- Redux slices for state management

## Documentation Style
- Include TypeScript types
- Provide usage examples
- Document props thoroughly
```

## Utility Commands

### `claudux check`

Verify environment and dependencies.

```bash
claudux check
```

**Alias:** `--check`

**Checks:**
- Node.js version
- Claude CLI installation
- Claude authentication
- Project detection
- Documentation directory

**Output:**
```
🔎 Environment check

• Node: v18.17.0 ✓
• Claude: claude-code v1.2.3 ✓
• Authentication: Valid ✓
• Project type: react
• docs/: present
```

### `claudux version`

Display version information.

```bash
claudux version
```

**Aliases:** `--version`, `-V`

**Output:**
```
claudux 1.0.0
```

### `claudux help`

Show help information.

```bash
claudux help [command]
```

**Aliases:** `--help`, `-h`

**Examples:**

```bash
# General help
claudux help

# Command-specific help
claudux help update
```

## Global Options

These options work with all commands:

| Option | Description |
|--------|-------------|
| `-v, --verbose` | Enable verbose output |
| `-vv` | Enable very verbose output |
| `-q, --quiet` | Suppress non-error output |
| `--no-color` | Disable colored output |
| `--cwd <path>` | Set working directory |

## Environment Variables

Control Claudux behavior with environment variables:

```bash
# Set verbosity
export CLAUDUX_VERBOSE=1  # 0=quiet, 1=normal, 2=debug

# Force Claude model
export FORCE_MODEL=opus    # opus, sonnet, haiku

# Disable colors
export NO_COLOR=1

# Set timeout
export CLAUDE_TIMEOUT=120  # seconds

# Custom Claude endpoint (advanced)
export CLAUDE_API_URL=https://custom-endpoint.com
```

## Command Workflows

### Initial Setup

```bash
# 1. Install Claudux
npm install -g claudux

# 2. Check environment
claudux check

# 3. Generate documentation
claudux update

# 4. Preview locally
claudux serve
```

### Regular Updates

```bash
# Update after code changes
claudux update

# Clean obsolete files periodically
claudux clean

# Validate links
claudux validate
```

### Major Refactoring

```bash
# After major changes, recreate docs
claudux recreate

# Generate new template
claudux template

# Update with new instructions
claudux update
```

## Exit Codes

Claudux uses standard exit codes:

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Missing dependencies |
| 3 | Authentication error |
| 4 | File system error |
| 5 | Network error |
| 130 | Interrupted (Ctrl+C) |

## Advanced Usage

### Scripting

Use Claudux in scripts:

```bash
#!/bin/bash

# Update docs only if code changed
if git diff --quiet HEAD~1 HEAD -- src/; then
  echo "No source changes"
else
  claudux update -q
  if [ $? -eq 0 ]; then
    git add docs/
    git commit -m "Update documentation"
  fi
fi
```

### CI/CD Integration

```yaml
# GitHub Actions example
- name: Update Documentation
  run: |
    npm install -g claudux
    claudux update --force-model sonnet
  env:
    CLAUDE_API_KEY: ${{ secrets.CLAUDE_API_KEY }}
```

### Parallel Execution

Claudux uses file locking to prevent conflicts:

```bash
# Safe to run in parallel for different projects
cd project1 && claudux update &
cd project2 && claudux update &
wait
```

## Troubleshooting Commands

### Debug Output

Enable maximum verbosity:
```bash
CLAUDUX_VERBOSE=2 claudux update -vv 2>&1 | tee debug.log
```

### Lock File Issues

Clear stale lock files:
```bash
rm /tmp/claudux-*.lock
```

### Permission Errors

Run with proper permissions:
```bash
# Fix npm permissions
npm config set prefix ~/.npm-global
export PATH=~/.npm-global/bin:$PATH
```

## Getting Help

- Run `claudux help` for built-in help
- Check [FAQ](/faq) for common questions
- Visit [GitHub Issues](https://github.com/leokwan/claudux/issues)
- Read [Troubleshooting Guide](/troubleshooting)