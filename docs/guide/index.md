# Getting Started

Claudux is an AI-powered documentation generator that analyzes your codebase and creates comprehensive VitePress documentation sites automatically.

## Installation

Install claudux globally via npm:

```bash
npm install -g claudux
```

**Requirements:**
- Node.js ≥ 18.0.0
- Claude CLI authenticated (`claude config get`)

## Quick Start

1. **Navigate to your project**:
   ```bash
   cd your-project
   ```

2. **Generate documentation**:
   ```bash
   claudux update
   ```

3. **Preview locally**:
   ```bash
   claudux serve  # Opens http://localhost:5173
   ```

## First Run Experience

When you run `claudux update` for the first time:

1. **Project Detection**: Automatically detects your project type (React, Next.js, Python, etc.)
2. **Code Analysis**: Scans source files to understand structure and patterns
3. **Documentation Generation**: Creates comprehensive docs with proper navigation
4. **Link Validation**: Ensures all internal links work correctly

## Interactive Menu

Run `claudux` without arguments to access the interactive menu:

```bash
$ claudux

📚 claudux - Your Project Documentation  
Powered by Claude AI - Everything stays local

Select:

1) Generate docs              (scan code → markdown)
2) Serve                      (vitepress dev server)
3) Create claudux.md           (docs preferences)  
4) Exit
```

## Basic Workflow

```bash
# One-time setup
npm install -g claudux
cd your-project

# Regular usage
claudux update    # Regenerate docs when code changes
claudux serve     # Preview changes locally
```

The generated documentation will be created in a `docs/` directory with:
- VitePress configuration
- Responsive navigation
- Full-text search
- Mobile-friendly design
- Automatic breadcrumbs

## Next Steps

- [Commands Reference →](/guide/commands)
- [Configuration Options →](/guide/configuration)  
- [Features Overview →](/features/)