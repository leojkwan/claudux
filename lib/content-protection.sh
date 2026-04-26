#!/bin/bash
# Content protection utilities for handling sensitive content

# Get protection markers for different file types
get_protection_markers() {
    local file="$1"
    local ext="${file##*.}"
    
    case "$ext" in
        md|markdown)
            printf '%s\n%s\n' "<!-- skip -->" "<!-- /skip -->"
            ;;
        swift|js|ts|jsx|tsx|java|c|cpp|h|hpp|rs|go)
            printf '%s\n%s\n' "// skip" "// /skip"
            ;;
        py|sh|bash|zsh|rb|pl)
            printf '%s\n%s\n' "# skip" "# /skip"
            ;;
        html|xml|vue)
            printf '%s\n%s\n' "<!-- skip -->" "<!-- /skip -->"
            ;;
        css|scss|sass|less)
            printf '%s\n%s\n' "/* skip */" "/* /skip */"
            ;;
        sql)
            printf '%s\n%s\n' "-- skip" "-- /skip"
            ;;
        *)
            # Default to hash comment
            printf '%s\n%s\n' "# skip" "# /skip"
            ;;
    esac
}

# Strip protected content from a file
strip_protected_content() {
    local file="$1"
    local temp_file
    temp_file=$(mktemp)
    
    if [[ ! -f "$file" ]]; then
        echo "$file"
        return 1
    fi
    
    # Get appropriate comment markers for this file type. Markers contain
    # spaces, so read them as two literal lines rather than shell words.
    local start_marker=""
    local end_marker=""
    {
        IFS= read -r start_marker
        IFS= read -r end_marker
    } < <(get_protection_markers "$file")
    
    # Remove protected sections using literal full-line marker matching.
    awk -v start="$start_marker" -v end="$end_marker" '
        function trim(value) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            return value
        }
        trim($0) == start { skip=1; next }
        trim($0) == end { skip=0; next }
        !skip { print }
    ' "$file" > "$temp_file"
    
    echo "$temp_file"
}

# Check if a path should be protected
is_protected_path() {
    local path="$1"
    
    # Protected directories
    if [[ "$path" =~ ^(notes|private|.git|node_modules|vendor|target|build|dist)/ ]]; then
        return 0
    fi
    
    # Protected files
    if [[ "$path" =~ \.(env|key|pem|p12|keystore)$ ]]; then
        return 0
    fi
    
    return 1
}
