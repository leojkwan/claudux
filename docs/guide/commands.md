[Home](/) > [Guide](/guide/) > Commands

# Command Reference

Complete reference for all Claudux commands, options, and usage patterns. This guide covers every command available in the Claudux CLI.

## Command Overview

| Command | Purpose | Usage |
|---------|---------|--------|
| [`claudux`](#interactive-mode) | Interactive menu | `claudux` |
| [`claudux update`](#update-command) | Generate/update documentation | `claudux update [options]` |
| [`claudux serve`](#serve-command) | Start development server | `claudux serve` |
| [`claudux clean`](#clean-command) | Remove obsolete documentation | `claudux clean` |
| [`claudux recreate`](#recreate-command) | Start fresh (delete all docs) | `claudux recreate` |
| [`claudux create-template`](#create-template-command) | Generate CLAUDE.md context | `claudux create-template` |
| [`claudux check`](#check-command) | Verify environment setup | `claudux check` |
| [`claudux version`](#version-command) | Show version information | `claudux version` |

## Interactive Mode

Run Claudux without arguments to launch the interactive menu.

```bash
claudux
```

### Features
- **Beginner-friendly** guided interface
- **Context-aware** menu options
- **Safe defaults** for all operations
- **Status detection** (new vs existing projects)

### Sample Output
```
📚 claudux - My Project Documentation
Powered by Claude AI - Everything stays local

Select:

  1) Update docs                (regenerate from code)
  2) Update (focused)           (enter directive → update)  
  3) Serve                      (vitepress dev server)
  4) Create CLAUDE.md           (AI context file)
  5) Recreate                   (start fresh)
  6) Exit

> 
```

### When to Use
- **First time** using Claudux
- **Occasional use** with guided workflow
- **Exploring options** without memorizing commands
- **Team members** unfamiliar with CLI tools

---

## Update Command

The core command that analyzes your codebase and generates/updates documentation.

### Basic Usage

```bash
claudux update
```

### Options

#### Message/Directive Options

```bash
# Provide focused directive for Claude
claudux update -m "Focus on API documentation"
claudux update --message "Document deployment process"
claudux update --with "Add usage examples for all functions"
```

**When to Use:**
- **Specific focus** - Guide Claude to emphasize certain areas
- **Missing content** - "Add installation instructions"
- **New features** - "Document the new authentication system"
- **User feedback** - "Improve getting started guide"

#### Strict Mode

```bash
claudux update --strict
claudux update -m "Fix broken links" --strict
```

**What it does:**
- Fails with error if links remain broken after auto-fix
- Ensures documentation quality before deployment
- Useful in CI/CD pipelines

#### Verbosity Control

```bash
claudux update -v          # Verbose output
claudux update -vv         # Very verbose (debug mode)
claudux update -q          # Quiet mode (errors only)
```

### Advanced Examples

#### Focused Documentation Updates

```bash
# API-focused update
claudux update -m "Document all REST endpoints with request/response examples"

# Architecture overview
claudux update -m "Explain system architecture and design patterns"

# Onboarding focused
claudux update -m "Create comprehensive developer onboarding guide"

# Deployment focused  
claudux update -m "Add detailed deployment and configuration instructions"

# Examples focused
claudux update -m "Add practical usage examples for all major features"
```

#### CI/CD Integration

```bash
# Ensure documentation is complete and valid
claudux update --strict

# Update with release notes
claudux update -m "Update docs for v2.0.0 release" --strict
```

### The Two-Phase Process

When you run `claudux update`, it follows a sophisticated approach:

**Phase 1: Analysis & Planning (15-45 seconds)**
1. **Configuration Loading**
   - Reads `docs-ai-config.json`
   - Loads project templates
   - Checks for `CLAUDE.md` context

2. **Codebase Analysis**  
   - Scans source code structure
   - Detects project type and frameworks
   - Identifies entry points and APIs

3. **Documentation Audit**
   - Lists existing documentation
   - Cross-references with current code
   - Identifies obsolete content (95% confidence threshold)

4. **Structure Planning**
   - Plans navigation hierarchy
   - Defines page relationships
   - Creates VitePress configuration

**Phase 2: Content Generation (30-90 seconds)**
1. **Content Creation**
   - Generates new documentation pages
   - Updates existing content
   - Extracts code examples from source

2. **Cross-Reference Building**
   - Creates internal links
   - Builds navigation structure
   - Adds breadcrumb navigation

3. **Quality Assurance**
   - Validates all links
   - Checks for broken references
   - Ensures consistent formatting

4. **Cleanup**
   - Removes obsolete files (high confidence only)
   - Updates VitePress configuration
   - Finalizes site structure

### Model Selection

```bash
# Force specific Claude model
FORCE_MODEL=opus claudux update      # Most powerful (default)
FORCE_MODEL=sonnet claudux update    # Faster and cheaper
```

**Model Comparison:**
- **Opus**: Most comprehensive analysis, best for complex projects
- **Sonnet**: Faster generation, good for regular updates

### Environment Variables

```bash
# Set default update message
CLAUDUX_MESSAGE="Weekly documentation sync" claudux update

# Enable verbose output
CLAUDUX_VERBOSE=1 claudux update
```

---

## Serve Command

Start a local development server to preview your documentation.

### Basic Usage

```bash
claudux serve
```

### What It Does

1. **Dependency Check**
   - Verifies VitePress installation
   - Installs dependencies if needed
   - Sets up isolated environment

2. **Server Start**
   - Launches VitePress dev server
   - Auto-selects available port (5173-5190)
   - Enables hot-reload for development

3. **Feature Setup**
   - Full-text search
   - Mobile-responsive design
   - Dark/light mode toggle
   - Edit links to source files

### Server Features

- **Hot Reload** - Changes reflect instantly
- **Mobile Optimized** - Works on all devices  
- **Search** - Full-text search across all docs
- **Navigation** - Auto-generated from structure
- **Performance** - Fast page loads with caching

### Sample Output

```bash
$ claudux serve
🌐 Starting documentation server...
📦 Setting up VitePress...
✅ Dependencies already installed
📖 Docs available at: http://localhost:5173

Press Ctrl+C to stop the server

  vitepress v1.0.0-rc.31

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
  ➜  press h to show help
```

### Automatic Setup

If docs don't exist, Claudux offers to generate them:

```bash
$ claudux serve
🌐 Starting documentation server...
📄 No documentation found!

You need to generate documentation first.
Run: claudux update (or select option 1 from the menu)

Would you like to generate docs now? (y/N): 
```

### Port Selection

Claudux automatically finds available ports:

1. **Default**: 5173 (VitePress default)
2. **Fallback**: 5174, 5175, ..., 5190
3. **Conflict Resolution**: Skips ports in use

---

## Clean Command

Intelligently remove obsolete documentation using AI analysis.

### Basic Usage

```bash
claudux clean
# or
claudux cleanup
```

### How It Works

1. **Semantic Analysis**
   - Cross-references documentation with current codebase
   - Checks if documented features still exist
   - Verifies API/interface accuracy

2. **Confidence Scoring**
   - Assigns confidence scores (0-100%)
   - Only deletes files with 95%+ confidence
   - Provides specific reasons for obsolescence

3. **Conservative Approach**
   - Protects valuable documentation
   - Never deletes based on filename patterns alone
   - Requires explicit evidence of obsolescence

### What Gets Cleaned

**High Confidence (95%+) Deletions:**
- Documentation for removed code files
- API docs for deleted endpoints
- Guides for removed features
- Examples using deleted functions

**Protected Content:**
- Custom written content
- Recently modified files
- Files with unclear obsolescence
- Configuration and setup docs

### Sample Output

```bash
$ claudux clean
🧹 Using AI to intelligently detect obsolete documentation...

🤖 Claude analyzing documentation for obsolete content...

Analyzing docs/api/old-payment-system.md...
❌ OBSOLETE (98% confidence): Documents removed PaymentService class
   Reason: PaymentService.ts was deleted in commit abc123

Analyzing docs/guide/legacy-setup.md...  
❌ OBSOLETE (96% confidence): Setup guide for deprecated v1 API
   Reason: All v1 endpoints removed, replaced with v2

✅ Cleanup complete
📊 Analyzed: 12 files
🗑️  Removed: 2 obsolete files
✅ Protected: 10 current files
```

### Manual Review Mode

For cautious cleanup, use verbose mode:

```bash
claudux clean -v
```

This shows detailed reasoning before any deletions.

---

## Recreate Command

Delete all documentation and regenerate from scratch.

### Basic Usage

```bash
claudux recreate
```

### Use Cases

- **Major refactoring** - Code structure changed significantly
- **Documentation debt** - Existing docs are too outdated
- **Fresh start** - Want to redesign documentation structure
- **Troubleshooting** - Fix persistent generation issues

### What It Does

1. **Complete Cleanup**
   - Deletes entire `docs/` directory
   - Removes VitePress configuration
   - Clears all generated content

2. **Fresh Generation**
   - Runs full analysis from scratch
   - Creates new documentation structure
   - Generates all content anew

### Safety Features

- **Confirmation prompt** before deletion
- **Git status check** to warn about uncommitted changes
- **Backup suggestion** for manual content

### Sample Output

```bash
$ claudux recreate
📚 claudux - My Project Documentation

⚠️  This will delete ALL documentation and start fresh!

Current documentation:
  - 15 markdown files
  - VitePress configuration
  - 3 custom pages

Continue? This cannot be undone. (y/N): y

🗑️  Deleting docs/ directory...
✅ Cleanup complete

🤖 Starting fresh documentation generation...
[... normal update process ...]
```

### Options

```bash
# Recreate with specific focus
claudux recreate -m "Focus on API documentation structure"
```

---

## Create Template Command

Generate a `CLAUDE.md` file with project-specific coding patterns and conventions.

### Basic Usage

```bash
claudux create-template
# or  
claudux template
```

### Purpose

Creates an AI context file that helps Claude understand:

- **Coding conventions** used in your project
- **Architecture patterns** and design decisions  
- **Project-specific terminology** and concepts
- **Important implementation details** to preserve
- **Anti-patterns** to avoid

### The Generation Process

1. **Codebase Analysis**
   - Scans actual code patterns
   - Identifies naming conventions
   - Detects architectural decisions
   - Finds testing strategies

2. **Context Creation**
   - Generates project-specific rules
   - Creates actionable directives for AI
   - Includes real examples from your code
   - Sets constraints and guidelines

### Sample CLAUDE.md Content

```markdown
# My Project AI Assistant Instructions

## Project Context
This is a Next.js application with TypeScript, using Prisma for database access and NextAuth.js for authentication.

## CRITICAL RULES

### Code Style
- **ALWAYS use TypeScript strict mode**
- **NEVER use 'any' type** - use proper type definitions
- **FOLLOW the pattern** in src/components/ui/ for new components
- **USE Tailwind CSS** for all styling

### Architecture
- **ALWAYS place API routes** in src/app/api/ directory
- **NEVER access database directly** from components - use API routes
- **FOLLOW the repository pattern** in src/lib/repositories/
```

### When to Use

- **Before first documentation generation** - Provides crucial context
- **After major architectural changes** - Updates AI understanding
- **When joining a team** - Codifies existing patterns
- **For complex projects** - Ensures AI follows conventions

### Customization

After generation, review and customize the `CLAUDE.md` file:

1. **Add project-specific rules** not detected automatically
2. **Update architectural decisions** to reflect current state
3. **Include deployment considerations** and constraints
4. **Document team conventions** and style guides

---

## Check Command

Verify your environment setup and dependencies.

### Basic Usage

```bash
claudux check
# or
claudux --check
```

### What It Checks

1. **Node.js Version**
   - Verifies Node.js ≥ 18.0.0
   - Shows current version

2. **Claude CLI**
   - Checks if Claude CLI is installed
   - Verifies authentication status
   - Shows current model configuration

3. **Project Status**
   - Detects project type
   - Shows documentation status
   - Lists protected directories

### Sample Output

```bash
$ claudux check
📚 claudux - My Project Documentation
Powered by Claude AI - Everything stays local

🔎 Environment check

• Node: v18.17.0
• Claude: claude-code 0.8.0
  Model: claude-3-5-sonnet-20241022
• docs/: present (8 files)
📁 Detected project type: nextjs
```

### Troubleshooting Output

```bash
$ claudux check  
📚 claudux - My Project Documentation

🔎 Environment check

• Node: v16.14.0
  ⚠️  Node.js v18+ is required (found v16.14.0)
• Claude: not found
  ❌ Claude CLI not found. Install: npm install -g @anthropic-ai/claude-code
• docs/: not present (will be created on first run)
```

### Use Cases

- **Before first use** - Verify setup is complete
- **Troubleshooting** - Diagnose environment issues  
- **Team setup** - Ensure all developers have correct versions
- **CI/CD validation** - Check environment in automated pipelines

---

## Version Command

Display version information for Claudux.

### Basic Usage

```bash
claudux version
claudux --version
claudux -V
```

### Output

```bash
$ claudux version
claudux 1.0.0
```

### Use Cases

- **Verify installation** - Confirm Claudux is installed
- **Check for updates** - Compare with latest available version
- **Bug reports** - Include version in issue reports
- **CI/CD logging** - Record version in build logs

---

## Global Options

These options work with any command:

### Verbosity Control

```bash
claudux -v [command]     # Verbose output
claudux -vv [command]    # Very verbose (debug mode)  
claudux -q [command]     # Quiet mode (errors only)
```

**Examples:**
```bash
claudux -v update        # Verbose update
claudux -vv serve        # Debug server startup
claudux -q clean         # Quiet cleanup
```

### Help Options

```bash
claudux --help           # Show full help
claudux -h              # Show help (short form)
claudux help            # Show help
```

---

## Environment Variables

Control Claudux behavior with environment variables:

### Model Selection

```bash
# Force specific Claude model
export FORCE_MODEL=opus     # Most powerful (default)
export FORCE_MODEL=sonnet   # Faster and cheaper
```

### Verbosity

```bash
# Set default verbosity level
export CLAUDUX_VERBOSE=0    # Quiet (default)
export CLAUDUX_VERBOSE=1    # Verbose
export CLAUDUX_VERBOSE=2    # Debug mode
```

### Default Messages

```bash
# Set default update message
export CLAUDUX_MESSAGE="Weekly documentation update"
```

### Output Control

```bash
# Disable colored output
export NO_COLOR=1
```

### Usage Examples

```bash
# Use environment variables
export FORCE_MODEL=sonnet
export CLAUDUX_VERBOSE=1
claudux update

# One-time usage
FORCE_MODEL=opus claudux update -m "Comprehensive documentation review"
```

---

## Command Combinations

### Typical Workflows

#### Development Cycle
```bash
# After code changes
claudux update && claudux serve
```

#### Pre-Release
```bash
# Ensure comprehensive, valid documentation
claudux recreate -m "Prepare release documentation" --strict
```

#### Maintenance
```bash
# Clean up and update
claudux clean && claudux update
```

#### Troubleshooting
```bash
# Full verbose debugging
claudux -vv check && claudux -vv update
```

### CI/CD Integration

```bash
# Validate documentation in pipeline
claudux check
claudux update --strict
claudux validate  # (if link validation is needed)
```

---

## Advanced Usage

### Scripting with Claudux

```bash
#!/bin/bash
# Update documentation script

set -e

echo "Checking environment..."
claudux check

echo "Updating documentation..."
claudux update -m "Automated documentation update"

echo "Validating links..."
claudux validate --auto-fix

echo "Documentation updated successfully!"
```

### Git Hooks Integration

```bash
# .git/hooks/pre-commit
#!/bin/bash
# Keep docs in sync with code changes

if git diff --cached --name-only | grep -E '\.(js|ts|py|go)$'; then
    echo "Code changes detected, updating documentation..."
    claudux update -q
    git add docs/
fi
```

## Getting Help

For additional help with any command:

- **Built-in help**: `claudux --help`
- **Command-specific help**: Most commands show usage on invalid input
- **Verbose output**: Use `-v` or `-vv` for detailed logging
- **Environment check**: `claudux check` for troubleshooting
- **GitHub issues**: [Report bugs or request features](https://github.com/leojkwan/claudux/issues)

---

<p align="center">
  <strong>Master all Claudux commands for effortless documentation.</strong><br/>
  <a href="/guide/configuration">Learn about configuration →</a> | 
  <a href="/guide/quickstart">Back to Quick Start →</a>
</p>