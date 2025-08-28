[Home](/) > [Guide](/guide/) > Quick Start

# Quick Start Tutorial

Get up and running with Claudux in under 5 minutes. This tutorial will guide you through generating your first AI-powered documentation.

## Before You Begin

Ensure you have completed the [Installation Guide](/guide/installation) and have:

- ✅ Node.js 18+ installed
- ✅ Claude CLI installed and configured (`npm install -g @anthropic-ai/claude-code`)
- ✅ Claudux installed (`npm install -g claudux@latest` or `npx claudux`)

## Step 1: Navigate to Your Project

Claudux works with any codebase. For this tutorial, we'll use an example project:

```bash
# Navigate to your existing project
cd ~/projects/my-app

# Or create a new sample project
mkdir my-sample-project
cd my-sample-project

# Initialize with some basic files
npm init -y
echo "# My Sample Project" > README.md
echo "A sample application for testing Claudux" >> README.md

mkdir src
echo 'console.log("Hello, world!");' > src/index.js
echo 'export const VERSION = "1.0.0";' > src/constants.js
```

## Step 2: Run Environment Check

Before generating documentation, verify your setup:

```bash
claudux check
```

You should see output similar to:
```
📚 claudux - My Sample Project Documentation
Powered by Claude AI - Everything stays local

🔎 Environment check

• Node: v18.17.0
• Claude: claude-code 0.8.0  
  Model: claude-3-5-sonnet-20241022
• docs/: not present (will be created on first run)
```

If there are any issues, refer back to the [Installation Guide](/guide/installation).

## Step 3: Generate Documentation

Now for the magic! Generate documentation from your codebase:

```bash
claudux update
```

### What Happens During Generation

Claudux follows a sophisticated two-phase process:

**Phase 1: Analysis & Planning** (15-30 seconds)
- 🔍 Analyzes your entire codebase
- 📊 Detects project type (Node.js, React, iOS, etc.)
- 📋 Plans documentation structure
- 🧹 Identifies any obsolete content

**Phase 2: Content Generation** (30-60 seconds) 
- ✍️ Generates markdown files
- 🔗 Creates proper cross-references
- ✅ Validates all links
- 🎨 Sets up VitePress configuration

### Sample Output

```bash
$ claudux update
📚 claudux - My Sample Project Documentation
Powered by Claude AI - Everything stays local

🔍 Environment check
• Node: v18.17.0  
• Claude: claude-code 0.8.0
• docs/: not present (will be created on first run)

📊 Starting documentation update and cleanup...

🧹 Step 1: Cleaning obsolete files...
No existing documentation to clean.

🤖 Step 2: Running two-phase documentation generation...
📊 Phase 1: Comprehensive analysis and planning
✏️  Phase 2: Executing the plan and generating docs

🤖 Claude analyzing project and generating documentation...
🧠 Using Claude Opus (most powerful)
🔧 Tools: Read, Write, Edit, Delete | Auto-accept mode
🚀 Two-phase generation in single session
💰 Estimated cost: ~$0.05 per run
⏳ This may take 60-120 seconds with Opus...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Claude analyzes your code and generates documentation]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Documentation generation complete!
📁 Created docs/ directory with 8 files
🔗 All links validated successfully
📖 VitePress configuration ready

Next: Run 'claudux serve' to preview your docs
```

## Step 4: Preview Your Documentation

Start the local development server to view your generated docs:

```bash
claudux serve
```

This will:
1. Install VitePress dependencies (first time only)
2. Start the development server
3. Open your documentation at http://localhost:5173

### What You'll See

Your generated documentation site includes:

- **Homepage** - Project overview and navigation
- **Getting Started** - Installation and setup
- **API Reference** - Code documentation
- **Examples** - Usage examples from your code
- **Technical Docs** - Architecture overview

### Navigation Features

- 🔍 **Full-text search** - Find any content instantly
- 📱 **Mobile-friendly** - Responsive design
- 🌙 **Dark mode** - Toggle light/dark themes
- 🔗 **Valid links** - All cross-references work
- 📝 **Edit links** - Direct GitHub editing

## Step 5: Understanding Your Generated Files

Claudux creates several files and directories:

```
your-project/
├── docs/
│   ├── index.md              # Homepage
│   ├── guide/
│   │   ├── index.md          # Getting started
│   │   ├── installation.md   # Setup instructions
│   │   └── quickstart.md     # Quick start
│   ├── api/
│   │   ├── index.md          # API overview
│   │   └── reference.md      # Detailed API docs
│   ├── examples/
│   │   ├── index.md          # Examples overview
│   │   └── basic-usage.md    # Usage examples
│   ├── .vitepress/
│   │   └── config.ts         # VitePress configuration
│   ├── package.json          # Docs dependencies
│   └── package-lock.json
└── docs-ai-config.json       # Claudux configuration (optional)
```

### Key Files Explained

- **`docs/index.md`** - Main homepage with project overview
- **`docs/.vitepress/config.ts`** - VitePress configuration with navigation
- **`docs-ai-config.json`** - Claudux settings (auto-generated)

