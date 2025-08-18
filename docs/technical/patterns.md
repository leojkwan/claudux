[Home](/) > [Technical](/technical/) > Coding Patterns

# Coding Patterns and Conventions

This document outlines the coding patterns, conventions, and best practices used throughout the Claudux codebase.

## Bash Coding Standards

### Script Structure

Every Bash script follows this structure:

```bash
#!/bin/bash
#
# Script description
# Additional details
#

# Script safety settings
set -u                    # Undefined variables are errors
set -o pipefail          # Pipe failures propagate

# Constants
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Global variables (minimize these)
VERBOSE=${VERBOSE:-0}

# Functions
main() {
    # Main logic
}

# Error handling
trap 'handle_error $? $LINENO' ERR

# Entry point
main "$@"
```

### Naming Conventions

#### Functions

Always use snake_case:

```bash
# Good
detect_project_type() {
    # ...
}

# Bad
detectProjectType() {
    # ...
}
```

#### Variables

Local variables: snake_case
```bash
local project_type="react"
local file_count=0
```

Constants: UPPER_SNAKE_CASE
```bash
readonly MAX_RETRIES=3
readonly DEFAULT_MODEL="opus"
```

Environment variables: UPPER_SNAKE_CASE with prefix
```bash
export CLAUDUX_VERBOSE=1
export CLAUDUX_MODEL="sonnet"
```

### Function Patterns

#### Input Validation

```bash
process_file() {
    local file="${1:?Error: file path required}"
    
    # Validate file exists
    [[ -f "$file" ]] || error_exit "File not found: $file"
    
    # Validate readable
    [[ -r "$file" ]] || error_exit "Cannot read file: $file"
    
    # Process file
    # ...
}
```

#### Return Values

```bash
# Boolean functions return 0 for true, 1 for false
is_protected() {
    local path="$1"
    
    if [[ "$path" =~ ^private/ ]]; then
        return 0  # true
    fi
    
    return 1  # false
}

# Usage
if is_protected "$file"; then
    echo "File is protected"
fi
```

#### Output Functions

```bash
# Functions that output values
get_project_name() {
    local name="MyProject"
    echo "$name"  # Output to stdout
}

# Usage
project_name=$(get_project_name)
```

### Error Handling

#### Error Exit Pattern

```bash
error_exit() {
    local message="$1"
    local code="${2:-1}"
    
    print_color "RED" "❌ Error: $message" >&2
    exit "$code"
}

# Usage
[[ -d "$dir" ]] || error_exit "Directory not found: $dir" 4
```

#### Try-Catch Pattern

```bash
try_operation() {
    local result
    
    if result=$(risky_operation 2>&1); then
        echo "$result"
        return 0
    else
        warn "Operation failed: $result"
        return 1
    fi
}
```

#### Cleanup on Exit

```bash
cleanup() {
    local exit_code=$?
    
    # Remove temp files
    [[ -f "$TEMP_FILE" ]] && rm -f "$TEMP_FILE"
    
    # Kill background processes
    jobs -p | xargs -r kill 2>/dev/null || true
    
    exit $exit_code
}

trap cleanup EXIT
```

### String Manipulation

#### Safe String Operations

```bash
# Parameter expansion for safety
trim_whitespace() {
    local str="$1"
    # Remove leading whitespace
    str="${str#"${str%%[![:space:]]*}"}"
    # Remove trailing whitespace
    str="${str%"${str##*[![:space:]]}"}"
    echo "$str"
}

# Default values
get_value() {
    local value="${1:-default}"
    echo "$value"
}

# String replacement
sanitize() {
    local input="$1"
    # Replace dangerous characters
    input="${input//[^a-zA-Z0-9\-\_]/}"
    echo "$input"
}
```

### Array Patterns

#### Array Declaration and Usage

```bash
# Declare arrays
declare -a files=()
declare -A config=()

# Add to array
files+=("file1.txt")
files+=("file2.txt")

# Iterate array
for file in "${files[@]}"; do
    process_file "$file"
done

# Array length
echo "Found ${#files[@]} files"

# Associative array
config[name]="MyProject"
config[type]="react"
echo "Project: ${config[name]}"
```

### File Operations

#### Safe File Reading

```bash
read_file_safely() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        error_exit "File not found: $file"
    fi
    
    if [[ ! -r "$file" ]]; then
        error_exit "Cannot read file: $file"
    fi
    
    # Read file
    cat "$file"
}
```

#### Atomic File Writing

```bash
write_file_atomically() {
    local file="$1"
    local content="$2"
    local temp_file
    
    # Create temp file
    temp_file=$(mktemp "${file}.XXXXXX")
    
    # Write to temp file
    echo "$content" > "$temp_file" || {
        rm -f "$temp_file"
        error_exit "Failed to write file"
    }
    
    # Move atomically
    mv "$temp_file" "$file"
}
```

### Process Management

#### Background Process Pattern

```bash
start_background_process() {
    local cmd="$1"
    
    # Start in background
    $cmd &
    local pid=$!
    
    # Store PID for cleanup
    echo "$pid" >> "$PID_FILE"
    
    # Check if started successfully
    sleep 1
    if ! kill -0 "$pid" 2>/dev/null; then
        error_exit "Failed to start process"
    fi
    
    echo "$pid"
}

cleanup_processes() {
    if [[ -f "$PID_FILE" ]]; then
        while read -r pid; do
            kill "$pid" 2>/dev/null || true
        done < "$PID_FILE"
        rm -f "$PID_FILE"
    fi
}
```

