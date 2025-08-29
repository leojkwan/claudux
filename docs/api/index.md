# CLI API Reference

Complete reference for all claudux command-line interface options and behaviors.

## Commands

### `claudux`

**Syntax**: `claudux [command] [options]`

**Description**: Main entry point. Without arguments, shows interactive menu.

**Examples:**
```bash
claudux                 # Interactive menu
claudux update          # Generate documentation
claudux serve           # Start dev server  
claudux --help          # Show help
```

### `claudux update`

**Syntax**: `claudux update [options]`

**Description**: Generate or update documentation by analyzing the current codebase.

**Options:**
- `-m, --message, --with <directive>`: Focused directive for generation
- `--strict`: Fail on broken links (exit code 1)

**Examples:**
```bash
claudux update
claudux update -m "Focus on API documentation"  
claudux update --with "Add deployment guide"
claudux update --strict
```

**Process flow:**
1. Load project configuration and detect type
2. Build comprehensive AI prompt
3. Execute two-phase generation (analysis → creation)  
4. Validate all internal links
5. Display change summary

**Exit codes:**
- `0`: Success
- `1`: Generation failed or broken links in strict mode
- `124`: Timeout
- `130`: Interrupted

### `claudux serve`

**Syntax**: `claudux serve`

**Description**: Start VitePress development server for local documentation preview.

**Behavior:**
- Serves at `http://localhost:5173`
- Hot reload on file changes
- Automatically installs VitePress dependencies if needed
- Prompts to generate docs if none exist

**Examples:**
```bash
claudux serve
# 📖 Docs available at: http://localhost:5173
# Press Ctrl+C to stop the server
```

### `claudux recreate`

**Syntax**: `claudux recreate`

**Description**: Delete all existing documentation and start fresh.

**Behavior:**
- Removes entire `docs/` directory
- Regenerates from scratch
- Useful for major structural changes

**Examples:**
```bash
claudux recreate
# ⚠️  This will delete all existing documentation
# Are you sure? (y/N): y
```

### `claudux template`

**Syntax**: `claudux template`

**Description**: Generate `claudux.md` file with documentation preferences for the project.

**Behavior:**
- Analyzes current project structure
- Creates preferences file based on detected patterns
- Guides future documentation generation

**Examples:**
```bash
claudux template
# ✅ Generated claudux.md (docs preferences) (42 lines)
```

### `claudux check`

**Syntax**: `claudux check`

**Description**: Validate environment and display system status.

**Output example:**
```
🔎 Environment check

• Node: v18.17.0
• Claude: claude-cli/1.2.3  
• docs/: present
```

**Validates:**
- Node.js version (≥18 required)
- Claude CLI installation and authentication
- Documentation directory status

## Global Options

### `--help`, `-h`, `help`

**Syntax**: `claudux [--help|-h|help]`

**Description**: Display help information and usage examples.

### `--version`, `-V`, `version`

**Syntax**: `claudux [--version|-V|version]`

**Description**: Display the installed claudux version.

**Output**: `claudux 1.0.2`

### `-q`

**Syntax**: `claudux -q [command]`

**Description**: Quiet mode - show errors only.

**Examples:**
```bash
claudux -q update    # Minimal output
claudux -q serve     # Quiet server startup
```

## Environment Variables

### `FORCE_MODEL`

**Values**: `opus`, `sonnet`

**Default**: `sonnet`

**Description**: Select Claude model for generation.

```bash
FORCE_MODEL=opus claudux update    # More capable, slower
FORCE_MODEL=sonnet claudux update  # Faster, default
```

### `CLAUDUX_MESSAGE`

**Description**: Default directive message for updates.

```bash
CLAUDUX_MESSAGE="Focus on API docs" claudux update
# Equivalent to: claudux update -m "Focus on API docs"
```

### `DOCS_BASE`

**Description**: Base path for deployed documentation (CI/CD use).

```bash
export DOCS_BASE='/my-project/'  # For GitHub Pages deployment
claudux update
```

**Usage**: Set in CI environments for proper deployment paths. Local development always uses `/`.

## Exit Codes

Claudux follows standard Unix conventions:

| Code | Meaning | Common Causes |
|------|---------|---------------|
| `0` | Success | Normal operation completed |
| `1` | General error | Missing dependencies, configuration issues |
| `2` | Usage error | Invalid command-line arguments |
| `124` | Timeout | Claude API timeout, network issues |
| `130` | Interrupted | User pressed Ctrl+C |

## Interactive Menu API

### Menu States

**No existing documentation:**
```
1) Generate docs              (scan code → markdown)
2) Serve                      (vitepress dev server) 
3) Create claudux.md           (docs preferences)
4) Exit
```

**Existing documentation:**
```
1) Update docs                (regenerate from code)
2) Update (focused)           (enter directive → update)
3) Serve                      (vitepress dev server)
4) Create claudux.md           (docs preferences) 
5) Recreate                   (start fresh)
6) Exit
```

### Menu Behavior

**Navigation**: Use number keys + Enter
**Cancellation**: Ctrl+C at any time
**Error handling**: Invalid selections prompt retry

## Configuration Files API

### `claudux.json`

**Location**: Project root

**Schema:**
```json
{
  "project": {
    "name": "string",              // Project display name
    "type": "string"               // Project type override
  },
  "ai": {
    "default_model": "sonnet|opus", // Model preference
    "timeout_seconds": 90           // Generation timeout
  }
}
```

### `claudux.md`

**Location**: Project root

**Purpose**: Documentation preferences and site structure guidance

**Generation**: `claudux template`

**Format**: Markdown with structured sections for site configuration, page hierarchy, and styling preferences.

## Integration APIs

### Git Integration

**Requirements**: Must be run from git repository

**Behavior:**
- Auto-detects project root via `git rev-parse --show-toplevel`
- Shows git status before generation
- Tracks documentation changes in git history

### VitePress Integration

**Generated files:**
- `docs/.vitepress/config.ts` - VitePress configuration
- `docs/package.json` - VitePress dependencies
- `docs/vite.config.js` - Vite build configuration

**Development server**: 
- Port: `5173` (VitePress default)
- Command: `npm run docs:dev` (from docs/ directory)

This API reference provides the complete interface for automating and integrating claudux into your development workflow.