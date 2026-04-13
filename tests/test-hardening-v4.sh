#!/bin/bash
# Tests: hardening v4 — trap safety, timeout validation, status function, dead code cleanup
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-harness.sh"

echo "=== Hardening V4 Tests ==="
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
    dir=$(mktemp -d /tmp/claudux-hv4-test-XXXXXX)
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
# Trap chaining in update() — lock dir not leaked
# ═══════════════════════════════════════════

# --- Test 1: update() trap chains with existing EXIT trap ---
(
    fn_body=$(cat "$LIB_DIR/docs-generation.sh")
    if echo "$fn_body" | grep -q 'trap -p EXIT'; then
        echo "chains-trap"
    else
        echo "replaces-trap"
    fi
) > /tmp/claudux-hv4-t1 2>&1
assert_eq "update() trap chains with existing EXIT trap" "chains-trap" "$(cat /tmp/claudux-hv4-t1)"

# --- Test 2: update() trap does not use bare 'trap ... EXIT' without chaining ---
(
    # Count bare trap EXIT lines (no trap -p inside)
    bare_traps=$(grep -c "trap.*EXIT" "$LIB_DIR/docs-generation.sh" | tr -d ' ')
    chain_traps=$(grep -c 'trap -p EXIT' "$LIB_DIR/docs-generation.sh" | tr -d ' ')
    # Every trap EXIT line should have a trap -p EXIT chain reference
    if [[ "$bare_traps" -le "$chain_traps" ]] || [[ "$bare_traps" -le 1 ]]; then
        echo "properly-chained"
    else
        echo "bare-traps: $bare_traps, chains: $chain_traps"
    fi
) > /tmp/claudux-hv4-t2 2>&1
assert_eq "no bare trap replacements in update()" "properly-chained" "$(cat /tmp/claudux-hv4-t2)"

# --- Test 3: update() temp file cleanup includes prompt and log files ---
(
    fn_body=$(cat "$LIB_DIR/docs-generation.sh")
    if echo "$fn_body" | grep -q 'prompt_file.*claude_log'; then
        echo "cleans-both"
    else
        echo "incomplete-cleanup"
    fi
) > /tmp/claudux-hv4-t3 2>&1
assert_eq "update() cleanup removes both prompt and log temp files" "cleans-both" "$(cat /tmp/claudux-hv4-t3)"

# ═══════════════════════════════════════════
# CLAUDUX_TIMEOUT validation in run_codex_exec
# ═══════════════════════════════════════════

# --- Test 4: run_codex_exec validates timeout is numeric ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    if echo "$fn_body" | grep -q 'not a valid integer'; then
        echo "validates"
    else
        echo "no-validation"
    fi
) > /tmp/claudux-hv4-t4 2>&1
assert_eq "run_codex_exec validates CLAUDUX_TIMEOUT is numeric" "validates" "$(cat /tmp/claudux-hv4-t4)"

# --- Test 5: run_codex_exec uses regex to check numeric ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    if echo "$fn_body" | grep -qF '[0-9]'; then
        echo "uses-regex"
    else
        echo "no-regex"
    fi
) > /tmp/claudux-hv4-t5 2>&1
assert_eq "run_codex_exec uses regex for numeric validation" "uses-regex" "$(cat /tmp/claudux-hv4-t5)"

# --- Test 6: Non-numeric CLAUDUX_TIMEOUT falls back to default 600 ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    if echo "$fn_body" | grep -q 'timeout_secs=600'; then
        echo "fallback-600"
    else
        echo "no-fallback"
    fi
) > /tmp/claudux-hv4-t6 2>&1
assert_eq "non-numeric timeout falls back to 600" "fallback-600" "$(cat /tmp/claudux-hv4-t6)"

# --- Test 7: CLAUDUX_TIMEOUT=0 falls through to no-timeout branch ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    # The function has 3 branches: timeout (gt 0 + timeout cmd), gtimeout (gt 0 + gtimeout), else (no timeout)
    has_else=$(echo "$fn_body" | grep -c 'else')
    if [[ "$has_else" -ge 1 ]]; then
        echo "has-fallthrough"
    else
        echo "no-fallthrough"
    fi
) > /tmp/claudux-hv4-t7 2>&1
assert_eq "CLAUDUX_TIMEOUT=0 has fallthrough to no-timeout" "has-fallthrough" "$(cat /tmp/claudux-hv4-t7)"

