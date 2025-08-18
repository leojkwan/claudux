[Home](/) > [Guide](/guide/) > Quick Start

# Quick Start

Get up and running with Claudux in just a few minutes! This tutorial walks you through generating documentation for your first project.

## Before You Begin

Make sure you have:
- ✅ Node.js ≥ 18.0.0 installed
- ✅ Claude CLI installed and authenticated
- ✅ Claudux installed globally

If not, see the [Installation Guide](/guide/installation).

## Step 1: Navigate to Your Project

Open your terminal and navigate to the project you want to document:

```bash
cd ~/projects/my-awesome-app
```

Claudux works with any codebase:
- JavaScript/TypeScript projects
- React/Next.js applications  
- Python packages
- iOS/Swift apps
- Rust crates
- And more...

## Step 2: Generate Documentation

Run the update command to generate documentation:

```bash
claudux update
```

What happens:
1. **Project Detection**: Claudux identifies your project type
2. **Codebase Analysis**: AI examines your files and structure
3. **Documentation Generation**: Creates comprehensive docs in `docs/` folder
4. **VitePress Setup**: Configures a beautiful documentation site

First run output:
```
🚀 Claudux - AI-Powered Documentation Generator

📝 Generating documentation...
✓ Project type detected: react
✓ Analyzing codebase structure...
✓ Creating documentation plan...
✓ Generating documentation files...
✓ Setting up VitePress configuration...

✅ Documentation generated successfully!
📁 Files created in: ./docs
🚀 Run 'claudux serve' to preview
```

## Step 3: Preview Your Documentation

Start the local development server:

```bash
claudux serve
```

This will:
- Install VitePress dependencies (first time only)
- Start a dev server at `http://localhost:5173`
- Enable hot-reload for documentation changes

Output:
```
🚀 Starting VitePress development server...
✓ Dependencies installed
✓ Server running at http://localhost:5173
Press Ctrl+C to stop
```

Open your browser and visit [http://localhost:5173](http://localhost:5173) to see your documentation!

## Step 4: Explore Your Documentation

Your generated documentation includes:

- **Home Page**: Project overview and quick links
- **Guide Section**: Installation, configuration, usage
- **API Reference**: Functions, classes, interfaces
- **Architecture**: System design and patterns
- **Examples**: Code samples and tutorials

Navigate through the sidebar to explore all sections.

## Step 5: Customize (Optional)

### Add Project Configuration

Create `docs-ai-config.json` in your project root:

```json
{
  "projectName": "My Awesome App",
  "primaryLanguage": "typescript",
  "frameworks": ["react", "tailwind"],
  "features": {
    "apiDocs": true,
    "tutorials": true,
    "examples": true
  }
}
```

### Add AI Instructions

Create `CLAUDE.md` for project-specific patterns:

```markdown
# Project Instructions for Claude

## Code Style
- Use functional components with hooks
- Follow Airbnb style guide
- Document all public APIs

## Documentation Style
- Keep examples practical
- Include TypeScript types
- Add runnable code samples
```

Run `claudux update` again to apply customizations.

## Common Workflows

### Update After Code Changes

When you modify your code, update the docs:

```bash
claudux update
```

Claudux intelligently:
- Detects what changed
- Updates relevant sections
- Preserves custom content
- Removes obsolete docs

### Clean Obsolete Files

Remove outdated documentation:

```bash
claudux clean
```

This uses semantic analysis to identify truly obsolete content.

### Validate Links

Check for broken links:

```bash
claudux validate
```

Auto-fix broken links:

```bash
claudux repair
```

### Start Fresh

Recreate documentation from scratch:

```bash
claudux recreate
```

## Interactive Mode

Run without arguments for an interactive menu:

```bash
claudux
```

Menu options:
```
🚀 Claudux - AI-Powered Documentation Generator

What would you like to do?

1) Generate/Update Documentation
2) Serve Documentation Locally  
3) Clean Obsolete Files
4) Validate Links
5) Create CLAUDE.md Template
6) Exit
```

## Example Projects

### React Application

```bash
cd my-react-app
claudux update
claudux serve
```

Generated structure:
```
docs/
├── guide/
│   ├── getting-started.md
│   ├── components.md
│   └── state-management.md
├── api/
│   ├── hooks.md
│   └── components.md
└── examples/
    └── common-patterns.md
```

### Python Package

```bash
cd my-python-lib
claudux update
claudux serve
```

Generated structure:
```
docs/
├── guide/
│   ├── installation.md
│   └── usage.md
├── api/
│   ├── modules.md
│   └── classes.md
└── examples/
    └── tutorials.md
```

## Tips for Best Results

1. **Clean Codebase**: Ensure your code is committed and organized
2. **Add Comments**: Well-commented code produces better documentation
3. **Use Types**: TypeScript/Python type hints improve API docs
4. **Review Output**: AI-generated content benefits from human review
5. **Iterate**: Run `claudux update` regularly to keep docs current

## Deployment

Your `docs/` folder is ready for static hosting:

### GitHub Pages
```bash
# In your repository settings, set GitHub Pages source to /docs folder
git add docs/
git commit -m "Add documentation"
git push
```

### Netlify
```bash
# Drop your docs/ folder into Netlify
# Or connect your repository
```

### Vercel
```bash
# Deploy with Vercel CLI
vercel docs/
```

### Custom Server
```bash
# Build for production
cd docs
npm run build
# Serve dist/ folder
```

## Next Steps

Congratulations! You've successfully generated documentation with Claudux.

Learn more about:
- [All Commands](/guide/commands) - Complete command reference
- [Configuration](/guide/configuration) - Customization options
- [Two-Phase Generation](/features/two-phase-generation) - How it works
- [API Reference](/api/) - Library functions

## Getting Help

- Run `claudux help` for command help
- Check [FAQ](/faq) for common questions
- Visit [Troubleshooting](/troubleshooting) for solutions
- Report issues on [GitHub](https://github.com/leokwan/claudux/issues)