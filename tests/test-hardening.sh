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

# --- Test 16: docs-generation.sh has no unguarded variable references ---
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
) > /tmp/claudux-harden-t16 2>&1
assert_eq "docs-generation.sh sources under set -u" "sourced-ok" "$(tail -1 /tmp/claudux-harden-t16)"
rm -rf "$TEST_DIR"

# --- Test 17: State file with special characters in file paths ---
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
) > /tmp/claudux-harden-t17 2>&1
assert_eq "file paths with spaces produce valid JSON" "valid-json" "$(cat /tmp/claudux-harden-t17)"
rm -rf "$TEST_DIR"

# Cleanup
rm -f /tmp/claudux-harden-t{1,2,3,4,5,6,7,8,9,10,11,12,13,14,16,17}

test_summary
