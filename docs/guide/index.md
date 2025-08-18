[Home](/) > Guide

# User Guide

Welcome to the Claudux user guide! This section covers everything you need to know to use Claudux effectively for generating and maintaining documentation.

## What is Claudux?

Claudux is a Bash-based CLI tool that leverages Claude Code to automatically generate comprehensive, maintainable documentation for your codebase. It combines the power of AI with the simplicity of Unix philosophy to deliver documentation that actually stays in sync with your code.

## Core Concepts

### Two-Phase Generation
Claudux uses a unique two-phase approach:
1. **Analysis Phase**: Examines your entire codebase to understand structure and patterns
2. **Generation Phase**: Creates documentation with cohesive narrative and correct cross-references

### Project Auto-Detection
The tool automatically identifies your project type and applies appropriate templates:
- React/Next.js applications
- iOS/Swift projects
- Python packages
- Rust crates
- Generic JavaScript projects
- And more...

### Smart Cleanup
Unlike simple regex-based tools, Claudux uses semantic analysis to identify obsolete documentation with 95% confidence, ensuring only truly outdated content is removed.

## Workflow Overview

```mermaid
graph LR
    A[Install Claudux] --> B[Run claudux update]
    B --> C[AI Analyzes Codebase]
    C --> D[Generates Docs]
    D --> E[Preview with claudux serve]
    E --> F[Deploy to Static Host]
```

## Quick Start Steps

1. **Install Claudux**
   ```bash
   npm install -g claudux
   ```

2. **Navigate to Your Project**
   ```bash
   cd your-project
   ```

3. **Generate Documentation**
   ```bash
   claudux update
   ```

4. **Preview Locally**
   ```bash
   claudux serve
   ```

5. **Deploy** (optional)
   Your `docs/` folder is ready for any static hosting service

## Key Commands

| Command | Description |
|---------|-------------|
| `claudux` | Interactive menu |
| `claudux update` | Generate/update documentation |
| `claudux serve` | Start local preview server |
| `claudux clean` | Remove obsolete files |
| `claudux validate` | Check for broken links |
| `claudux template` | Generate CLAUDE.md instructions |

## Configuration

Claudux can be configured through:
- `docs-ai-config.json` - Project-specific settings
- `CLAUDE.md` - AI assistant instructions
- Environment variables - Runtime options

See the [Configuration Guide](/guide/configuration) for details.

## Best Practices

1. **Run regularly**: Keep docs in sync by running `claudux update` after significant changes
2. **Review generated content**: While AI is powerful, human review ensures accuracy
3. **Customize templates**: Add project-specific instructions to `CLAUDE.md`
4. **Protect custom content**: Use protection markers for hand-written sections
5. **Version control**: Commit your `docs/` folder to track changes

## Getting Help

- Check the [FAQ](/faq) for common questions
- Review [Troubleshooting](/troubleshooting) for solutions
- Report issues on [GitHub](https://github.com/leokwan/claudux/issues)
- Read the [Technical Documentation](/technical/) for deeper understanding

## Next Steps

- [Installation](/guide/installation) - Detailed installation instructions
- [Quick Start](/guide/quickstart) - Step-by-step tutorial
- [Commands](/guide/commands) - Complete command reference
- [Configuration](/guide/configuration) - Customization options