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
    local verbose_level=1
    
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
            if [[ "$verbose_level" -ge 1 ]]; then
                printf "\r\033[K🔍 Analyzing: %s\n" "$current_file"
            fi
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
            print_color "CYAN" "━━━ Phase 1: Analysis & Planning ━━━"
        elif [[ "$line" =~ "Phase 2:" ]]; then
            echo ""
            print_color "CYAN" "━━━ Phase 2: Documentation Generation ━━━"
        elif [[ "$line" =~ "Error:" ]] || [[ "$line" =~ "error:" ]]; then
            print_color "RED" "❌ $line"
        elif [[ "$line" =~ "Warning:" ]] || [[ "$line" =~ "warning:" ]]; then
            print_color "YELLOW" "⚠️  $line"
        elif [[ "$line" =~ "Success:" ]] || [[ "$line" =~ "Complete" ]]; then
            echo "✅ $line"
        elif [[ "$line" =~ ^[[:space:]]*$ ]]; then
            # Skip empty lines to reduce noise
            :
        elif [[ "$line" =~ "Tool Use:" ]] || [[ "$line" =~ "Using tool:" ]]; then
            if [[ "$verbose_level" -ge 2 ]]; then
                echo "   $line"
            fi
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

# Parse streaming JSON lines from Claude CLI and render concise progress
format_claude_output_stream() {
    local file_count=0
    local verbose_level=1
    local line
    local delta_preview_chars=180

    while IFS= read -r line; do
        # Emit heartbeat for init messages so users see early activity
        if echo "$line" | grep -q '"subtype"[[:space:]]*:[[:space:]]*"init"'; then
            # Try to extract model for a concise summary line
            local init_model
            init_model=$(echo "$line" | sed -n 's/.*"model"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
            if [[ -n "$init_model" ]]; then
                print_color "BLUE" "   🔄 Session started • Model: $init_model"
            else
                print_color "BLUE" "   🔄 Session started"
            fi
            continue
        fi
        if echo "$line" | grep -q '"type"[[:space:]]*:[[:space:]]*"result"'; then
            # Final result message; show brief summary if verbose
            if [[ "$verbose_level" -ge 1 ]]; then
                local turns
                turns=$(echo "$line" | sed -n 's/.*"num_turns"[[:space:]]*:[[:space:]]*\([0-9]\+\).*/\1/p')
                local cost
                cost=$(echo "$line" | sed -n 's/.*"total_cost_usd"[[:space:]]*:[[:space:]]*\([0-9.]*\).*/\1/p')
                [[ -n "$turns" ]] && echo "   ✅ Completed in $turns turns"
                [[ -n "$cost" ]] && echo "   💰 Cost: $cost USD"
            fi
            continue
        fi
        # Fast-path: if this doesn't look like JSON, fall back to plain formatter heuristics
        if [[ ! "$line" =~ ^\{ ]] && [[ ! "$line" =~ ^\[ ]]; then
            if [[ -n "$line" ]]; then
                echo "   $line"
            fi
            continue
        fi

        # Errors
        if echo "$line" | grep -qi '"error"'; then
            print_color "RED" "❌ $line"
            continue
        fi

        # Ignore large tool_result payloads (we already print concise tool usage lines)
        if echo "$line" | grep -q '"tool_result"'; then
            continue
        fi

        # Extract a path if present
        local path
        path=$(echo "$line" | sed -n 's/.*"path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

        # Detect file write/create/update events heuristically
        if echo "$line" | grep -qE 'file_(write|create|update)|"action"\s*:\s*"(write|create|update)"|"op"\s*:\s*"(write|create|update)"'; then
            if [[ -n "$path" ]]; then
                ((file_count++))
                printf "\r\033[K📝 Change [%d]: %s\n" "$file_count" "$path"
                continue
            fi
        fi

        # Tool usage notifications (verbose only)
        if [[ "$verbose_level" -ge 1 ]]; then
            local tool
            tool=$(echo "$line" | sed -n 's/.*"toolName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
            if [[ -z "$tool" ]]; then
                tool=$(echo "$line" | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
            fi
            if [[ -n "$tool" ]] && echo "$line" | grep -qE 'tool|Tool|tool_use'; then
                printf "\r\033[K"
                print_color "CYAN" "🔧 Using tool: $tool"
                continue
            fi
        fi

        # Text deltas: always show a short preview
        local text
        text=$(echo "$line" | sed -n 's/.*"text"[[:space:]]*:[[:space:]]*"\([^"\n]*\)".*/\1/p')
        if [[ -n "$text" ]]; then
            # Unescape common sequences
            text=${text//\\n/$'\n'}
            text=${text//\\t/$'\t'}
            # Truncate to preview length
            if [[ ${#text} -gt $delta_preview_chars ]]; then
                echo "   $text" | sed -E "s/^(.{0,$delta_preview_chars}).*$/   \1.../"
            else
                echo "   $text"
            fi
            continue
        fi

        # Default: suppress raw JSON lines to keep output clean
        :
    done

    # Clear progress line and print summary
    printf "\r\033[K"
    if [[ $file_count -gt 0 ]]; then
        echo ""
        success "📚 Processed $file_count files"
    fi
}