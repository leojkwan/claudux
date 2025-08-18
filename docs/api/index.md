[Home](/) > API

# API Reference

Complete reference documentation for Claudux CLI commands and library functions.

## CLI Commands

The Claudux CLI provides commands for documentation generation, management, and serving.

### Core Commands

| Command | Description |
|---------|-------------|
| [`update`](/api/cli#update) | Generate or update documentation |
| [`serve`](/api/cli#serve) | Start local preview server |
| [`clean`](/api/cli#clean) | Remove obsolete documentation |
| [`recreate`](/api/cli#recreate) | Delete and regenerate all docs |
| [`validate`](/api/cli#validate) | Check for broken links |
| [`repair`](/api/cli#repair) | Fix broken links automatically |
| [`template`](/api/cli#template) | Generate CLAUDE.md template |

### Utility Commands

| Command | Description |
|---------|-------------|
| [`check`](/api/cli#check) | Verify environment setup |
| [`version`](/api/cli#version) | Display version information |
| [`help`](/api/cli#help) | Show help information |

[Full CLI Reference →](/api/cli)

## Library Functions

Claudux is built with modular Bash libraries that can be sourced and used in custom scripts.

### Core Modules

| Module | Purpose |
|--------|---------|
| [`colors.sh`](/api/library#colors) | Terminal color output |
| [`project.sh`](/api/library#project) | Project detection and configuration |
| [`claude-utils.sh`](/api/library#claude-utils) | Claude AI integration |
| [`docs-generation.sh`](/api/library#docs-generation) | Documentation generation |
| [`cleanup.sh`](/api/library#cleanup) | Obsolete file cleanup |
| [`content-protection.sh`](/api/library#content-protection) | Content protection logic |
| [`server.sh`](/api/library#server) | Development server management |
| [`ui.sh`](/api/library#ui) | User interface and menus |
| [`validate-links.sh`](/api/library#validate-links) | Link validation |
| [`git-utils.sh`](/api/library#git-utils) | Git integration |

[Full Library Reference →](/api/library)

## Environment Variables

Configure Claudux behavior through environment variables:

| Variable | Type | Description |
|----------|------|-------------|
| `CLAUDUX_VERBOSE` | 0-2 | Output verbosity level |
| `FORCE_MODEL` | string | Override Claude model |
| `NO_COLOR` | 1 | Disable colored output |
| `CLAUDE_TIMEOUT` | number | Request timeout in seconds |
| `CLAUDUX_CLEANUP_THRESHOLD` | 0.0-1.0 | Obsolescence confidence |

## Exit Codes

Claudux uses standard exit codes for scripting:

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | General error |
| `2` | Missing dependencies |
| `3` | Authentication error |
| `4` | File system error |
| `5` | Network error |
| `130` | Interrupted (Ctrl+C) |

## Configuration Files

### docs-ai-config.json

Project-specific configuration:

```json
{
  "projectName": "string",
  "projectType": "string",
  "primaryLanguage": "string",
  "frameworks": ["string"],
  "features": {
    "apiDocs": "boolean",
    "tutorials": "boolean",
    "examples": "boolean"
  }
}
```

### CLAUDE.md

AI assistant instructions for project-specific patterns and conventions.

### .clauduxignore

Protection patterns using gitignore syntax:

```gitignore
# Protected directories
internal/
private/

# Protected files
*-manual.md
CHANGELOG.md
```

## Integration

### Bash Scripts

Source Claudux libraries in your scripts:

```bash
#!/bin/bash
source "$(npm root -g)/claudux/lib/colors.sh"
source "$(npm root -g)/claudux/lib/project.sh"

# Use functions
print_color "GREEN" "✓ Success"
project_type=$(detect_project_type)
```

### CI/CD

Integrate with continuous integration:

```yaml
# GitHub Actions
- run: |
    npm install -g claudux
    claudux update --force-model sonnet
```

### Node.js

Call Claudux from Node.js:

```javascript
const { exec } = require('child_process');

exec('claudux update', (error, stdout, stderr) => {
  if (error) {
    console.error(`Error: ${error}`);
    return;
  }
  console.log(stdout);
});
```

## Advanced Usage

### Custom Templates

Create project-specific templates:

```bash
lib/templates/
├── myproject-claudux.md
├── myproject-config.json
└── myproject/
    └── sidebar.json
```

### Hooks

Add pre/post hooks for commands:

```bash
# pre-update.sh
#!/bin/bash
echo "Preparing for update..."
git stash

# post-update.sh
#!/bin/bash
echo "Update complete"
git add docs/
git commit -m "Update documentation"
```

### Parallel Execution

Safe for parallel execution:

```bash
# Different projects
(cd project1 && claudux update) &
(cd project2 && claudux update) &
wait
```

## API Stability

### Stable APIs

These interfaces are stable and safe to depend on:
- CLI commands and their options
- Environment variables
- Configuration file formats
- Exit codes

### Unstable APIs

These may change between versions:
- Library function signatures
- Internal file formats
- Template structures

## Version Compatibility

| Claudux Version | Node.js | Claude CLI |
|-----------------|---------|------------|
| 1.0.x | ≥18.0.0 | ≥1.0.0 |
| 0.9.x | ≥16.0.0 | ≥0.9.0 |

## Getting Help

- View built-in help: `claudux help [command]`
- Read guides: [User Guide](/guide/)
- Check examples: [Examples](/examples/)
- Report issues: [GitHub Issues](https://github.com/leokwan/claudux/issues)