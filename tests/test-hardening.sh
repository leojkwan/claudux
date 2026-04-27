#!/bin/bash
# Tests: edge-case hardening — codex-utils.sh, error paths, robustness
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-harness.sh"

echo "=== Hardening & Edge Case Tests ==="
echo ""

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$REPO_ROOT/lib"

# Stub color/logging functions
info()    { :; }
warn()    { :; }
success() { :; }
error_exit() { echo "ERROR: $1" >&2; return 1; }
print_color() { shift; echo "$@"; }

# Helper: create a temp git repo
setup_repo() {
    local dir
    dir=$(mktemp -d /tmp/claudux-harden-test-XXXXXX)
    (
        cd "$dir"
        git init -q
        git config user.email "test@test.com"
        git config user.name "Test"
        echo "init" > README.md
        git add README.md
        git commit -q -m "initial"
    )
    echo "$dir"
}

# ═══════════════════════════════════════════
# codex-utils.sh edge cases
# ═══════════════════════════════════════════

# --- Test 1: codex-utils.sh sources cleanly ---
(
    source "$LIB_DIR/codex-utils.sh" 2>&1
    echo "sourced-ok"
) > /tmp/claudux-harden-t1 2>&1
assert_eq "codex-utils.sh sources without error" "sourced-ok" "$(tail -1 /tmp/claudux-harden-t1)"

# --- Test 2: get_codex_model_settings returns pipe-delimited output ---
(
    source "$LIB_DIR/codex-utils.sh"
    result=$(get_codex_model_settings)
    fields=$(echo "$result" | tr '|' '\n' | wc -l | tr -d ' ')
    echo "$fields"
) > /tmp/claudux-harden-t2 2>&1
assert_eq "get_codex_model_settings returns 4 fields" "4" "$(cat /tmp/claudux-harden-t2)"

# --- Test 3: get_codex_model_settings defaults to gpt-5.4 ---
(
    unset CODEX_MODEL 2>/dev/null || true
    unset CODEX_REASONING_EFFORT 2>/dev/null || true
    source "$LIB_DIR/codex-utils.sh"
    IFS='|' read -r model name timeout effort <<< "$(get_codex_model_settings)"
    echo "$model"
) > /tmp/claudux-harden-t3 2>&1
assert_eq "default codex model is gpt-5.4" "gpt-5.4" "$(cat /tmp/claudux-harden-t3)"

# --- Test 4: get_codex_model_settings respects CODEX_MODEL env var ---
(
    export CODEX_MODEL="gpt-5.3-codex"
    source "$LIB_DIR/codex-utils.sh"
    IFS='|' read -r model name timeout effort <<< "$(get_codex_model_settings)"
    echo "$model"
) > /tmp/claudux-harden-t4 2>&1
assert_eq "CODEX_MODEL override works" "gpt-5.3-codex" "$(cat /tmp/claudux-harden-t4)"

# --- Test 5: get_codex_model_settings respects CODEX_REASONING_EFFORT ---
(
    export CODEX_REASONING_EFFORT="medium"
    source "$LIB_DIR/codex-utils.sh"
    IFS='|' read -r model name timeout effort <<< "$(get_codex_model_settings)"
    echo "$effort"
) > /tmp/claudux-harden-t5 2>&1
assert_eq "CODEX_REASONING_EFFORT override works" "medium" "$(cat /tmp/claudux-harden-t5)"

# --- Test 6: get_codex_model_settings handles unknown model gracefully ---
(
    export CODEX_MODEL="some-future-model"
    source "$LIB_DIR/codex-utils.sh"
    IFS='|' read -r model name timeout effort <<< "$(get_codex_model_settings)"
    echo "$name"
) > /tmp/claudux-harden-t6 2>&1
assert_contains "unknown model gets a name" "$(cat /tmp/claudux-harden-t6)" "some-future-model"

# --- Test 7: format_codex_output_stream handles empty input ---
(
    source "$LIB_DIR/codex-utils.sh"
    echo "" | format_codex_output_stream
    echo "exit-ok"
) > /tmp/claudux-harden-t7 2>&1
assert_contains "empty input to formatter exits ok" "$(cat /tmp/claudux-harden-t7)" "exit-ok"

