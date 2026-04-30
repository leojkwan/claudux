#!/bin/bash
# Documentation cleanup functions

manifest_deletion_guard_required() {
    local manifest="docs-structure.json"
    if declare -F docs_structure_path >/dev/null 2>&1; then
        manifest="$(docs_structure_path)"
    elif [[ -n "${CLAUDUX_DOCS_STRUCTURE:-}" ]]; then
        manifest="$CLAUDUX_DOCS_STRUCTURE"
    fi

    [[ -f "$manifest" ]]
}

summarize_manifest_deletion_guard() {
    local manifest="docs-structure.json"
    if declare -F docs_structure_path >/dev/null 2>&1; then
        manifest="$(docs_structure_path)"
    elif [[ -n "${CLAUDUX_DOCS_STRUCTURE:-}" ]]; then
        manifest="$CLAUDUX_DOCS_STRUCTURE"
    fi

    if [[ ! -f "$manifest" ]] || ! command -v node >/dev/null 2>&1; then
        return 0
    fi

    node - "$manifest" <<'NODE'
const fs = require('fs');
const manifestPath = process.argv[2];

let manifest;
try {
  manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
} catch {
  process.exit(0);
}

const pages = Array.isArray(manifest.pages) ? manifest.pages : [];
const protectedPages = pages.filter(page =>
  page && page.path && page.deletion_policy === 'never_delete_without_manifest_change'
);

console.log(`Manifest deletion guard: ${protectedPages.length} protected page(s) from ${manifestPath}`);
for (const page of protectedPages.slice(0, 12)) {
  console.log(`  - ${page.path}`);
}
if (protectedPages.length > 12) {
  console.log(`  - ... ${protectedPages.length - 12} more`);
}
NODE
}

# AI-powered cleanup of obsolete documentation files
cleanup_docs() {
    info "🧹 Using AI to intelligently detect obsolete documentation..."
    echo ""
    
    # Check if docs exist
    if [[ ! -d "docs" ]] || [[ -z "$(find docs -name "*.md" -not -path "*/node_modules/*" 2>/dev/null | head -1)" ]]; then
        warn "📄 No documentation files found to clean"
        return
    fi

    if manifest_deletion_guard_required && [[ "${CLAUDUX_ALLOW_MANIFEST_CLEANUP:-}" != "1" ]]; then
        warn "Manifest deletion guard active: refusing AI cleanup deletion while docs-structure.json exists."
        summarize_manifest_deletion_guard
        echo ""
        info "Edit docs-structure.json first, or set CLAUDUX_ALLOW_MANIFEST_CLEANUP=1 for an explicit manifest-aware cleanup run."
        return 0
    fi

    if manifest_deletion_guard_required && declare -F validate_docs_structure_manifest >/dev/null 2>&1; then
        validate_docs_structure_manifest || error_exit "docs-structure.json failed validation before cleanup"
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

    if manifest_deletion_guard_required; then
        cleanup_prompt+="

DETERMINISTIC MANIFEST RULE:
- docs-structure.json is a binding deletion contract.
- Do NOT delete any path listed in docs-structure.json.
- Do NOT delete pinned or source-owned sections.
- If a manifest-listed page appears obsolete, report the suggested manifest diff instead of deleting the file.
- Only unlisted docs files may be deleted, and only with 95%+ confidence."
    fi

    # Run Claude for intelligent obsolescence detection
    warn "🤖 Claude analyzing documentation for obsolete content..."
    echo ""
    
    claude api "$cleanup_prompt" \
        --print \
        --permission-mode acceptEdits \
        --allowedTools "Read,Write,Bash" \
        --verbose \
        --model "${FORCE_MODEL:-sonnet}"
    
    local exit_code=$?
    echo ""
    
    if [[ $exit_code -eq 0 ]]; then
        if manifest_deletion_guard_required && declare -F validate_docs_structure_manifest >/dev/null 2>&1; then
            validate_docs_structure_manifest --post-generation || error_exit "docs-structure.json validation failed after cleanup"
        fi
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

    if manifest_deletion_guard_required && [[ "${CLAUDUX_ALLOW_MANIFEST_RECREATE:-}" != "1" ]]; then
        warn "Manifest deletion guard active: refusing to delete docs/ while docs-structure.json exists."
        summarize_manifest_deletion_guard
        echo ""
        error_exit "Recreate would delete manifest-owned documentation. Edit docs-structure.json first, or set CLAUDUX_ALLOW_MANIFEST_RECREATE=1 for an explicit destructive rebuild."
    fi

    if declare -F validate_dependencies >/dev/null 2>&1; then
        validate_dependencies
    elif declare -F check_generation_backend >/dev/null 2>&1; then
        check_generation_backend
    fi

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
        # Force remove, ignoring errors
        rm -rf docs/ 2>/dev/null || true
        
        # Check if it was actually removed
        if [[ -d "docs" ]]; then
            # Directory still exists, this is a real problem
            error_exit "Failed to remove docs/ directory. Check permissions or if files are in use."
        else
            success "   ✅ Removed docs/ directory"
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
