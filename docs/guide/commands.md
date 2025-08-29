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
4. Validates all links to prevent 404s
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

## Utility Commands

### `claudux check`

Validate your environment and dependencies.

```bash
claudux check
```

Checks:
- Node.js version (≥18 required)
- Claude CLI installation and authentication  
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
- Generate docs (scan code → markdown)
- Serve (VitePress dev server) 
- Create claudux.md (docs preferences)

**Existing docs:**
- Update docs (regenerate from code)
- Update (focused) (enter directive → update)
- Serve (VitePress dev server)
- Recreate (start fresh)

## Advanced Usage

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
claudux update --strict         # Fail on broken links
```

**Global flags:**
```bash
claudux -q update              # Quiet mode (errors only)
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