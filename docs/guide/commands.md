# Commands Reference

## Core Commands

### `claudux update`

Generate or update documentation by analyzing your codebase.

```bash
claudux update
```

**With focused directive:**
```bash
claudux update -m "Add API documentation for new endpoints"
claudux update --with "Focus on the authentication module"
```

**Process:**
1. Scans source code for structure and patterns
2. Analyzes existing documentation for outdated content
3. Generates new pages and updates existing ones
4. Validates internal links (external URLs are skipped) to prevent 404s
5. Shows detailed change summary

### `claudux serve` 

Start the VitePress development server to preview documentation locally.

```bash
claudux serve
```

- Opens at `http://localhost:5173`
- Hot reload when files change
- Full-text search enabled
- Mobile-responsive design

### `claudux recreate`

Delete all existing documentation and start fresh.

```bash
claudux recreate
```

**Use when:**
- Major project restructuring
- Switching documentation approach
- Fixing fundamental organization issues

### `claudux template`

Generate a `claudux.md` file with documentation preferences for your project.

```bash
claudux template
```

Creates a preferences file that guides future documentation generation based on your project's specific patterns and conventions.

## Change Tracking Commands

### `claudux diff`

Show files that have changed since the last documentation generation.

```bash
claudux diff
```

Compares the current HEAD against the checkpoint SHA stored in `.claudux-state.json`, then adds uncommitted documentation/config changes such as `docs/**`, `docs-structure.json`, `docs-map.md`, `.ai-docs-style.md`, and `docs-site-plan.json`. Lists all modified, added, deleted, staged, or untracked files that may need doc updates.

### `claudux status`

Show documentation freshness and last generation details.

```bash
claudux status
```

Displays:
- Last generation timestamp and checkpoint commit SHA
- Backend used (Claude or Codex)
- Documented file count
- Commits behind HEAD (if stale)
- Uncommitted documentation/config changes (if the checkpoint commit is otherwise fresh)

### `claudux validate`

Run link validation on the generated documentation.

```bash
claudux validate
```

Checks all internal links in VitePress config and markdown files. Reports broken links without re-generating docs.

## Utility Commands

### `claudux check`

Validate your environment and dependencies.

```bash
claudux check
```

Checks:
- Node.js version (>=18 required)
- Active backend (Claude or Codex)
- Backend CLI installation and authentication
- Documentation directory status

### `claudux --help`

Display help information and usage examples.

```bash
claudux --help
claudux help
claudux -h
```

### `claudux --version`

Show the installed claudux version.

```bash
claudux --version
claudux version
claudux -V
```

## Interactive Mode

Run `claudux` without arguments to access the interactive menu:

```bash
claudux
```

The menu adapts based on whether documentation already exists:

**First run (no docs):**
- Generate docs (scan code -> markdown)
- Serve (VitePress dev server)
- Create claudux.md (docs preferences)

**Existing docs:**
- Update docs (regenerate from code)
- Update (focused) (enter directive -> update)
- Diff (files changed since last gen)
- Status (documentation freshness)
- Validate links (check for broken links)
- Serve (VitePress dev server)
- Create claudux.md (docs preferences)
- Recreate (start fresh)

## Advanced Usage

### Backend Selection

Switch between AI backends using environment variables:

```bash
# Default -- uses Claude
claudux update

# Use Codex instead
CLAUDUX_BACKEND=codex claudux update

# Or export for the session
export CLAUDUX_BACKEND=codex
export CODEX_MODEL=gpt-5.4            # default
export CODEX_REASONING_EFFORT=xhigh   # default
claudux update
```

### Environment Variables

Control model selection and behavior:

```bash
# Force specific Claude model
FORCE_MODEL=opus claudux update
FORCE_MODEL=sonnet claudux update  # Default

# Pre-set directive message
CLAUDUX_MESSAGE="Focus on API docs" claudux update
```

### Flags and Options

**Update command options:**
```bash
claudux update -m "message"     # Focused directive
claudux update --with "message" # Same as -m
claudux update --strict         # Re-prompt (then error) on broken internal links
```

## Command Workflow

**Typical development cycle:**

```bash
# Initial setup
claudux update

# Make code changes
# ... edit your source files ...

# Update docs to reflect changes  
claudux update

# Preview changes
claudux serve

# Focused updates for specific changes
claudux update -m "Document the new authentication flow"
```

## Exit Codes

Claudux follows standard Unix exit code conventions:

- `0`: Success
- `1`: General error
- `2`: Incorrect usage  
- `124`: Timeout
- `130`: Interrupted (Ctrl+C)

Use in CI/CD:
```bash
claudux update || exit 1  # Fail build if docs generation fails
```
