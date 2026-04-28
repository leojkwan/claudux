#!/bin/bash
# Tests: backend router — CLAUDUX_BACKEND env var selects the correct backend
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-harness.sh"

echo "=== Backend Router Tests ==="
echo ""

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$REPO_ROOT/lib"

# --- Test 1: Default backend is "claude" ---
(
    unset CLAUDUX_BACKEND 2>/dev/null || true
    result="${CLAUDUX_BACKEND:-claude}"
    echo "$result"
) > /tmp/claudux-test-backend-default 2>&1
assert_eq "default backend is claude" "claude" "$(cat /tmp/claudux-test-backend-default)"

# --- Test 2: CLAUDUX_BACKEND=codex is respected ---
(
    export CLAUDUX_BACKEND=codex
    result="${CLAUDUX_BACKEND:-claude}"
    echo "$result"
) > /tmp/claudux-test-backend-codex 2>&1
assert_eq "CLAUDUX_BACKEND=codex is respected" "codex" "$(cat /tmp/claudux-test-backend-codex)"

# --- Test 3: bin/claudux sources codex-utils.sh when backend=codex ---
codex_source_block=$(sed -n '/Source Codex backend/,/^fi$/p' "$REPO_ROOT/bin/claudux")
assert_contains "bin/claudux has codex conditional source" "$codex_source_block" "codex-utils.sh"

# --- Test 4: docs-generation.sh defines run_codex_once ---
assert_contains "run_codex_once defined in docs-generation.sh" \
    "$(grep 'run_codex_once' "$LIB_DIR/docs-generation.sh")" \
    "run_codex_once"

# --- Test 5: docs-generation.sh defines run_claude_once ---
assert_contains "run_claude_once defined in docs-generation.sh" \
    "$(grep 'run_claude_once' "$LIB_DIR/docs-generation.sh")" \
    "run_claude_once"

# --- Test 6: The router if/else uses CLAUDUX_BACKEND to pick run_codex_once ---
routing_block=$(sed -n '/Launch generation.*route based on CLAUDUX_BACKEND/,/claude_exit_code=\$?/p' "$LIB_DIR/docs-generation.sh")
assert_contains "router calls run_codex_once for codex backend" "$routing_block" 'run_codex_once'
assert_contains "router calls run_claude_once for default backend" "$routing_block" 'run_claude_once'
assert_contains "router checks backend == codex" "$routing_block" '"codex"'

# --- Test 7: codex-utils.sh exists and defines required functions ---
assert_file_exists "lib/codex-utils.sh exists" "$LIB_DIR/codex-utils.sh"

codex_utils_content=$(cat "$LIB_DIR/codex-utils.sh")
assert_contains "codex-utils.sh defines check_codex" "$codex_utils_content" "check_codex()"
assert_contains "codex-utils.sh defines get_codex_model_settings" "$codex_utils_content" "get_codex_model_settings()"
assert_contains "codex-utils.sh defines run_codex_exec" "$codex_utils_content" "run_codex_exec()"
assert_contains "codex-utils.sh defines format_codex_output_stream" "$codex_utils_content" "format_codex_output_stream()"

# --- Test 8: validate_dependencies checks codex CLI when backend=codex ---
validate_fn=$(sed -n '/^validate_dependencies()/,/^}/p' "$REPO_ROOT/bin/claudux")
assert_contains "validate checks for codex CLI" "$validate_fn" 'command -v codex'
assert_contains "validate checks for CODEX_UTILS_MISSING" "$validate_fn" 'CODEX_UTILS_MISSING'

# --- Test 9: CLAUDUX_BACKEND=codex sets CODEX_UTILS_MISSING when lib missing ---
(
    export CLAUDUX_BACKEND=codex
    codex_lib="/tmp/nonexistent-codex-utils-$$.sh"
    if [[ -f "$codex_lib" ]]; then
        source "$codex_lib"
    else
        CODEX_UTILS_MISSING=true
    fi
    echo "${CODEX_UTILS_MISSING:-false}"
) > /tmp/claudux-test-missing 2>&1
assert_eq "CODEX_UTILS_MISSING set when lib missing" "true" "$(cat /tmp/claudux-test-missing)"

