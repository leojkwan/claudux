[Home](/) > [Development](/development/) > Adding Features

# Adding Features

This guide walks through adding new features to Claudux, from conception to implementation.

## Feature Development Process

### 1. Planning

Before coding:
- Check existing issues/discussions
- Define the feature scope
- Consider backward compatibility
- Plan the implementation approach

### 2. Implementation

Follow the development workflow:
1. Create feature branch
2. Write tests first (TDD)
3. Implement feature
4. Update documentation
5. Submit PR

## Common Feature Types

### Adding a New Command

Example: Adding a `stats` command to show documentation statistics.

#### Step 1: Define Command Handler

`lib/stats.sh`:
```bash
#!/bin/bash
#
# stats.sh - Documentation statistics
#

# @description Show documentation statistics
show_stats() {
    local docs_dir="${1:-docs}"
    
    if [[ ! -d "$docs_dir" ]]; then
        error_exit "No documentation found"
    fi
    
    # Count files
    local total_files=$(find "$docs_dir" -name "*.md" | wc -l)
    local total_lines=$(find "$docs_dir" -name "*.md" -exec wc -l {} + | tail -1 | awk '{print $1}')
    local total_words=$(find "$docs_dir" -name "*.md" -exec wc -w {} + | tail -1 | awk '{print $1}')
    
    # Calculate sizes
    local total_size=$(du -sh "$docs_dir" | cut -f1)
    
    # Display stats
    print_color "CYAN" "📊 Documentation Statistics"
    echo ""
    echo "  Files:  $total_files"
    echo "  Lines:  $total_lines"
    echo "  Words:  $total_words"
    echo "  Size:   $total_size"
    
    # Show breakdown by directory
    echo ""
    print_color "CYAN" "📁 Breakdown by Section:"
    for dir in "$docs_dir"/*/; do
        if [[ -d "$dir" ]]; then
            local name=$(basename "$dir")
            local count=$(find "$dir" -name "*.md" | wc -l)
            printf "  %-15s %d files\n" "$name:" "$count"
        fi
    done
}
```

#### Step 2: Add to Router

`bin/claudux`:
```bash
# Add to REQUIRED_LIBS
REQUIRED_LIBS=("colors.sh" "project.sh" "stats.sh" ...)

# Add case in main()
"stats")
    check_function "show_stats"
    show_stats
    ;;
```

#### Step 3: Update Help

`lib/ui.sh`:
```bash
show_help() {
    # ...
    echo "  stats          Show documentation statistics"
    # ...
}
```

#### Step 4: Add to Menu

`lib/ui.sh`:
```bash
show_menu() {
    # ...
    echo "7) Show Statistics"
    # ...
    
    case $choice in
        7)
            show_stats
            ;;
    esac
}
```

#### Step 5: Write Tests

`tests/unit/test-stats.sh`:
```bash
#!/bin/bash

test_stats_command() {
    # Setup
    mkdir -p test-docs/guide
    echo "# Test" > test-docs/index.md
    echo "# Guide" > test-docs/guide/index.md
    
    # Execute
    output=$(show_stats "test-docs")
    
    # Assert
    assert_contains "$output" "Files:  2"
    assert_contains "$output" "guide:"
    
    # Cleanup
    rm -rf test-docs
}
```

### Adding Project Type Support

Example: Adding support for Django projects.

#### Step 1: Add Detection Logic

`lib/project.sh`:
```bash
detect_project_type() {
    # ...
    
    # Django detection
    if [[ -f "manage.py" ]] && [[ -f "settings.py" || -d "*/settings.py" ]]; then
        echo "django"
        return
    fi
    
    # ...
}
```

#### Step 2: Create Configuration Template

`lib/templates/django-config.json`:
```json
{
  "project": {
    "type": "django",
    "name": "Django Project",
    "description": "Django web application"
  },
  "documentation": {
    "sections": [
      "models",
      "views",
      "templates",
      "api",
      "admin",
      "management-commands"
    ],
    "framework_specific": {
      "include_migrations": false,
      "document_admin": true,
      "api_style": "rest_framework"
    }
  }
}
```

#### Step 3: Create AI Instructions

`lib/templates/django-claude.md`:
```markdown
# Django Project Documentation

## Focus Areas
- Model documentation with field descriptions
- View documentation (class-based and function-based)
- URL routing patterns
- Template usage
- REST API endpoints (if using DRF)
- Admin interface customizations
- Management commands
- Settings documentation

## Django-Specific Patterns
- Use Django terminology (models, views, templates)
- Document database relationships
- Include migration information if relevant
- Document signals and middleware
- Explain custom template tags/filters

## Code Examples
- Show model usage examples
- Include view examples with URL patterns
- Demonstrate template inheritance
- Show API usage with curl examples
```

#### Step 4: Test Detection

```bash
# Create test Django project
mkdir test-django
cd test-django
touch manage.py
mkdir myapp
touch myapp/settings.py

# Test detection
claudux check
# Should show: "Project type: django"
```

### Adding Configuration Options

Example: Adding a `minify` option for generated docs.

#### Step 1: Update Configuration Schema

