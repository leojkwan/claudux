[Home](/) > Guide

# Getting Started Guide

Welcome to Claudux! This guide will help you get up and running with AI-powered documentation generation for your projects.

## What You'll Learn

This guide covers everything you need to know to use Claudux effectively:

- Installing Claudux and its prerequisites
- Generating your first documentation
- Understanding the two-phase generation process
- Customizing output for your project
- Best practices and tips

## Prerequisites

Before you begin, ensure you have:

1. **Node.js 18+** installed
2. **Claude CLI** installed and configured
3. A project you want to document

## Quick Overview

Claudux works in three simple steps:

### 1. Install
```bash
npm install -g claudux
```

### 2. Generate
```bash
cd your-project
claudux update
```

### 3. Preview
```bash
claudux serve
```

That's it! Your documentation is ready at `http://localhost:5173`.

## How Claudux Works

### Two-Phase Generation Process

Claudux uses a sophisticated two-phase approach:

**Phase 1: Analysis & Planning**
- Scans your entire codebase
- Detects project type and structure
- Identifies existing documentation
- Plans the documentation hierarchy
- Detects obsolete content

**Phase 2: Content Generation**
- Generates new documentation
- Updates existing content
- Creates proper cross-references
- Validates all links
- Removes obsolete files (95% confidence)

### Project Detection

Claudux automatically detects your project type:

- **iOS** - Xcode projects, Swift packages
- **Next.js** - App Router or Pages Router
- **React** - Create React App, Vite
- **Python** - Django, Flask, FastAPI
- **Rust** - Cargo projects
- **Go** - Go modules
- **Generic** - Any project with README

### Content Protection

Claudux protects important directories:

- `private/`, `notes/`, `secret/`
- `.git/`, `node_modules/`
- Custom content you've added
- Files listed in `.gitignore`

## Interactive Mode

Run `claudux` without arguments for an interactive menu:

```bash
$ claudux

╭─────────────────────────────────────╮
│  🤖 CLAUDUX - AI Docs Generator     │
╰─────────────────────────────────────╯

What would you like to do?

  1) 📝 Update documentation
  2) 🌐 Serve docs locally
  3) 🧹 Clean obsolete docs
  4) 🔄 Recreate from scratch
  5) 📋 Check Claude CLI
  6) ❌ Exit

Your choice:
```

## Typical Workflow

### First-Time Setup

1. **Install Claudux globally:**
   ```bash
   npm install -g claudux
   ```

2. **Navigate to your project:**
   ```bash
   cd ~/projects/my-app
   ```

3. **Generate initial documentation:**
   ```bash
   claudux update
   ```

4. **Preview the results:**
   ```bash
   claudux serve
   ```

### Updating Documentation

After making code changes:

```bash
# Update docs to match current code
claudux update

# Update with specific focus
claudux update -m "Focus on the new API endpoints"
```

### Starting Fresh

If documentation gets out of sync:

```bash
# Delete all docs and regenerate
claudux recreate
```

## Best Practices

### 1. Keep Your Code Organized

Claudux works best with well-structured projects:
- Clear directory organization
- Meaningful file names
- Consistent patterns

### 2. Use CLAUDE.md for Project Context

Create a `CLAUDE.md` file to provide project-specific context:

```bash
claudux create-template
```

This helps Claudux understand:
- Coding conventions
- Architecture patterns  
- Project-specific terminology
- Important implementation details

### 3. Configure for Your Needs

Customize via `claudux.json`:

```json
{
  "project": {
    "name": "My App",
    "type": "javascript"
  }
}
```

### 4. Regular Updates

Run `claudux update` regularly:
- After major features
- Before releases
- When onboarding team members

## Common Use Cases

### Onboarding New Team Members

```bash
# Generate comprehensive docs
claudux update -m "Create detailed onboarding documentation"
```

### API Documentation

```bash
# Focus on API endpoints
claudux update -m "Document all API endpoints with examples"
```

### Architecture Overview

```bash
# Generate architecture docs
claudux update -m "Explain system architecture and design patterns"
```

## Troubleshooting Quick Tips

- **Claude CLI not found?** Install with `npm install -g @anthropic-ai/claude-code`
- **Permission denied?** Use `sudo npm install -g claudux`
- **Port already in use?** Claudux auto-selects ports 5173-5190
- **Docs not updating?** Try `claudux clean` then `claudux update`

## Next Steps

- [Installation Details →](/guide/installation)
- [Quick Start Tutorial →](/guide/quickstart)
- [Command Reference →](/guide/commands)
- [Configuration Options →](/guide/configuration)

---

<p align="center">
  Ready to generate amazing documentation? <a href="/guide/installation">Let's get started →</a>
</p>