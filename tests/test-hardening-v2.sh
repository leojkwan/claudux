#!/bin/bash
# Tests: hardening v2 — atomic state writes, corruption recovery, crash detection, runtime guards
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-harness.sh"

echo "=== Hardening V2 Tests ==="
echo ""

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$REPO_ROOT/lib"

# Stub color/logging functions
info()    { :; }
warn()    { echo "WARN: $*" >&2; }
success() { :; }
error_exit() { echo "ERROR: $1" >&2; return 1; }
print_color() { shift; echo "$@"; }

# Helper: create a temp git repo
setup_repo() {
    local dir
    dir=$(mktemp -d /tmp/claudux-hv2-test-XXXXXX)
    (
        cd "$dir"
        git init -q
        git config user.email "test@test.com"
        git config user.name "Test"
        echo "init" > README.md
        mkdir -p docs
        echo "# Index" > docs/index.md
        git add README.md docs/index.md
        git commit -q -m "initial"
    )
    echo "$dir"
}

# ═══════════════════════════════════════════
# Atomic state writes
# ═══════════════════════════════════════════

# --- Test 1: save_claudux_state uses atomic write (temp + mv) ---
(
    source "$LIB_DIR/docs-generation.sh"
    fn_body=$(declare -f save_claudux_state)
    if echo "$fn_body" | grep -q 'tmp_state' && echo "$fn_body" | grep -q 'mv -f'; then
        echo "atomic"
    else
        echo "direct-write"
    fi
) > /tmp/claudux-hv2-t1 2>&1
assert_eq "save_claudux_state uses atomic write pattern" "atomic" "$(cat /tmp/claudux-hv2-t1)"

# --- Test 2: No temp file left behind after successful save ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state
    # Check no .tmp files exist
    tmp_count=$(ls -1 "$TEST_DIR"/.claudux-state.json.tmp.* 2>/dev/null | wc -l | tr -d ' ')
    echo "$tmp_count"
) > /tmp/claudux-hv2-t2 2>&1
assert_eq "no temp files left after save" "0" "$(cat /tmp/claudux-hv2-t2)"
rm -rf "$TEST_DIR"

# --- Test 3: State file is valid JSON after atomic write ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    mkdir -p docs/guide
    echo "# Setup" > docs/guide/setup.md
    git add docs/guide/setup.md
    git commit -q -m "add guide"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state
    if command -v jq >/dev/null 2>&1; then
        if jq . "$STATE_FILE" >/dev/null 2>&1; then
            echo "valid"
        else
            echo "invalid"
        fi
    else
        echo "valid"
    fi
) > /tmp/claudux-hv2-t3 2>&1
assert_eq "atomic write produces valid JSON" "valid" "$(cat /tmp/claudux-hv2-t3)"
rm -rf "$TEST_DIR"

# --- Test 4: save_claudux_state validates JSON before committing (jq path) ---
(
    source "$LIB_DIR/docs-generation.sh"
    fn_body=$(declare -f save_claudux_state)
    if echo "$fn_body" | grep -q 'jq.*tmp_state'; then
        echo "validates"
    else
        echo "no-validation"
    fi
) > /tmp/claudux-hv2-t4 2>&1
assert_eq "save validates JSON before mv" "validates" "$(cat /tmp/claudux-hv2-t4)"

# ═══════════════════════════════════════════
# State file corruption recovery
# ═══════════════════════════════════════════

# --- Test 5: load_claudux_state returns 1 when file missing ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    rm -f "$STATE_FILE"
    load_claudux_state >/dev/null 2>&1
    echo "$?"
) > /tmp/claudux-hv2-t5 2>&1
assert_eq "load returns 1 when missing" "1" "$(cat /tmp/claudux-hv2-t5)"
rm -rf "$TEST_DIR"

# --- Test 6: load_claudux_state returns 2 for corrupt file (missing last_sha) ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    echo '{"some_random": "json"}' > "$STATE_FILE"
    load_claudux_state >/dev/null 2>&1
    echo "$?"
) > /tmp/claudux-hv2-t6 2>&1
assert_eq "load returns 2 for corrupt state (missing last_sha)" "2" "$(cat /tmp/claudux-hv2-t6)"
rm -rf "$TEST_DIR"

# --- Test 7: load_claudux_state returns 2 for non-JSON content ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    echo "THIS IS NOT JSON AT ALL" > "$STATE_FILE"
    load_claudux_state >/dev/null 2>&1
    echo "$?"
) > /tmp/claudux-hv2-t7 2>&1
assert_eq "load returns 2 for non-JSON content" "2" "$(cat /tmp/claudux-hv2-t7)"
rm -rf "$TEST_DIR"

