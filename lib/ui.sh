#!/bin/bash
# User interface and menu functions

# Show the main header
show_header() {
    load_project_config
    echo "📚 claudux - ${PROJECT_NAME} Documentation"
    echo "Powered by Claude AI - Everything stays local"
    echo ""
}

# Create claudux.md (docs site preferences)
create_claudux_md() {
    # Load project configuration first
    load_project_config
    
    if [[ -f "claudux.md" ]]; then
        print_color "YELLOW" "⚠️  claudux.md already exists!"
        echo ""
        echo "Current file contains $(wc -l < claudux.md) lines"
        echo ""
        read -p "❓ Overwrite existing claudux.md? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "📋 Keeping existing claudux.md"
            return 0
        fi
    fi
    
    # Check Claude availability
    check_claude
    
    # No interactive preference capture; generation is fully automatic
    
    # Get model settings
    IFS='|' read -r model model_name timeout_msg cost_estimate <<< "$(get_model_settings)"
    
    print_color "BLUE" "🧠 Analyzing $PROJECT_NAME to generate docs preferences..."
    echo ""
    
    # Create analysis prompt
    local prompt="Analyze this $PROJECT_TYPE project ($PROJECT_NAME) and create a claudux.md file that captures USER PREFERENCES for how the documentation website should be structured.

PURPOSE:
- claudux.md is a human-authored preferences file that guides documentation generation and VitePress layout. It is NOT the documentation itself.

DELIVERABLE: Write a new file named 'claudux.md' in the project root with concise, opinionated preferences. Use markdown with clear section headings and short bullet lists.

REQUIRED SECTIONS (keep concise):
- Site
  - title, description (1 line each)
  - preferred nav items (top-level) with desired order
  - logo policy (auto-detect | none)
- Structure
  - which sections to include (guide, features, technical, api, development, examples)
  - which sections to omit
  - sidebar policy (unified '/' sidebar vs per-section), depth levels, collapsed defaults
- Pages
  - must-have pages (e.g., /guide/index, /guide/installation, /features/index)
  - page ordering rules (alphabetical | custom groups)
  - naming conventions (Title Case, emoji usage yes/no)
- Links
  - internal link rules (use '/guide/' for index pages, avoid placeholders)
  - external links to include in nav (GitHub, npm) if detectable
- Policies
  - base path policy (local '/' with CI override via DOCS_BASE)
  - verbosity (be explicit, avoid placeholders), no broken links
  - protected content guidance (do not edit notes/, private/, or <!-- skip --> sections)

GUIDELINES:
- Derive sensible defaults from the codebase and package metadata when possible.
- Keep preferences high-level and durable; avoid project-internal trivia.
- Prefer single-line bullets; avoid long paragraphs.

OUTPUT:
- Create/overwrite 'claudux.md' with the preferences above."
    
    # Keep prompt minimal and code-driven; no user preference injection
    
    info "🤖 Claude analyzing $PROJECT_NAME..."
    info "🧠 Using $model_name"
    info "⏳ This will analyze your actual code patterns..."
    echo ""
    
    # Call Claude to analyze and generate (non-interactive)
    claude \
        --print \
        --model "$model" \
        --allowedTools "Read,Write,Edit,Delete" \
        --permission-mode acceptEdits \
        --verbose \
        "$prompt"
    
    local claude_exit_code=$?
    
    if [[ $claude_exit_code -eq 0 ]] && [[ -f "claudux.md" ]]; then
        local line_count=$(wc -l < claudux.md)
        print_color "GREEN" "✅ Generated claudux.md (docs preferences) ($line_count lines)"
        echo ""
        echo "💡 Next steps:"
        echo "  1. Review and adjust preferences as needed"
        echo "  2. Run 'claudux update' to generate docs honoring these preferences"
        echo ""
    else
        print_color "RED" "❌ Failed to generate claudux.md with Claude"
        return 1
    fi
}

# Validate links in documentation
validate_links() {
    info "🔍 Running link validation..."
    echo ""

    local auto_fix=false
    local user_message=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --auto-fix)
                auto_fix=true
                shift
                ;;
            -m|--message)
                shift
                user_message="${1:-}"
                shift || true
                ;;
            *)
                shift
                ;;
        esac
    done
    
    if [[ ! -d "docs" ]]; then
        error_exit "❌ No documentation found. Generate docs first with 'claudux update'"
    fi
    
    if [[ ! -f "$LIB_DIR/validate-links.sh" ]]; then
        error_exit "❌ Link validation script not found"
    fi
    
    # Run validation script; also capture machine-readable list when failing
    local missing_tmp=$(mktemp /tmp/claudux-missing-XXXXXX || mktemp)
    rm -f "$missing_tmp" 2>/dev/null || true
    "$LIB_DIR/validate-links.sh"
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        # Try again to collect a list for auto-fix flow
        "$LIB_DIR/validate-links.sh" --output "$missing_tmp" >/dev/null 2>&1 || true
    fi
    
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        success "✅ All links are valid!"
    else
        warn "⚠️  Some links are broken."
        if $auto_fix && [[ -s "$missing_tmp" ]]; then
            local file_list=$(sed 's#^docs/##' "$missing_tmp" | tr '\n' ' ')
            info "🛠️  Auto-fixing by asking Claude to create: $file_list"
            local fix_msg="Create the following missing documentation files with correct frontmatter and minimal but accurate content; update navigation accordingly. Ensure config.ts links are valid. Missing files: ${file_list}. ${user_message}"
            CLAUDUX_AUTOFIXED=1 update -m "$fix_msg"
            return $?
        else
            warn "Run: claudux update -m 'Fill all missing pages and fix broken links'"
        fi
    fi
    
    return $exit_code
}

