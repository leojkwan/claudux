#!/bin/bash

# Validate that all links in VitePress config actually exist
# This prevents 404 errors in documentation

echo "🔍 Validating documentation links..."

# Check if docs directory exists
if [ ! -d "docs" ]; then
    echo "❌ docs/ directory not found"
    exit 1
fi

# Check if config.ts exists
if [ ! -f "docs/.vitepress/config.ts" ]; then
    echo "❌ docs/.vitepress/config.ts not found"
    exit 1
fi

# Extract links from config.ts sidebar and nav
# This is a simple grep - could be enhanced with proper parsing
LINKS=$(grep -oE "link:\s*['\"]([^'\"]+)" docs/.vitepress/config.ts | sed -E "s/link:\s*['\"]([^'\"]+)/\1/")

BROKEN_LINKS=0

for link in $LINKS; do
    # Remove hash anchors for file checking
    FILE_PATH=$(echo "$link" | sed 's/#.*//')
    
    # Convert link to actual file path
    if [[ "$FILE_PATH" == */ ]]; then
        # Directory link - check for index.md
        CHECK_PATH="docs${FILE_PATH}index.md"
    else
        # File link - add .md extension
        CHECK_PATH="docs${FILE_PATH}.md"
    fi
    
    # Check if file exists
    if [ ! -f "$CHECK_PATH" ]; then
        echo "❌ Broken link: $link → Missing: $CHECK_PATH"
        BROKEN_LINKS=$((BROKEN_LINKS + 1))
    else
        echo "✅ Valid link: $link → Found: $CHECK_PATH"
    fi
done

if [ $BROKEN_LINKS -eq 0 ]; then
    echo ""
    echo "✅ All links validated successfully!"
else
    echo ""
    echo "❌ Found $BROKEN_LINKS broken links"
    echo "Please ensure all files referenced in config.ts are created"
    exit 1
fi