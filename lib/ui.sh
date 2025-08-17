#!/bin/bash
# User interface and menu functions

# Show the main header
show_header() {
    load_project_config
    echo "📚 ClauDux - ${PROJECT_NAME} Documentation"
    echo "Powered by Claude AI - Everything stays local"
    echo ""
}

# Create CLAUDE.md by analyzing actual codebase patterns
create_claudux_md() {
    # Load project configuration first
    load_project_config
    
    if [[ -f "CLAUDE.md" ]]; then
        print_color "YELLOW" "⚠️  CLAUDE.md already exists!"
        echo ""
        echo "Current file contains $(wc -l < CLAUDE.md) lines"
        echo ""
        read -p "❓ Overwrite existing CLAUDE.md? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "📋 Keeping existing CLAUDE.md"
            return 0
        fi
    fi
    
    # Check Claude availability
    check_claude
    
    # No interactive preference capture; generation is fully automatic
    
    # Get model settings
    IFS='|' read -r model model_name timeout_msg cost_estimate <<< "$(get_model_settings)"
    
    # Detect project type and select an appropriate reference template
    local template_file
    case "$PROJECT_TYPE" in
        "ios")
            template_file="$LIB_DIR/templates/ios-claude.md"
            ;;
        "nextjs")
            template_file="$LIB_DIR/templates/nextjs-claude.md"
            ;;
        "react"|"javascript"|"nodejs")
            template_file="$LIB_DIR/templates/generic-claude.md"
            ;;
        *)
            template_file="$LIB_DIR/templates/generic-claude.md"
            ;;
    esac
    
    if [[ ! -f "$template_file" ]]; then
        print_color "RED" "❌ Template reference file not found: $template_file"
        return 1
    fi
    
    print_color "BLUE" "🧠 Analyzing $PROJECT_NAME codebase to generate coding patterns..."
    print_color "CYAN" "📋 Using $template_file as reference guide"
    echo ""
    
    # Create analysis prompt
    local prompt="Analyze this $PROJECT_TYPE project ($PROJECT_NAME) and create a CLAUDE.md file containing AI coding assistant rules and instructions based on the actual patterns and conventions used in this codebase.

**OBJECTIVE:**
Create a CLAUDE.md file that tells AI assistants (Claude, Cursor, etc.) HOW to work with this codebase. This is NOT documentation - it's a set of rules and instructions for AI to follow when modifying or extending the code.

**FORMAT REQUIREMENTS:**
The CLAUDE.md file should contain INSTRUCTIONS and RULES for AI assistants, structured like:
- Project overview (2-3 sentences max) 
- Key architecture decisions to respect
- Code style rules (MUST follow, SHOULD follow)
- Testing requirements (what tests to write, how to run them)
- Common patterns to use (with examples from actual code)
- Anti-patterns to avoid (what NOT to do)
- Project-specific commands and workflows
- File organization rules
- Important constraints and gotchas

**ANALYZE THE CODEBASE FOR:**
- Actual naming conventions used (files, functions, variables)
- Import/dependency patterns
- Error handling approaches
- State management patterns
- Testing strategies and tools
- Build and deployment processes
- Code formatting rules (if any)
- Security practices

**OUTPUT STYLE:**
Write as DIRECTIVES to an AI assistant. Use imperative mood. Examples:
- \"ALWAYS use TypeScript strict mode\"
- \"NEVER commit directly to main branch\"
- \"When creating new components, follow the pattern in src/components/Button.tsx\"
- \"Before modifying database schemas, check migrations in db/migrations/\"
- \"Run 'npm test' before committing any changes\"

**IMPORTANT:**
- Write rules based on ACTUAL patterns found in the code, not generic best practices
- Include specific file paths and function names as examples
- Make it actionable - every rule should guide AI behavior
- Keep it concise - focus on what's unique or critical to this project

