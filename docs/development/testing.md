[Home](/) > [Development](/development/) > Testing

# Testing Approach

Claudux uses a comprehensive testing strategy focused on reliability, cross-platform compatibility, and safe file operations. Our testing approach emphasizes manual verification and real-world scenarios over automated unit tests.

## Testing Philosophy

### Manual Testing Focus

Unlike traditional software projects, Claudux relies primarily on **manual testing** because:

- **AI-generated content** varies between runs and is difficult to assert against
- **File system operations** need careful verification in real environments  
- **Cross-platform behavior** requires testing on actual systems
- **Interactive features** need human verification for usability

### Safety-First Approach

All testing emphasizes **safe operations**:
- Use `--dry-run` flags where available
- Test in isolated environments
- Verify cleanup processes thoroughly
- Never test destructive operations on production code

## Required Testing Before Commits

### Core Functionality Tests

Run these tests **before every commit**:

#### 1. Basic CLI Functionality
```bash
# Test version command (should never fail)
./bin/claudux version

# Expected output: claudux X.X.X
```

#### 2. Project Detection and Generation
```bash
# Test full documentation generation
cd /path/to/test-project
claudux update

# Verify:
# - Project type detected correctly
# - Documentation generated in docs/
# - No error messages
# - Process completes successfully
```

#### 3. VitePress Integration
```bash
# Test development server
claudux serve

# Verify:
# - Server starts successfully
# - Port is allocated (3000-3100 range)
# - Documentation is accessible
# - No build errors
# - Server can be stopped with Ctrl+C
```

#### 4. Cleanup Safety
```bash
# Test cleanup operations safely
claudux clean --dry-run

# Verify:
# - Shows files that would be deleted
# - Protects important directories
# - No actual deletion occurs
# - Clear output about what would happen
```

## Cross-Platform Testing

### macOS vs Linux Differences

Test on **both platforms** to handle these critical differences:

#### Hash Command Variations
```bash
# macOS uses 'md5'
echo "test" | md5

# Linux uses 'md5sum' 
echo "test" | md5sum

# Our code handles both:
# lib/git-utils.sh uses conditional logic
```

#### sed Command Behavior  
```bash
# macOS sed requires empty string after -i
sed -i '' 's/old/new/' file.txt

# Linux sed can use -i directly
sed -i 's/old/new/' file.txt

# Test both syntaxes work correctly
```

#### Process Handling
```bash
# Different signal handling between platforms
# Test interrupt handling (Ctrl+C) works correctly
# Verify background processes are cleaned up
```

### Platform-Specific Test Commands

#### On macOS:
```bash
# Test hash commands
echo "test" | md5
which md5sum >/dev/null || echo "md5sum not available (expected)"

# Test sed behavior
echo "old text" | sed -i '' 's/old/new/'
```

#### On Linux:
```bash  
# Test hash commands
echo "test" | md5sum
which md5 >/dev/null || echo "md5 not available (expected)"

# Test sed behavior
echo "old text" | sed -i 's/old/new/'
```

## Feature-Specific Testing

### When Adding New Features

Test these additional scenarios:

#### Graceful Degradation
```bash
# Test with optional tools missing
# Temporarily rename jq to test fallbacks
sudo mv /usr/bin/jq /usr/bin/jq.bak
claudux update  # Should still work with sed fallbacks
sudo mv /usr/bin/jq.bak /usr/bin/jq

# Test without git
sudo mv /usr/bin/git /usr/bin/git.bak  
claudux update  # Should show warning but continue
sudo mv /usr/bin/git.bak /usr/bin/git
```

#### Interrupt Handling
```bash
# Test Ctrl+C during generation
claudux update
# Press Ctrl+C during execution
# Verify:
# - Process stops cleanly
# - Lock files are removed
# - Background processes are killed
# - Partial files are cleaned up
```

#### Lock File Management
```bash
# Test concurrent execution prevention
claudux update &
sleep 1
claudux update  # Should fail with lock error

# Test lock cleanup
# Kill first process and verify lock is removed
# Check /tmp/claudux-*.lock files
```

#### Background Process Cleanup
```bash
# Test server interrupt handling  
claudux serve &
SERVER_PID=$!

# Interrupt and verify cleanup
kill -INT $SERVER_PID
sleep 2

# Check no hanging processes
ps aux | grep vitepress
ps aux | grep node
```

## Testing New Project Types

When adding support for new project types:

### Template Testing
```bash
# Create sample project of new type
mkdir test-newtype-project
cd test-newtype-project

# Add characteristic files for detection
touch characteristic-file
echo "project content" > main-file

# Test detection
claudux update

# Verify:
# - Project type detected correctly  
# - Appropriate template used
# - Generated docs are relevant
# - No errors or warnings
```

### Detection Logic Testing
```bash
# Test detection priority order
# Create project with multiple framework indicators

# Should detect more specific framework first
touch package.json next.config.js  # Should detect Next.js, not generic Node
claudux update

# Verify detection logic in output
CLAUDUX_VERBOSE=1 claudux update
```

## Testing Command Modifications

### Testing New Commands

When adding new commands to `bin/claudux`:

```bash
# Test command recognition
claudux new-command
# Should execute without "unknown command" error

# Test help integration
claudux help
# Should show new command in help text

# Test interactive menu
claudux
# New command should appear in menu if user-facing
```

