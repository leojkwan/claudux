[Home](/) > [Development](/development/) > Testing

# Testing Guide

Comprehensive testing ensures Claudux remains reliable across platforms and use cases.

## Test Structure

```
tests/
├── unit/               # Unit tests for individual functions
├── integration/        # End-to-end workflow tests
├── platform/          # Platform-specific tests
├── fixtures/          # Test projects and data
└── run-all.sh        # Master test runner
```

## Running Tests

### Run All Tests

```bash
./tests/run-all.sh
```

### Run Specific Test Suites

```bash
# Unit tests only
./tests/unit/run-unit-tests.sh

# Integration tests
./tests/integration/run-integration-tests.sh

# Platform tests
./tests/platform/test-macos.sh
./tests/platform/test-linux.sh
```

### Run Individual Tests

```bash
# Test specific module
./tests/unit/test-project.sh

# Test specific command
./tests/integration/test-update-command.sh
```

## Writing Tests

### Unit Test Structure

```bash
#!/bin/bash
# tests/unit/test-example.sh

# Test setup
source "$(dirname "$0")/../../lib/colors.sh"
source "$(dirname "$0")/../test-helpers.sh"

# Test function
test_print_color() {
    local description="print_color outputs colored text"
    local output=$(print_color "GREEN" "test")
    
    assert_contains "$output" "test"
    assert_contains "$output" "\033[0;32m"
}

# Run tests
run_test test_print_color

# Report results
report_test_results
```

### Integration Test Example

```bash
#!/bin/bash
# tests/integration/test-generation.sh

test_full_generation() {
    # Setup test project
    setup_test_project "react"
    
    # Run generation
    claudux update --force-model haiku
    
    # Verify results
    assert_directory_exists "docs"
    assert_file_exists "docs/.vitepress/config.ts"
    assert_file_contains "docs/index.md" "# Documentation"
    
    # Cleanup
    cleanup_test_project
}
```

## Test Helpers

### Assertion Functions

```bash
# Check equality
assert_equals "expected" "$actual"

# Check contains
assert_contains "$haystack" "needle"

# Check file/directory
assert_file_exists "path/to/file"
assert_directory_exists "path/to/dir"

# Check file contents
assert_file_contains "file.txt" "content"

# Check command success
assert_success command
assert_failure command
```

### Setup Functions

```bash
# Create test project
setup_test_project() {
    local type="$1"
    mkdir -p test-project
    cd test-project
    
    case "$type" in
        react)
            echo '{"dependencies":{"react":"^18.0.0"}}' > package.json
            ;;
        python)
            touch setup.py
            ;;
    esac
}

# Cleanup
cleanup_test_project() {
    cd ..
    rm -rf test-project
}
```

## Test Coverage Areas

### Core Functionality

- [ ] Project detection
- [ ] Documentation generation
- [ ] Cleanup logic
- [ ] Link validation
- [ ] Content protection
- [ ] VitePress setup

### Commands

Test each command with various options:

```bash
# Update command
claudux update
claudux update -m "message"
claudux update --force-model opus
claudux update -v

# Clean command
claudux clean
claudux clean --dry-run
claudux clean --threshold 0.9
```

### Error Conditions

```bash
# Missing dependencies
test_missing_claude_cli() {
    PATH="/usr/bin" claudux update
    assert_failure
}

# Invalid project
test_empty_directory() {
    cd $(mktemp -d)
    claudux update
    assert_contains "$(cat docs/index.md)" "generic"
}
```

### Platform Compatibility

```bash
# macOS specific
test_macos_md5() {
    local result=$(echo "test" | md5)
    assert_not_empty "$result"
}

# Linux specific
test_linux_md5sum() {
    local result=$(echo "test" | md5sum)
    assert_not_empty "$result"
}
```

## Continuous Integration

### GitHub Actions Test Workflow

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        node: [18, 20]
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node }}
      
      - name: Install Claudux
        run: npm install -g .
      
      - name: Run Tests
        run: ./tests/run-all.sh
      
      - name: Upload Coverage
        uses: codecov/codecov-action@v3