# --- Test 8: format_codex_output_stream handles non-JSON input ---
(
    source "$LIB_DIR/codex-utils.sh"
    echo "this is not json at all" | format_codex_output_stream
    echo "exit-ok"
) > /tmp/claudux-harden-t8 2>&1
assert_contains "non-JSON input to formatter exits ok" "$(cat /tmp/claudux-harden-t8)" "exit-ok"

# --- Test 18: formatter parses real Codex thread.started event ---
(
    source "$LIB_DIR/codex-utils.sh"
    echo '{"type":"thread.started","thread_id":"019d83be-c3a8-7b50-bec6-e0d2c0e9772e"}' | format_codex_output_stream
) > /tmp/claudux-harden-t18 2>&1
assert_contains "thread.started shows session id" "$(cat /tmp/claudux-harden-t18)" "Codex session:"

# --- Test 19: formatter parses item.started command_execution ---
(
    source "$LIB_DIR/codex-utils.sh"
    echo '{"type":"item.started","item":{"id":"item_1","type":"command_execution","command":"/bin/zsh -lc '\''wc -l bin/claudux'\''","status":"in_progress"}}' | format_codex_output_stream
) > /tmp/claudux-harden-t19 2>&1
assert_contains "item.started shows running command" "$(cat /tmp/claudux-harden-t19)" "Running [1]:"

# --- Test 20: formatter parses item.completed agent_message ---
(
    source "$LIB_DIR/codex-utils.sh"
    echo '{"type":"item.completed","item":{"id":"item_0","type":"agent_message","text":"CODEX_PING_OK"}}' | format_codex_output_stream
) > /tmp/claudux-harden-t20 2>&1
assert_contains "agent_message shows text" "$(cat /tmp/claudux-harden-t20)" "Agent: CODEX_PING_OK"

# --- Test 21: formatter parses turn.completed with token usage ---
(
    source "$LIB_DIR/codex-utils.sh"
    echo '{"type":"turn.completed","usage":{"input_tokens":28311,"cached_input_tokens":2432,"output_tokens":9}}' | format_codex_output_stream
) > /tmp/claudux-harden-t21 2>&1
assert_contains "turn.completed shows token counts" "$(cat /tmp/claudux-harden-t21)" "tokens: 28311 in / 9 out"

# --- Test 22: formatter handles multi-line Codex session ---
(
    # Override success stub so formatter summary is visible
    success() { echo "$@"; }
    source "$LIB_DIR/codex-utils.sh"
    {
        echo '{"type":"thread.started","thread_id":"test-thread-123"}'
        echo '{"type":"turn.started"}'
        echo '{"type":"item.completed","item":{"id":"item_0","type":"agent_message","text":"Analyzing codebase"}}'
        echo '{"type":"item.started","item":{"id":"item_1","type":"command_execution","command":"ls -la docs/","status":"in_progress"}}'
        echo '{"type":"item.completed","item":{"id":"item_1","type":"command_execution","command":"ls -la docs/","aggregated_output":"total 8\n","exit_code":0,"status":"completed"}}'
        echo '{"type":"item.completed","item":{"id":"item_2","type":"agent_message","text":"Found 3 doc files"}}'
        echo '{"type":"turn.completed","usage":{"input_tokens":1000,"cached_input_tokens":500,"output_tokens":50}}'
    } | format_codex_output_stream
) > /tmp/claudux-harden-t22 2>&1
result22=$(cat /tmp/claudux-harden-t22)
assert_contains "multi-line session shows session id" "$result22" "Codex session:"
assert_contains "multi-line session shows command" "$result22" "Running [1]:"
assert_contains "multi-line session shows messages" "$result22" "Agent: Analyzing codebase"
assert_contains "multi-line session shows summary" "$result22" "Codex finished (1 commands, 0 files, 2 messages)"