### Testing Command Options

```bash
# Test all command variations
claudux command
claudux command --option
claudux command --option value
claudux command -v          # verbose
claudux command -q          # quiet

# Test invalid options
claudux command --invalid   # Should show helpful error
```

## Testing AI Integration

### Model Testing
```bash
# Test different Claude models
claudux update --force-model opus
claudux update --force-model sonnet
claudux update --force-model haiku

# Verify:
# - Model selection works
# - Generation quality appropriate for model
# - No API errors
# - Rate limiting handled
```

### Context Limit Testing
```bash
# Test with large codebase
# Generate docs for project with >200K tokens
claudux update

# Verify:
# - Files are chunked appropriately
# - No context limit errors
# - Generation completes successfully
```

### Prompt Testing
```bash
# Test custom prompts
claudux update -m "Custom generation instruction"

# Verify:
# - Custom prompt is incorporated
# - Output reflects the instruction
# - Prompt structure is maintained
```

## Environment Testing

### Dependency Testing
```bash
# Test dependency checking
claudux check

# Verify reports:
# - Node.js version
# - Claude CLI availability  
# - Optional tool status
# - Clear error messages for missing deps
```

### Configuration Testing
```bash
# Test various config scenarios
echo '{"projectName": "Test"}' > docs-ai-config.json
claudux update
rm docs-ai-config.json

# Test with invalid JSON
echo '{invalid json}' > docs-ai-config.json
claudux update  # Should handle gracefully
rm docs-ai-config.json
```

### Environment Variable Testing
```bash
# Test verbose modes
CLAUDUX_VERBOSE=1 claudux update
CLAUDUX_VERBOSE=2 claudux update

# Test color disable
NO_COLOR=1 claudux update

# Test model override
FORCE_MODEL=sonnet claudux update
```

## Testing Critical Gotchas

### Lock File Race Conditions
```bash
# Simulate lock file race
claudux update &
PID1=$!
sleep 0.1
claudux update &
PID2=$!

# One should succeed, other should fail safely
wait $PID1 $PID2
```

### Symlink Resolution
```bash
# Test symlink handling
ln -s /path/to/claudux/bin/claudux ~/bin/claudux-link
~/bin/claudux-link version

# Should resolve correctly
```

### Port Conflicts
```bash
# Start something on port 3000
python3 -m http.server 3000 &
HTTP_PID=$!

# Test Claudux finds alternate port
claudux serve

kill $HTTP_PID
```

## Test Project Setup

### Creating Test Projects

#### Minimal Test Project
```bash
mkdir minimal-test
cd minimal-test
echo "# Test Project" > README.md
echo "This is a test project for Claudux development." >> README.md
```

#### Complex Test Project
```bash
mkdir complex-test
cd complex-test

# Create realistic project structure
mkdir -p src/{components,utils} docs tests
echo "# Complex Test Project" > README.md
echo "export const utils = {}" > src/utils/index.js
echo "export const Component = () => {}" > src/components/Component.js
echo "# Existing docs" > docs/existing.md
echo "describe('tests', () => {})" > tests/test.js
```

#### Framework-Specific Test Projects
```bash
# Next.js test project
mkdir nextjs-test && cd nextjs-test
echo '{"dependencies": {"next": "^13.0.0"}}' > package.json
touch next.config.js

# React test project  
mkdir react-test && cd react-test
echo '{"dependencies": {"react": "^18.0.0"}}' > package.json
mkdir src public

# iOS test project
mkdir ios-test && cd ios-test
touch project.pbxproj Package.swift
```

## Debugging Test Issues

### Enable Debug Output
```bash
# Maximum verbosity
CLAUDUX_VERBOSE=2 claudux update

# Shell debugging
bash -x ./bin/claudux update
```

### Check Process State
```bash
# During testing, check processes
ps aux | grep claudux
ps aux | grep vitepress  
ps aux | grep node

# Check lock files
ls -la /tmp/claudux-*.lock
```

### Verify File Operations
```bash
# Check what files would be affected
claudux clean --dry-run

# Monitor file changes during update
ls -la docs/ 
claudux update
ls -la docs/
```

## Test Documentation

### Document Test Cases

When adding features, document:

1. **Test scenarios covered**
2. **Expected behavior**  
3. **Platform-specific considerations**
4. **Known limitations**

### Example Test Case Documentation
```markdown
## Testing Django Project Detection

### Setup
- Create Django project with manage.py
- Include requirements.txt with Django
- Add typical Django directory structure

### Test Command
`claudux update`

### Expected Results
- Project type: "django" detected
- Uses django-claude.md template
- Generates Django-specific documentation
- Includes models, views, URL patterns

### Platform Notes
- Works on both macOS and Linux
- Requires Python in PATH for full detection
```

## Continuous Testing

### Before Releases

Run comprehensive test suite:

1. **All platform combinations**
2. **All supported project types**
3. **All CLI commands and options**
4. **Error scenarios and edge cases**
5. **Performance with large codebases**

### Regular Testing Schedule

- **Before each commit**: Core functionality tests
- **Before each PR**: Cross-platform tests
- **Before each release**: Full test suite
- **Weekly**: Test with latest Claude CLI versions

---

<p align="center">
  <a href="adding-features">Next: Adding Features →</a>
</p>