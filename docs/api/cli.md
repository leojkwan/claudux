[Home](/) > [API](/api/) > CLI Commands

# CLI Commands Reference

Complete reference for all Claudux command-line interface commands.

## claudux update

Generate or update documentation for your project.

### Syntax

```bash
claudux update [options]
```

### Options

| Option | Description |
|--------|-------------|
| `-m, --message <text>` | Provide specific instructions for AI |
| `--force-model <model>` | Override default model (opus/sonnet/haiku) |
| `-v, --verbose` | Enable verbose output |
| `-vv` | Enable very verbose (debug) output |
| `-q, --quiet` | Suppress non-error output |

### Examples

```bash
# Basic update
claudux update

# Update with specific focus
claudux update -m "Focus on API documentation"

# Force specific model
claudux update --force-model opus

# Debug mode
claudux update -vv
```

### Process

1. Detects project type
2. Analyzes codebase structure
3. Creates documentation plan
4. Generates documentation files
5. Sets up VitePress configuration
6. Cleans obsolete files

### Exit Codes

- `0` - Success
- `1` - General error
- `2` - Missing dependencies
- `3` - Authentication error

---

## claudux serve

Start VitePress development server for local preview.

### Syntax

```bash
claudux serve
```

### Aliases

- `server`
- `dev`

### Behavior

1. Checks for VitePress installation
2. Installs dependencies if needed
3. Starts development server
4. Opens browser automatically

### Default Port

- Primary: 5173
- Fallback: 3000-3100 range

### Environment Variables

```bash
# Custom port
VITE_PORT=3000 claudux serve
```

---

## claudux clean

Remove obsolete documentation using semantic analysis.

### Syntax

```bash
claudux clean [options]
```

### Aliases

- `cleanup`

### Options

| Option | Description |
|--------|-------------|
| `--dry-run` | Preview changes without deleting |
| `--force` | Skip confirmation prompts |
| `--threshold <value>` | Confidence threshold (0.0-1.0, default: 0.95) |

### Examples

```bash
# Interactive cleanup
claudux clean

# Preview only
claudux clean --dry-run

# Force cleanup
claudux clean --force

# Lower threshold
claudux clean --threshold 0.9
```

### Protected Content

Never deletes:
- Files with protection markers
- Directories in `.clauduxignore`
- Built-in protected patterns

---

## claudux recreate

Delete all documentation and regenerate from scratch.

### Syntax

```bash
claudux recreate [options]
```

### Options

| Option | Description |
|--------|-------------|
| `-m, --message <text>` | Instructions for regeneration |
| `--force` | Skip confirmation prompt |

### Examples

```bash
# Interactive recreation
claudux recreate

# Force recreation
claudux recreate --force

# Recreate with focus
claudux recreate -m "Detailed API docs"
```

### Warning

Deletes ALL files in `docs/` except protected content.

---

## claudux validate

Check documentation for broken links.

### Syntax

```bash
claudux validate [options]
```

### Aliases

- `check-links`

### Options

| Option | Description |
|--------|-------------|
| `--external` | Also check external links |
| `--timeout <ms>` | Timeout for external checks (default: 5000) |

### Examples

```bash
# Check internal links
claudux validate

# Check all links
claudux validate --external

# Custom timeout
claudux validate --external --timeout 10000
```

### Output Format

```
✓ Internal links: 47/47 valid
⚠ External links: 12/14 valid

Broken links:
- docs/api/old.md -> /api/deprecated (404)
```

---

## claudux repair

Automatically fix broken links.

### Syntax

```bash
claudux repair [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--create-missing` | Create missing target files |
| `--update-links` | Update incorrect paths |
| `--dry-run` | Preview fixes without applying |

### Examples

```bash
# Auto-repair
claudux repair

# Create missing files
claudux repair --create-missing

# Preview repairs
claudux repair --dry-run
```

---

## claudux template

Generate or update CLAUDE.md template for your project.

### Syntax

```bash
claudux template
```

