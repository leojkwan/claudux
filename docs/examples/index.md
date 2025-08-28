[Home](/) > Examples

# Examples & Use Cases

Welcome to the Claudux examples section! Here you'll find practical, real-world examples of how to use Claudux to generate AI-powered documentation for different types of projects.

## What You'll Find Here

This section provides hands-on examples covering:

- **[Basic Setup →](basic-setup.md)** - First-time setup and configuration for common project types
- **[Advanced Usage →](advanced-usage.md)** - Advanced patterns, customization, and workflow integration

## Quick Reference

### Basic Commands
```bash
# Interactive menu
claudux

# Generate/update documentation
claudux update

# Serve documentation locally
claudux serve

# Start completely fresh
claudux recreate
```

### Common Patterns
```bash
# Focused updates with specific guidance
claudux update -m "Document the authentication system"

# Check environment and dependencies
claudux check

# Create project-specific AI context file
claudux create-template
```

## Example Project Types

Claudux automatically detects and optimizes for different project types:

### JavaScript/Node.js Projects
- **React Apps** - Component documentation, props, hooks
- **Next.js Apps** - Pages, API routes, app router
- **Express APIs** - Endpoints, middleware, authentication
- **npm Libraries** - API reference, usage examples

### Mobile Development
- **iOS Apps** - Swift code, architecture, UI components
- **React Native** - Cross-platform components and navigation

### Other Languages
- **Python** - Django, Flask, FastAPI projects  
- **Rust** - Cargo projects, crates documentation
- **Go** - Modules, packages, CLI tools
- **Java** - Maven/Gradle projects, Spring Boot

## Documentation Patterns

### Generated Structure
```
docs/
├── index.md              # Project overview
├── guide/
│   ├── index.md          # Getting started
│   ├── installation.md   # Setup instructions
│   └── quickstart.md     # Quick tutorial
├── api/
│   ├── index.md          # API overview
│   └── reference.md      # Detailed documentation
├── examples/
│   ├── index.md          # Examples overview
│   └── basic-usage.md    # Usage examples
└── .vitepress/
    └── config.ts         # Navigation configuration
```

### Content Features
- **Automatic breadcrumbs** - Navigation between pages
- **Cross-references** - Links between related content
- **Code examples** - Extracted from your actual code
- **Search functionality** - Full-text search across all docs
- **Mobile-responsive** - Works on all devices

## Best Practices

### 1. Start Simple
Begin with basic generation, then refine with focused updates:

```bash
# Initial generation
claudux update

# Then focus on specific areas
claudux update -m "Add detailed API examples"
```

### 2. Use Project Context
Create a `CLAUDE.md` file for better results:

```bash
claudux create-template
```

This helps Claude understand your:
- Coding conventions
- Architecture patterns
- Project-specific terminology
- Important implementation details

### 3. Regular Updates
Keep documentation synchronized with code:

```bash
# After feature development
claudux update -m "Document the new user dashboard"

# Before releases
claudux update -m "Ensure all features are documented"
```

## Workflow Integration

### Git Workflow
```bash
# 1. Develop feature
git checkout -b feature/new-api

# 2. Update docs as you develop
claudux update -m "Document new API endpoints"

# 3. Review and commit together
git add . && git commit -m "Add new API with documentation"
```

### CI/CD Integration
```bash
# In your CI pipeline
- name: Update Documentation
  run: |
    npm install -g claudux
    claudux update --force-model sonnet
    git add docs/
    git commit -m "Update documentation [skip ci]" || true
```

## Environment Variables

Control Claudux behavior with environment variables:

```bash
# Use different Claude model
FORCE_MODEL=sonnet claudux update

# Enable verbose logging
CLAUDUX_VERBOSE=1 claudux update

# Default message for updates
CLAUDUX_MESSAGE="Focus on API documentation" claudux update
```

## Getting Help

### Built-in Help
```bash
claudux --help          # Full help
claudux check           # Environment check
claudux -v update       # Verbose mode
```

### Troubleshooting

**Documentation seems generic?**
- Create `CLAUDE.md` with project context
- Use focused updates with `-m` flag

**Server won't start?**
- Check if ports 5173-5190 are available
- Try `claudux clean && claudux serve`

**Links are broken?**  
- Claudux validates links automatically
- Check update output for validation results

## Next Steps

Ready to dive deeper? Check out our detailed examples:

- **[Basic Setup Examples →](basic-setup.md)** - Step-by-step setup for different project types
- **[Advanced Usage Examples →](advanced-usage.md)** - Power user techniques and workflows

---

<p align="center">
  <strong>Ready to see Claudux in action?</strong><br/>
  <a href="basic-setup.md">Start with basic setup →</a> | 
  <a href="advanced-usage.md">Jump to advanced usage →</a>
</p>