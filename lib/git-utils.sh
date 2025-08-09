#!/bin/bash
# Git utilities for change tracking and analysis

# Show current git status summary
show_git_status() {
    info "📋 Current repository status:"
    
    local status_count=$(git status --porcelain 2>/dev/null | wc -l)
    
    if [[ $status_count -eq 0 ]]; then
        echo "   Working directory clean"
        return
    fi
    
    # Show first 10 files
    git status --porcelain 2>/dev/null | head -10
    
    if [[ $status_count -gt 10 ]]; then
        echo "   ... and $((status_count - 10)) more files"
    fi
}

# Show detailed changes with semantic descriptions
show_detailed_changes() {
    # Get list of changed files, filtering out non-documentation files
    local changed_files=$(git status --porcelain docs/ 2>/dev/null | \
        grep -v -E "(node_modules/|package-lock\.json|package\.json|\.vitepress/cache/|\.vitepress/dist/|\.vitepress/temp/)")
    
    if [[ -z "$changed_files" ]]; then
        info "   📝 No documentation files were modified"
        echo ""
        warn "💡 Next steps:"
        warn "   • Documentation appears to be up-to-date"
        warn "   • Try making code changes and running again"
        return
    fi
    
    echo ""
    success "📄 Files changed:"
    echo ""
    
    # Parse git status and show reasons
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local status="${line:0:2}"
            local file="${line:3}"
            
            case "$status" in
                "A ")
                    success "   ✅ Created: $file - New documentation file"
                    ;;
                "M ")
                    info "   📝 Updated: $file - Content synchronized with codebase"
                    ;;
                "D ")
                    print_color "RED" "   🗑️  Deleted: $file - Obsolete or duplicate content removed"
                    ;;
                "R ")
                    warn "   📦 Renamed: $file - File reorganized"
                    ;;
                "??")
                    success "   ✨ Added: $file - New documentation generated"
                    ;;
                *)
                    info "   📋 Modified: $file - Documentation updated"
                    ;;
            esac
        fi
    done <<< "$changed_files"
    
    echo ""
    warn "💡 Next steps:"
    warn "   • Review changes: git diff docs/"
    warn "   • Commit changes: git add docs/ && git commit -m '📚 Update documentation'"
    warn "   • Undo if needed: git checkout -- docs/"
}

# Check if we're in a git repository
ensure_git_repo() {
    if ! git rev-parse --git-dir &> /dev/null; then
        warn "Not in a git repository. Git features will be limited."
        return 1
    fi
    return 0
}