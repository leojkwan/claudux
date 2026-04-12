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
# Stdout: JSONL events only.  Stderr: sent to CODEX_STDERR_LOG (default /tmp/claudux-codex-stderr.log).
run_codex_exec() {
    local prompt="$1"
    local output_file="${2:-}"
    local model="${CODEX_MODEL:-gpt-5.4}"
    local effort="${CODEX_REASONING_EFFORT:-xhigh}"
    local stderr_log="${CODEX_STDERR_LOG:-/tmp/claudux-codex-stderr.log}"

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

    # Pass prompt via stdin; redirect stderr to log to keep stdout as clean JSONL
    echo "$prompt" | codex "${codex_args[@]}" 2>>"$stderr_log"
}

# Parse Codex JSONL output and render progress.
# Codex CLI v0.119+ emits: thread.started, turn.started, item.started,
# item.completed (with nested item.type: agent_message | command_execution),
# turn.completed.  This is completely different from Claude's stream-json.
format_codex_output_stream() {
    local cmd_count=0
    local msg_count=0
    local file_count=0
    local line

    while IFS= read -r line; do
        # Skip empty lines and non-JSON (stderr bleed-through)
        [[ -z "$line" ]] && continue
        [[ "$line" != "{"* ]] && continue

        # Top-level event type — must match the FIRST "type" field, not a nested one.
        # Anchor after the opening brace to avoid greedy .* skipping to nested types.
        local event_type
        event_type=$(echo "$line" | sed -n 's/^{"type"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

        case "$event_type" in
            "thread.started")
                local thread_id
                thread_id=$(echo "$line" | sed -n 's/.*"thread_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
                [[ -n "$thread_id" ]] && printf "\r\033[KCodex session: %s\n" "${thread_id:0:12}..."
                ;;
            "item.started")
                # Detect nested item type: command_execution or file_change
                if echo "$line" | grep -q '"type"[[:space:]]*:[[:space:]]*"command_execution"'; then
                    local cmd
                    cmd=$(echo "$line" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
                    if [[ -n "$cmd" ]]; then
                        ((cmd_count++))
                        printf "\r\033[KRunning [%d]: %s\n" "$cmd_count" "${cmd:0:100}"
                    fi
                elif echo "$line" | grep -q '"type"[[:space:]]*:[[:space:]]*"file_change"'; then
                    # Count files being changed and show paths
                    local paths
                    paths=$(echo "$line" | grep -o '"path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"path"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/g')
                    local count=0
                    while IFS= read -r p; do
                        [[ -z "$p" ]] && continue
                        ((file_count++))
                        ((count++))
                        printf "\r\033[KWriting [%d]: %s\n" "$file_count" "$(basename "$p")"
                    done <<< "$paths"
                fi
                ;;
            "item.completed")
                # Sub-types: agent_message, command_execution, file_change
                if echo "$line" | grep -q '"type"[[:space:]]*:[[:space:]]*"agent_message"'; then
                    ((msg_count++))
                    local text
                    text=$(echo "$line" | sed -n 's/.*"text"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
                    if [[ -n "$text" ]]; then
                        printf "\r\033[KAgent: %s\n" "${text:0:120}"
                    fi
                elif echo "$line" | grep -q '"type"[[:space:]]*:[[:space:]]*"command_execution"'; then
                    local exit_code
                    exit_code=$(echo "$line" | sed -n 's/.*"exit_code"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p')
                    local cmd
                    cmd=$(echo "$line" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
                    if [[ -n "$exit_code" ]] && [[ "$exit_code" -ne 0 ]]; then
                        printf "\r\033[KCommand failed (exit %s): %s\n" "$exit_code" "${cmd:0:80}"
                    fi
                fi
                # file_change completed events are already counted in item.started
                ;;
            "turn.completed")
                local input_tokens output_tokens
                input_tokens=$(echo "$line" | sed -n 's/.*"input_tokens"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p')
                output_tokens=$(echo "$line" | sed -n 's/.*"output_tokens"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p')
                printf "\r\033[K"
                if [[ -n "$input_tokens" ]] && [[ -n "$output_tokens" ]]; then
                    printf "Turn complete — tokens: %s in / %s out\n" "$input_tokens" "$output_tokens"
                fi
                ;;
        esac
    done

    printf "\r\033[K"
    if [[ $cmd_count -gt 0 ]] || [[ $msg_count -gt 0 ]] || [[ $file_count -gt 0 ]]; then
        echo ""
        success "Codex finished ($cmd_count commands, $file_count files, $msg_count messages)"
    fi
}