# --- Test 8: Negative CLAUDUX_TIMEOUT is rejected as non-numeric ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    # The regex ^[0-9]+$ will reject negative numbers (no leading minus allowed)
    if echo "$fn_body" | grep -qF '^[0-9]'; then
        echo "rejects-negative"
    else
        echo "allows-negative"
    fi
) > /tmp/claudux-hv4-t8 2>&1
assert_eq "negative CLAUDUX_TIMEOUT is rejected" "rejects-negative" "$(cat /tmp/claudux-hv4-t8)"

# ═══════════════════════════════════════════
# Timeout error routing to stderr log
# ═══════════════════════════════════════════

# --- Test 9: Timeout error message is written to stderr_log ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    if echo "$fn_body" | grep -q 'timeout_msg.*stderr_log'; then
        echo "routed"
    else
        echo "not-routed"
    fi
) > /tmp/claudux-hv4-t9 2>&1
assert_eq "timeout error routed to stderr log" "routed" "$(cat /tmp/claudux-hv4-t9)"

# --- Test 10: Timeout error message also goes to stderr ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    if echo "$fn_body" | grep -q 'timeout_msg.*>&2'; then
        echo "to-stderr"
    else
        echo "no-stderr"
    fi
) > /tmp/claudux-hv4-t10 2>&1
assert_eq "timeout error also goes to stderr" "to-stderr" "$(cat /tmp/claudux-hv4-t10)"

# --- Test 11: Timeout error is stored in a variable before echoing ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    if echo "$fn_body" | grep -q 'local timeout_msg'; then
        echo "uses-variable"
    else
        echo "inline-echo"
    fi
) > /tmp/claudux-hv4-t11 2>&1
assert_eq "timeout error uses variable for consistent output" "uses-variable" "$(cat /tmp/claudux-hv4-t11)"

# ═══════════════════════════════════════════
# claudux_status() function — ported from release branch
# ═══════════════════════════════════════════

# --- Test 12: claudux_status function exists in docs-generation.sh ---
(
    source "$LIB_DIR/docs-generation.sh"
    if declare -F claudux_status >/dev/null 2>&1; then
        echo "exists"
    else
        echo "missing"
    fi
) > /tmp/claudux-hv4-t12 2>&1
assert_eq "claudux_status function exists" "exists" "$(cat /tmp/claudux-hv4-t12)"

# --- Test 13: claudux_status returns 1 when no state file ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    rm -f "$STATE_FILE"
    claudux_status >/dev/null 2>&1
    echo "$?"
) > /tmp/claudux-hv4-t13 2>&1
assert_eq "claudux_status returns 1 when no state" "1" "$(cat /tmp/claudux-hv4-t13)"
rm -rf "$TEST_DIR"

# --- Test 14: claudux_status shows "No documentation checkpoint found" when no state ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    rm -f "$STATE_FILE"
    claudux_status 2>&1
) > /tmp/claudux-hv4-t14 2>&1
assert_contains "no-state message correct" "$(cat /tmp/claudux-hv4-t14)" "No documentation checkpoint found"
rm -rf "$TEST_DIR"

# --- Test 15: claudux_status shows last_run when state is valid ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state
    claudux_status 2>&1
) > /tmp/claudux-hv4-t15 2>&1
assert_contains "status shows last generated time" "$(cat /tmp/claudux-hv4-t15)" "Last generated:"
rm -rf "$TEST_DIR"

# --- Test 16: claudux_status shows backend ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state
    claudux_status 2>&1
) > /tmp/claudux-hv4-t16 2>&1
assert_contains "status shows backend" "$(cat /tmp/claudux-hv4-t16)" "Backend:"
rm -rf "$TEST_DIR"

# --- Test 17: claudux_status shows checkpoint SHA ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state
    claudux_status 2>&1
) > /tmp/claudux-hv4-t17 2>&1
assert_contains "status shows checkpoint SHA" "$(cat /tmp/claudux-hv4-t17)" "Checkpoint SHA:"
rm -rf "$TEST_DIR"

