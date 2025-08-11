#!/bin/bash
# Documentation generation and update functions

# Build the comprehensive prompt for Claude
build_generation_prompt() {
    local project_type="$1"
    local project_name="$2"
    local user_directive="${3:-}"
    
    # Check for configuration files
    local style_guide=""
    local template_config=""
    local docs_map=""
    
    # AI style guide locations
    for location in ".ai-docs-style.md" "$HOME/.ai-docs-style.md" "/usr/local/share/.ai-docs-style.md"; do
        if [[ -f "$location" ]]; then
            style_guide="$location"
            break
        fi
    done
    
    # Template configuration (support both directory and file naming styles)
    if [[ -f "$LIB_DIR/templates/${project_type}/config.json" ]]; then
        template_config="$LIB_DIR/templates/${project_type}/config.json"
    elif [[ -f "$LIB_DIR/templates/${project_type}-project-config.json" ]]; then
        template_config="$LIB_DIR/templates/${project_type}-project-config.json"
    elif [[ -f "$LIB_DIR/templates/${project_type}-config.json" ]]; then
        template_config="$LIB_DIR/templates/${project_type}-config.json"
    elif [[ -f "$LIB_DIR/templates/generic/config.json" ]]; then
        template_config="$LIB_DIR/templates/generic/config.json"
    fi
    
    # Documentation map
    for mapfile in "docs-map.md" "docs-structure.json"; do
        if [[ -f "$mapfile" ]]; then
            docs_map="$mapfile"
            break
        fi
    done
    
    # Project-specific coding patterns (claudux.md)
    local claudux_patterns=""
    if [[ -f "claudux.md" ]]; then
        claudux_patterns="claudux.md"
    fi
    
    # Build the prompt
    local prompt="Analyze this ${project_type} project (${project_name}) and intelligently update the documentation following these guidelines:

**STEP 1: Read Configuration Files**"
    
    if [[ -n "$template_config" ]]; then
        prompt+="
- Read $template_config for ${project_type}-specific documentation patterns and structure"
    fi
    
    if [[ -n "$style_guide" ]]; then
        prompt+="
- Read $style_guide for universal AI documentation principles"
    fi
    
    if [[ -n "$docs_map" ]]; then
        prompt+="
- Read $docs_map for loose documentation guidance and protected areas"
    fi
    
    if [[ -n "$claudux_patterns" ]]; then
        prompt+="
- Read $claudux_patterns for project-specific coding patterns, conventions, and architectural guidelines"
    fi
    
    prompt+="

**STEP 2: Analyze Codebase**
- Examine the current source files, build configuration, and architecture patterns
- Identify what documentation needs updating based on the structure configuration
- Focus on the specific areas and file patterns defined in the project config

**STEP 3: Two-Phase Documentation Generation**

==== PHASE 1: COMPREHENSIVE ANALYSIS & PLANNING ====
🧠 First, analyze the entire project and create a detailed plan:

1. **Read Configuration & Templates**:
   - Load all template configs, style guides, and docs-map files
   - Read lib/vitepress/sidebar-example.md for sidebar configuration patterns
   - Understand the expected documentation structure
   - Note any protected areas or special requirements

2. **Analyze Codebase Structure**:
   - Scan source code to understand architecture
   - Identify key components, APIs, and features
   - Note testing approaches and build systems
   - Find main entry points and public interfaces

3. **Audit Existing Documentation**:
   - List all existing documentation files
   - Cross-reference each doc against current code
   - Identify outdated content (with confidence scores)
   - Find missing documentation gaps

4. **Create Detailed Execution Plan**:
   - List all NEW files to create with descriptions
   - List all files to UPDATE with specific changes
   - List any OBSOLETE files with 95%+ confidence
   - Show the final documentation structure

 5. **Generate VitePress Configuration**:
   - Create docs/.vitepress/config.ts based on your analysis
   - Auto-detect project name, description from package.json/README
   - For mobile apps, find and use app icon from Assets/Resources
    - Build sidebar structure matching your planned documentation
    - Include proper navigation categories
    - Set up social links based on detected repository
   - Enable 3-column layout with outline configuration
    - Import the custom theme: \`import { defineConfig } from 'vitepress'\`
   - Reference config.template.ts for VitePress config structure
   - IMPORTANT: Reference sidebar-example.md for proper sidebar configuration
   
   The config MUST include:
   - Dynamic sidebar object matching your doc structure
   - CRITICAL: Sidebar must appear on ALL pages including root:
     * Add a '/' root section to sidebar config
     * Include the same sidebar items for '/' as other sections
     * Example: sidebar: { '/': [...items], '/guide/': [...items] }
   - outline: { level: [2, 3], label: 'On this page' }
   - Proper nav array with main sections
   - Logo path if found
   - Clean URLs enabled

 6. **Validate All Links**:
   CRITICAL: Every link in config.ts MUST correspond to a file you plan to create!
   - For each sidebar item link (e.g., '/guide/setup'), ensure you're creating 'guide/setup.md'
   - For hash links (e.g., '/guide/setup#installation'), ensure that heading exists
   - For nav links, verify the target files will exist
   - Use '/guide/' for index pages (maps to '/guide/index.md')
   - NO broken links allowed - this is a quality gate

 IMPORTANT: The config.ts must have zero broken links. Cross-check every link against your planned files.

 Platform guardrails:
  - For non-iOS projects, DO NOT include iOS-specific concepts, links, or pages (e.g., Tuist, SwiftData, CloudKit, App Store, TestFlight, Xcode). Only include them for \`project_type=ios\`.
 - Resources menu must include only links with absolute URLs you can determine (e.g., detected GitHub repo). Do not add placeholder links like '#'.
 - The nav must only include sections for which you will create pages (e.g., omit '/technical/' if you are not creating 'docs/technical/index.md').

Output your complete analysis and plan, then proceed to Phase 2.

==== PHASE 2: EXECUTE THE PLAN ====
✏️ Now systematically execute your plan from Phase 1:

**CREATE New Documentation**:
- Generate all planned documentation files
- Use accurate, current code examples
- Follow template structures exactly
- Reference claudux.md for project-specific coding patterns and conventions when creating technical documentation
- Ensure all internal links work
- Add breadcrumb navigation at the top of EVERY page (except root):
  * Format: [Home](/) > [Section](/section/) > Current Page
  * Example: [Home](/) > [Guide](/guide/) > [Setup](/guide/setup)
  * Place as first line of content after frontmatter
  * Use descriptive names, not paths

VitePress Routing Rules:
- '/guide/' → 'docs/guide/index.md'
- '/guide/setup' → 'docs/guide/setup.md'
- '/guide/setup#install' → 'docs/guide/setup.md' with ## Install heading
- Always create index.md for directory roots

**UPDATE Existing Documentation**:
- Fix all outdated information identified
- Add missing sections or details
- Update code examples to current versions
- Preserve valuable existing content
- Ensure breadcrumb navigation exists at top of page
- Update breadcrumbs if file has moved or been renamed

**REMOVE Obsolete Files** (95%+ confidence only):
- Delete files referencing non-existent code
- Remove docs for deleted features
- Clean up superseded duplicate content

🎯 Quality Checks:
- Every code example must be from actual current code
- All links must point to existing files
- Technical details must match implementation
- No hypothetical or placeholder content"
    
    # Append user directive if provided
    if [[ -n "$user_directive" ]]; then
        prompt+="

**USER DIRECTIVE (Highest Priority)**
- ${user_directive}

Strictly adhere to this directive while keeping ZERO broken links in config.ts and ensuring every link maps to a real file you create."
    fi

    echo "$prompt"
}

# Main update function
update() {
    # Parse optional flags (e.g., -m/--message/--with for a focused run)
    local user_message="${CLAUDUX_MESSAGE:-}"
    local already_autofixed="${CLAUDUX_AUTOFIXED:-}" # env guard to avoid loops
    local strict_mode=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--message|--with)
                shift
                user_message="${1:-}"
                shift || true
                ;;
            --strict)
                strict_mode=true
                shift
                ;;
            --)
                shift; break ;;
            -*)
                error_exit "Unknown option for 'update': $1. Usage: claudux update [--with|-m \"message\"] [--strict]" 2
                ;;
            *)
                error_exit "Unexpected argument: $1" 2
                ;;
        esac
    done
    info "📊 Starting documentation update and cleanup..."
    echo ""
    
    # Show current git status
    show_git_status
    echo ""
    
    # First, clean up obsolete files
    warn "🧹 Step 1: Cleaning obsolete files..."
    cleanup_docs_silent
    echo ""
    
    # Get model settings
    IFS='|' read -r model model_name timeout_msg cost_estimate <<< "$(get_model_settings)"
    
    # Set up automatic mode
    warn "🤖 Step 2: Running two-phase documentation generation..."
    info "📊 Phase 1: Comprehensive analysis and planning"
    info "✏️  Phase 2: Executing the plan and generating docs"
    
    warn "🤖 Claude analyzing project and generating documentation..."
    info "🧠 Using $model_name"
    info "🔧 Tools: Read, Write, Edit, Delete | Auto-accept mode"
    info "🚀 Two-phase generation in single session"
    success "$cost_estimate"
    warn "$timeout_msg"
    echo ""
    
    # Start progress indicator
    local progress_pid=$(show_progress 15 45)
    
    # Build the prompt
    info "📝 Building prompt for $PROJECT_TYPE project..."
    if [[ -n "$user_message" ]]; then
        info "🎯 Focused directive: ${user_message:0:120}"
    fi
    load_project_config
    
    # Debug project config
    info "   Project: $PROJECT_NAME (type: $PROJECT_TYPE)"
    
    local prompt=$(build_generation_prompt "$PROJECT_TYPE" "$PROJECT_NAME" "$user_message")
    
    # Check if prompt was built successfully
    if [[ -z "$prompt" ]]; then
        warn "❌ Failed to build generation prompt"
        warn "   PROJECT_TYPE: $PROJECT_TYPE"
        warn "   PROJECT_NAME: $PROJECT_NAME"
        warn "   Working directory: $(pwd)"
        error_exit "Cannot continue without a valid prompt"
    else
        success "✅ Prompt built successfully (${#prompt} chars)"
    fi
    
    # Run Claude
    echo "" # Ensure clean line before Claude output
    info "🚀 Starting documentation generation..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Save prompt for debugging
    echo "$prompt" > /tmp/claudux-prompt.txt
    
    # Run Claude with real-time output (no buffering)
    local claude_exit_code=0
    if command -v stdbuf &> /dev/null; then
        # Use stdbuf to disable output buffering for real-time display
        stdbuf -o0 -e0 claude \
            --print \
            --model "$model" \
            --allowedTools "Read,Write,Edit,Delete" \
            --permission-mode acceptEdits \
            "$prompt" 2>&1 | tee /tmp/claudux-claude.log | format_claude_output
        claude_exit_code=${PIPESTATUS[0]}
    else
        # Fallback without stdbuf
        claude \
            --print \
            --model "$model" \
            --allowedTools "Read,Write,Edit,Delete" \
            --permission-mode acceptEdits \
            "$prompt" 2>&1 | tee /tmp/claudux-claude.log | format_claude_output
        claude_exit_code=${PIPESTATUS[0]}
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Log Claude invocation result
    if [[ $claude_exit_code -ne 0 ]]; then
        warn "❌ Claude CLI exited with code: $claude_exit_code"
        if [[ -f /tmp/claudux-claude.log ]]; then
            warn "📋 Last output from Claude:"
            tail -20 /tmp/claudux-claude.log | sed 's/^/   /'
        fi
    fi
    
    # Kill the progress indicator
    if [[ -n "$progress_pid" ]]; then
        kill $progress_pid 2>/dev/null || true
        wait $progress_pid 2>/dev/null || true
    fi
    
    echo ""
    
    if [[ $claude_exit_code -eq 0 ]]; then
        success "Documentation update complete!"
        echo ""
        
        # Validate links in generated documentation
        info "🔍 Step 3: Validating documentation links..."
        if [[ -f "$LIB_DIR/validate-links.sh" ]]; then
            set +e
            "$LIB_DIR/validate-links.sh"
            VALIDATE_EXIT=$?
            set -e
            echo ""
            if [[ $VALIDATE_EXIT -ne 0 ]]; then
                warn "⚠️  Link validation found issues. Some documentation links may be broken."

                # Attempt a single auto-fix pass: collect missing files and re-run with a focused directive
                if [[ -z "$already_autofixed" ]]; then
                    # Re-run validator to collect machine-readable list
                    local missing_tmp="/tmp/claudux-missing-files.txt"
                    rm -f "$missing_tmp" 2>/dev/null || true
                    if "$LIB_DIR/validate-links.sh" --output "$missing_tmp" >/dev/null 2>&1; then
                        : # no-op; shouldn't happen because prior run failed
                    fi
                    if [[ -s "$missing_tmp" ]]; then
                        local file_list=$(sed 's#^docs/##' "$missing_tmp" | tr '\n' ' ')
                        warn "🛠️  Auto-fix: asking Claude to create missing pages: $file_list"
                        echo ""

                        # Build a focused directive
                        local fix_msg="Create the following missing documentation files with correct frontmatter, breadcrumbs, and minimal but accurate content; update navigation accordingly. Ensure config.ts links are valid and do not introduce new links that lack files. Missing files: ${file_list}"

                        # Mark as autofixed to avoid loops and re-run in-place (second pass)
                        if $strict_mode; then
                            CLAUDUX_AUTOFIXED=1 update --strict -m "$fix_msg"
                        else
                            CLAUDUX_AUTOFIXED=1 update -m "$fix_msg"
                        fi
                        return $?
                    fi
                fi

                warn "   Consider running 'claudux update -m \"Fill all missing pages and fix broken links\"' to target the fix."
                echo ""
                # Continue instead of exiting - validation is informational
                if $strict_mode; then
                    error_exit "❌ Broken links remain after generation. Strict mode is enabled."
                fi
            fi
        fi
        
        # Show detailed change summary
        info "📋 Step 4: Analyzing changes made..."
        show_detailed_changes
        
    else
        warn "Claude Code failed with exit code $claude_exit_code"
        echo ""
        warn "🔧 Troubleshooting steps:"
        echo "   1. Check Claude CLI is authenticated:"
        echo "      claude config get"
        echo ""
        echo "   2. Try with a different model:"
        echo "      FORCE_MODEL=sonnet claudux update"
        echo ""
        echo "   3. Check internet connection"
        echo ""
        echo "   4. View full log:"
        echo "      cat /tmp/claudux-claude.log"
        echo ""
        echo "   5. Report issue:"
        echo "      https://github.com/anthropics/claude-code/issues"
        
        exit "$claude_exit_code"
    fi
}