```

## Manual Testing Checklist

Before releases, manually test:

### Installation

- [ ] npm install -g claudux
- [ ] npm install -g github:leokwan/claudux
- [ ] npm link (development)

### Basic Commands

- [ ] claudux (interactive menu)
- [ ] claudux update
- [ ] claudux serve
- [ ] claudux clean
- [ ] claudux validate

### Project Types

- [ ] React project
- [ ] Next.js project
- [ ] Python package
- [ ] Generic project

### Features

- [ ] Two-phase generation
- [ ] Content protection
- [ ] Link validation
- [ ] Smart cleanup
- [ ] VitePress setup

### Error Handling

- [ ] Missing Claude CLI
- [ ] No authentication
- [ ] Empty directory
- [ ] Large codebase
- [ ] Network errors

## Performance Testing

### Benchmark Tests

```bash
# Time generation
time claudux update

# Memory usage
/usr/bin/time -l claudux update  # macOS
/usr/bin/time -v claudux update  # Linux

# Profile execution
bash -x claudux update 2>&1 | grep "^+"
```

### Load Testing

```bash
# Large codebase
test_large_project() {
    # Create 1000 files
    for i in {1..1000}; do
        echo "content" > "file$i.js"
    done
    
    time claudux update
    assert_success
}
```

## Test Fixtures

### Sample Projects

```
tests/fixtures/
├── react-app/
│   ├── package.json
│   ├── src/
│   └── public/
├── python-lib/
│   ├── setup.py
│   └── src/
└── generic/
    └── index.js
```

### Mock Responses

```bash
# Mock Claude API response
mock_claude_response() {
    cat <<EOF
# Documentation

Generated documentation content here.
EOF
}
```

## Debugging Tests

### Verbose Test Output

```bash
# Enable debug output
DEBUG=1 ./tests/run-all.sh

# Trace execution
bash -x ./tests/unit/test-project.sh
```

### Test Isolation

```bash
# Run test in isolation
(
    cd $(mktemp -d)
    source /path/to/test.sh
    test_function
)
```

## Test Best Practices

### 1. Keep Tests Fast

```bash
# Use minimal fixtures
# Mock external calls
# Run in parallel when possible
```

### 2. Make Tests Deterministic

```bash
# Set fixed timestamps
export TEST_DATE="2024-01-01"

# Use consistent random seeds
export RANDOM=42
```

### 3. Clean Up After Tests

```bash
trap cleanup EXIT

cleanup() {
    rm -rf test-*
    unset TEST_VARS
}
```

### 4. Test Edge Cases

```bash
# Empty input
test_empty_input() {
    result=$(function "")
    assert_failure
}

# Large input
test_large_input() {
    input=$(seq 1 10000)
    result=$(function "$input")
    assert_success
}
```

## Coverage Reporting

### Generate Coverage Report

```bash
# Run with coverage
./tests/coverage.sh

# View report
open coverage/index.html
```

### Coverage Goals

- Unit tests: 80% coverage
- Integration tests: 60% coverage
- Overall: 70% coverage

## Contributing Tests

When adding features:

1. Write tests first (TDD)
2. Ensure tests pass
3. Add integration tests
4. Update test documentation

Example PR with tests:

```bash
git add lib/new-feature.sh
git add tests/unit/test-new-feature.sh
git add tests/integration/test-new-feature-workflow.sh
git commit -m "feat: add new feature with tests"
```

## Test Maintenance

### Regular Tasks

- Review and update fixtures
- Remove obsolete tests
- Improve test performance
- Update CI configuration

### Test Refactoring

When refactoring tests:
1. Ensure all tests pass before changes
2. Refactor incrementally
3. Verify coverage maintained
4. Update documentation

## Troubleshooting Tests

### Test Failures

```bash
# Run single test for debugging
bash -x ./tests/unit/test-failing.sh

# Check environment
env | grep -E "CLAUDUX|PATH"
```

### Flaky Tests

Identify and fix:
1. Add retries for network tests
2. Increase timeouts
3. Mock external dependencies
4. Use fixed seeds/dates

## Resources

- [Bash Testing Frameworks](https://github.com/bats-core/bats-core)
- [Shell Check](https://www.shellcheck.net/)
- [Test Best Practices](https://testingjavascript.com/)

## Next Steps

- [Contributing](/development/contributing) - How to contribute
- [Adding Features](/development/adding-features) - Feature development
- [CI/CD](#) - Continuous integration setup