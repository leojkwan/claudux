[Home](/) > [Development](/development/) > Contributing

# Contributing to Claudux

Thank you for your interest in contributing to Claudux! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be respectful, inclusive, and constructive in all interactions. We're building a tool to help developers, and everyone's contribution is valued.

## Ways to Contribute

### Reporting Issues

Found a bug or have a feature request? [Open an issue](https://github.com/leokwan/claudux/issues):

1. Search existing issues first
2. Use issue templates when available
3. Include:
   - Clear description
   - Steps to reproduce
   - Expected vs actual behavior
   - System information

### Submitting Pull Requests

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**
4. **Test thoroughly**
5. **Commit with conventional commits**: `git commit -m "feat: add amazing feature"`
6. **Push to your fork**: `git push origin feature/amazing-feature`
7. **Open a Pull Request**

### Improving Documentation

Documentation improvements are always welcome:
- Fix typos or clarify instructions
- Add examples
- Improve explanations
- Translate documentation

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/claudux.git
cd claudux

# Add upstream remote
git remote add upstream https://github.com/leokwan/claudux.git

# Install and link
npm link

# Verify setup
claudux version
```

## Development Process

### Before Starting

1. Check existing issues and PRs
2. Discuss major changes in an issue first
3. Keep changes focused and atomic

### While Developing

1. Follow [coding patterns](/technical/patterns)
2. Write clear, commented code
3. Add tests for new features
4. Update documentation

### Before Submitting

Run through this checklist:

- [ ] Code follows style guidelines
- [ ] Tests pass locally
- [ ] Documentation updated
- [ ] Commit messages follow convention
- [ ] Branch is up to date with main

## Testing Requirements

### Run All Tests

```bash
./scripts/test-all.sh
```

### Test Specific Components

```bash
# Test a module
./scripts/test-module.sh project

# Test a command
./scripts/test-command.sh update
```

### Manual Testing

Test on different platforms:
```bash
# macOS
./tests/platform/test-macos.sh

# Linux
./tests/platform/test-linux.sh
```

## Code Style Guidelines

### Bash Conventions

```bash
# Use snake_case
function_name() {
    local variable_name="value"
}

# Constants in UPPER_CASE
readonly CONSTANT_NAME="value"

# Meaningful names
# Good
detect_project_type()
# Bad
dpt()
```

### Error Handling

```bash
# Always handle errors
if ! command; then
    error_exit "Command failed"
fi

# Use error_exit for fatal errors
[[ -f "$file" ]] || error_exit "File not found: $file"
```

### Documentation

```bash
# Document functions
# @description Clear, concise description
# @param $1 - Parameter description
# @return Return value description
function_name() {
    # Implementation
}
```

## Commit Message Guidelines

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, no code change
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

### Examples

```bash
feat(templates): add Django project support

- Add Django detection logic
- Create Django-specific templates
- Include Python documentation patterns

Closes #123
```

```bash
fix(cleanup): preserve protected directories

Protected directories were being deleted during cleanup.
This fix adds additional checks for protected patterns.

Fixes #456
```

## Pull Request Process

1. **Update your fork**:
```bash
git fetch upstream
git checkout main
git merge upstream/main
```

2. **Create PR with clear description**:
- What changes were made
- Why were they necessary
- How were they tested

3. **Respond to feedback**:
- Address review comments
- Update as needed
- Be patient and respectful

4. **After merge**:
- Delete your feature branch
- Update your fork
- Celebrate! 🎉

## Project Structure

Understanding the structure helps you contribute effectively:

```
lib/
├── claude-utils.sh      # AI integration (complex)
├── docs-generation.sh   # Core engine (complex)
├── cleanup.sh          # Cleanup logic (moderate)
├── project.sh          # Detection (moderate)
├── colors.sh           # Utils (simple)
└── ui.sh               # Interface (simple)
```

Start with simpler modules to understand the codebase.

## Adding Features

### New Command Example

Adding a `stats` command:

1. **Add command handler** (`lib/ui.sh`):
```bash
show_stats() {
    local doc_count=$(find docs -name "*.md" | wc -l)
    echo "Documentation files: $doc_count"
}
```

2. **Add to router** (`bin/claudux`):
```bash
"stats")
    show_stats
    ;;
```

3. **Update help** (`lib/ui.sh`):
```bash
echo "  stats         Show documentation statistics"
```

4. **Add tests** (`tests/test-stats.sh`):
```bash
test_stats_command() {
    output=$(claudux stats)
    assert_contains "$output" "Documentation files"
}
```

### New Project Type Example

Adding Svelte support:

1. **Detection** (`lib/project.sh`):
```bash
if [[ -f "svelte.config.js" ]]; then
    echo "svelte"
    return
fi
```

2. **Template** (`lib/templates/svelte-config.json`):
```json
{
  "project": {
    "type": "svelte",
    "name": "Svelte Application"
  }
}
```

3. **Instructions** (`lib/templates/svelte-claude.md`):
```markdown
# Svelte Project

Focus on:
- Component documentation
- Reactive statements
- Stores documentation
```

## Review Process

PRs are reviewed for:

1. **Functionality**: Does it work as intended?
2. **Code Quality**: Is it clean and maintainable?
3. **Testing**: Are there adequate tests?
4. **Documentation**: Is it documented?
5. **Compatibility**: Works on macOS/Linux?

## Getting Help

- **Questions**: Open a [discussion](https://github.com/leokwan/claudux/discussions)
- **Bugs**: Open an [issue](https://github.com/leokwan/claudux/issues)
- **Ideas**: Share in discussions
- **Security**: Email security concerns privately

## Recognition

Contributors are recognized in:
- GitHub contributors list
- Release notes
- Documentation credits

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Thank You!

Your contributions make Claudux better for everyone. Whether it's code, documentation, bug reports, or ideas, every contribution matters.

Happy coding! 🚀