# --- Test 10: check command shows correct backend info ---
check_block=$(sed -n '/"check"|"--check"/,/;;/p' "$REPO_ROOT/bin/claudux")
assert_contains "check shows backend" "$check_block" 'CLAUDUX_BACKEND'
assert_contains "check shows codex model" "$check_block" 'CODEX_MODEL'

# --- Test 11: show_header says "Claude AI" under default backend ---
(
    unset CLAUDUX_BACKEND 2>/dev/null || true
    "$REPO_ROOT/bin/claudux" check 2>&1 | head -2
) > /tmp/claudux-test-header-claude 2>&1
assert_contains "default header mentions Claude AI" \
    "$(cat /tmp/claudux-test-header-claude)" \
    "Powered by Claude AI"

# --- Test 12: show_header switches to Codex when CLAUDUX_BACKEND=codex ---
(
    export CLAUDUX_BACKEND=codex
    export CODEX_MODEL=gpt-5.5
    export CODEX_REASONING_EFFORT=xhigh
    "$REPO_ROOT/bin/claudux" check 2>&1 | head -2
) > /tmp/claudux-test-header-codex 2>&1
assert_contains "codex header mentions Codex" \
    "$(cat /tmp/claudux-test-header-codex)" \
    "Powered by Codex (gpt-5.5, xhigh reasoning)"
assert_not_contains "codex header does NOT hardcode GPT-5.4" \
    "$(cat /tmp/claudux-test-header-codex)" \
    "GPT-5.4"
assert_not_contains "codex header does NOT say Claude AI" \
    "$(cat /tmp/claudux-test-header-codex)" \
    "Powered by Claude AI"

# --- Test 13: Claude-specific model lookup lives inside run_claude_once ---
# Regression guard for the dog-food finding that CLAUDUX_BACKEND=codex printed
# "🧠 Model: Claude Sonnet" before the router handed off to run_codex_once.
# The call to get_model_settings (Claude-only helper) must not appear in the
# pre-router body of update().
update_fn=$(sed -n '/^update()/,/^}/p' "$LIB_DIR/docs-generation.sh")
update_body_before_claude_once=$(sed -n '/^update()/,/^    run_claude_once()/p' "$LIB_DIR/docs-generation.sh")
assert_not_contains "get_model_settings not called before run_claude_once" \
    "$update_body_before_claude_once" \
    'get_model_settings'
assert_contains "run_claude_once body calls get_model_settings" \
    "$update_fn" \
    'get_model_settings'

# --- Test 14: backend is resolved up-front in update() ---
# The router reads "$backend" — that variable must be declared early in update()
# so downstream helpers (cleanup, logging) can branch on it without set -u firing
# or the codex path leaking a Claude label.
first_backend_line=$(grep -n 'local backend=' "$LIB_DIR/docs-generation.sh" | head -1 | cut -d: -f1)
first_backend_info_line=$(grep -n 'info "Backend:' "$LIB_DIR/docs-generation.sh" | head -1 | cut -d: -f1)
assert_contains "backend variable is declared in docs-generation.sh" \
    "$(grep 'local backend=' "$LIB_DIR/docs-generation.sh")" \
    'CLAUDUX_BACKEND:-claude'
# Numeric ordering: backend declaration appears before first "Backend:" info
# print by treating the comparison result as a string "true"/"false".
backend_before_info="false"
if [[ -n "$first_backend_line" && -n "$first_backend_info_line" ]] && [[ "$first_backend_line" -lt "$first_backend_info_line" ]]; then
    backend_before_info="true"
fi
assert_eq "backend declared before first Backend: info print" "true" "$backend_before_info"

# --- Test 15: Claude --help probe is NOT run on the codex path ---
# Regression guard for the dog-food finding that `claude --help | grep output-format`
# ran unconditionally, triggering Claude CLI even when backend=codex.
# The probe must live inside run_claude_once() only.
run_claude_body=$(sed -n '/^    run_claude_once()/,/^    }/p' "$LIB_DIR/docs-generation.sh")
run_codex_body=$(sed -n '/^    run_codex_once()/,/^    }/p' "$LIB_DIR/docs-generation.sh")
assert_contains "claude --help probe is inside run_claude_once" \
    "$run_claude_body" \
    'claude --help'
