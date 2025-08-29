#!/bin/bash
# Documentation cleanup functions

# AI-powered cleanup of obsolete documentation files
cleanup_docs() {
    info "🧹 Using AI to intelligently detect obsolete documentation..."
    echo ""
    
    # Check if docs exist
    if [[ ! -d "docs" ]] || [[ -z "$(find docs -name "*.md" -not -path "*/node_modules/*" 2>/dev/null | head -1)" ]]; then
        warn "📄 No documentation files found to clean"
        return
    fi
    
    # Use Claude to analyze docs and detect obsolete files
    local cleanup_prompt="Analyze the documentation in the docs/ folder and identify genuinely obsolete files.

IMPORTANT: Use SEMANTIC ANALYSIS, not filename patterns!
- Cross-reference documentation content against the actual codebase
- Check if documented features/files still exist
- Verify if APIs/interfaces match current implementations
- Identify docs referencing removed/renamed components

For each obsolete file found:
1. Analyze its content and cross-reference with codebase
2. Provide confidence score (0-100%)
3. Give specific reason why it's obsolete
4. Only recommend deletion for 95%+ confidence

Be conservative - documentation is valuable. Only mark as obsolete if:
- It references code/features that no longer exist
- It documents removed functionality
- It contains information that directly contradicts current implementation

Use 'rm' command to delete files with clear explanations."

    # Run Claude for intelligent obsolescence detection
    warn "🤖 Claude analyzing documentation for obsolete content..."
    echo ""
    
    claude api "$cleanup_prompt" \
        --print \
        --permission-mode acceptEdits \
        --allowedTools "Read,Write,Bash" \
        --verbose \
        --model "${FORCE_MODEL:-opus}"
    
    local exit_code=$?
    echo ""
    
    if [[ $exit_code -eq 0 ]]; then
        success "🎉 AI-powered cleanup complete!"
    else
        error_exit "Claude cleanup failed with exit code $exit_code"
    fi
}

# Silent cleanup for use during main update process
cleanup_docs_silent() {
    # Handled by Claude AI during the main update process; no output
    :
}

# Recreate docs from scratch
recreate_docs() {
    # pass through any args to the subsequent update call (e.g., -m/--with)
    local passthrough=("$@")
    warn "🗑️  This will completely delete all documentation and start fresh!"
    print_color "RED" "⚠️  This action cannot be undone."
    echo ""
    info "Files that will be deleted:"
    echo "  • docs/ directory (all content)"
    echo "  • docs-site-plan.json (if exists)"
    echo ""
    
    # Get confirmation
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        warn "⏹️  Operation cancelled."
        return
    fi
    
    echo ""
    warn "🗑️  Removing existing documentation..."
    
    # Remove docs directory
    if [[ -d "docs" ]]; then
        if rm -rf docs/; then
            success "   ✅ Removed docs/ directory"
        else
            error_exit "Failed to remove docs/ directory"
        fi
    fi
    
    # Remove site plan if it exists
    if [[ -f "docs-site-plan.json" ]]; then
        if rm -f docs-site-plan.json; then
            success "   ✅ Removed docs-site-plan.json"
        else
            warn "   ⚠️  Failed to remove docs-site-plan.json"
        fi
    fi
    
    echo ""
    success "🚀 Starting fresh documentation generation..."
    echo ""
    
    # Generate fresh docs and allow focused directive
    if [[ ${#passthrough[@]} -eq 0 ]]; then
        update
    else
        update "${passthrough[@]}"
    fi
}