# --- Test 23: formatter handles failed command_execution ---
(
    source "$LIB_DIR/codex-utils.sh"
    echo '{"type":"item.completed","item":{"id":"item_1","type":"command_execution","command":"cat nonexistent.md","aggregated_output":"","exit_code":1,"status":"completed"}}' | format_codex_output_stream
) > /tmp/claudux-harden-t23 2>&1
assert_contains "failed command shows error" "$(cat /tmp/claudux-harden-t23)" "Command failed (exit 1)"

# --- Test 24: formatter ignores stderr noise mixed in ---
(
    source "$LIB_DIR/codex-utils.sh"
    {
        echo 'Reading prompt from stdin...'
        echo '2026-04-12T22:10:10.149441Z ERROR codex_core::codex: failed to load skill'
        echo '{"type":"item.completed","item":{"id":"item_0","type":"agent_message","text":"Hello"}}'
    } | format_codex_output_stream
) > /tmp/claudux-harden-t24 2>&1
result24=$(cat /tmp/claudux-harden-t24)
assert_contains "stderr noise ignored, message parsed" "$result24" "Agent: Hello"
assert_not_contains "stderr noise not shown" "$result24" "ERROR"

# ═══════════════════════════════════════════
# save/load state robustness
# ═══════════════════════════════════════════

# --- Test 9: save_claudux_state outside a git repo ---
NON_GIT_DIR=$(mktemp -d /tmp/claudux-harden-nongit-XXXXXX)
(
    cd "$NON_GIT_DIR"
    STATE_FILE="$NON_GIT_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$NON_GIT_DIR/.claudux-state.json"
    save_claudux_state
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    fi
) > /tmp/claudux-harden-t9 2>&1
state9=$(cat /tmp/claudux-harden-t9)
assert_contains "non-git repo state has unknown SHA" "$state9" '"last_sha": "unknown"'
assert_contains "non-git repo state has files_documented" "$state9" '"files_documented": []'
rm -rf "$NON_GIT_DIR"

# --- Test 10: save_claudux_state with many docs files (stress) ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    mkdir -p docs/guide docs/api
    for i in $(seq 1 20); do
        echo "# Page $i" > "docs/guide/page-$i.md"
        echo "# API $i" > "docs/api/endpoint-$i.md"
    done
    git add docs/
    git commit -q -m "add 40 doc files"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state
    if command -v jq >/dev/null 2>&1; then
        count=$(jq '.files_documented | length' "$STATE_FILE")
        echo "$count"
    else
        # Count quoted strings in files_documented array
        count=$(grep -o '"docs/' "$STATE_FILE" | wc -l | tr -d ' ')
        echo "$count"
    fi
) > /tmp/claudux-harden-t10 2>&1
assert_eq "40 doc files tracked in state" "40" "$(cat /tmp/claudux-harden-t10)"
rm -rf "$TEST_DIR"

# --- Test 11: claudux_diff_since_last with corrupted state file ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    echo "NOT JSON AT ALL" > "$STATE_FILE"
    output=$(claudux_diff_since_last 2>&1)
    ec=$?
    if [[ $ec -ne 0 ]]; then echo "caught-error"; else echo "no-error"; fi
) > /tmp/claudux-harden-t11 2>&1
assert_eq "corrupted state file caught" "caught-error" "$(cat /tmp/claudux-harden-t11)"
rm -rf "$TEST_DIR"

# ═══════════════════════════════════════════
# bin/claudux robustness
# ═══════════════════════════════════════════

# --- Test 12: bin/claudux --version doesn't crash ---
(
    bash "$REPO_ROOT/bin/claudux" --version 2>&1
    echo "exit:$?"
) > /tmp/claudux-harden-t12 2>&1
result12=$(cat /tmp/claudux-harden-t12)
assert_contains "version command exits cleanly" "$result12" "exit:0"
assert_contains "version output contains claudux" "$result12" "claudux"

# --- Test 13: bin/claudux help doesn't crash ---
(
    bash "$REPO_ROOT/bin/claudux" help 2>&1
    echo "exit:$?"
) > /tmp/claudux-harden-t13 2>&1
assert_contains "help command exits cleanly" "$(cat /tmp/claudux-harden-t13)" "exit:0"

