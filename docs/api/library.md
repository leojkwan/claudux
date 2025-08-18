[Home](/) > [API](/api/) > Library Functions

# Library Functions Reference

Claudux is built with modular Bash libraries that can be sourced and used in custom scripts.

## Usage

Source libraries in your scripts:

```bash
#!/bin/bash
CLAUDUX_LIB="$(npm root -g)/claudux/lib"
source "$CLAUDUX_LIB/colors.sh"
source "$CLAUDUX_LIB/project.sh"
```

---

## colors.sh

Terminal color output and formatting utilities.

### Functions

#### print_color()
Print colored text to terminal.

```bash
print_color COLOR "message"
```

**Parameters:**
- `COLOR`: Color name (RED, GREEN, YELLOW, BLUE, CYAN, MAGENTA, WHITE)
- `message`: Text to print

**Example:**
```bash
print_color "GREEN" "✓ Success"
print_color "RED" "✗ Error"
print_color "YELLOW" "⚠ Warning"
```

#### error_exit()
Print error message and exit.

```bash
error_exit "message" [exit_code]
```

**Parameters:**
- `message`: Error message
- `exit_code`: Optional exit code (default: 1)

**Example:**
```bash
error_exit "File not found" 4
```

#### warn()
Print warning message.

```bash
warn "message"
```

**Example:**
```bash
warn "Configuration file missing, using defaults"
```

#### info()
Print info message.

```bash
info "message"
```

#### success()
Print success message.

```bash
success "message"
```

---

## project.sh

Project detection and configuration utilities.

### Functions

#### detect_project_type()
Detect project type based on files and structure.

```bash
project_type=$(detect_project_type)
```

**Returns:** Project type string (nextjs, react, ios, python, rust, generic)

**Example:**
```bash
type=$(detect_project_type)
echo "Detected project type: $type"
```

#### load_project_config()
Load project configuration from docs-ai-config.json.

```bash
load_project_config
```

**Sets variables:**
- `PROJECT_NAME`
- `PROJECT_TYPE`
- `PRIMARY_LANGUAGE`
- `FRAMEWORKS`

**Example:**
```bash
load_project_config
echo "Project: $PROJECT_NAME"
echo "Type: $PROJECT_TYPE"
```

#### find_project_logo()
Find project logo file.

```bash
logo_path=$(find_project_logo)
```

**Returns:** Path to logo file or empty string

**Search order:**
1. `assets/logo.*`
2. `public/logo.*`
3. `static/logo.*`
4. `images/logo.*`

#### get_project_config()
Get configuration for specific project type.

```bash
config=$(get_project_config "react")
```

**Parameters:**
- `project_type`: Type of project

**Returns:** Path to configuration template

---

## claude-utils.sh

Claude AI integration utilities.

### Functions

#### check_claude()
Check Claude CLI installation and authentication.

```bash
check_claude
```

**Exits if:**
- Claude CLI not installed
- Not authenticated

**Example:**
```bash
if check_claude; then
    echo "Claude is ready"
fi
```

#### get_model_settings()
Get model configuration.

```bash
eval $(get_model_settings)
```

**Sets variables:**
- `MODEL`: Selected model (opus/sonnet/haiku)
- `MAX_TOKENS`: Token limit
- `TEMPERATURE`: Creativity setting

#### generate_with_claude()
Generate content using Claude API.

```bash
result=$(generate_with_claude "$prompt" "$model")
```

**Parameters:**
- `prompt`: Generation prompt
- `model`: Optional model override

**Returns:** Generated content

**Example:**
```bash
prompt="Generate a README for this project"
content=$(generate_with_claude "$prompt")
```

#### show_progress()
Display progress indicator.

```bash
show_progress "Generating documentation"
```

**Parameters:**
- `message`: Progress message

#### format_claude_output()
Format Claude API output for display.

```bash
formatted=$(format_claude_output "$raw_output")
```

---

## docs-generation.sh

Documentation generation core functions.

### Functions

#### build_generation_prompt()
Build comprehensive generation prompt.

```bash
prompt=$(build_generation_prompt "$project_type" "$custom_message")
```

**Parameters:**
- `project_type`: Type of project
- `custom_message`: Optional custom instructions

**Returns:** Complete prompt for Claude

#### update()
Main documentation update function.

```bash
update "$@"
```

**Parameters:** All command-line arguments

**Process:**
1. Load configuration
2. Detect project type
3. Build prompt
4. Generate documentation
5. Setup VitePress
6. Clean obsolete files

#### generate_docs_map()
Generate documentation structure map.

```bash
generate_docs_map > docs-map.md
```

**Returns:** Markdown documentation map

---

## cleanup.sh

Documentation cleanup utilities.

### Functions

#### cleanup_docs()
Interactive cleanup of obsolete documentation.

```bash
cleanup_docs
```

**Behavior:**
- Analyzes documentation
- Identifies obsolete files
- Requests confirmation
- Deletes approved files

#### cleanup_docs_silent()
Silent cleanup without interaction.

```bash
cleanup_docs_silent
```

**Used for:** Automated cleanup in scripts

#### recreate_docs()
Delete and regenerate all documentation.

```bash
recreate_docs "$message"
```

**Parameters:**
- `message`: Optional regeneration instructions

#### analyze_obsolete_docs()
Analyze and identify obsolete documentation.

```bash
obsolete_files=$(analyze_obsolete_docs)
```

**Returns:** List of obsolete file paths

---

## content-protection.sh

Content protection and preservation utilities.

### Functions

#### is_protected_path()
Check if path is protected.

```bash
if is_protected_path "docs/internal.md"; then
    echo "File is protected"
fi
```

**Parameters:**
- `path`: File or directory path

**Returns:** 0 if protected, 1 otherwise

