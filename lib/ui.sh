#!/bin/bash
# User interface and menu functions

# Show the main header
show_header() {
    load_project_config
    echo "📚 ClauDux - ${PROJECT_NAME} Documentation"
    echo "Powered by Claude AI - Everything stays local"
    echo ""
}

# Create claudux.md by analyzing actual codebase patterns
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
    
    # Get model settings
    IFS='|' read -r model model_name timeout_msg cost_estimate <<< "$(get_model_settings)"
    
    # Detect project type and template reference
    local template_file
    case "$PROJECT_TYPE" in
        "ios")
            template_file="$LIB_DIR/templates/ios-claudux.md"
            ;;
        *)
            print_color "YELLOW" "⚠️  Using iOS template as reference"
            template_file="$LIB_DIR/templates/ios-claudux.md"  # Default to iOS for now
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
    local prompt="Analyze this $PROJECT_TYPE project ($PROJECT_NAME) and create a project-specific claudux.md file containing the actual coding patterns and conventions used in this codebase.

**INSTRUCTIONS:**
1. **Use Template as Reference**: Read $template_file as a reference guide for structure and types of patterns to look for
2. **Analyze Real Code**: Examine the actual source files, architecture, and implementation patterns
3. **Generate Project-Specific Content**: Create claudux.md with patterns that actually exist in this project

**WHAT TO ANALYZE:**
- Architecture patterns (how components are organized)
- Dependency injection patterns (managers, protocols, initialization)
- State management approaches (ViewModels, data flow)
- Code organization (directory structure, file naming)
- Testing patterns (mocking, test data, strategies)
- Error handling approaches
- Performance considerations
- Common utilities and extensions

**OUTPUT REQUIREMENTS:**
- Create claudux.md with real examples from this codebase
- Use actual class names, protocols, and file names when possible
- Include code snippets from real files
- Explain WHY these patterns were chosen for this project
- Make it specific to $PROJECT_NAME, not generic advice

**IMPORTANT:**
- This should reflect the ACTUAL patterns in this project
- Use real code examples, not hypothetical ones
- Document the reasoning behind architectural decisions
- Include project-specific context and constraints

Generate the claudux.md file now."
    
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
    
    if [[ $claude_exit_code -eq 0 ]] && [[ -f "claudux.md" ]]; then
        local line_count=$(wc -l < claudux.md)
        print_color "GREEN" "✅ Generated project-specific claudux.md ($line_count lines)"
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
    echo "  ./claudux dev            - Start docs server (alias for serve)"
    echo "  ./claudux serve          - Start docs server"
    echo "  ./claudux create-template - Analyze codebase and generate claudux.md patterns"
    echo "  ./claudux clean          - Clean up obsolete docs only"
    echo "  ./claudux recreate       - Start fresh (delete all docs)"
    echo "  ./claudux help           - Show this help"
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
    echo "Choose an option:"
    echo ""
    
    # Set PS3 for select prompt
    PS3="Select (1-7): "
    
    select choice in \
        "Update documentation (analyze codebase & generate docs)" \
        "Start documentation server" \
        "Generate claudux.md from codebase analysis" \
        "Show help and tips" \
        "Clean obsolete files only" \
        "Recreate docs (start fresh)" \
        "Exit"
    do
        case $choice in
            "Update documentation (analyze codebase & generate docs)")
                echo ""
                update
                break
                ;;
            "Start documentation server")
                echo ""
                serve
                break
                ;;
            "Generate claudux.md from codebase analysis")
                echo ""
                create_claudux_md
                break
                ;;
            "Show help and tips")
                echo ""
                show_help
                break
                ;;
            "Clean obsolete files only")
                echo ""
                cleanup_docs
                break
                ;;
            "Recreate docs (start fresh)")
                echo ""
                recreate_docs
                break
                ;;
            "Exit")
                echo ""
                echo "👋 Goodbye!"
                exit 0
                ;;
            *)
                print_color "RED" "❌ Invalid option. Please choose 1-7."
                ;;
        esac
    done
}