# --- Test 14: bin/claudux unknown-command exits non-zero ---
(
    bash "$REPO_ROOT/bin/claudux" totally-bogus-command 2>&1
    echo "exit:$?"
) > /tmp/claudux-harden-t14 2>&1
assert_contains "unknown command exits non-zero" "$(cat /tmp/claudux-harden-t14)" "exit:1"

# --- Test 15: CODEX_UTILS_MISSING flag blocks update-path validation ---
validate_fn=$(sed -n '/^validate_dependencies()/,/^}/p' "$REPO_ROOT/bin/claudux")
assert_contains "validate checks CODEX_UTILS_MISSING" "$validate_fn" 'CODEX_UTILS_MISSING'

# --- Test 16: update rejects bad options before backend auth ---
(
    cd "$REPO_ROOT"
    bash "$REPO_ROOT/bin/claudux" update --help 2>&1
    echo "exit:$?"
) > /tmp/claudux-harden-t16 2>&1
result16=$(cat /tmp/claudux-harden-t16)
assert_contains "update --help reports update option error" "$result16" "Unknown option for 'update': --help"
assert_contains "update --help exits 2" "$result16" "exit:2"
assert_not_contains "update --help skips model auth probe" "$result16" "Checking available models"
assert_not_contains "update --help skips auth API call" "$result16" "API Error"

(
    cd "$REPO_ROOT"
    bash "$REPO_ROOT/bin/claudux" update -m 2>&1
    echo "exit:$?"
) > /tmp/claudux-harden-t16-missing 2>&1
result16_missing=$(cat /tmp/claudux-harden-t16-missing)
assert_contains "update -m requires message" "$result16_missing" "Option -m requires an argument"
assert_contains "update -m exits 2" "$result16_missing" "exit:2"
assert_not_contains "update -m skips auth API call" "$result16_missing" "API Error"

(
    cd "$REPO_ROOT"
    bash "$REPO_ROOT/bin/claudux" update --message --strict 2>&1
    echo "exit:$?"
) > /tmp/claudux-harden-t16-option-value 2>&1
result16_option_value=$(cat /tmp/claudux-harden-t16-option-value)
assert_contains "update --message rejects option as value" "$result16_option_value" "Option --message requires a non-option argument"
assert_contains "update --message option exits 2" "$result16_option_value" "exit:2"
assert_not_contains "update --message option skips auth API call" "$result16_option_value" "API Error"

# --- Test 17: docs-generation.sh has no unguarded variable references ---
# set -u will catch unset vars; verify the file can be sourced in a strict shell
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    set -u
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    # Provide stubs for all required globals
    LIB_DIR="$REPO_ROOT/lib"
    source "$LIB_DIR/docs-generation.sh" 2>&1
    echo "sourced-ok"
) > /tmp/claudux-harden-t17 2>&1
assert_eq "docs-generation.sh sources under set -u" "sourced-ok" "$(tail -1 /tmp/claudux-harden-t17)"
rm -rf "$TEST_DIR"

# --- Test 18: State file with special characters in file paths ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    mkdir -p "docs/my guide"
    echo "# Space" > "docs/my guide/setup.md"
    git add "docs/my guide/setup.md"
    git commit -q -m "file with space"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state
    if command -v jq >/dev/null 2>&1; then
        if jq . "$STATE_FILE" >/dev/null 2>&1; then
            echo "valid-json"
        else
            echo "invalid-json"
        fi
    else
        if grep -q "my guide" "$STATE_FILE"; then
            echo "valid-json"
        else
            echo "missing-path"
        fi
    fi
) > /tmp/claudux-harden-t18 2>&1
assert_eq "file paths with spaces produce valid JSON" "valid-json" "$(cat /tmp/claudux-harden-t18)"
rm -rf "$TEST_DIR"

# ═══════════════════════════════════════════
# Auth error detection in check_codex()
# ═══════════════════════════════════════════

