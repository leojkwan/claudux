[Home](/) > [Development](/development/) > Contributing

# Contributing Guidelines

Thank you for your interest in contributing to Claudux! This guide will help you understand our development process and ensure your contributions align with the project's goals.

## Quick Start

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Create a feature branch** from `main`
4. **Make your changes** following our coding standards
5. **Test thoroughly** using our testing checklist
6. **Submit a pull request** with a clear description

## Development Philosophy

Claudux follows the Unix philosophy: **do one thing well, make it modular, and handle errors gracefully**. Our codebase prioritizes:

- **Unix compatibility** over modern convenience
- **Modular architecture** over monolithic design  
- **Semantic content analysis** over simple templating
- **Bash-first implementation** over cross-language solutions

## Code Standards

### Language Requirements

- **ALWAYS write core functionality in Bash** - this is a Bash-first project
- **NEVER introduce Python, Ruby, or other scripting languages** for core features
- **NEVER add npm dependencies** beyond what's in package.json unless absolutely necessary
- **ALWAYS check for command availability** before using (see `lib/project.sh:check_command()`)

### Bash Standards

#### Required Script Headers
```bash
#!/bin/bash
set -u              # Fail on undefined variables
set -o pipefail     # Pipe failures propagate
```

#### Naming Conventions
- **USE snake_case** for all Bash functions and variables
- **DON'T use camelCase** in Bash - always snake_case
- **USE descriptive names** that explain purpose

#### Function Patterns
```bash
# Good: Clear purpose, error handling, local variables
generate_documentation() {
    local project_path="$1"
    local output_dir="$2"
    
    if [[ ! -d "$project_path" ]]; then
        error_exit "Project path does not exist: $project_path"
    fi
    
    log_verbose "Generating docs for $project_path"
    # Implementation...
}
```

#### Error Handling Pattern
```bash
error_exit() {
    print_color "RED" "❌ $1" >&2
    exit "${2:-1}"
}
```

#### Logging Pattern
```bash
log_verbose "Debug information"        # For verbose output  
print_color "GREEN" "✓ Success"        # Success messages
print_color "YELLOW" "⚠️ Warning"      # Warnings
print_color "RED" "❌ Error"           # Error messages
```

### File Organization

#### Module Structure
- **ALWAYS place new library functions in appropriate `lib/*.sh` files**
- **NEVER put business logic in `bin/claudux`** - it's a router only
- **ALWAYS source dependencies using**: `source "$SCRIPT_DIR/../lib/module.sh"`
- **FOLLOW the pattern** in `lib/colors.sh` for new utility modules

#### Path Handling
- **ALWAYS use absolute paths** via `resolve_script_path()`
- **NEVER use relative paths** in sourced files
- **FOLLOW symlink resolution pattern** from `bin/claudux:11-31`
- **USE `mktemp`** for temporary files, not hardcoded paths

### Output Standards

- **DON'T use `echo`** for user output - use `print_color` or `printf`
- **DON'T parse JSON with sed** when jq is available
- **DON'T use global variables** without `readonly` or `local` declaration

## Git Workflow

### Branch Naming

Use descriptive branch names with prefixes:
- `feat/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation only
- `refactor/` - Code restructuring
- `test/` - Test additions/changes
- `chore/` - Maintenance tasks

Examples:
- `feat/add-django-support`
- `fix/cleanup-lock-files`
- `docs/update-api-examples`

### Commit Message Format

Follow [Conventional Commits](https://conventionalcommits.org/):

```
<type>(<scope>): <description>

<optional body>

<optional footer>
```

#### Types
- `feat:` New features
- `fix:` Bug fixes  
- `docs:` Documentation only
- `refactor:` Code restructuring
- `test:` Test additions/changes
- `chore:` Maintenance tasks

#### Examples
```bash
feat(templates): add Django project support

Add Django-specific template and detection logic to support
Django projects with proper app structure recognition.

Closes #42
```

```bash
fix(cleanup): ensure lock file cleanup on all exit paths

Previously lock files could persist if script was interrupted
during certain operations. Added proper trap handling.
```

### Pull Request Process

1. **Create feature branch** from `main`:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feat/your-feature-name
   ```

2. **Make your changes** following our coding standards

3. **Test thoroughly** (see [Testing Guidelines](testing)):
   ```bash
   # Basic functionality
   ./bin/claudux version
   
   # Test with sample project
   claudux update
   
   # Verify VitePress integration
   claudux serve
   
   # Check cleanup safety
   claudux clean --dry-run
   ```

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