## Step 6: Making Updates

As you develop your project, keep documentation in sync:

### Regular Updates
```bash
# Update docs after making code changes
claudux update
```

### Focused Updates
```bash
# Update with specific guidance
claudux update -m "Focus on the new API endpoints"
claudux update -m "Add examples for the authentication flow"
claudux update -m "Document the configuration options"
```

### Starting Fresh
```bash
# Delete all docs and regenerate
claudux recreate
```

## Interactive Mode

For a guided experience, run Claudux without arguments:

```bash
claudux
```

This launches an interactive menu:

```
📚 claudux - My Sample Project Documentation
Powered by Claude AI - Everything stays local

Select:

  1) Generate docs              (scan code → markdown)
  2) Serve                      (vitepress dev server)  
  3) Create CLAUDE.md           (AI context file)
  4) Exit

> 
```

Perfect for beginners or occasional users!

## Common Workflow Patterns

### Using npx (No Installation Required)

If you prefer not to install Claudux globally, you can use npx:

```bash
# Generate documentation without installing
npx claudux@latest update

# Serve documentation
npx claudux@latest serve

# Run interactively
npx claudux@latest
```

This is perfect for:
- One-time documentation generation
- CI/CD pipelines
- Trying Claudux without commitment
- Ensuring you always use the latest version

### Development Workflow
```bash
# 1. Make code changes
git add . && git commit -m "Add new feature"

# 2. Update documentation
claudux update  # or: npx claudux@latest update

# 3. Review changes
claudux serve  # Check at http://localhost:5173

# 4. Commit documentation
git add docs/ && git commit -m "Update documentation"
```

### Release Workflow
```bash
# Before a release, ensure docs are comprehensive
claudux update -m "Create comprehensive release documentation"

# Build static site for deployment (if needed)
cd docs && npm run docs:build
```

### Team Onboarding
```bash
# Generate detailed onboarding docs
claudux update -m "Create detailed developer onboarding guide"
```

## Understanding the Output

### Two-Phase Process

**Phase 1: Analysis**
- Reads your entire codebase
- Detects frameworks and patterns  
- Plans the documentation structure
- Creates VitePress navigation

**Phase 2: Generation**
- Writes markdown content
- Extracts code examples
- Creates cross-references
- Validates all links

### Quality Indicators

✅ **Good Signs:**
- "All links validated successfully"
- "VitePress configuration ready"
- Multiple sections generated
- Code examples included

⚠️ **Watch For:**
- Link validation warnings
- Missing sections
- Generic content (may need focused updates)

## Customization Hints

### Project-Specific Context

Generate a `CLAUDE.md` file for better results:

```bash
claudux create-template
```

This creates project-specific context that helps Claude understand:
- Your coding conventions
- Architecture patterns
- Important implementation details
- Project-specific terminology

### Configuration File

Customize via `claudux.json`:

```json
{
  "project": {
    "name": "My Sample Project",
    "type": "nodejs"
  }
}
```

## Next Steps

Now that you have working documentation:

1. **[Command Reference →](/guide/commands)** - Learn all available commands and options
2. **[Configuration Guide →](/guide/configuration)** - Customize Claudux for your needs  
3. **[Features Overview →](/features/)** - Explore advanced features
4. **[Examples →](/examples/)** - See real-world usage patterns

## Tips for Success

### 1. Keep Code Organized
Well-structured projects generate better documentation:
- Clear directory hierarchy
- Meaningful file names
- Consistent coding patterns

### 2. Use Focused Updates
Guide Claude with specific directives:
```bash
claudux update -m "Document the authentication system"
claudux update -m "Add deployment instructions" 
claudux update -m "Create API usage examples"
```

### 3. Regular Maintenance
Run updates regularly:
- After major features
- Before releases  
- When onboarding team members

### 4. Content Protection
Claudux protects important directories automatically:
- `notes/`, `private/`, `secret/`
- `.git/`, `node_modules/`
- Files matching `.gitignore` patterns

## Troubleshooting

### Common Issues

**Documentation seems generic?**
```bash
# Create project context file
claudux create-template

# Then update with context
claudux update
```

**Server won't start?**
```bash
# Check if port is in use
claudux serve  # Auto-selects ports 5173-5190

# Or clean and retry
claudux clean && claudux update
```

**Links are broken?**
```bash
# Claudux validates links automatically
# Check the update output for validation results
```

**Need more verbose output?**
```bash
# Enable verbose logging
CLAUDUX_VERBOSE=1 claudux update
# or
claudux -v update
```

## Getting Help

- **Built-in Help**: `claudux --help`
- **Environment Check**: `claudux check`
- **Verbose Mode**: `claudux -v update`
- **GitHub Issues**: [Report bugs](https://github.com/leojkwan/claudux/issues)

---

<p align="center">
  <strong>Congratulations! You've generated your first AI-powered documentation.</strong><br/>
  <a href="/guide/commands">Learn about all commands →</a> | 
  <a href="/guide/configuration">Customize your setup →</a>
</p>