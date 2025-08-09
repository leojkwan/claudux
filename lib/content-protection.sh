#!/bin/bash
# Content protection utilities for handling sensitive content

# Get protection markers for different file types
get_protection_markers() {
    local file="$1"
    local ext="${file##*.}"
    
    case "$ext" in
        md|markdown)
            echo "<!-- skip -->" "<!-- /skip -->"
            ;;
        swift|js|ts|jsx|tsx|java|c|cpp|h|hpp|rs|go)
            echo "// skip" "// /skip"
            ;;
        py|sh|bash|zsh|rb|pl)
            echo "# skip" "# /skip"
            ;;
        html|xml|vue)
            echo "<!-- skip -->" "<!-- /skip -->"
            ;;
        css|scss|sass|less)
            echo "/* skip */" "/* /skip */"
            ;;
        sql)
            echo "-- skip" "-- /skip"
            ;;
        *)
            # Default to hash comment
            echo "# skip" "# /skip"
            ;;
    esac
}

# Strip protected content from a file
strip_protected_content() {
    local file="$1"
    local temp_file=$(mktemp)
    
    if [[ ! -f "$file" ]]; then
        echo "$file"
        return 1
    fi
    
    # Get appropriate comment markers for this file type
    local markers=($(get_protection_markers "$file"))
    local start_marker="${markers[0]}"
    local end_marker="${markers[1]}"
    
    # Remove protected sections using awk
    awk -v start="$start_marker" -v end="$end_marker" '
        $0 ~ start { skip=1; next }
        $0 ~ end { skip=0; next }
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