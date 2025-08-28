#!/bin/bash
# Project detection and configuration utilities

# Load project configuration from claudux.json or .claudux.json
load_project_config() {
    PROJECT_NAME="Your Project"
    PROJECT_TYPE="generic"
    
    # Try claudux.json first
    if [[ -f "claudux.json" ]] && command -v jq &> /dev/null; then
        PROJECT_NAME=$(jq -r '.project.name // "Your Project"' claudux.json 2>/dev/null || echo "Your Project")
        PROJECT_TYPE=$(jq -r '.project.type // "generic"' claudux.json 2>/dev/null || echo "generic")
    # Fallback to .claudux.json
    elif [[ -f ".claudux.json" ]]; then
        if command -v jq &> /dev/null; then
            PROJECT_NAME=$(jq -r '.name // "Your Project"' .claudux.json 2>/dev/null || echo "Your Project")
            PROJECT_TYPE=$(jq -r '.type // empty' .claudux.json 2>/dev/null || echo "")
        elif grep -q '"name"' .claudux.json 2>/dev/null; then
            PROJECT_NAME=$(grep '"name"' .claudux.json | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' 2>/dev/null || echo "Your Project")
        fi
    fi
    
    # Auto-detect type if not specified
    if [[ -z "$PROJECT_TYPE" ]] || [[ "$PROJECT_TYPE" == "generic" ]]; then
        PROJECT_TYPE=$(detect_project_type)
    fi
    
    export PROJECT_NAME
    export PROJECT_TYPE
}

# Detect project type from file patterns
detect_project_type() {
    # iOS/Swift project
    if [[ -f "Project.swift" ]] || [[ -n "$(find . -maxdepth 1 -name "*.xcodeproj" -o -name "*.xcworkspace" 2>/dev/null | head -1)" ]]; then
        echo "ios"
    # Next.js project (check before React)
    elif [[ -f "next.config.js" ]] || [[ -f "next.config.mjs" ]] || [[ -f "next.config.ts" ]] || ([[ -f "package.json" ]] && grep -q '"next"' package.json 2>/dev/null); then
        echo "nextjs"
    # React project
    elif [[ -f "package.json" ]] && grep -q '"react"' package.json 2>/dev/null; then
        echo "react"
    # Node.js project
    elif [[ -f "package.json" ]] && grep -q '"@types/node"' package.json 2>/dev/null; then
        echo "nodejs"
    # JavaScript project
    elif [[ -f "package.json" ]]; then
        echo "javascript"
    # Rust project
    elif [[ -f "Cargo.toml" ]]; then
        echo "rust"
    # Python project
    elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]; then
        echo "python"
    # Go project
    elif [[ -f "go.mod" ]]; then
        echo "go"
    # Java project
    elif [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
        echo "java"
    else
        echo "generic"
    fi
}

# Find project logo/icon
find_project_logo() {
    local logo_path=""
    
    # iOS app icon
    if [[ "$PROJECT_TYPE" == "ios" ]]; then
        # Look for app icon in Assets
        logo_path=$(find . -path "*/Assets.xcassets/AppIcon.appiconset/*.png" -o -path "*/Assets.xcassets/AppIcon.appiconset/*.jpg" 2>/dev/null | grep -E "(1024|512)" | head -1)
        
        # Try other common locations
        if [[ -z "$logo_path" ]]; then
            logo_path=$(find . -name "logo*.png" -o -name "logo*.jpg" -o -name "icon*.png" -o -name "icon*.jpg" 2>/dev/null | grep -v node_modules | head -1)
        fi
    else
        # Generic logo search
        logo_path=$(find . -maxdepth 3 -name "logo*.png" -o -name "logo*.jpg" -o -name "logo*.svg" -o -name "icon*.png" -o -name "icon*.svg" 2>/dev/null | grep -v node_modules | head -1)
    fi
    
    echo "$logo_path"
}