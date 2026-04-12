#!/bin/bash
# Codex CLI utilities — mirrors claude-utils.sh for the Codex backend

# Check if Codex CLI is installed
check_codex() {
    if ! command -v codex &> /dev/null; then
        error_exit "Codex CLI not found. Install: npm install -g @openai/codex"
    fi

    success "Codex CLI found: $(codex --version)"
    info "Using Codex backend (CLAUDUX_BACKEND=codex)"
}

# Get model name and settings for Codex
get_codex_model_settings() {
    local model="${CODEX_MODEL:-gpt-5.4}"
    local effort="${CODEX_REASONING_EFFORT:-xhigh}"
    local model_name=""
    local timeout_msg=""

    case "$model" in
        "gpt-5.4")
            model_name="GPT-5.4 (${effort} reasoning)"
            timeout_msg="This may take 60-180 seconds with GPT-5.4 xhigh..."
            ;;
        "gpt-5.3-codex")
            model_name="GPT-5.3 Codex (${effort} reasoning)"
            timeout_msg="This should take 30-90 seconds..."
            ;;
        *)
            model_name="Codex $model (${effort} reasoning)"
            timeout_msg="Processing time varies by model..."
            ;;
    esac

    echo "$model|$model_name|$timeout_msg|$effort"
}

# Run Codex non-interactively with a prompt
# Usage: run_codex_exec "prompt text" [output_file]
run_codex_exec() {
    local prompt="$1"
    local output_file="${2:-}"
    local model="${CODEX_MODEL:-gpt-5.4}"
    local effort="${CODEX_REASONING_EFFORT:-xhigh}"

    local codex_args=(
        exec
        -m "$model"
        -c "model_reasoning_effort=\"$effort\""
        -c "approval_policy=\"never\""
        -c "sandbox_mode=\"danger-full-access\""
        --json
    )

    if [[ -n "$output_file" ]]; then
        codex_args+=(-o "$output_file")
    fi

    # Pass prompt via stdin to avoid shell escaping issues
    echo "$prompt" | codex "${codex_args[@]}"
}

# Parse Codex JSONL output and render progress
# Mirrors format_claude_output_stream() but for Codex event format
format_codex_output_stream() {
    local file_count=0
    local reads=0
    local creates=0
    local updates=0
    local deletes=0
    local line

    while IFS= read -r line; do
        # Skip empty lines
        [[ -z "$line" ]] && continue

        # Parse event type from JSONL
        local event_type
        event_type=$(echo "$line" | sed -n 's/.*"type"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

        case "$event_type" in
            "agent_start"|"session_start")
                local init_model
                init_model=$(echo "$line" | sed -n 's/.*"model"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
                if [[ -n "$init_model" ]]; then
                    print_color "BLUE" "   Session started - Model: $init_model"
                fi
                ;;
            "tool_use"|"tool_call")
                local tool_name
                tool_name=$(echo "$line" | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
                case "$tool_name" in
                    "read"|"Read")
                        ((reads++))
                        local file_path
                        file_path=$(echo "$line" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
                        [[ -n "$file_path" ]] && printf "\r\033[KAnalyzing: %s\n" "$file_path"
                        ;;
                    "write"|"Write"|"create"|"Create")
                        ((creates++))
                        ((file_count++))
                        local file_path
                        file_path=$(echo "$line" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
                        [[ -n "$file_path" ]] && printf "\r\033[KCreated [%d]: %s\n" "$file_count" "$file_path"
                        ;;
                    "edit"|"Edit")
                        ((updates++))
                        ((file_count++))
                        local file_path
                        file_path=$(echo "$line" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
                        [[ -n "$file_path" ]] && printf "\r\033[KUpdated [%d]: %s\n" "$file_count" "$file_path"
                        ;;
                    "delete"|"Delete")
                        ((deletes++))
                        ((file_count++))
                        local file_path
                        file_path=$(echo "$line" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
                        [[ -n "$file_path" ]] && printf "\r\033[KRemoved [%d]: %s\n" "$file_count" "$file_path"
                        ;;
                esac
                ;;
            "error")
                local error_msg
                error_msg=$(echo "$line" | sed -n 's/.*"message"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
                print_color "RED" "Error: $error_msg"
                ;;
            "agent_end"|"session_end")
                printf "\r\033[K"
                ;;
        esac
    done

    printf "\r\033[K"
    if [[ $file_count -gt 0 ]]; then
        echo ""
        success "Processed $file_count files (reads: $reads, creates: $creates, updates: $updates, deletes: $deletes)"
    fi
}