`lib/project.sh`:
```bash
load_project_config() {
    # ...
    
    # New option
    MINIFY_DOCS=$(jq -r '.documentation.minify // false' "$config_file" 2>/dev/null || echo "false")
    export MINIFY_DOCS
}
```

#### Step 2: Implement Feature

`lib/docs-generation.sh`:
```bash
post_process_docs() {
    if [[ "$MINIFY_DOCS" == "true" ]]; then
        info "Minifying documentation..."
        
        for file in docs/**/*.md; do
            # Remove extra whitespace
            sed -i 's/[[:space:]]*$//' "$file"
            # Remove multiple blank lines
            sed -i '/^$/N;/^\n$/d' "$file"
        done
        
        success "Documentation minified"
    fi
}
```

#### Step 3: Document Option

Update configuration documentation:
```json
{
  "documentation": {
    "minify": true  // Minify generated markdown
  }
}
```

## Feature Guidelines

### Code Quality

1. **Follow Patterns**: Use existing code patterns
2. **Error Handling**: Always handle errors gracefully
3. **Documentation**: Document all new functions
4. **Testing**: Include comprehensive tests

### Backward Compatibility

1. **Don't Break Existing**: Ensure existing features work
2. **Deprecate Gracefully**: Mark old features as deprecated
3. **Migration Path**: Provide upgrade instructions

### Performance

1. **Optimize**: Consider performance impact
2. **Async When Possible**: Use background processes
3. **Cache Results**: Cache expensive operations

## Testing New Features

### Unit Testing

Test individual functions:
```bash
# Test new function
test_new_feature() {
    result=$(new_feature_function "input")
    assert_equals "expected" "$result"
}
```

### Integration Testing

Test with other components:
```bash
# Test command integration
test_new_command() {
    output=$(claudux new-command)
    assert_success
    assert_contains "$output" "expected text"
}
```

### Manual Testing

Checklist:
- [ ] Test on macOS
- [ ] Test on Linux
- [ ] Test with various project types
- [ ] Test error conditions
- [ ] Test with existing features

## Documentation

### Update User Documentation

1. Add to command reference
2. Update configuration guide
3. Add examples
4. Update FAQ if needed

### Update Development Documentation

1. Document in API reference
2. Add to module documentation
3. Update architecture if needed

## Submitting Features

### Pull Request Checklist

- [ ] Tests pass
- [ ] Documentation updated
- [ ] No breaking changes
- [ ] Follows code style
- [ ] Commit messages follow convention

### PR Description Template

```markdown
## Feature: [Feature Name]

### Description
What this feature does and why it's needed.

### Implementation
- How it works
- Key changes made
- New files/functions added

### Testing
- Unit tests added
- Integration tests added
- Manual testing performed

### Documentation
- User docs updated
- Dev docs updated
- Examples added

### Breaking Changes
None / List any breaking changes

### Screenshots
If applicable
```

## Examples of Good Features

### Example 1: Parallel Processing

```bash
# Feature: Process multiple files in parallel
process_files_parallel() {
    local -a files=("$@")
    
    # Process in parallel with limit
    printf '%s\n' "${files[@]}" | \
        xargs -P 4 -I {} bash -c 'process_file "$@"' _ {}
}
```

### Example 2: Progress Indicator

```bash
# Feature: Show progress during long operations
show_progress_bar() {
    local current="$1"
    local total="$2"
    local width=50
    
    local progress=$((current * width / total))
    local percentage=$((current * 100 / total))
    
    printf "\r["
    printf "%${progress}s" | tr ' ' '='
    printf "%$((width - progress))s" | tr ' ' '-'
    printf "] %d%%" "$percentage"
}
```

### Example 3: Caching

```bash
# Feature: Cache expensive operations
declare -A CACHE

cached_operation() {
    local key="$1"
    local cache_file="/tmp/claudux-cache-$key"
    
    # Check cache
    if [[ -f "$cache_file" ]] && [[ $(find "$cache_file" -mmin -60) ]]; then
        cat "$cache_file"
        return
    fi
    
    # Perform operation
    local result=$(expensive_operation "$key")
    
    # Cache result
    echo "$result" > "$cache_file"
    echo "$result"
}
```

## Feature Ideas

Potential features to implement:

1. **Watch Mode**: Auto-regenerate on file changes
2. **Diff Mode**: Show what changed between generations
3. **Template System**: User-defined templates
4. **Plugin Architecture**: Extensible with plugins
5. **Multi-language Docs**: Generate in multiple languages
6. **Export Formats**: PDF, EPUB, etc.
7. **Metrics Dashboard**: Documentation quality metrics
8. **Version Tracking**: Track doc versions
9. **Collaborative Mode**: Multi-user editing
10. **AI Model Selection**: Per-section model choice

## Resources

- [Architecture](/technical/) - System design
- [Patterns](/technical/patterns) - Code patterns
- [Testing](/development/testing) - Testing guide
- [Contributing](/development/contributing) - Contribution process

## Getting Help

- Discuss ideas in [GitHub Discussions](https://github.com/leokwan/claudux/discussions)
- Ask questions in [Issues](https://github.com/leokwan/claudux/issues)
- Review existing [Pull Requests](https://github.com/leokwan/claudux/pulls)