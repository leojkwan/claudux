#!/bin/bash

# Validate that all links in VitePress config actually exist
# This prevents 404 errors in documentation

OUTPUT_FILE=""

# Parse optional args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      shift
      OUTPUT_FILE="${1:-}"
      shift || true
      ;;
    *)
      shift
      ;;
  esac
done

echo "🔍 Validating documentation links..."

# Check if docs directory exists
if [ ! -d "docs" ]; then
    echo "❌ docs/ directory not found"
    exit 1
fi

# Function to check for duplicate IDs in markdown files
check_duplicate_ids() {
    echo "🔍 Checking for duplicate heading IDs..."
    local duplicate_found=false
    
    # Extract all {#id} patterns from markdown files
    local temp_ids=$(mktemp)
    find docs -name "*.md" -type f -exec grep -H -o '{#[^}]*}' {} \; 2>/dev/null | \
        sed 's/{#\([^}]*\)}/\1/' > "$temp_ids" 2>/dev/null || true
    
    if [[ -s "$temp_ids" ]]; then
        # Check for duplicates
        local duplicates=$(cut -d: -f2 "$temp_ids" | sort | uniq -d)
        if [[ -n "$duplicates" ]]; then
            echo "❌ Duplicate heading IDs found:"
            while IFS= read -r duplicate_id; do
                if [[ -n "$duplicate_id" ]]; then
                    echo "   ID '$duplicate_id' appears in:"
                    grep -H "{#$duplicate_id}" docs/*.md docs/**/*.md 2>/dev/null | sed 's/^/     /'
                fi
            done <<< "$duplicates"
            duplicate_found=true
        fi
    fi
    
    rm -f "$temp_ids" 2>/dev/null
    
    if [[ "$duplicate_found" == "true" ]]; then
        echo "❌ Fix duplicate IDs before continuing"
        return 1
    else
        echo "✅ No duplicate heading IDs found"
        return 0
    fi
}

# Run duplicate ID check first
if ! check_duplicate_ids; then
    exit 1
fi

# Locate VitePress config (support .ts/.mjs/.js)
CONFIG_FILE=""
for f in docs/.vitepress/config.ts docs/.vitepress/config.mjs docs/.vitepress/config.js; do
  if [ -f "$f" ]; then
    CONFIG_FILE="$f"
    break
  fi
done

if [ -z "$CONFIG_FILE" ]; then
  echo "❌ docs/.vitepress/config.(ts|mjs|js) not found"
  exit 1
fi

# Extract links from config.ts sidebar and nav
# This is a simple grep - could be enhanced with proper parsing
LINKS=$(grep -oE "link:\s*['\"][^'\"]+['\"]" "$CONFIG_FILE" | sed "s/link: ['\"]//; s/['\"].*//")

BROKEN_LINKS=0
VALID_LINKS=0
EXTERNAL_LINKS=0
BROKEN_LIST=""

for link in $LINKS; do
    # Skip external URLs
    if echo "$link" | grep -Eq '^https?://|^mailto:'; then
        EXTERNAL_LINKS=$((EXTERNAL_LINKS + 1))
        continue
    fi

    # Remove hash anchors for file checking
    FILE_PATH=$(echo "$link" | sed 's/#.*//')
    
    # Normalize site-rooted paths and convert link to actual file path
    # Rules:
    #  - '/' maps to docs/index.md
    #  - '/path/' maps to docs/path/index.md
    #  - '/path' maps to docs/path.md
    if [[ "$FILE_PATH" == "/" ]]; then
        CHECK_PATH="docs/index.md"
    elif [[ "$FILE_PATH" == */ ]]; then
        CHECK_PATH="docs${FILE_PATH}index.md"
    else
        CHECK_PATH="docs${FILE_PATH}.md"
    fi
    
    # Check if file exists
    if [ ! -f "$CHECK_PATH" ]; then
        BROKEN_LIST="${BROKEN_LIST}   ❌ $link → Missing: $CHECK_PATH\n"
        if [[ -n "$OUTPUT_FILE" ]]; then
            echo "$CHECK_PATH" >> "$OUTPUT_FILE"
        fi
        BROKEN_LINKS=$((BROKEN_LINKS + 1))
    else
        VALID_LINKS=$((VALID_LINKS + 1))
    fi
done

echo ""
echo "📊 Link validation summary:"
echo "   ✅ Valid links: $VALID_LINKS"
if [ $EXTERNAL_LINKS -gt 0 ]; then
    echo "   🔗 External links: $EXTERNAL_LINKS (skipped)"
fi

if [ $BROKEN_LINKS -eq 0 ]; then
    echo ""
    echo "✅ All internal links validated successfully!"
else
    echo "   ❌ Broken links: $BROKEN_LINKS"
    echo ""
    echo "Broken links found:"
    echo -e "$BROKEN_LIST"
    echo "These files may need to be created or the links updated."
    exit 1
fi