### Command Execution

#### Safe Command Execution

```bash
execute_command() {
    local cmd="$1"
    local output
    local status
    
    # Execute and capture output/status
    output=$(eval "$cmd" 2>&1)
    status=$?
    
    if [[ $status -ne 0 ]]; then
        error_exit "Command failed: $cmd\nOutput: $output"
    fi
    
    echo "$output"
}
```

#### Command with Timeout

```bash
execute_with_timeout() {
    local timeout="$1"
    local cmd="$2"
    
    timeout "$timeout" bash -c "$cmd" || {
        local status=$?
        if [[ $status -eq 124 ]]; then
            error_exit "Command timed out after ${timeout}s"
        else
            error_exit "Command failed with status $status"
        fi
    }
}
```

## Module Patterns

### Module Structure

```bash
#!/bin/bash
#
# module_name.sh - Module description
#

# Guard against multiple inclusion
[[ -n "${MODULE_NAME_LOADED:-}" ]] && return 0
readonly MODULE_NAME_LOADED=1

# Module dependencies
source "$LIB_DIR/dependency.sh" || exit 1

# Module constants
readonly MODULE_CONSTANT="value"

# Module functions
module_function() {
    # Implementation
}

# Module initialization (if needed)
_init_module() {
    # Setup code
}

# Initialize on source
_init_module
```

### Dependency Management

```bash
# Check and load dependencies
load_dependencies() {
    local deps=("colors.sh" "project.sh" "utils.sh")
    
    for dep in "${deps[@]}"; do
        local dep_path="$LIB_DIR/$dep"
        
        if [[ ! -f "$dep_path" ]]; then
            echo "Missing dependency: $dep" >&2
            return 1
        fi
        
        source "$dep_path" || {
            echo "Failed to load: $dep" >&2
            return 1
        }
    done
}
```

## Cross-Platform Patterns

### Platform Detection

```bash
detect_platform() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}
```

### Platform-Specific Code

```bash
get_sed_in_place_args() {
    if [[ "$(detect_platform)" == "macos" ]]; then
        echo "-i ''"
    else
        echo "-i"
    fi
}

# Usage
sed $(get_sed_in_place_args) 's/old/new/g' file.txt
```

## Logging Patterns

### Structured Logging

```bash
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        ERROR)
            print_color "RED" "[$timestamp] ERROR: $message" >&2
            ;;
        WARN)
            print_color "YELLOW" "[$timestamp] WARN: $message" >&2
            ;;
        INFO)
            [[ $VERBOSE -ge 1 ]] && \
                print_color "CYAN" "[$timestamp] INFO: $message"
            ;;
        DEBUG)
            [[ $VERBOSE -ge 2 ]] && \
                echo "[$timestamp] DEBUG: $message"
            ;;
    esac
}
```

## Testing Patterns

### Test Function Structure

```bash
test_function_name() {
    local description="$1"
    local expected="$2"
    local actual
    
    # Setup
    setup_test_environment
    
    # Execute
    actual=$(function_to_test)
    
    # Assert
    if [[ "$actual" == "$expected" ]]; then
        echo "✓ $description"
        return 0
    else
        echo "✗ $description"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        return 1
    fi
    
    # Cleanup
    cleanup_test_environment
}
```

## Performance Patterns

### Caching Pattern

```bash
# Simple cache implementation
declare -A CACHE

cached_operation() {
    local key="$1"
    
    # Check cache
    if [[ -n "${CACHE[$key]:-}" ]]; then
        echo "${CACHE[$key]}"
        return 0
    fi
    
    # Perform operation
    local result=$(expensive_operation "$key")
    
    # Store in cache
    CACHE[$key]="$result"
    
    echo "$result"
}
```

### Bulk Operations

```bash
# Process files in batches
process_files_batch() {
    local -a files=("$@")
    local batch_size=10
    local i
    
    for ((i=0; i<${#files[@]}; i+=batch_size)); do
        local batch=("${files[@]:i:batch_size}")
        
        # Process batch in parallel
        printf '%s\n' "${batch[@]}" | \
            xargs -P 4 -I {} process_file {}
    done
}
```

## Security Patterns

### Input Validation

```bash
validate_input() {
    local input="$1"
    local pattern="$2"
    
    if [[ ! "$input" =~ $pattern ]]; then
        error_exit "Invalid input: $input"
    fi
}

# Usage
validate_input "$email" '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
```

### Path Sanitization

```bash
sanitize_path() {
    local path="$1"
    
    # Remove directory traversal
    path="${path//../}"
    
    # Remove leading slashes
    path="${path#/}"
    
    # Ensure within bounds
    if [[ "$path" =~ ^\.\./ ]]; then
        error_exit "Invalid path: $path"
    fi
    
    echo "$path"
}
```

## Documentation Patterns

### Function Documentation

```bash
# @description Process a documentation file
# @param $1 - File path to process
# @param $2 - Output directory (optional)
# @return 0 on success, 1 on failure
# @example process_doc_file "README.md" "docs/"
process_doc_file() {
    local file="$1"
    local output_dir="${2:-docs}"
    
    # Implementation
}
```

## Conclusion

These patterns ensure Claudux maintains high code quality, reliability, and maintainability. Following these conventions makes the codebase consistent and easier to understand for contributors.

## See Also

- [Architecture](/technical/) - System architecture overview
- [Modules](/technical/modules) - Module documentation
- [Contributing](/development/contributing) - Contribution guidelines