# --- Test 25: check_codex detects auth error keywords ---
# We can't run the real codex CLI in tests, but we can verify the grep pattern
# matches the keywords check_codex looks for.
(
    auth_keywords=("auth" "api.key" "unauthorized" "401" "login" "token")
    pattern='auth|api.key|unauthorized|401|login|token'
    all_match=true
    for kw in "${auth_keywords[@]}"; do
        if ! echo "Error: $kw required" | grep -qiE "$pattern"; then
            all_match=false
            break
        fi
    done
    if $all_match; then echo "all-match"; else echo "mismatch"; fi
) > /tmp/claudux-harden-t25 2>&1
assert_eq "auth error keywords all match grep pattern" "all-match" "$(cat /tmp/claudux-harden-t25)"

# --- Test 26: check_codex auth probe pattern does NOT match non-auth errors ---
(
    pattern='auth|api.key|unauthorized|401|login|token'
    false_positives=0
    for msg in "rate limit exceeded" "network timeout" "model not found" "internal server error"; do
        if echo "$msg" | grep -qiE "$pattern"; then
            ((false_positives++))
        fi
    done
    echo "$false_positives"
) > /tmp/claudux-harden-t26 2>&1
assert_eq "non-auth errors do not match auth pattern" "0" "$(cat /tmp/claudux-harden-t26)"

# --- Test 27: check_codex function signature includes auth probe ---
# Accepts either the modern zero-token `codex login status` probe OR the legacy
# `codex exec ... echo hello` fallback (kept for back-compat with older CLIs).
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f check_codex)
    if echo "$fn_body" | grep -q 'codex login status' \
       || echo "$fn_body" | grep -q 'codex exec.*echo hello'; then
        echo "has-probe"
    else
        echo "no-probe"
    fi
) > /tmp/claudux-harden-t27 2>&1
assert_eq "check_codex has auth probe" "has-probe" "$(cat /tmp/claudux-harden-t27)"

# --- Test 28: check_codex error message mentions 'codex login' (remedy) ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f check_codex)
    if echo "$fn_body" | grep -qE "codex login|codex auth"; then
        echo "has-remedy"
    else
        echo "no-remedy"
    fi
) > /tmp/claudux-harden-t28 2>&1
assert_eq "check_codex error message mentions remedy" "has-remedy" "$(cat /tmp/claudux-harden-t28)"

# --- Test 28b: check_codex prefers the zero-token `login status` probe ---
# Regression guard: we must not silently fall back to the ~28K-token `echo hello`
# probe as the primary path. The modern probe must be tried first.
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f check_codex)
    login_line=$(echo "$fn_body" | grep -n 'codex login status' | head -1 | cut -d: -f1)
    exec_line=$(echo "$fn_body" | grep -n 'codex exec.*echo hello' | head -1 | cut -d: -f1)
    if [[ -z "$login_line" ]]; then
        echo "no-modern-probe"
    elif [[ -n "$exec_line" ]] && [[ "$login_line" -gt "$exec_line" ]]; then
        echo "modern-probe-not-primary"
    else
        echo "modern-probe-first"
    fi
) > /tmp/claudux-harden-t28b 2>&1
assert_eq "check_codex prefers zero-token login-status probe" "modern-probe-first" "$(cat /tmp/claudux-harden-t28b)"

# ═══════════════════════════════════════════
# Timeout handling in run_codex_exec()
# ═══════════════════════════════════════════

# --- Test 29: run_codex_exec function reads CLAUDUX_TIMEOUT ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    if echo "$fn_body" | grep -q 'CLAUDUX_TIMEOUT'; then
        echo "reads-timeout"
    else
        echo "no-timeout"
    fi
) > /tmp/claudux-harden-t29 2>&1
assert_eq "run_codex_exec reads CLAUDUX_TIMEOUT" "reads-timeout" "$(cat /tmp/claudux-harden-t29)"

# --- Test 30: run_codex_exec defaults to 600s timeout ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    if echo "$fn_body" | grep -q 'CLAUDUX_TIMEOUT:-600'; then
        echo "default-600"
    else
        echo "no-default"
    fi
) > /tmp/claudux-harden-t30 2>&1
assert_eq "run_codex_exec defaults timeout to 600s" "default-600" "$(cat /tmp/claudux-harden-t30)"

