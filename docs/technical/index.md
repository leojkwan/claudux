# Technical Architecture

Claudux is built as a modular Bash CLI tool that orchestrates AI-powered documentation generation using Claude Code and VitePress.

## High-Level Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Input    │───▶│   claudux CLI    │───▶│  Claude AI      │
│   (Commands)    │    │   (Orchestrator) │    │  (Analysis)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                        ┌──────────────────┐    ┌─────────────────┐
                        │   VitePress      │◀───│  Generated      │
                        │   (Rendering)    │    │  Docs           │
                        └──────────────────┘    └─────────────────┘
```

## Core Components

### 1. Main Entry Point

**`bin/claudux`** - Command router and dependency manager

```bash
#!/bin/bash
# Entry point that:
# - Validates environment and dependencies
# - Routes commands to appropriate handlers  
# - Sources library modules in dependency order
# - Handles global error conditions and cleanup
```

**Key responsibilities:**
- Command-line argument parsing
- Environment validation (Node.js, Claude CLI)
- Library module loading and dependency management
- Global error handling and interrupt management

### 2. Library Modules

Modular functionality organized by concern:

| Module | Purpose | Key Functions |
|--------|---------|---------------|
| `colors.sh` | Terminal output utilities | `print_color()`, `error_exit()`, `warn()` |
| `project.sh` | Project detection and config | `detect_project_type()`, `load_project_config()` |
| `claude-utils.sh` | Claude AI integration | `check_claude()`, `get_model_settings()` |
| `docs-generation.sh` | Core generation logic | `build_generation_prompt()`, `update()` |
| `content-protection.sh` | Content protection | `is_protected_path()`, protection markers |
| `git-utils.sh` | Git operations | `show_git_status()`, `show_detailed_changes()` |
| `server.sh` | VitePress dev server | `serve()`, dependency management |
| `cleanup.sh` | Obsolete content removal | Smart cleanup with confidence scoring |
| `ui.sh` | Interactive interface | `show_menu()`, `show_help()`, `create_claudux_md()` |
| `validate-links.sh` | Link validation | Internal/external link checking |

### 3. Template System

**Template hierarchy:**
```
lib/templates/
├── generic/config.json          # Default fallback
├── react-project-config.json    # React-specific structure
├── nextjs-project-config.json   # Next.js patterns  
├── ios-project-config.json      # iOS app documentation
└── python-project-config.json   # Python project patterns
```

**Template selection logic** (`lib/project.sh:24-26`):
1. Use project-type specific template if available
2. Fall back to generic template
3. Auto-detect project type from file patterns

### 4. VitePress Integration

**Configuration generation** (`lib/vitepress/config.template.ts`):
- Dynamic project metadata injection
- Sidebar structure based on planned documentation
- Auto-detected social links and repository information
- Theme customization and search configuration

**Development server** (`lib/server.sh`):
- VitePress setup and dependency management
- Live reload and hot module replacement
- Port configuration and conflict resolution

## Data Flow

### 1. Command Processing Flow

```
claudux update
    │
    ├─ load_project_config()     # Detect type, read claudux.json
    │
    ├─ build_generation_prompt() # Construct AI prompt  
    │
    ├─ claude [prompt]           # AI analysis and generation
    │
    ├─ validate_links()          # Check link integrity
    │
    └─ show_detailed_changes()   # Display results
```

### 2. AI Prompt Construction

**Prompt building** (`lib/docs-generation.sh:5-227`):

```bash
# Input sources (in order):
1. Template configuration (project-type specific)
2. Style guide (.ai-docs-style.md if present)  
3. Documentation map (docs-map.md if present)
4. CLAUDE.md (project patterns and conventions)
5. User directive (--with flag)

# Output: Comprehensive prompt for two-phase generation
```

### 3. Configuration Loading

**Configuration precedence** (`lib/project.sh:5-30`):
1. `claudux.json` (primary configuration)
2. `.claudux.json` (alternative location)
3. Auto-detection from file patterns
4. Generic fallback defaults

## Error Handling Strategy

### 1. Defensive Programming

**Strict mode** (`bin/claudux:8`):
```bash
set -u                    # Catch undefined variables
set -o pipefail          # Propagate pipe failures
```

**Command validation** (`lib/claude-utils.sh:6-8`):
```bash
if ! command -v claude &> /dev/null; then
    error_exit "Claude Code CLI not found. Install: npm install -g @anthropic-ai/claude-code"
fi
```

### 2. Graceful Degradation

**Optional dependencies:**
```bash
# jq is preferred but not required
if command -v jq &> /dev/null; then
    PROJECT_NAME=$(jq -r '.project.name' claudux.json)
else
    PROJECT_NAME=$(grep '"name"' claudux.json | sed 's/.*"\([^"]*\)".*/\1/')
fi
```

### 3. User-Friendly Error Messages

**Centralized error functions** (`lib/colors.sh:27-44`):
- Consistent formatting with colors and emoji
- Helpful next-step guidance
- Proper stderr routing for scripting

## Security Considerations

### 1. Local Processing

- All code analysis happens locally
- No source code sent to external APIs
- Claude CLI handles authentication and API communication
- User maintains control over all data

### 2. Content Protection

**Protected path enforcement** (`lib/content-protection.sh:61-74`):
```bash
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

### 3. Permission Management

**Claude CLI permissions** (controlled in AI calls):
- `--allowedTools "Read,Write,Edit,Delete"` - Only necessary file operations
- `--permission-mode acceptEdits` - Automatic approval for documentation edits
- No system command execution capabilities

## Performance Optimization

### 1. Lazy Loading

Dependencies checked only when needed:
```bash
# Only check jq availability when parsing JSON
if [[ -f "claudux.json" ]] && command -v jq &> /dev/null; then
```

### 2. Early Returns

Skip unnecessary work:
```bash
# Skip cleanup if no docs exist
if [[ ! -d "docs" ]]; then
    warn "📄 No documentation files found to clean"
    return
fi
```

### 3. Progress Indicators

Long-running operations show progress:
```bash
# Visual feedback during AI generation
local progress_pid=$(show_progress 8 24)
```

## Extensibility

### 1. Project Type Detection

**Adding new project types** (`lib/project.sh:33-64`):
```bash
detect_project_type() {
    # Add new detection patterns here
    if [[ -f "specific-file.json" ]]; then
        echo "new-type"
    # Existing detection logic...
}
```

### 2. Template System

**Adding project templates:**
1. Create `lib/templates/newtype-project-config.json`
2. Define documentation structure and patterns
3. Project detection will automatically use new template

### 3. VitePress Theme

**Custom theming** (`lib/vitepress/theme/`):
- Custom CSS in `custom.css`
- Vue components for enhanced functionality
- Breadcrumb navigation component

This modular architecture enables easy maintenance, testing, and extension while maintaining robust error handling and user experience.