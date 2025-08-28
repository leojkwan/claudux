# Module Documentation

[Home](/) > [Technical](/technical/) > Module Documentation

This document provides detailed documentation for all modules in the `/lib/` directory. Each module follows strict separation of concerns and provides specific functionality to the Claudux system.

## Core Utility Modules

### colors.sh - Terminal Colors and Error Handling

**Purpose**: Provides consistent terminal color output and standardized error handling patterns.

**Key Functions:**
```bash
print_color() {
    local color=$1
    local text=$2
    # Safe color printing with fallback
}

error_exit() {
    print_color "RED" "❌ $1" >&2
    exit "${2:-1}"
}
```

**Exported Colors:**
- `GREEN`, `YELLOW`, `BLUE`, `RED`, `NC` (No Color)

**Standard Functions:**
- `warn()` - Yellow warning messages
- `info()` - Blue informational messages
- `success()` - Green success messages
- `error_exit()` - Red error with exit

**Usage Pattern:**
```bash
success "Configuration loaded successfully"
warn "Node.js version is below recommended"
error_exit "Required file not found" 2
```

### ui.sh - User Interface Components

**Purpose**: Provides interactive menus, headers, and user interface elements.

**Key Components:**
- Interactive command selection menu
- Formatted headers with project information
- Help text generation and display
- Progress indicators and status updates

**Core Functions:**
- `show_header()` - Display branded header with project info
- `show_menu()` - Interactive command selection
- `show_help()` - Comprehensive help text
- `create_claudux_md()` - Generate project template files

**Interactive Features:**
- Colored menu options with keyboard shortcuts
- Real-time project type detection display
- Graceful handling of user interrupts

### project.sh - Project Detection and Configuration

**Purpose**: Detects project types and loads configuration from various sources.

**Configuration Cascade:**
1. `docs-ai-config.json` (primary configuration)
2. `.claudux.json` (legacy format)
3. Auto-detection (fallback)

**Project Detection Logic:**
```bash
detect_project_type() {
    # iOS/Swift: *.xcodeproj, *.xcworkspace, Project.swift
    # Next.js: next.config.*, package.json with "next"
    # React: package.json with "react"
    # Node.js: package.json with "@types/node"
    # Python: requirements.txt, pyproject.toml, setup.py
    # Rust: Cargo.toml
    # Go: go.mod
    # Flutter: pubspec.yaml with flutter SDK
    # Android: build.gradle with android plugin
    # Rails: Gemfile with rails gem
}
```

**Key Functions:**
- `load_project_config()` - Load and export PROJECT_NAME, PROJECT_TYPE
- `detect_project_type()` - File pattern-based detection
- `get_project_config()` - Return appropriate template configuration path

**Configuration Variables:**
- `PROJECT_NAME` - Human-readable project name
- `PROJECT_TYPE` - Detected or configured project type

## AI Integration Modules

### claude-utils.sh - Claude CLI Integration

**Purpose**: Abstracts Claude CLI interactions and provides model management.

**Model Configuration:**
```bash
get_model_settings() {
    local model="${FORCE_MODEL:-opus}"
    case "$model" in
        "opus")
            model_name="Claude Opus (most powerful)"
            cost_estimate="~\$0.05 per run"
            ;;
        "sonnet")
            model_name="Claude Sonnet (fast & capable)"
            cost_estimate="~\$0.01 per run"
            ;;
    esac
}
```

**Key Functions:**
- `check_claude()` - Verify CLI installation and configuration
- `get_model_settings()` - Return model info and cost estimates
- `show_progress()` - Display generation progress indicators
- `generate_with_claude()` - Main AI generation wrapper

**Features:**
- Automatic model detection and validation
- Cost estimation display
- Progress indication during long operations
- Error handling for API failures

### docs-generation.sh - Documentation Generation

**Purpose**: Orchestrates the two-phase documentation generation process.

**Prompt Building System:**
```bash
build_generation_prompt() {
    local project_type="$1"
    local project_name="$2"
    local user_directive="${3:-}"
    
    # Configuration file locations:
    # - .ai-docs-style.md (style guide)
    # - lib/templates/${project_type}/config.json (template config)
    # - docs-map.md (documentation structure)
    # - CLAUDE.md (project-specific patterns)
}
```

**Two-Phase Process:**

**Phase 1 - Analysis & Planning:**
1. Read configuration files and templates
2. Analyze codebase structure and patterns
3. Audit existing documentation
4. Identify obsolete content (95% confidence threshold)
5. Create detailed generation plan

**Phase 2 - Content Generation:**
1. Apply content protection filters
2. Generate or update documentation files
3. Ensure consistency with templates
4. Validate links and references
5. Update VitePress configuration

**Key Functions:**
- `build_generation_prompt()` - Construct comprehensive AI prompts
- `update()` - Main documentation update workflow
- `recreate_docs()` - Full documentation regeneration
- `load_generation_settings()` - Configure generation parameters

### cleanup.sh - Obsolete File Detection

**Purpose**: Identifies and manages obsolete documentation files using semantic analysis.

**Obsolescence Detection:**
```bash
# Confidence thresholds for semantic analysis
OBSOLETE_CONFIDENCE_THRESHOLD=95  # 95% confidence required
STALE_DAYS=30                     # Files older than 30 days
```

**Detection Methods:**
1. **File Age Analysis**: Identify files not modified within threshold
2. **Content Relevance**: Semantic analysis against current codebase
3. **Reference Checking**: Detect broken internal references
4. **Structure Validation**: Ensure files match current project structure