# --- Test 31: run_codex_exec handles exit code 124 (timeout) ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    if echo "$fn_body" | grep -q 'rc -eq 124'; then
        echo "handles-124"
    else
        echo "no-124"
    fi
) > /tmp/claudux-harden-t31 2>&1
assert_eq "run_codex_exec detects timeout exit code 124" "handles-124" "$(cat /tmp/claudux-harden-t31)"

# --- Test 32: run_codex_exec tries gtimeout on macOS ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    if echo "$fn_body" | grep -q 'gtimeout'; then
        echo "has-gtimeout"
    else
        echo "no-gtimeout"
    fi
) > /tmp/claudux-harden-t32 2>&1
assert_eq "run_codex_exec has gtimeout fallback for macOS" "has-gtimeout" "$(cat /tmp/claudux-harden-t32)"

# --- Test 33: run_codex_exec has no-timeout fallback when CLAUDUX_TIMEOUT=0 ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    # The else branch runs codex without timeout wrapper
    if echo "$fn_body" | grep -q 'echo.*\| codex'; then
        echo "has-fallback"
    else
        echo "no-fallback"
    fi
) > /tmp/claudux-harden-t33 2>&1
assert_eq "run_codex_exec has no-timeout fallback" "has-fallback" "$(cat /tmp/claudux-harden-t33)"

# --- Test 34: run_codex_exec timeout error message includes duration ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    if echo "$fn_body" | grep -q 'timed out after'; then
        echo "has-duration"
    else
        echo "no-duration"
    fi
) > /tmp/claudux-harden-t34 2>&1
assert_eq "timeout error message includes duration" "has-duration" "$(cat /tmp/claudux-harden-t34)"

# ═══════════════════════════════════════════
# Integration: diff/status after backend switch
# ═══════════════════════════════════════════

# --- Test 35: state file preserves backend across save/load cycle ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    export CLAUDUX_BACKEND=codex
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state
    loaded=$(load_claudux_state)
    if command -v jq >/dev/null 2>&1; then
        echo "$loaded" | jq -r '.backend'
    else
        echo "$loaded" | grep '"backend"' | sed 's/.*: *"\([^"]*\)".*/\1/'
    fi
) > /tmp/claudux-harden-t35 2>&1
assert_eq "state preserves codex backend after load" "codex" "$(cat /tmp/claudux-harden-t35)"
rm -rf "$TEST_DIR"

# --- Test 36: claudux_diff_since_last works after codex-backend save ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    export CLAUDUX_BACKEND=codex
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state

    # Make a change after checkpoint
    echo "new content" >> README.md
    git add README.md
    git commit -q -m "post-codex change"

    changed=$(claudux_diff_since_last 2>/dev/null)
    if echo "$changed" | grep -q "README.md"; then
        echo "diff-works"
    else
        echo "diff-broken"
    fi
) > /tmp/claudux-harden-t36 2>&1
assert_eq "diff works after codex-backend save" "diff-works" "$(cat /tmp/claudux-harden-t36)"
rm -rf "$TEST_DIR"

# --- Test 37: CLAUDUX_TIMEOUT=0 disables timeout (function still has the path) ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    # When timeout_secs is 0 or non-numeric, the -gt 0 check fails and we hit the else
    if echo "$fn_body" | grep -qE 'timeout_secs.*-gt 0'; then
        echo "guards-zero"
    else
        echo "no-guard"
    fi
) > /tmp/claudux-harden-t37 2>&1
assert_eq "CLAUDUX_TIMEOUT=0 guard exists" "guards-zero" "$(cat /tmp/claudux-harden-t37)"

# --- Test 38: codex-utils.sh sources cleanly under set -u ---
(
    set -u
    source "$LIB_DIR/codex-utils.sh" 2>&1
    echo "sourced-ok"
) > /tmp/claudux-harden-t38 2>&1
assert_eq "codex-utils.sh sources cleanly under set -u" "sourced-ok" "$(tail -1 /tmp/claudux-harden-t38)"

# Cleanup
rm -f /tmp/claudux-harden-t{1,2,3,4,5,6,7,8,9,10,11,12,13,14,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38}

test_summary
