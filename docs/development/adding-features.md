[Home](/) > [Development](/development/) > Adding Features

# Adding New Features

This guide explains how to extend Claudux with new functionality while maintaining consistency with the existing codebase architecture and patterns.

## Overview

Claudux follows a modular architecture where all business logic lives in `lib/*.sh` files, and `bin/claudux` serves only as a router. When adding features, always follow established patterns and maintain the Unix philosophy of doing one thing well.

## Adding New Commands

Follow this step-by-step process to add new CLI commands:

### 1. Add Command Case in Main Router

Edit `bin/claudux` and add your command to the main switch statement:

```bash
# In bin/claudux main() function
case "${1:-}" in
    # ... existing cases ...
    "your-new-command"|"alias")
        check_function "show_header"
        check_function "your_new_function"
        show_header
        shift
        your_new_function "$@"
        ;;
    # ... rest of cases ...
esac
```

**Key patterns to follow:**
- Use `check_function` to verify function exists
- Call `show_header` for consistency
- Use `shift` to remove command from arguments
- Pass remaining arguments with `"$@"`

### 2. Create Handler Function

Add the actual implementation to an appropriate `lib/*.sh` file:

```bash
# In lib/appropriate-module.sh
your_new_function() {
    local option_flag=false
    local target_dir="."
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --option|-o)
                option_flag=true
                shift
                ;;
            --target|-t)
                target_dir="$2"
                shift 2
                ;;
            *)
                error_exit "Unknown option: $1"
                ;;
        esac
    done
    
    # Validate inputs
    if [[ ! -d "$target_dir" ]]; then
        error_exit "Directory does not exist: $target_dir"
    fi
    
    # Implementation
    log_verbose "Starting new feature operation"
    
    if $option_flag; then
        print_color "YELLOW" "⚠️ Option flag enabled"
    fi
    
    # Do the actual work
    perform_operation "$target_dir"
    
    print_color "GREEN" "✓ Operation completed successfully"
}

perform_operation() {
    local dir="$1"
    # Implementation details
}
```

**Follow these patterns:**
- Use `local` for all variables
- Parse arguments with proper error handling
- Validate inputs before processing
- Use established logging patterns
- Return meaningful exit codes

### 3. Update Help Text

Add your command to the help output in `lib/ui.sh`:

```bash
# In lib/ui.sh show_help() function
show_help() {
    cat << 'EOF'
Usage: claudux [command] [options]

Commands:
  update              Generate/update documentation
  serve               Start local development server
  clean               Remove obsolete documentation
  recreate            Delete all docs and regenerate
  your-new-command    Description of your new command
  # ... rest of commands
  
Options for your-new-command:
  --option, -o        Enable optional behavior
  --target, -t DIR    Specify target directory
EOF
}
```

### 4. Add to Interactive Menu

If your command should be user-facing, add it to the interactive menu in `lib/ui.sh`:

```bash
# In lib/ui.sh show_menu() function
show_menu() {
    echo "What would you like to do?"
    echo ""
    echo "  1) 📝 Update documentation"
    echo "  2) 🌐 Serve docs locally" 
    echo "  3) 🧹 Clean obsolete docs"
    echo "  4) 🔄 Recreate from scratch"
    echo "  5) 🆕 Your new feature"  # Add here
    echo "  6) ❌ Exit"
    
    # ... handle menu selection
    case $choice in
        # ... existing cases
        "5")
            your_new_function
            ;;
    esac
}
```

### 5. Test the New Command

Follow the testing checklist:

```bash
# Basic functionality
./bin/claudux your-new-command

# With options
./bin/claudux your-new-command --option --target /path

# Help integration
./bin/claudux help | grep "your-new-command"

# Interactive menu
./bin/claudux  # Verify menu item appears

# Error handling
./bin/claudux your-new-command --invalid-option
```

## Adding Project Type Support

To add support for a new project framework or language:

### 1. Create Template Files

Create a template in `lib/templates/` with the naming convention `projecttype-claude.md`:

```bash
# lib/templates/django-claude.md
# Django Project Documentation Generation

## Project Context
This is a Django web application project with the following characteristics:

### Project Structure
- Django apps in individual directories
- Models, views, URLs pattern
- Settings split between development and production
- Static files and templates organization

### Key Components to Document
1. **Models**: Database schema and relationships
2. **Views**: Request handling and business logic  
3. **URLs**: Routing configuration
4. **Templates**: Frontend presentation layer
5. **Admin**: Django admin customizations
6. **Management Commands**: Custom Django commands

### Documentation Focus
- API endpoints and their usage
- Model relationships and database design
- Authentication and permissions
- Deployment considerations
- Development setup instructions

### Code Analysis Priorities
1. Analyze models.py files for database schema
2. Examine views.py for business logic patterns
3. Review urls.py for API structure
4. Check settings.py for configuration options
5. Document custom management commands

Generate comprehensive documentation that helps both developers and stakeholders understand the Django application architecture and functionality.
```