#### get_protection_markers()
Get list of protection markers.

```bash
markers=$(get_protection_markers)
```

**Returns:** List of protection marker patterns

#### strip_protected_content()
Extract protected content from file.

```bash
strip_protected_content "docs/api.md"
```

**Parameters:**
- `file`: File path

**Creates:** `$file.protected` with protected content

#### restore_protected_content()
Restore protected content to file.

```bash
restore_protected_content "docs/api.md"
```

**Parameters:**
- `file`: File path

---

## server.sh

Development server management.

### Functions

#### serve()
Start VitePress development server.

```bash
serve
```

**Behavior:**
1. Checks for docs directory
2. Installs dependencies
3. Finds available port
4. Starts server
5. Opens browser

#### find_available_port()
Find available port for server.

```bash
port=$(find_available_port 3000)
```

**Parameters:**
- `start_port`: Starting port number

**Returns:** Available port number

#### install_vitepress()
Install VitePress dependencies.

```bash
install_vitepress
```

**Behavior:**
- Checks for existing installation
- Runs npm install
- Validates installation

---

## ui.sh

User interface and interaction utilities.

### Functions

#### show_header()
Display Claudux header banner.

```bash
show_header
```

**Output:**
```
🚀 Claudux - AI-Powered Documentation Generator
```

#### show_menu()
Display interactive menu.

```bash
show_menu
```

**Returns:** Selected menu option

#### show_help()
Display help information.

```bash
show_help [command]
```

**Parameters:**
- `command`: Optional specific command

#### create_claudux_md()
Generate CLAUDE.md template.

```bash
create_claudux_md
```

**Creates:** CLAUDE.md or claudux.md file

#### confirm()
Get user confirmation.

```bash
if confirm "Continue?"; then
    echo "Proceeding..."
fi
```

**Parameters:**
- `message`: Confirmation prompt

**Returns:** 0 for yes, 1 for no

---

## validate-links.sh

Link validation utilities.

### Functions

#### validate_links()
Validate all documentation links.

```bash
validate_links [options]
```

**Options:**
- `--auto-fix`: Fix broken links
- `--external`: Check external links

**Returns:** Number of broken links

#### check_internal_links()
Check internal documentation links.

```bash
broken=$(check_internal_links)
```

**Returns:** List of broken links

#### check_external_links()
Check external links.

```bash
check_external_links "$timeout"
```

**Parameters:**
- `timeout`: Request timeout in milliseconds

#### repair_links()
Automatically repair broken links.

```bash
repair_links "$broken_links"
```

**Parameters:**
- `broken_links`: List of broken links

---

## git-utils.sh

Git repository utilities.

### Functions

#### ensure_git_repo()
Ensure working directory is a git repository.

```bash
ensure_git_repo
```

**Returns:** 0 if git repo, 1 otherwise

#### show_git_status()
Display git status summary.

```bash
show_git_status
```

**Output:** Modified files and branch information

#### show_detailed_changes()
Show detailed git changes.

```bash
show_detailed_changes
```

**Output:** Diff of changes

#### get_git_remote()
Get git remote URL.

```bash
remote=$(get_git_remote)
```

**Returns:** Remote repository URL

#### extract_github_info()
Extract GitHub username and repo from remote.

```bash
eval $(extract_github_info)
```

**Sets variables:**
- `GITHUB_USER`
- `GITHUB_REPO`

---

## Environment Variables

Libraries respect these environment variables:

| Variable | Description |
|----------|-------------|
| `CLAUDUX_VERBOSE` | Verbosity level (0-2) |
| `NO_COLOR` | Disable colors |
| `FORCE_MODEL` | Override AI model |
| `SCRIPT_DIR` | Script directory |
| `WORKING_DIR` | Working directory |

---

## Error Handling

All functions follow consistent error handling:

```bash
# Check function existence
check_function "function_name"

# Handle errors
if ! function_call; then
    error_exit "Function failed"
fi

# Trap errors
trap 'error_exit "Script failed"' ERR
```

---

## Best Practices

### 1. Always Source Dependencies

```bash
source "$LIB_DIR/colors.sh" || exit 1
source "$LIB_DIR/project.sh" || exit 1
```

### 2. Check Function Availability

```bash
if declare -F print_color >/dev/null; then
    print_color "GREEN" "Ready"
fi
```

### 3. Use Local Variables

```bash
function_name() {
    local var="value"
    # Use $var
}
```

### 4. Handle Errors Gracefully

```bash
if ! detect_project_type; then
    warn "Could not detect project type"
    PROJECT_TYPE="generic"
fi
```

### 5. Respect Verbosity

```bash
[[ $CLAUDUX_VERBOSE -ge 1 ]] && echo "Debug info"
```

---

## Examples

### Custom Documentation Script

```bash
#!/bin/bash

# Source libraries
CLAUDUX_LIB="$(npm root -g)/claudux/lib"
source "$CLAUDUX_LIB/colors.sh"
source "$CLAUDUX_LIB/project.sh"
source "$CLAUDUX_LIB/claude-utils.sh"

# Detect project
project_type=$(detect_project_type)
print_color "CYAN" "Project type: $project_type"

# Check Claude
if ! check_claude; then
    error_exit "Claude not available"
fi

# Generate custom docs
prompt="Generate a technical specification"
docs=$(generate_with_claude "$prompt")

# Save documentation
echo "$docs" > SPEC.md
success "✓ Documentation generated"
```

### Cleanup Automation

```bash
#!/bin/bash

source "$(npm root -g)/claudux/lib/cleanup.sh"
source "$(npm root -g)/claudux/lib/colors.sh"

# Run cleanup
info "Starting automated cleanup..."
cleanup_docs_silent

# Report results
success "Cleanup complete"
```