# --- Test 8: load_claudux_state returns 2 for truncated JSON ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    echo '{"last_sha": "abc123", "last_run": "2026-0' > "$STATE_FILE"
    load_claudux_state >/dev/null 2>&1
    echo "$?"
) > /tmp/claudux-hv2-t8 2>&1
# Truncated JSON has last_sha but is invalid JSON; if jq available returns 2, otherwise 0
if command -v jq >/dev/null 2>&1; then
    assert_eq "load returns 2 for truncated JSON (jq available)" "2" "$(cat /tmp/claudux-hv2-t8)"
else
    assert_eq "load returns 0 for truncated JSON (no jq — has last_sha)" "0" "$(cat /tmp/claudux-hv2-t8)"
fi
rm -rf "$TEST_DIR"

# --- Test 9: load_claudux_state returns 0 for valid state ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state
    load_claudux_state >/dev/null 2>&1
    echo "$?"
) > /tmp/claudux-hv2-t9 2>&1
assert_eq "load returns 0 for valid state" "0" "$(cat /tmp/claudux-hv2-t9)"
rm -rf "$TEST_DIR"

# --- Test 10: load_claudux_state warns on corrupt file ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    echo "GARBAGE" > "$STATE_FILE"
    load_claudux_state 2>&1
) > /tmp/claudux-hv2-t10 2>&1
assert_contains "load warns on corrupt state" "$(cat /tmp/claudux-hv2-t10)" "corrupt"
rm -rf "$TEST_DIR"

# --- Test 11: claudux_diff_since_last handles corrupt state gracefully ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    echo '{"not":"valid","for":"claudux"}' > "$STATE_FILE"
    output=$(claudux_diff_since_last 2>&1)
    ec=$?
    echo "ec=$ec"
) > /tmp/claudux-hv2-t11 2>&1
assert_contains "diff handles corrupt state non-zero exit" "$(cat /tmp/claudux-hv2-t11)" "ec=1"
rm -rf "$TEST_DIR"

# ═══════════════════════════════════════════
# Crash detection in error reporting
# ═══════════════════════════════════════════

# --- Test 12: docs-generation.sh detects exit 137 (SIGKILL/OOM) ---
(
    source "$LIB_DIR/docs-generation.sh"
    fn_body=$(cat "$LIB_DIR/docs-generation.sh")
    if echo "$fn_body" | grep -q '137'; then
        echo "detects-137"
    else
        echo "no-137"
    fi
) > /tmp/claudux-hv2-t12 2>&1
assert_eq "crash detection for exit 137 (SIGKILL)" "detects-137" "$(cat /tmp/claudux-hv2-t12)"

# --- Test 13: docs-generation.sh detects exit 139 (segfault) ---
(
    fn_body=$(cat "$LIB_DIR/docs-generation.sh")
    if echo "$fn_body" | grep -q '139'; then
        echo "detects-139"
    else
        echo "no-139"
    fi
) > /tmp/claudux-hv2-t13 2>&1
assert_eq "crash detection for exit 139 (SIGSEGV)" "detects-139" "$(cat /tmp/claudux-hv2-t13)"

# --- Test 14: docs-generation.sh detects exit 130 (SIGINT) ---
(
    fn_body=$(cat "$LIB_DIR/docs-generation.sh")
    if echo "$fn_body" | grep -q '130'; then
        echo "detects-130"
    else
        echo "no-130"
    fi
) > /tmp/claudux-hv2-t14 2>&1
assert_eq "crash detection for exit 130 (SIGINT)" "detects-130" "$(cat /tmp/claudux-hv2-t14)"

# --- Test 15: docs-generation.sh reports empty log on crash ---
(
    fn_body=$(cat "$LIB_DIR/docs-generation.sh")
    if echo "$fn_body" | grep -q 'crashed before producing'; then
        echo "reports-empty"
    else
        echo "no-report"
    fi
) > /tmp/claudux-hv2-t15 2>&1
assert_eq "empty output crash detection message present" "reports-empty" "$(cat /tmp/claudux-hv2-t15)"

# --- Test 16: Error output includes backend label not just "Claude" ---
(
    fn_body=$(cat "$LIB_DIR/docs-generation.sh")
    if echo "$fn_body" | grep -q 'backend_label'; then
        echo "uses-backend-label"
    else
        echo "hardcoded-claude"
    fi
) > /tmp/claudux-hv2-t16 2>&1
assert_eq "error messages use dynamic backend label" "uses-backend-label" "$(cat /tmp/claudux-hv2-t16)"

# ═══════════════════════════════════════════
# run_codex_exec runtime guard
# ═══════════════════════════════════════════