### 2. Add Detection Logic

Update `lib/project.sh` to detect your project type in the `detect_project_type()` function:

```bash
# In lib/project.sh detect_project_type() function
detect_project_type() {
    # Order matters - more specific frameworks first
    
    # Django detection
    if [[ -f "manage.py" ]] && grep -q "django" requirements.txt 2>/dev/null; then
        echo "django"
        return
    fi
    
    # ... existing detections ...
    
    # Generic fallback
    if [[ -f "README.md" ]] || [[ -f "readme.md" ]] || [[ -f "README.txt" ]]; then
        echo "generic"
        return
    fi
    
    echo "unknown"
}
```

**Detection best practices:**
- Check most specific frameworks first
- Use multiple indicators for reliability
- Fall back to generic detection
- Never return empty string

### 3. Update Configuration Function

Add your project type to `get_project_config()` in `lib/project.sh`:

```bash
# In lib/project.sh get_project_config() function
get_project_config() {
    local project_type="$1"
    local template_path=""
    
    case "$project_type" in
        "django")
            template_path="$LIB_DIR/templates/django-claude.md"
            ;;
        "ios")
            template_path="$LIB_DIR/templates/ios-claude.md"
            ;;
        # ... existing cases ...
        *)
            template_path="$LIB_DIR/templates/generic-claude.md"
            ;;
    esac
    
    echo "$template_path"
}
```

### 4. Create Project Configuration

Add a configuration file in `lib/templates/` for project-specific settings:

```bash
# lib/templates/django-project-config.json
{
    "projectType": "django",
    "features": {
        "apiDocs": true,
        "modelDocs": true,  
        "adminDocs": true,
        "deploymentGuide": true
    },
    "ignorePaths": [
        "*/migrations/*",
        "venv/",
        "env/",
        "__pycache__/",
        "*.pyc"
    ],
    "focusAreas": [
        "models.py",
        "views.py", 
        "urls.py",
        "admin.py",
        "settings/"
    ]
}
```

### 5. Test Project Type Detection

Create a test project and verify detection:

```bash
# Create Django test project
mkdir test-django-project
cd test-django-project

# Add Django indicators
touch manage.py
echo "Django>=3.2" > requirements.txt

# Test detection
claudux update

# Verify in output:
# - "Detected project type: django"
# - Uses django-claude.md template
# - Generates Django-specific docs
```

## Modifying AI Prompts

AI prompts are built dynamically in `lib/docs-generation.sh`. Follow this process:

### 1. Locate Prompt Building Function

Find `build_generation_prompt()` in `lib/docs-generation.sh`:

```bash
# In lib/docs-generation.sh
build_generation_prompt() {
    local analysis_file="$1"
    local message="$2"
    local template_file="$3"
    
    # Multi-part prompt structure
    cat << EOF
## System Context
You are generating documentation for a ${PROJECT_TYPE} project.

## Analysis Results  
$(cat "$analysis_file")

## User Directive
$message

## Template Instructions
$(cat "$template_file")

## Output Requirements
Generate markdown documentation that...
EOF
}
```

### 2. Understand Prompt Structure

Maintain the established structure:
1. **System Context** - Sets AI's role and project context
2. **Analysis Results** - Current codebase analysis
3. **User Directive** - Custom instructions from user
4. **Template Instructions** - Project-type-specific guidance
5. **Output Requirements** - Format and structure requirements

### 3. Add New Prompt Components

To add new sections or modify existing ones:

```bash
build_generation_prompt() {
    local analysis_file="$1"
    local message="$2"
    local template_file="$3"
    
    cat << EOF
## System Context
You are generating documentation for a ${PROJECT_TYPE} project.
Project name: ${PROJECT_NAME}
Generation timestamp: $(date)

## Analysis Results
$(cat "$analysis_file")

## User Directive  
$message

## New Custom Section
Additional context or instructions for your feature.

## Template Instructions
$(cat "$template_file")

## Output Requirements
Generate comprehensive markdown documentation following these guidelines:
- Use clear headers and structure
- Include code examples where appropriate
- Add cross-references between sections
- Follow project naming conventions
EOF
}
```

### 4. Test Prompt Changes

Test with different project types and scenarios:

```bash
# Test with verbose output to see full prompt
CLAUDUX_VERBOSE=2 claudux update

# Test with custom message
claudux update -m "Focus on API documentation"

# Test with specific model
claudux update --force-model sonnet

# Verify output quality and structure
```

### 5. Optimize for Token Efficiency

Keep prompts concise but informative:

- **Remove redundant instructions**
- **Use clear, specific language**
- **Avoid unnecessary examples in prompts**
- **Check total token count** for large projects

## Advanced Feature Patterns

### Adding Configuration Options

For features that need user configuration:

