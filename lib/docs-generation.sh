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
    
    # Project-specific coding patterns (CLAUDE.md)
    local claudux_patterns=""
    if [[ -f "CLAUDE.md" ]]; then
        claudux_patterns="CLAUDE.md"
    fi
    
    # Documentation site preferences (claudux.md)
    local claudux_prefs=""
    if [[ -f "claudux.md" ]]; then
        claudux_prefs="claudux.md"
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
    
    if [[ -n "$claudux_prefs" ]]; then
        prompt+="
- Read $claudux_prefs for documentation site preferences: sections to include/omit, nav items and order, sidebar policy (unified '/' vs per-section), outline depth, page naming/ordering conventions, logo policy, base path policy (dev '/' with CI via DOCS_BASE), and link rules (no placeholders)"
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
   - Understand the expected documentation structure from templates
   - Note any protected areas or special requirements
   - Analyze existing docs structure if present

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
   - Auto-detect project name, description from package.json/README or similar manifest files
   - For projects with logos/icons, detect and use them appropriately
    - Build sidebar structure matching your planned documentation
    - Include proper navigation categories suitable for the project type
    - Set up social links based on detected repository and package registry
   - Enable 3-column layout with outline configuration
    - Generate proper VitePress configuration structure
   - Base path policy:
     * Use environment-aware base: process.env.DOCS_BASE || '/'
     * Local development defaults to '/' (no DOCS_BASE set)
     * CI/deployment sets DOCS_BASE (e.g., '/claudux/' for GitHub Pages)
   - IMPORTANT: Reference sidebar-example.md for proper sidebar configuration
   - Build nested sidebar navigation that matches your documentation hierarchy
   - Use consistent patterns for section organization
   - Apply preferences from claudux.md when present (nav items and order, sections include/omit, sidebar policy, outline depth, naming/emoji policy)
   
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

DOCUMENTATION ACCURACY GUIDELINES:
  - For CLI tools: Analyze actual command implementations (e.g., bin scripts, package.json scripts) to document only commands that exist
  - For libraries: Document only exported functions/classes that are actually available
  - Installation: Base instructions on package.json, Cargo.toml, setup.py, or other manifest files
  - Requirements: Document actual prerequisites found in the codebase (Node version, Python version, system deps)
  - Examples: Use real code examples from the actual codebase, not hypothetical ones
  - Adapt tone and structure to match the project's domain (e.g., enterprise vs open source)
  - Respect existing documentation conventions if updating an existing docs folder
  - Verbosity is enabled by default; do NOT document verbose flags (e.g., -v/--verbose) or any CLAUDUX_VERBOSE env configuration
  - Default AI model is Sonnet for speed; if you mention model selection, state that users can force Opus via FORCE_MODEL=opus when needed

VITEPRESS CONFIGURATION BEST PRACTICES:
  - Only reference assets that exist in the project or that you're creating
  - Use detected social links (GitHub, npm) rather than placeholder URLs
  - If no logo is found, the theme will show a monogram - don't force a logo reference
  - Match sidebar structure to actual documentation files you're creating

PROJECT-SPECIFIC FLEXIBILITY:
  - Adapt documentation structure to the project's needs (not all projects need all sections)
  - Small libraries may only need API reference; large apps may need architecture docs
  - Use appropriate section names for the domain (e.g., "Recipes" for a cookbook app)
  - Include project-specific sections that make sense (e.g., "Security" for auth libraries)

Output your complete analysis and plan, then proceed to Phase 2.

==== PHASE 2: EXECUTE THE PLAN ====
✏️ Now systematically execute your plan from Phase 1:

**CREATE New Documentation**:
- Generate all planned documentation files
- Use accurate, current code examples
- Follow template structures exactly
- Reference CLAUDE.md for project-specific coding patterns and conventions when creating technical documentation
- Ensure all internal links work

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

- Respect project-specific conventions from CLAUDE.md if present
- Respect site preferences from claudux.md if present

**REMOVE Obsolete Files** (95%+ confidence only):
- Delete files referencing non-existent code
- Remove docs for deleted features
- Clean up superseded duplicate content