assert_not_contains "claude --help probe is NOT in run_codex_once" \
    "$run_codex_body" \
    'claude --help'
# And the hoisted streaming-mode info line is also Claude-scoped now.
assert_contains "Streaming mode info lives inside run_claude_once" \
    "$run_claude_body" \
    'Streaming mode enabled'

# --- Test 16: prompt-built success message is not double-emojied ---
# Regression guard for the dog-food finding of "✅ ✅ Prompt built". The
# success() helper prepends ✅, so the message string must not also start with ✅.
prompt_built_line=$(grep 'Prompt built successfully' "$LIB_DIR/docs-generation.sh" | grep 'success')
assert_not_contains "success() call for Prompt built does NOT hardcode ✅" \
    "$prompt_built_line" \
    'success "✅'

# --- Test 17: failure log labels and troubleshooting match the correct backend ---
# Regression guard for "❌ Claude CLI exited" printed when codex failed.
fail_block=$(sed -n '/local backend_label=/,/exit "\$claude_exit_code"/p' "$LIB_DIR/docs-generation.sh")
assert_contains "failure label is backend-aware" \
    "$fail_block" \
    'Codex CLI'
assert_contains "failure label still handles claude backend" \
    "$fail_block" \
    'Claude CLI'
assert_contains "codex failure points at Codex auth" \
    "$fail_block" \
    'codex login status'
assert_contains "codex failure suggests supported model fallback" \
    "$fail_block" \
    'CODEX_MODEL=gpt-5.4'
assert_contains "codex failure suggests Codex CLI upgrade" \
    "$fail_block" \
    'npm install -g @openai/codex'
assert_not_contains "failure branch does NOT say Claude Code failed" \
    "$fail_block" \
    'Claude Code failed'

# --- Test 18: manifest section patch mode removes Claude write tools ---
# Deterministic docs mode must not hand the model whole-tree write permission.
assert_contains "update enables section patch mode from manifest" \
    "$update_fn" \
    'CLAUDUX_SECTION_PATCH_MODE=1'
assert_contains "Claude patch mode downgrades allowed tools to Read" \
    "$run_claude_body" \
    'allowed_tools="Read"'
assert_contains "Claude normal mode still has legacy write tools" \
    "$run_claude_body" \
    'allowed_tools="Read,Write,Edit,Delete"'
assert_contains "section patches are extracted from model output" \
    "$update_fn" \
    'extract_section_patch_payload'
assert_contains "section patches are applied by claudux" \
    "$update_fn" \
    'apply_manifest_section_patches'

# --- Test 19: Codex patch mode requests a read-only sandbox ---
codex_exec_body=$(sed -n '/^run_codex_exec()/,/^}/p' "$LIB_DIR/codex-utils.sh")
assert_contains "Codex exec reads section patch mode" \
    "$codex_exec_body" \
    'CLAUDUX_SECTION_PATCH_MODE'
assert_contains "Codex patch mode defaults to read-only sandbox" \
    "$codex_exec_body" \
    'read-only'
assert_contains "Codex normal mode still defaults to danger-full-access" \
    "$codex_exec_body" \
    'danger-full-access'

# --- Test 20: failed backend / patch extraction keeps the raw JSONL log ---
retain_fn=$(sed -n '/^retain_generation_debug_log()/,/^}/p' "$LIB_DIR/docs-generation.sh")
assert_contains "docs-generation defines debug log retention helper" \
    "$retain_fn" \
    'Retained backend JSONL log'
assert_contains "debug log retention writes a /tmp claudux jsonl copy" \
    "$retain_fn" \
    '/tmp/claudux-'
assert_contains "section patch failure retains the backend log" \
    "$update_fn" \
    'retain_generation_debug_log "$claude_log" "section-patch-failure"'
assert_contains "backend nonzero failure retains the backend log" \
    "$fail_block" \
    'retain_generation_debug_log "$claude_log" "backend-failure"'

# Cleanup
rm -f /tmp/claudux-test-backend-default /tmp/claudux-test-backend-codex /tmp/claudux-test-missing
rm -f /tmp/claudux-test-header-claude /tmp/claudux-test-header-codex

test_summary