```bash
# In appropriate lib file
load_feature_config() {
    local config_file="docs-ai-config.json"
    
    if [[ -f "$config_file" ]] && command -v jq >/dev/null 2>&1; then
        FEATURE_ENABLED=$(jq -r '.features.yourFeature // false' "$config_file" 2>/dev/null)
    else
        FEATURE_ENABLED=false
    fi
}

your_feature_function() {
    load_feature_config
    
    if [[ "$FEATURE_ENABLED" == "true" ]]; then
        log_verbose "Feature enabled by configuration"
        # Feature implementation
    else
        log_verbose "Feature disabled or not configured"
        return 0
    fi
}
```

### Adding Background Processing

For long-running operations:

```bash
start_background_task() {
    local task_id="$$-$(date +%s)"
    local lock_file="/tmp/claudux-task-$task_id.lock"
    
    # Start background process
    (
        trap "rm -f '$lock_file' 2>/dev/null" EXIT
        echo $$ > "$lock_file"
        
        # Long running task
        perform_long_operation
        
    ) &
    
    local bg_pid=$!
    echo "Task started with PID: $bg_pid"
    
    # Clean up on script exit
    trap "kill $bg_pid 2>/dev/null || true" EXIT
    
    return 0
}
```

### Adding File Validation

For features that process files:

```bash
validate_file_safety() {
    local file_path="$1"
    
    # Check if file is in protected directory
    if is_protected_path "$file_path"; then
        error_exit "Cannot modify protected file: $file_path"
    fi
    
    # Check file size
    local size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null || echo 0)
    if [[ $size -gt 1048576 ]]; then  # 1MB
        print_color "YELLOW" "⚠️ Large file detected: $file_path (${size} bytes)"
    fi
    
    # Check if file is binary
    if file "$file_path" | grep -q "binary"; then
        log_verbose "Skipping binary file: $file_path"
        return 1
    fi
    
    return 0
}
```

## Anti-Patterns to Avoid

### Don't Add Business Logic to bin/claudux

```bash
# ❌ Bad: Logic in main router
case "${1:-}" in
    "bad-command")
        # Complex logic here is wrong
        if [[ condition ]]; then
            do_something
        fi
        ;;
esac

# ✅ Good: Router delegates to library function  
case "${1:-}" in
    "good-command")
        check_function "good_command_handler"
        show_header
        shift
        good_command_handler "$@"
        ;;
esac
```

### Don't Use Hardcoded Paths

```bash
# ❌ Bad: Hardcoded paths
echo "data" > /tmp/myfile.txt

# ✅ Good: Use mktemp
local temp_file=$(mktemp)
trap "rm -f '$temp_file'" EXIT
echo "data" > "$temp_file"
```

### Don't Ignore Error Handling

```bash
# ❌ Bad: No error handling
result=$(some_command)
process_result "$result"

# ✅ Good: Proper error handling  
if ! result=$(some_command); then
    error_exit "Command failed: some_command"
fi

if [[ -z "$result" ]]; then
    error_exit "Command returned empty result"
fi

process_result "$result"
```

### Don't Break the Module Pattern

```bash
# ❌ Bad: Global variables without declaration
function_name() {
    GLOBAL_VAR="value"  # Can cause issues
}

# ✅ Good: Proper variable scope
function_name() {
    local local_var="value"
    readonly GLOBAL_CONSTANT="value"  # If truly global
}
```

## Testing Your New Feature

### Comprehensive Testing Checklist

- [ ] **Basic functionality** works as expected
- [ ] **Error handling** for invalid inputs  
- [ ] **Help text** is accurate and helpful
- [ ] **Cross-platform compatibility** (macOS and Linux)
- [ ] **Integration** with existing commands
- [ ] **Configuration** options work correctly
- [ ] **Performance** is acceptable for target use cases
- [ ] **Documentation** is updated appropriately

### Example Test Script

Create a test script for your feature:

```bash
#!/bin/bash
# test-new-feature.sh

set -e

echo "Testing new feature..."

# Setup test environment
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Create test project
echo "# Test Project" > README.md
mkdir src tests

# Test basic functionality
echo "✅ Testing basic command..."
claudux your-new-command

# Test with options
echo "✅ Testing with options..."
claudux your-new-command --option --target src

# Test error handling
echo "✅ Testing error handling..."
if claudux your-new-command --invalid-option 2>/dev/null; then
    echo "❌ Should have failed with invalid option"
    exit 1
fi

# Test help
echo "✅ Testing help integration..."
claudux help | grep -q "your-new-command" || {
    echo "❌ Command not in help text"
    exit 1
}

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo "🎉 All tests passed!"
```

## Documentation Requirements

When adding features, update documentation:

1. **This guide** - Add patterns for others to follow
2. **Command help** - Update `lib/ui.sh:show_help()`
3. **Interactive menu** - Update if user-facing
4. **README** - Add to feature list if significant
5. **Examples** - Provide usage examples

---

<p align="center">
  <a href="./">← Back to Development Guide</a>
</p>