🎯 Quality Checks:
- Every code example must be from actual current code
- All links must point to existing files
- Technical details must match implementation
- No hypothetical or placeholder content
- Follow project's coding standards and conventions
- Use terminology consistent with the project's domain
- Respect any custom documentation patterns in CLAUDE.md
- Follow documentation site preferences in claudux.md if present
- **CRITICAL: Ensure all heading IDs are unique** - no duplicate {#id} attributes within or across files
- Use descriptive, hierarchical IDs (e.g., {#platform-android-issues} instead of {#android} twice)"
    
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
    
    # First, clean up obsolete files (handled within generation)
    cleanup_docs_silent

    # Get model settings
    IFS='|' read -r model model_name timeout_msg cost_estimate <<< "$(get_model_settings)"

    info "🚀 Generating documentation..."
    info "🧠 Model: $model_name"

    # Start progress indicator (shorter initial delay for quicker feedback)
    local progress_pid=$(show_progress 8 24)
    
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
    # Create unique temp files for this session
    local prompt_file=$(mktemp /tmp/claudux-prompt-XXXXXX || mktemp)
    local claude_log=$(mktemp /tmp/claudux-claude-XXXXXX || mktemp)
    
    # Ensure we got valid temp files
    if [[ -z "$prompt_file" ]] || [[ -z "$claude_log" ]]; then
        error_exit "Failed to create temporary files"
    fi
    
    # Clean up temp files on exit
    trap "rm -f '$prompt_file' '$claude_log' 2>/dev/null" EXIT
    
    echo "$prompt" > "$prompt_file"
    
    # Run Claude with real-time streaming output
    local claude_exit_code=0
    
    # Check if --output-format flag is supported
    local output_format_flag=""
    if claude --help 2>&1 | grep -q "output-format"; then
        output_format_flag="--output-format stream-json"
        info "🔄 Streaming mode enabled for real-time progress"
    fi
    # Choose formatter based on output mode support
    local formatter="format_claude_output"
    if [[ -n "$output_format_flag" ]]; then
        formatter="format_claude_output_stream"
    fi
    
    # Always be verbose when streaming JSON
    local verbose_flag="--verbose"
    
    # Function: run Claude once and stream output; return exit code
    run_claude_once() {
        local started=false
        : > "$claude_log"

        if command -v stdbuf &> /dev/null; then
            ( stdbuf -o0 -e0 claude \
                --print \
                --model "$model" \
                --allowedTools "Read,Write,Edit,Delete" \
                --permission-mode acceptEdits \
                $verbose_flag \
                $output_format_flag \
                "$prompt" 2>&1 | tee "$claude_log" ) | $formatter &
        else
            ( claude \
                --print \
                --model "$model" \
                --allowedTools "Read,Write,Edit,Delete" \
                --permission-mode acceptEdits \
                $verbose_flag \
                $output_format_flag \
                "$prompt" 2>&1 | tee "$claude_log" ) | $formatter &
        fi
        local stream_pid=$!

        # Wait up to 20s for first bytes written to log
        for _ in $(seq 1 20); do
            if [[ -s "$claude_log" ]]; then
                started=true
                break
            fi
            sleep 1
        done

        if ! $started; then
            warn "⏱️  No visible progress after 20s"
            kill "$stream_pid" 2>/dev/null || true
            wait "$stream_pid" 2>/dev/null || true
            return 124
        fi

        trap 'echo ""; warn "Interrupt received, stopping generation..."; kill -TERM ${stream_pid} 2>/dev/null || true; [[ -n "$progress_pid" ]] && kill $progress_pid 2>/dev/null || true; wait ${stream_pid} 2>/dev/null || true; exit 130' INT
        wait ${stream_pid}
        local ec=$?
        trap - INT
        return $ec
    }

    # Launch generation once
    claude_exit_code=1
    run_claude_once
    claude_exit_code=$?
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Log Claude invocation result
    if [[ $claude_exit_code -ne 0 ]]; then
        warn "❌ Claude CLI exited with code: $claude_exit_code"
        if [[ -f "$claude_log" ]]; then
            warn "📋 Last output from Claude:"
            tail -20 "$claude_log" | sed 's/^/   /'
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

        # Update base path in docs/.vitepress/config.ts to use DOCS_BASE env var
        if [[ -f "docs/.vitepress/config.ts" ]]; then
            # Replace base path with environment-aware setting
            if grep -q "base:" "docs/.vitepress/config.ts" 2>/dev/null; then
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i '' "s/base:[[:space:]]*[^,]*/base: process.env.DOCS_BASE || '\/'/g" "docs/.vitepress/config.ts"
                else
                    sed -i "s/base:[[:space:]]*[^,]*/base: process.env.DOCS_BASE || '\/'/g" "docs/.vitepress/config.ts"
                fi
            fi
        fi
        
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
                    local missing_tmp=$(mktemp /tmp/claudux-missing-XXXXXX || mktemp)
                    rm -f "$missing_tmp" 2>/dev/null || true
                    if "$LIB_DIR/validate-links.sh" --output "$missing_tmp" >/dev/null 2>&1; then
                        : # no-op; shouldn't happen because prior run failed
                    fi
                    if [[ -s "$missing_tmp" ]]; then
                        local file_list=$(sed 's#^docs/##' "$missing_tmp" | tr '\n' ' ')
                        warn "🛠️  Auto-fix: asking Claude to create missing pages: $file_list"
                        echo ""

                        # Build a focused directive
                        local fix_msg="Create the following missing documentation files with correct frontmatter and minimal but accurate content; update navigation accordingly. Ensure config.ts links are valid and do not introduce new links that lack files. Missing files: ${file_list}"

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
        echo "      FORCE_MODEL=opus claudux update"
        echo ""
        echo "   3. Check internet connection"
        echo ""
        echo "   4. View full log:"
        echo "      Check Claude logs for details"
        echo ""
        echo "   5. Report issue:"
        echo "      https://github.com/anthropics/claude-code/issues"
        
        exit "$claude_exit_code"
    fi
}