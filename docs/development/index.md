[Home](/) > Development

# Development Guide

Welcome to the Claudux development guide. This section covers everything you need to contribute to Claudux.

## Getting Started

### Prerequisites

- Bash 4.0+
- Node.js 18+
- Git
- Claude CLI (for testing)

### Setup Development Environment

```bash
# Clone the repository
git clone https://github.com/leokwan/claudux.git
cd claudux

# Link for local development
npm link

# Verify installation
claudux version
```

## Project Structure

```
claudux/
├── bin/
│   └── claudux              # Main entry point
├── lib/
│   ├── *.sh                 # Library modules
│   ├── templates/           # Project templates
│   └── vitepress/           # VitePress configuration
├── docs/                    # Documentation (generated)
├── examples/                # Example projects
├── scripts/                 # Development scripts
└── tests/                   # Test files
```

## Development Workflow

### 1. Create Feature Branch

```bash
git checkout -b feature/your-feature
```

### 2. Make Changes

Follow the [coding patterns](/technical/patterns):
- Use snake_case for functions
- Add error handling
- Include documentation

### 3. Test Locally

```bash
# Test with example project
cd examples/basic-js-app
claudux update

# Run specific command
claudux validate --external
```

### 4. Run Tests

```bash
# Run test suite
./scripts/test.sh

# Test specific module
./scripts/test-module.sh colors
```

### 5. Submit Pull Request

```bash
git add .
git commit -m "feat: add new feature"
git push origin feature/your-feature
```

## Key Development Tasks

### Adding a New Command

1. **Update bin/claudux**:
```bash
# Add case in main() function
"new-command")
    check_function "new_command_handler"
    new_command_handler "$@"
    ;;
```

2. **Create handler function**:
```bash
# In appropriate lib/*.sh file
new_command_handler() {
    local option="$1"
    # Implementation
}
```

3. **Update help text**:
```bash
# In lib/ui.sh:show_help()
echo "  new-command    Description of command"
```

4. **Add to menu** (if user-facing):
```bash
# In lib/ui.sh:show_menu()
echo "7) New Command"
```

### Adding Project Type Support

1. **Create detection logic**:
```bash
# In lib/project.sh:detect_project_type()
if [[ -f "specific-file.ext" ]]; then
    echo "new-type"
    return
fi
```

2. **Create template configuration**:
```json
// lib/templates/new-type-config.json
{
  "project": {
    "type": "new-type",
    "name": "New Type Project"
  }
}
```

3. **Create AI instructions**:
```markdown
<!-- lib/templates/new-type-claude.md -->
# New Type Project Instructions

Focus on:
- Specific patterns
- Framework conventions
- Documentation style
```

4. **Test detection**:
```bash
cd test-project
claudux check  # Should show "new-type"
```

### Modifying AI Prompts

1. **Locate prompt building**:
```bash
# lib/docs-generation.sh:build_generation_prompt()
```

2. **Modify prompt structure**:
```bash
cat <<EOF
Your new prompt instructions here
EOF
```

3. **Test generation**:
```bash
claudux update --force-model sonnet
```

## Testing

### Unit Tests

Located in `tests/`:

```bash
tests/
├── test-colors.sh
├── test-project.sh
├── test-protection.sh
└── test-utils.sh
```

Run tests:
```bash
./tests/run-all.sh
```

### Integration Tests

Test full workflows:

```bash
# Test generation
./tests/integration/test-generation.sh

# Test cleanup
./tests/integration/test-cleanup.sh
```

### Manual Testing Checklist

Before submitting PR:

- [ ] Test on macOS
- [ ] Test on Linux
- [ ] Test with different project types
- [ ] Test error conditions
- [ ] Test cleanup safety
- [ ] Verify no broken links

## Debugging

### Enable Debug Output

```bash
# Maximum verbosity
CLAUDUX_VERBOSE=2 claudux update -vv

# Trace execution
bash -x $(which claudux) update
```

### Common Issues

**Lock file stuck:**
```bash
rm /tmp/claudux-*.lock
```

**Module not loading:**
```bash
# Check module exists
ls -la lib/module.sh

# Test sourcing
source lib/module.sh
```

**Command not found:**
```bash
# Check function exists
declare -F function_name
```

## Code Style

### Bash Style Guide

Follow these conventions:

```bash
# Good function
detect_project_type() {
    local project_root="${1:-.}"
    
    if [[ -f "$project_root/package.json" ]]; then
        echo "javascript"
        return 0
    fi
    
    echo "unknown"
    return 1
}

# Bad function
DetectProjectType() {
    if [ -f package.json ]; then
        echo javascript
    fi
}
```

### Documentation Comments

```bash
# @description Detect project type
# @param $1 - Project root directory
# @return Project type string
# @example type=$(detect_project_type "/path/to/project")
detect_project_type() {
    # Implementation
}
```

## Contributing Guidelines

### Commit Messages

Follow conventional commits:

```
feat: add new feature
fix: resolve bug
docs: update documentation
refactor: restructure code
test: add tests
chore: maintenance tasks
```

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] Refactoring

## Testing
- [ ] Tested on macOS
- [ ] Tested on Linux
- [ ] Added tests

## Checklist
- [ ] Follows code style
- [ ] Includes documentation
- [ ] No broken functionality
```

## Release Process

### Version Bumping

```bash
# Update version in package.json
npm version patch  # or minor, major

# Tag release
git tag v1.0.1
git push --tags
```

### Release Checklist

1. [ ] All tests passing
2. [ ] Documentation updated
3. [ ] CHANGELOG updated
4. [ ] Version bumped
5. [ ] Tag created
6. [ ] NPM published

## Resources

### Documentation

- [Architecture](/technical/) - System design
- [Patterns](/technical/patterns) - Coding patterns
- [Modules](/technical/modules) - Module details
- [API Reference](/api/) - Complete API

### External Resources

- [Bash Manual](https://www.gnu.org/software/bash/manual/)
- [ShellCheck](https://www.shellcheck.net/) - Script analysis
- [Claude Documentation](https://docs.anthropic.com/)
- [VitePress Guide](https://vitepress.dev/)

## Getting Help

- Open an [issue](https://github.com/leokwan/claudux/issues)
- Start a [discussion](https://github.com/leokwan/claudux/discussions)
- Check [FAQ](/faq)

## Next Steps

- [Contributing](/development/contributing) - Contribution process
- [Testing](/development/testing) - Testing guide
- [Adding Features](/development/adding-features) - Feature development