**Key Functions:**
- `cleanup_docs()` - Main cleanup workflow with dry-run support
- `identify_obsolete_files()` - Semantic obsolescence detection
- `safe_cleanup()` - Protected cleanup with confirmation
- `generate_cleanup_report()` - Detailed removal justification

**Safety Features:**
- Dry-run mode for preview
- Content protection respect
- User confirmation for removals
- Detailed logging of cleanup actions

## Content Processing Modules

### content-protection.sh - Sensitive Content Protection

**Purpose**: Filters and protects sensitive content using comment-based markers.

**Protection Markers by File Type:**
```bash
get_protection_markers() {
    case "$ext" in
        md|markdown) echo "<!-- skip -->" "<!-- /skip -->" ;;
        swift|js|ts|jsx|tsx|java|c|cpp|h|hpp|rs|go) echo "// skip" "// /skip" ;;
        py|sh|bash|zsh|rb|pl) echo "# skip" "# /skip" ;;
        html|xml|vue) echo "<!-- skip -->" "<!-- /skip -->" ;;
        css|scss|sass|less) echo "/* skip */" "/* /skip */" ;;
        sql) echo "-- skip" "-- /skip" ;;
    esac
}
```

**Protected Directory Patterns:**
- `notes/`, `private/`, `secret/`
- `.git/`, `.env*`, `config/secrets/`
- `node_modules/`, `vendor/`, `build/`
- User-defined patterns in configuration

**Key Functions:**
- `get_protection_markers()` - File type-specific comment markers
- `strip_protected_content()` - Remove protected sections
- `is_protected_directory()` - Check directory protection status
- `apply_content_filters()` - Full content filtering pipeline

**Security Features:**
- Multi-language comment support
- Nested protection section handling
- Graceful handling of malformed markers
- Logging of protected content filtering

### validate-links.sh - Link Validation and Repair

**Purpose**: Validates documentation links and provides automatic repair functionality.

**Link Detection:**
```bash
# Markdown link patterns
MARKDOWN_LINK_REGEX='\[([^\]]+)\]\(([^)]+)\)'
# Relative link patterns
RELATIVE_LINK_REGEX='^\.\?\/.*\.md$'
```

**Validation Types:**
1. **Internal Links**: Verify files exist within docs/
2. **Relative Links**: Check path resolution
3. **Anchor Links**: Validate heading references
4. **External Links**: HTTP/HTTPS URL validation (optional)

**Key Functions:**
- `validate_links()` - Main validation with reporting
- `check_internal_links()` - Verify documentation cross-references
- `repair_broken_links()` - Automatic link correction
- `generate_link_report()` - Detailed validation results

**Repair Capabilities:**
- Automatic path correction for moved files
- Anchor link updates for heading changes
- Broken link detection and reporting
- Batch repair with user confirmation

## Integration Modules

### git-utils.sh - Git Integration

**Purpose**: Provides Git repository integration for change detection and versioning.

**Change Detection:**
```bash
# Detect modified files since last documentation update
get_changed_files() {
    git diff --name-only HEAD~1 HEAD 2>/dev/null || echo ""
}
```

**Key Functions:**
- `is_git_repository()` - Check if directory is Git-managed
- `get_changed_files()` - Identify modified files for incremental updates
- `get_project_info()` - Extract repository metadata
- `check_git_status()` - Repository status and health checks

**Features:**
- Graceful handling of non-Git projects
- Change detection for incremental documentation
- Repository metadata extraction
- Branch and commit information display

### server.sh - Development Server Management

**Purpose**: Manages VitePress development server with intelligent port allocation.

**Port Management:**
```bash
# Scan port range 3000-3100 for availability
find_available_port() {
    for port in {3000..3100}; do
        if ! lsof -i :$port >/dev/null 2>&1; then
            echo $port
            return 0
        fi
    done
    return 1
}
```

**Server Features:**
- Automatic VitePress installation and configuration
- Intelligent port conflict resolution
- Background server management
- Graceful shutdown handling

**Key Functions:**
- `serve()` - Start development server with port detection
- `setup_vitepress()` - Install and configure VitePress if needed
- `find_available_port()` - Port availability scanning
- `stop_server()` - Graceful server shutdown

**Process Management:**
- Background process tracking
- PID file management
- Signal handling for clean shutdown
- Port cleanup on exit

## Module Interaction Patterns

### Dependency Chain
```
bin/claudux
├── colors.sh (foundation)
├── project.sh (configuration)
├── content-protection.sh (security)
├── claude-utils.sh (AI integration)
├── git-utils.sh (versioning)
├── docs-generation.sh (core workflow)
├── cleanup.sh (maintenance)
├── server.sh (development)
├── validate-links.sh (quality)
└── ui.sh (interface)
```

### Cross-Module Communication
- **Environment Variables**: `PROJECT_NAME`, `PROJECT_TYPE`, `SCRIPT_DIR`, `WORKING_DIR`
- **Function Validation**: All modules use `check_function()` before calling external functions
- **Error Propagation**: Consistent `error_exit()` usage across all modules
- **Logging Standards**: Uniform `info()`, `warn()`, `success()` messaging

### Configuration Sharing
- **Global Settings**: Shared through environment variables
- **Template System**: Common template resolution across modules  
- **Protection Rules**: Consistent content protection across processing modules
- **Path Resolution**: Absolute paths enforced throughout the system

This modular architecture ensures clean separation of concerns while maintaining consistent interfaces and error handling patterns across all components.