5. **Push to your fork**:
   ```bash
   git push origin feat/your-feature-name
   ```

6. **Create pull request** with:
   - Clear title describing the change
   - Detailed description of what was changed and why
   - Reference to related issues
   - Screenshots/examples if applicable

### Pull Request Requirements

Before submitting a PR, ensure:

- [ ] Code follows Bash standards (`set -u`, `set -o pipefail`)
- [ ] Functions use snake_case naming
- [ ] Error handling follows established patterns
- [ ] No business logic in `bin/claudux` 
- [ ] All new functions are in appropriate `lib/*.sh` files
- [ ] Changes work on both macOS and Linux
- [ ] Basic functionality tests pass
- [ ] No new npm dependencies added
- [ ] Commit messages follow conventional format

## Testing Requirements

### Before Every Commit

1. **Basic functionality check:**
   ```bash
   ./bin/claudux version
   ```

2. **Test with a sample project:**
   ```bash
   claudux update
   ```

3. **Verify VitePress serves:**
   ```bash
   claudux serve
   ```

4. **Check cleanup safety:**
   ```bash
   claudux clean --dry-run
   ```

### Cross-Platform Testing

Test on both macOS and Linux to handle:
- **Hash command differences**: `md5` vs `md5sum`
- **sed syntax variations**: `-i` flag behavior
- **Process handling**: Signal trapping differences

### Feature-Specific Testing

When adding features, also verify:
- **Graceful degradation** when optional tools missing (jq, git)
- **Interrupt handling** (Ctrl+C during generation)  
- **Lock file cleanup** on all exit paths
- **Background process cleanup** in trap handlers

## Anti-Patterns to Avoid

### Code Style Anti-Patterns
- **DON'T use camelCase** in Bash - always snake_case
- **DON'T use `echo`** for user output - use `print_color` or `printf`
- **DON'T parse JSON with sed** when jq is available
- **DON'T use global variables** without `readonly` or `local` declaration

### Error Handling Anti-Patterns
- **DON'T silently fail** - always report errors
- **DON'T use `exit` directly** - use `error_exit` function
- **DON'T ignore pipe failures** - always use `set -o pipefail`
- **DON'T assume commands exist** - check with `command -v`

### AI Integration Anti-Patterns
- **DON'T call Claude directly** - use `generate_with_claude()`
- **DON'T exceed context limits** - check file sizes before sending
- **DON'T regenerate unchanged content** - use incremental updates
- **DON'T ignore rate limits** - implement exponential backoff

## Common Contribution Types

### Bug Fixes

1. **Reproduce the issue** in your development environment
2. **Create a failing test** that demonstrates the bug
3. **Fix the issue** following coding standards
4. **Verify the fix** with the test
5. **Test cross-platform** compatibility

### New Features

1. **Discuss the feature** in a GitHub issue first
2. **Follow the appropriate pattern**:
   - [Adding Commands](adding-features#adding-commands)
   - [Adding Project Types](adding-features#adding-project-types)
   - [Modifying AI Prompts](adding-features#modifying-ai-prompts)
3. **Update documentation** as needed
4. **Add tests** for the new functionality

### Documentation Improvements

1. **Focus on clarity** and practical examples
2. **Include breadcrumb navigation** at the top
3. **Reference actual code patterns** from the codebase
4. **Test all code examples** to ensure they work

## Development Environment Setup

### Local Development

```bash
# Clone your fork
git clone https://github.com/yourusername/claudux.git
cd claudux

# Create a test project
mkdir ~/test-project
cd ~/test-project
echo "# Test Project" > README.md

# Test claudux with your test project
/path/to/claudux/bin/claudux update
```

### Environment Variables for Testing

```bash
# Enable verbose output for debugging
export CLAUDUX_VERBOSE=1

# Test with different Claude model
export FORCE_MODEL=sonnet

# Disable colors for cleaner logs
export NO_COLOR=1
```

## Getting Help

- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - Questions and general discussion
- **Code Review** - Pull request feedback and suggestions

## Recognition

Contributors will be recognized in:
- GitHub contributors list
- Release notes for significant contributions
- Project documentation for major features

Thank you for contributing to Claudux! 🚀

---

<p align="center">
  <a href="testing">Next: Testing Guidelines →</a>
</p>