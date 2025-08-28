# Architecture Overview

[Home](/) > [Technical](/technical/) > Architecture Overview

This document provides a comprehensive overview of the Claudux architecture, a Bash-based CLI tool for AI-powered documentation generation using Claude and VitePress.

## Core Architecture

### Entry Point - Router Pattern

The main entry point `/bin/claudux` follows a strict router pattern that handles:

- **Path Resolution**: Robust symlink resolution with loop detection (max 10 levels)
- **Library Loading**: Sequential loading of required modules with error handling
- **Command Routing**: Clean command dispatch without business logic
- **Dependency Validation**: Pre-execution checks for Node.js, Claude CLI, and other tools
- **Process Isolation**: File locking to prevent concurrent execution conflicts

```bash
# Key architectural elements from bin/claudux
SCRIPT_DIR="$(resolve_script_path)"
WORKING_DIR="$(pwd)"

# Sequential library loading
REQUIRED_LIBS=("colors.sh" "project.sh" "content-protection.sh" "claude-utils.sh" ...)
```

### Core Module System

All business logic resides in modular `/lib/*.sh` files following strict separation of concerns:

#### Foundation Layer
- **`colors.sh`**: Terminal color utilities and error handling patterns
- **`project.sh`**: Project type detection and configuration management
- **`ui.sh`**: User interface components and interactive menus

#### Content Processing Layer
- **`content-protection.sh`**: Sensitive content filtering and protection
- **`docs-generation.sh`**: Two-phase documentation generation workflow
- **`cleanup.sh`**: Obsolete file detection and semantic analysis

#### Integration Layer
- **`claude-utils.sh`**: Claude CLI abstraction and model management
- **`git-utils.sh`**: Git repository integration and change detection
- **`server.sh`**: VitePress development server management
- **`validate-links.sh`**: Documentation link validation and repair

### Template System Architecture

The template system in `/lib/templates/` provides project-specific configuration:

```
lib/templates/
├── generic/               # Default fallback templates
│   └── config.json
├── nextjs-claude.md      # Next.js specific prompts
├── ios-claudux.md        # iOS project patterns
└── react-project-config.json  # React configuration
```

**Template Resolution Priority:**
1. `${project_type}/config.json` (directory structure)
2. `${project_type}-project-config.json` (file naming)
3. `${project_type}-config.json` (simplified naming)
4. `generic/config.json` (fallback)

### VitePress Integration

The VitePress integration in `/lib/vitepress/` handles:

- **Dynamic Configuration**: Template-based config generation with sidebar automation
- **Theme Customization**: Custom components and styling in `/theme/`
- **Development Server**: Port management (3000-3100 range) with conflict resolution
- **Build Process**: Production build optimization and deployment preparation

## Key Architectural Patterns

### Error Handling Pattern

All modules follow consistent error handling:

```bash
# From lib/colors.sh
error_exit() {
    print_color "RED" "❌ $1" >&2
    exit "${2:-1}"
}

# Usage throughout codebase
[[ -f "$file" ]] || error_exit "File not found: $file"
```

### Path Resolution Pattern

Absolute paths are enforced throughout the system:

```bash
# From bin/claudux - symlink resolution
resolve_script_path() {
    local source="${BASH_SOURCE[0]}"
    local count=0
    
    while [[ -L "$source" ]] && [[ $count -lt 10 ]]; do
        # Robust symlink resolution logic
    done
}
```

### Function Validation Pattern

All function calls are validated before execution:

```bash
# From bin/claudux
check_function() {
    local func_name="$1"
    if ! declare -F "$func_name" >/dev/null 2>&1; then
        error_exit "Required function '$func_name' not found"
    fi
}
```

### Configuration Cascade Pattern

Configuration loading follows a priority cascade:

```bash
# From lib/project.sh
load_project_config() {
    # 1. docs-ai-config.json (primary)
    # 2. .claudux.json (legacy)
    # 3. Auto-detection (fallback)
}
```

## Two-Phase Generation Workflow

The documentation generation follows a sophisticated two-phase approach:

### Phase 1: Analysis & Planning
1. **Configuration Loading**: Read project configs, style guides, and documentation maps
2. **Codebase Analysis**: Scan source structure, identify components and APIs
3. **Content Audit**: Cross-reference existing docs against current code
4. **Obsolescence Detection**: Semantic analysis with 95% confidence threshold
5. **Generation Planning**: Create detailed update plan with file priorities

### Phase 2: Content Generation
1. **Protected Content Filtering**: Strip sensitive sections using comment markers
2. **Incremental Updates**: Update only changed or obsolete content
3. **Template Application**: Apply project-specific documentation patterns
4. **Quality Validation**: Link checking and content verification
5. **VitePress Integration**: Sidebar generation and site configuration

## Security Architecture

### Content Protection System

Multi-layered protection for sensitive content:

```bash
# Comment-based protection markers by file type
get_protection_markers() {
    case "$ext" in
        md|markdown) echo "<!-- skip -->" "<!-- /skip -->" ;;
        swift|js|ts) echo "// skip" "// /skip" ;;
        py|sh|bash) echo "# skip" "# /skip" ;;
    esac
}
```

### Directory Protection

Automatic protection for sensitive directories:
- `notes/`, `private/`, `.git/`
- `node_modules/`, `vendor/`
- Hidden directories (`.*/`)

### Process Isolation

File locking prevents concurrent execution:

```bash
# From bin/claudux
acquire_lock() {
    local lock_file="${TMPDIR:-/tmp}/claudux-$(pwd | md5sum).lock"
    # PID-based locking with stale lock cleanup
}
```

## Performance Optimizations

### Incremental Processing
- Content hashing to detect changes
- Selective file processing based on modification time
- Semantic obsolescence detection to avoid unnecessary regeneration

### Resource Management
- Background process cleanup via trap handlers
- Temporary file management with automatic cleanup
- Memory-efficient file processing with streaming

### Network Optimization
- Claude model selection for cost/speed balance
- Request batching for multiple file updates
- Exponential backoff for API rate limiting

## Extensibility Points

### Adding New Project Types
1. Create detection logic in `detect_project_type()`
2. Add template in `/lib/templates/`
3. Update configuration cascade in `get_project_config()`

### Custom Documentation Patterns
1. Extend prompt building in `build_generation_prompt()`
2. Add template-specific logic in `/lib/docs-generation.sh`
3. Create project-specific configuration files

### Integration Extensions
1. Add new utility modules to `/lib/`
2. Update `REQUIRED_LIBS` array in `/bin/claudux`
3. Follow established patterns for error handling and logging

## Dependencies and Requirements

### Core Dependencies
- **Bash 4.0+**: Core scripting environment
- **Node.js 18+**: VitePress and npm ecosystem
- **Claude CLI**: AI integration (`@anthropic-ai/claude-cli`)
- **Git**: Version control integration (optional)

### Optional Tools
- **jq**: JSON parsing (graceful fallback to sed/grep)
- **flock**: File locking on systems that support it
- **mdsum/md5**: Content hashing for change detection

This architecture provides a robust, extensible foundation for AI-powered documentation generation while maintaining Unix philosophy principles of modularity and composability.