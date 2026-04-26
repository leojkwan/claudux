# Features Overview

Claudux combines AI-powered code analysis with modern documentation tooling to solve the documentation maintenance problem.

## Core Features

### 🔄 Automatic Updates

**Problem**: Documentation becomes stale the moment you ship new code.

**Solution**: Claudux analyzes your actual source code on every run, detecting:
- New functions and APIs
- Changed behavior and patterns  
- Deprecated or removed features
- Updated configuration options

```bash
claudux update  # Always generates current documentation
```

### 🧠 Code Understanding

**Problem**: Generic documentation templates don't capture your project's uniqueness.

**Solution**: Claude AI understands your codebase structure and patterns:
- Analyzes import/export relationships
- Detects architectural patterns (MVC, microservices, etc.)
- Understands framework conventions (React hooks, Express middleware)
- Preserves domain-specific terminology

### ⚡ One-Command Generation

**Problem**: Documentation toolchains are complex and time-consuming.

**Solution**: Single command generates complete sites:

```bash
claudux update  # Generates VitePress site with navigation, search, mobile support
```

**Includes:**
- Responsive navigation structure
- Full-text search
- Mobile-friendly design  
- Auto-generated breadcrumbs
- Dark/light theme toggle

### 🔒 Local Orchestration

**Problem**: Docs tools should be explicit about where orchestration runs and which model backend is used.

**Solution**: Claudux runs as a local CLI and delegates model work to your selected authenticated backend:
- Reads files from your local checkout
- Uses locally installed Claude or Codex CLI
- Processes generated docs in your environment
- Sends prompt context through the selected backend CLI

### 🍰 Zero Configuration

**Problem**: Documentation tools require extensive setup and maintenance.

**Solution**: Intelligent project detection and defaults:

```bash
cd any-project
claudux update  # Just works
```

**Auto-detects:**
- Project type (React, Python, Go, etc.)
- Entry points and main modules
- Testing frameworks and build tools
- Existing documentation patterns

## Advanced Features

### 🔗 Link Validation

Prevents broken documentation with built-in validation:

```bash
claudux update  # Includes automatic link checking
```

**Validates:**
- Internal page references
- Anchor links within pages
- Asset and image references  
- External URL accessibility

**Auto-fix capability:**
```bash
claudux update -m "Fix broken links and create missing pages"
```

### 🛡️ Content Protection

Preserves sensitive or manually curated content:

```markdown
<!-- skip -->
This section won't be modified by claudux
<!-- /skip -->
```

**Automatically protects:**
- `notes/` and `private/` directories
- Environment files (`*.env`, `*.key`)
- Configuration secrets

### 🎯 Focused Updates

Target specific documentation areas:

```bash
claudux update -m "Update API documentation only"
claudux update --with "Add examples for the new authentication flow"
```

### 📱 Project-Specific Optimization

Adapts documentation structure to your project type:

**CLI tools**: Command reference, installation, examples  
**Libraries**: API docs, integration guides, usage patterns  
**Web apps**: Features, deployment, configuration  
**Mobile apps**: Setup, architecture, app store guidelines

## Quality Assurance

### Accuracy Guarantees

- **Code examples**: Extracted from actual source files
- **API documentation**: Based on current function signatures
- **Installation steps**: Derived from `package.json`, `requirements.txt`, etc.
- **No placeholders**: All content references real project elements

### Consistency Features

- **Unified navigation**: Sidebar appears on all pages
- **Cross-references**: Automatic linking between related concepts
- **Terminology**: Consistent use of project-specific terms
- **Styling**: Follows your project's established patterns

## Next Steps

Explore specific features in detail:

- [Two-Phase Generation →](/features/two-phase-generation)
- [Smart Cleanup →](/features/smart-cleanup)  
- [Content Protection →](/features/content-protection)
