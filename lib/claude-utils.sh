#!/bin/bash
# Claude CLI utilities and checks

# Check if Claude CLI is installed and configured
check_claude() {
    if ! command -v claude &> /dev/null; then
        error_exit "Claude Code CLI not found. Install: npm install -g @anthropic-ai/claude-code"
    fi
    
    success "Claude Code CLI found: $(claude --version)"
    
    # Show current model configuration
    info "🧠 Checking available models..."
    claude config get model 2>/dev/null || info "ℹ️  Using default model"
    
    # Detect and show project type
    load_project_config
    info "📁 Detected project type: $PROJECT_TYPE"
}

# Get model name and settings
get_model_settings() {
    local model="${FORCE_MODEL:-opus}"
    local model_name=""
    local timeout_msg=""
    local cost_estimate=""
    
    case "$model" in
        "opus")
            model_name="Claude Opus (most powerful)"
            timeout_msg="⏳ This may take 60-120 seconds with Opus..."
            cost_estimate="💰 Estimated cost: ~\$0.05 per run"
            ;;
        "sonnet")
            model_name="Claude Sonnet (fast & capable)"
            timeout_msg="⏳ This should take 30-60 seconds with Sonnet..."
            cost_estimate="💰 Estimated cost: ~\$0.01 per run"
            ;;
        *)
            model_name="Claude $model"
            timeout_msg="⏳ Processing time varies by model..."
            cost_estimate="💰 Cost varies by model"
            ;;
    esac
    
    echo "$model|$model_name|$timeout_msg|$cost_estimate"
}

# Show progress indicator
show_progress() {
    local phase1_delay="${1:-15}"
    local phase2_delay="${2:-45}"
    
    {
        sleep "$phase1_delay" && echo "$(date '+%H:%M:%S') 📊 Phase 1: Analyzing project structure..."
        sleep $((phase1_delay + 15)) && echo "$(date '+%H:%M:%S') 📊 Phase 1: Creating documentation plan..."
        sleep "$phase2_delay" && echo "$(date '+%H:%M:%S') ✏️  Phase 2: Generating new documentation..."
        sleep $((phase2_delay + 15)) && echo "$(date '+%H:%M:%S') ✏️  Phase 2: Updating existing files..."
        sleep $((phase2_delay + 30)) && echo "$(date '+%H:%M:%S') ✏️  Phase 2: Finalizing documentation..."
    } &
    
    echo $!  # Return PID for later cleanup
}

# Format Claude's output for better readability
format_claude_output() {
    local file_count=0
    local current_file=""
    
    while IFS= read -r line; do
        # Detect file operations
        if [[ "$line" =~ Writing.*to[[:space:]]+(.*) ]]; then
            current_file="${BASH_REMATCH[1]}"
            ((file_count++))
            printf "\r\033[K✅ Created [%d]: %s\n" "$file_count" "$current_file"
        elif [[ "$line" =~ Creating[[:space:]]+(.*) ]]; then
            current_file="${BASH_REMATCH[1]}"
            ((file_count++))
            printf "\r\033[K📝 Creating [%d]: %s\n" "$file_count" "$current_file"
        elif [[ "$line" =~ Reading[[:space:]]+(.*) ]]; then
            current_file="${BASH_REMATCH[1]}"
            printf "\r\033[K🔍 Analyzing: %s" "$current_file"
        elif [[ "$line" =~ Updating[[:space:]]+(.*) ]]; then
            current_file="${BASH_REMATCH[1]}"
            ((file_count++))
            printf "\r\033[K📝 Updated [%d]: %s\n" "$file_count" "$current_file"
        elif [[ "$line" =~ Deleting[[:space:]]+(.*) ]]; then
            current_file="${BASH_REMATCH[1]}"
            ((file_count++))
            printf "\r\033[K🗑️  Removed [%d]: %s\n" "$file_count" "$current_file"
        elif [[ "$line" =~ "Phase 1:" ]]; then
            echo ""
            echo "━━━ Phase 1: Analysis & Planning ━━━"
        elif [[ "$line" =~ "Phase 2:" ]]; then
            echo ""
            echo "━━━ Phase 2: Documentation Generation ━━━"
        elif [[ "$line" =~ "Error:" ]] || [[ "$line" =~ "error:" ]]; then
            echo "❌ $line"
        elif [[ "$line" =~ "Warning:" ]] || [[ "$line" =~ "warning:" ]]; then
            echo "⚠️  $line"
        elif [[ "$line" =~ "Success:" ]] || [[ "$line" =~ "Complete" ]]; then
            echo "✅ $line"
        elif [[ "$line" =~ ^[[:space:]]*$ ]]; then
            # Skip empty lines to reduce noise
            :
        elif [[ "$line" =~ "Tool Use:" ]] || [[ "$line" =~ "Using tool:" ]]; then
            # Skip tool use messages to reduce noise
            :
        elif [[ "$line" =~ "Assistant:" ]]; then
            # Skip assistant markers
            :
        else
            # For other important messages, show them dimmed
            if [[ ${#line} -gt 80 ]]; then
                # Truncate long lines
                echo "   ${line:0:77}..."
            elif [[ -n "$line" ]]; then
                echo "   $line"
            fi
        fi
    done
    
    # Clear the progress line
    printf "\r\033[K"
    
    if [[ $file_count -gt 0 ]]; then
        echo ""
        success "📚 Processed $file_count files"
    fi
}