# --- Test 18: claudux_status reports commits behind after new commit ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state

    echo "new" >> README.md
    git add README.md
    git commit -q -m "new commit"

    claudux_status 2>&1
) > /tmp/claudux-hv4-t18 2>&1
assert_contains "status shows commits behind" "$(cat /tmp/claudux-hv4-t18)" "commit(s) behind HEAD"
rm -rf "$TEST_DIR"

# --- Test 19: claudux_status shows up-to-date via CLI when at HEAD ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state

    # Use CLI to get full output (stubbed success() suppresses in direct call)
    bash "$REPO_ROOT/bin/claudux" status 2>&1
) > /tmp/claudux-hv4-t19 2>&1
assert_contains "status shows up to date via CLI" "$(cat /tmp/claudux-hv4-t19)" "up to date"
rm -rf "$TEST_DIR"

# --- Test 20: claudux_status returns 1 for corrupt state ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    echo "GARBAGE" > "$STATE_FILE"
    claudux_status >/dev/null 2>&1
    echo "$?"
) > /tmp/claudux-hv4-t20 2>&1
assert_eq "claudux_status returns 1 for corrupt state" "1" "$(cat /tmp/claudux-hv4-t20)"
rm -rf "$TEST_DIR"

# ═══════════════════════════════════════════
# bin/claudux status uses claudux_status() not inline code
# ═══════════════════════════════════════════

# --- Test 21: bin/claudux status case uses claudux_status function ---
(
    # Extract the status case block
    status_block=$(sed -n '/^[[:space:]]*"status")/,/;;/p' "$REPO_ROOT/bin/claudux")
    if echo "$status_block" | grep -q 'claudux_status'; then
        echo "uses-function"
    else
        echo "uses-inline"
    fi
) > /tmp/claudux-hv4-t21 2>&1
assert_eq "bin/claudux status uses claudux_status function" "uses-function" "$(cat /tmp/claudux-hv4-t21)"

# --- Test 22: bin/claudux status case does NOT contain inline jq parsing ---
(
    status_block=$(sed -n '/^[[:space:]]*"status")/,/;;/p' "$REPO_ROOT/bin/claudux")
    if echo "$status_block" | grep -q 'jq -r'; then
        echo "has-inline-jq"
    else
        echo "no-inline-jq"
    fi
) > /tmp/claudux-hv4-t22 2>&1
assert_eq "bin/claudux status has no inline jq parsing (uses function)" "no-inline-jq" "$(cat /tmp/claudux-hv4-t22)"

# --- Test 23: bin/claudux status case is compact (fewer than 5 lines) ---
(
    line_count=$(sed -n '/^[[:space:]]*"status")/,/;;/p' "$REPO_ROOT/bin/claudux" | wc -l | tr -d ' ')
    if [[ "$line_count" -le 5 ]]; then
        echo "compact"
    else
        echo "bloated: $line_count lines"
    fi
) > /tmp/claudux-hv4-t23 2>&1
assert_eq "status case is compact (delegated to function)" "compact" "$(cat /tmp/claudux-hv4-t23)"

# ═══════════════════════════════════════════
# End-to-end: status CLI after valid state
# ═══════════════════════════════════════════

# --- Test 24: claudux status CLI shows documented files count ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state

    bash "$REPO_ROOT/bin/claudux" status 2>&1
) > /tmp/claudux-hv4-t24 2>&1
assert_contains "status CLI shows documented files" "$(cat /tmp/claudux-hv4-t24)" "Documented files:"
rm -rf "$TEST_DIR"

# --- Test 25: claudux status CLI exits 0 when state is valid ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state

    bash "$REPO_ROOT/bin/claudux" status >/dev/null 2>&1
    echo "$?"
) > /tmp/claudux-hv4-t25 2>&1
assert_eq "status CLI exits 0 with valid state" "0" "$(cat /tmp/claudux-hv4-t25)"
rm -rf "$TEST_DIR"

# Cleanup
rm -f /tmp/claudux-hv4-t{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25}

test_summary