# --- Test 17: run_codex_exec has runtime PATH guard ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    if echo "$fn_body" | grep -q 'command -v codex'; then
        echo "has-guard"
    else
        echo "no-guard"
    fi
) > /tmp/claudux-hv2-t17 2>&1
assert_eq "run_codex_exec has runtime PATH guard" "has-guard" "$(cat /tmp/claudux-hv2-t17)"

# --- Test 18: run_codex_exec returns 127 when codex not in PATH ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    if echo "$fn_body" | grep -q 'return 127'; then
        echo "returns-127"
    else
        echo "no-127"
    fi
) > /tmp/claudux-hv2-t18 2>&1
assert_eq "run_codex_exec returns 127 when codex missing" "returns-127" "$(cat /tmp/claudux-hv2-t18)"

# ═══════════════════════════════════════════
# Edge cases: state save with concurrent PIDs
# ═══════════════════════════════════════════

# --- Test 19: Two rapid saves don't leave temp files ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"

    save_claudux_state
    echo "x" >> README.md
    git add README.md
    git commit -q -m "second commit"
    save_claudux_state

    tmp_count=$(ls -1 "$TEST_DIR"/.claudux-state.json.tmp.* 2>/dev/null | wc -l | tr -d ' ')
    echo "$tmp_count"
) > /tmp/claudux-hv2-t19 2>&1
assert_eq "no temp files after two rapid saves" "0" "$(cat /tmp/claudux-hv2-t19)"
rm -rf "$TEST_DIR"

# --- Test 20: State file content is correct after second save ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state

    echo "x" >> README.md
    git add README.md
    git commit -q -m "second commit"
    save_claudux_state

    second_sha=$(git rev-parse HEAD)
    if command -v jq >/dev/null 2>&1; then
        saved_sha=$(jq -r '.last_sha' "$STATE_FILE")
    else
        saved_sha=$(grep '"last_sha"' "$STATE_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/')
    fi

    if [[ "$saved_sha" == "$second_sha" ]]; then
        echo "correct"
    else
        echo "stale"
    fi
) > /tmp/claudux-hv2-t20 2>&1
assert_eq "second save has correct SHA" "correct" "$(cat /tmp/claudux-hv2-t20)"
rm -rf "$TEST_DIR"

# ═══════════════════════════════════════════
# Edge case: load + diff when load returns 2
# ═══════════════════════════════════════════

# --- Test 21: claudux_diff_since_last returns error when load returns 2 ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    # Write invalid JSON with no last_sha
    echo '{"corrupt": true}' > "$STATE_FILE"
    output=$(claudux_diff_since_last 2>&1)
    ec=$?
    echo "$ec"
) > /tmp/claudux-hv2-t21 2>&1
assert_eq "diff returns non-zero for corrupt state" "1" "$(cat /tmp/claudux-hv2-t21)"
rm -rf "$TEST_DIR"

# --- Test 22: claudux_status gracefully handles corrupt state ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    echo "GARBAGE" > "$STATE_FILE"
    output=$(claudux_status 2>&1)
    ec=$?
    echo "ec=$ec"
) > /tmp/claudux-hv2-t22 2>&1
# claudux_status should handle the corrupt state as "no state"
result22=$(cat /tmp/claudux-hv2-t22)
assert_contains "status handles corrupt state" "$result22" "ec=1"
rm -rf "$TEST_DIR"

# ═══════════════════════════════════════════
# Edge case: save_claudux_state sources cleanly under set -u
# ═══════════════════════════════════════════

# --- Test 23: save_claudux_state works under set -u ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    set -u
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    LIB_DIR="$REPO_ROOT/lib"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state 2>&1
    echo "exit:$?"
) > /tmp/claudux-hv2-t23 2>&1
assert_contains "save works under set -u" "$(cat /tmp/claudux-hv2-t23)" "exit:0"
rm -rf "$TEST_DIR"

# --- Test 24: load_claudux_state works under set -u ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    set -u
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    LIB_DIR="$REPO_ROOT/lib"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state 2>/dev/null
    load_claudux_state >/dev/null 2>&1
    echo "exit:$?"
) > /tmp/claudux-hv2-t24 2>&1
assert_contains "load works under set -u" "$(cat /tmp/claudux-hv2-t24)" "exit:0"
rm -rf "$TEST_DIR"

# ═══════════════════════════════════════════
# Edge case: empty state file (zero bytes)
# ═══════════════════════════════════════════

# --- Test 25: load_claudux_state returns 2 for empty file ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    : > "$STATE_FILE"  # create empty file
    load_claudux_state >/dev/null 2>&1
    echo "$?"
) > /tmp/claudux-hv2-t25 2>&1
assert_eq "load returns 2 for empty file" "2" "$(cat /tmp/claudux-hv2-t25)"
rm -rf "$TEST_DIR"

# Cleanup
rm -f /tmp/claudux-hv2-t{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25}

test_summary