### Aliases

- `create-template`

### Output

Creates `CLAUDE.md` with:
- Project type detection
- Framework identification
- Coding patterns
- Documentation style guide

### Example Output

```markdown
# Project Instructions for Claude

## Project Type
React application with TypeScript

## Key Technologies
- React 18
- TypeScript
- Redux Toolkit
```

---

## claudux check

Verify environment and dependencies.

### Syntax

```bash
claudux check
```

### Alias

- `--check`

### Checks

- Node.js version
- Claude CLI installation
- Claude authentication
- Project type detection
- Documentation directory

### Output

```
🔎 Environment check

• Node: v18.17.0 ✓
• Claude: claude-code v1.2.3 ✓
• Authentication: Valid ✓
• Project type: react
• docs/: present
```

---

## claudux version

Display version information.

### Syntax

```bash
claudux version
```

### Aliases

- `--version`
- `-V`

### Output

```
claudux 1.0.0
```

---

## claudux help

Show help information.

### Syntax

```bash
claudux help [command]
```

### Aliases

- `--help`
- `-h`

### Examples

```bash
# General help
claudux help

# Command help
claudux help update
```

---

## Interactive Mode

Launch interactive menu when run without arguments.

### Syntax

```bash
claudux
```

### Menu Options

```
What would you like to do?

1) Generate/Update Documentation
2) Serve Documentation Locally
3) Clean Obsolete Files
4) Validate Links
5) Create CLAUDE.md Template
6) Exit
```

---

## Global Options

These options work with all commands:

| Option | Description |
|--------|-------------|
| `-v, --verbose` | Enable verbose output |
| `-vv` | Enable very verbose output |
| `-q, --quiet` | Suppress non-error output |
| `--no-color` | Disable colored output |
| `--cwd <path>` | Set working directory |

### Examples

```bash
# Verbose update
claudux update -v

# Quiet clean
claudux clean -q

# No colors
claudux --no-color update

# Different directory
claudux --cwd /path/to/project update
```

---

## Command Chaining

Commands can be chained in scripts:

```bash
#!/bin/bash
# Update and serve
claudux update && claudux serve

# Clean, update, validate
claudux clean --force && \
claudux update && \
claudux validate
```

---

## Error Handling

All commands follow consistent error handling:

```bash
# Check success
if claudux update; then
    echo "Success"
else
    echo "Failed with code $?"
fi

# Capture output
output=$(claudux validate 2>&1)
```

---

## Scripting Examples

### Automated Updates

```bash
#!/bin/bash
# Auto-update on git push

if git diff --quiet HEAD~1 HEAD -- src/; then
    echo "No source changes"
else
    claudux update -q
    if [ $? -eq 0 ]; then
        git add docs/
        git commit -m "docs: update documentation"
    fi
fi
```

### CI Integration

```bash
#!/bin/bash
# CI documentation check

set -e  # Exit on error

claudux check
claudux update --force-model sonnet
claudux validate --external
```

### Batch Processing

```bash
#!/bin/bash
# Update multiple projects

for project in project1 project2 project3; do
    echo "Updating $project..."
    (cd "$project" && claudux update -q)
done
```

---

## Performance Tips

### Parallel Execution

```bash
# Safe parallel execution
claudux clean &
pid1=$!
claudux validate &
pid2=$!
wait $pid1 $pid2
```

### Caching

```bash
# Use environment for repeated runs
export FORCE_MODEL=sonnet
export CLAUDUX_VERBOSE=0

claudux update  # Uses cached settings
```

### Optimization

```bash
# Skip unnecessary steps
claudux update --skip-cleanup --skip-validation
```

---

## Debugging

### Maximum Verbosity

```bash
CLAUDUX_VERBOSE=2 claudux update -vv 2>&1 | tee debug.log
```

### Trace Execution

```bash
bash -x $(which claudux) update
```

### Environment Check

```bash
# Print all settings
env | grep CLAUDUX
claudux check
```