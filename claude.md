# Claudux - AI Documentation Generator

## Overview

Claudux is a command-line tool that leverages Claude Code to automatically generate comprehensive documentation for your projects. It analyzes your codebase and creates beautiful, well-structured documentation using VitePress.

## Architecture

### Core Components

1. **Main Script (`bin/claudux`)**
   - Entry point for all commands
   - Routes to appropriate library functions
   - Handles user interaction

2. **Library Modules (`lib/`)**
   - `claude-utils.sh`: Claude AI integration
   - `docs-generation.sh`: Documentation generation logic
   - `project.sh`: Project detection and analysis
   - `server.sh`: VitePress dev server management
   - `ui.sh`: Interactive menu system
   - `cleanup.sh`: Obsolete file detection
   - `content-protection.sh`: Safe content handling
   - `git-utils.sh`: Git integration
   - `colors.sh`: Terminal color support

### Two-Phase Generation Process

1. **Phase 1: Architecture Planning**
   - Analyzes project structure
   - Detects project type (Node.js, Python, iOS, etc.)
   - Creates documentation map
   - Plans content structure

2. **Phase 2: Content Generation**
   - Generates detailed documentation
   - Creates API references
   - Builds usage guides
   - Adds examples and tutorials

## Key Features

### Intelligent Obsolescence Detection
- Semantic analysis of documentation changes
- Preserves manually added content
- Removes only truly obsolete files

### Multi-Format Support
- Automatic project type detection
- Language-specific documentation patterns
- Framework-aware content generation

### VitePress Integration
- Beautiful, searchable documentation sites
- Mobile-responsive design
- Dark mode support
- Fast static site generation

## Technical Details

### Dependencies
- Bash 4.0+
- Node.js 14+
- Claude CLI (for AI generation)
- VitePress (installed per project)

### File Structure
```
project/
├── docs/                    # Generated documentation
│   ├── .vitepress/         # VitePress config
│   ├── api/                # API documentation
│   ├── guide/              # User guides
│   └── index.md            # Home page
├── docs-ai-config.json     # Claudux configuration
└── docs-map.md             # Documentation structure
```

### Configuration
Claudux uses `docs-ai-config.json` for project-specific settings:
- Documentation scope
- Excluded paths
- Custom templates
- Generation preferences

## Integration with Claude Code

Claudux is designed to showcase the power of Claude Code subscriptions:

1. **Context-Aware Generation**: Understands your entire codebase
2. **Intelligent Updates**: Only regenerates changed sections
3. **Smart Cleanup**: Semantic obsolescence detection
4. **Natural Language**: Conversational, easy-to-read documentation

## Best Practices

### For Best Results
1. Keep code well-commented
2. Use clear function/class names
3. Maintain consistent project structure
4. Review generated documentation
5. Customize templates as needed

### Common Use Cases
- API documentation
- Library references
- Tutorial generation
- Architecture documentation
- Migration guides

## Development Workflow

1. **Initial Setup**
   ```bash
   npm install -g claudux
   claudux template  # Create config
   ```

2. **Generate Documentation**
   ```bash
   claudux update
   ```

3. **Preview Locally**
   ```bash
   claudux serve
   ```

4. **Clean Obsolete Files**
   ```bash
   claudux clean
   ```

---

*Claudux leverages Claude Code to transform your codebase into comprehensive, maintainable documentation.*