# Show help and usage information
show_help() {
    echo ""
    echo "💡 Quick Tips:"
    echo "• Use '<!-- skip -->' to protect sensitive content"
    echo "• The 'notes/' folder is automatically protected" 
    echo "• Everything runs locally - no data leaves your machine"
    echo "• Press Ctrl+C anytime to cancel"
    echo ""
    echo "🔧 Command line usage:"
    echo "  ./claudux                - Show interactive menu"
    echo "  ./claudux update         - Update docs (includes cleanup and validation)"
    echo "  ./claudux update -m \"message\""
    echo "                         - Update with a focused directive for Claude"
    echo "  ./claudux serve          - Start docs server (localhost:5173)"
    echo "  ./claudux recreate       - Start fresh (delete all docs)"
    echo "  ./claudux template       - Generate claudux.md (docs preferences)"
    echo "  ./claudux help           - Show this help"
    echo ""
    echo "Options:"
    echo "  --with, -m               - Provide a high-level directive to guide generation"
    echo "  -q                       - Quiet (errors only)"
    echo ""
    echo "Environment:"
    echo "  FORCE_MODEL=opus|sonnet  - Select Claude model (default: sonnet)"
    echo "  CLAUDUX_MESSAGE=...      - Default directive if -m/--with not provided"
    echo ""
    echo "💡 The main update command automatically:"
    echo "  • Scans your codebase and updates docs"
    echo "  • Uses semantic analysis to detect obsolete content"
    echo "  • Validates links to prevent 404s"
    echo ""
    echo "🌟 Advanced features:"
    echo "  • Automatic link validation prevents 404 errors"
    echo "  • Dynamic VitePress config based on your project"
    echo "  • Intelligent logo/icon detection for mobile apps"
    echo "  • 3-column layout with breadcrumbs built-in"
    echo ""
    echo "📁 Protected paths:"
    echo "  • notes/, private/, .git/, node_modules/"
    echo "  • *.env, *.key, *.pem files"
    echo "  • Use skip markers to protect specific content"
    echo ""
}

# Interactive menu system
show_menu() {
    # Check if docs exist to determine menu type
    local has_docs=false
    if [[ -d "docs" ]] && [[ -f "docs/index.md" ]] && [[ $(ls -A docs/*.md 2>/dev/null | wc -l) -gt 1 ]]; then
        has_docs=true
    fi
    
    if [[ "$has_docs" == "false" ]]; then
        # First run menu - no docs yet
        echo "Select:"
        echo ""
        
        PS3="> "
        
        select choice in \
            "Generate docs              (scan code → markdown)" \
            "Serve                      (vitepress dev server)" \
            "Create claudux.md           (docs preferences)" \
            "Exit"
        do
            case $choice in
                "Generate docs              (scan code → markdown)")
                    echo ""
                    update
                    break
                    ;;
                "Serve                      (vitepress dev server)")
                    echo ""
                    serve
                    break
                    ;;
                "Create claudux.md           (docs preferences)")
                    echo ""
                    create_claudux_md
                    break
                    ;;
                "Exit")
                    echo ""
                    exit 0
                    ;;
                *)
                    print_color "RED" "Invalid"
                    ;;
            esac
        done
    else
        # Existing project menu - docs present
        echo "Select:"
        echo ""
        
        PS3="> "
        
        select choice in \
            "Update docs                (regenerate from code)" \
            "Update (focused)           (enter directive → update)" \
            "Serve                      (vitepress dev server)" \
            "Create claudux.md           (docs preferences)" \
            "Recreate                   (start fresh)" \
            "Exit"
        do
            case $choice in
                "Update docs                (regenerate from code)")
                    echo ""
                    update
                    break
                    ;;
                "Update (focused)           (enter directive → update)")
                    echo ""
                    read -r -p "Enter focused directive (leave empty to cancel): " directive
                    if [[ -n "$directive" ]]; then
                        update --with "$directive"
                    else
                        warn "No directive entered; cancelled."
                    fi
                    break
                    ;;
                "Serve                      (vitepress dev server)")
                    echo ""
                    serve
                    break
                    ;;
                "Create claudux.md           (docs preferences)")
                    echo ""
                    create_claudux_md
                    break
                    ;;
                "Recreate                   (start fresh)")
                    echo ""
                    recreate_docs
                    break
                    ;;
                "Exit")
                    echo ""
                    exit 0
                    ;;
                *)
                    print_color "RED" "Invalid"
                    ;;
            esac
        done
    fi
    
    # Footer hint
    echo ""
    echo "Run 'claudux --help' for help."
}