Generate the CLAUDE.md file now."
    
    # Keep prompt minimal and code-driven; no user preference injection
    
    info "🤖 Claude analyzing $PROJECT_NAME codebase..."
    info "🧠 Using $model_name"
    info "⏳ This will analyze your actual code patterns..."
    echo ""
    
    # Call Claude to analyze and generate (non-interactive)
    claude \
        --print \
        --model "$model" \
        --allowedTools "Read,Write,Edit,Delete" \
        --permission-mode acceptEdits \
        "$prompt"
    
    local claude_exit_code=$?
    
    if [[ $claude_exit_code -eq 0 ]] && [[ -f "CLAUDE.md" ]]; then
        local line_count=$(wc -l < CLAUDE.md)
        print_color "GREEN" "✅ Generated project-specific CLAUDE.md ($line_count lines)"
        echo ""
        echo "💡 Next steps:"
        echo "  1. Review the generated patterns - they're based on your actual code"
        echo "  2. Customize any patterns that need adjustment"
        echo "  3. Run documentation update to use these patterns"
        echo ""
    else
        print_color "RED" "❌ Failed to analyze codebase with Claude"
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
            local fix_msg="Create the following missing documentation files with correct frontmatter, breadcrumbs, and minimal but accurate content; update navigation accordingly. Ensure config.ts links are valid. Missing files: ${file_list}. ${user_message}"
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
    echo "  ./claudux update         - Update docs with cleanup"
    echo "  ./claudux update -m \"message\""
    echo "                         - Update with a focused directive for Claude"
    echo "  ./claudux update --with \"directive\" [--strict]"
    echo "                         - Same as -m, --strict fails if links remain broken after auto-fix"
    echo "  ./claudux serve          - Start docs server (localhost:5173)"
    echo "  ./claudux validate       - Check for broken links in docs"
    echo "  ./claudux repair [-m \"message\"]"
    echo "                         - Validate and auto-create missing pages using Claude"
    echo "  ./claudux clean          - Clean up obsolete docs only"
    echo "  ./claudux recreate       - Start fresh (delete all docs)"
    echo "  ./claudux create-template - Analyze codebase and generate CLAUDE.md"
    echo "  ./claudux help           - Show this help"
    echo ""
    echo "Options:"
    echo "  --with, -m               - Provide a high-level directive to guide generation"
    echo "  --strict                 - Exit with error if links remain broken after auto-fix"
    echo "  -v / -vv                 - Increase verbosity (set CLAUDUX_VERBOSE=1/2)"
    echo "  -q                       - Quiet (errors only)"
    echo ""
    echo "Environment:"
    echo "  FORCE_MODEL=opus|sonnet  - Select Claude model (default: opus)"
    echo "  CLAUDUX_MESSAGE=...      - Default directive if -m/--with not provided"
    echo "  CLAUDUX_VERBOSE=0|1|2    - Verbosity level (0 default)"
    echo ""
    echo "💡 The main update command automatically:"
    echo "  • Runs two-phase generation in a single Claude session"
    echo "  • Phase 1: Analyzes entire project and creates a plan"
    echo "  • Phase 2: Executes the plan and generates documentation"
    echo "  • Uses semantic analysis to detect obsolete content"
    echo "  • Shows detailed reasoning for all changes"
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
            "Create CLAUDE.md           (AI context file)" \
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
                "Create CLAUDE.md           (AI context file)")
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
            "Validate links             (test all doc links)" \
            "Repair links               (validate and auto-fix)" \
            "Clean obsolete             (rm stale .md files)" \
            "Create CLAUDE.md           (AI context file)" \
            "Recreate                   (rm -rf docs && update)" \
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
                "Validate links             (test all doc links)")
                    echo ""
                    validate_links
                    break
                    ;;
                "Repair links               (validate and auto-fix)")
                    echo ""
                    validate_links --auto-fix
                    break
                    ;;
                "Clean obsolete             (rm stale .md files)")
                    echo ""
                    cleanup_docs
                    break
                    ;;
                "Create CLAUDE.md           (AI context file)")
                    echo ""
                    create_claudux_md
                    break
                    ;;
                "Recreate                   (rm -rf docs && update)")
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
    echo "→ ./claudux --help"
}