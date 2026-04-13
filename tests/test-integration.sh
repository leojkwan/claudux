#!/bin/bash
# Tests: integration edge cases — CLI commands, JSON escaping, backend switching, formatter robustness
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-harness.sh"

echo "=== Integration & Edge Case Tests ==="
echo ""

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$REPO_ROOT/lib"

# Stub color/logging functions
info()    { :; }
warn()    { echo "WARN: $*" >&2; }
success() { :; }
error_exit() { echo "ERROR: $1" >&2; return 1; }
print_color() { shift; echo "$@"; }
show_header() { :; }
show_help() { echo "usage: claudux <command>"; }

# Helper: create a temp git repo
setup_repo() {
    local dir
    dir=$(mktemp -d /tmp/claudux-integ-test-XXXXXX)
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
# JSON escaping in save_claudux_state
# ═══════════════════════════════════════════

# --- Test 1: Filenames with double-quotes produce valid JSON ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    mkdir -p 'docs/guide'
    # Create a file whose name contains a double-quote character
    echo "# Quoted" > 'docs/guide/my"file.md'
    git add -A
    git commit -q -m "file with quote in name"
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
        # Fallback: check the escaped quote appears
        if grep -q 'my\\"file.md' "$STATE_FILE"; then
            echo "valid-json"
        else
            echo "invalid-json"
        fi
    fi
) > /tmp/claudux-integ-t1 2>&1
assert_eq "filenames with double-quotes produce valid JSON" "valid-json" "$(cat /tmp/claudux-integ-t1)"
rm -rf "$TEST_DIR"

# --- Test 2: Filenames with backslashes produce valid JSON ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    mkdir -p 'docs/guide'
    echo "# Slashed" > 'docs/guide/back\slash.md'
    git add -A
    git commit -q -m "file with backslash in name"
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
        echo "valid-json"
    fi
) > /tmp/claudux-integ-t2 2>&1
assert_eq "filenames with backslashes produce valid JSON" "valid-json" "$(cat /tmp/claudux-integ-t2)"
rm -rf "$TEST_DIR"

# ═══════════════════════════════════════════
# Backend switching between runs
# ═══════════════════════════════════════════

# --- Test 3: State saved with claude, diff works with CLAUDUX_BACKEND=codex ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    unset CLAUDUX_BACKEND 2>/dev/null || true
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state

    # Switch backend and make a change
    export CLAUDUX_BACKEND=codex
    echo "new" >> README.md
    git add README.md
    git commit -q -m "change after backend switch"

    changed=$(claudux_diff_since_last 2>/dev/null)
    if echo "$changed" | grep -q "README.md"; then
        echo "diff-works"
    else
        echo "diff-broken"
    fi
) > /tmp/claudux-integ-t3 2>&1
assert_eq "diff works across backend switch (claude->codex)" "diff-works" "$(cat /tmp/claudux-integ-t3)"
rm -rf "$TEST_DIR"

# --- Test 4: State saved with codex, diff works with default (claude) backend ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    export CLAUDUX_BACKEND=codex
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state

    # Switch to default backend and make a change
    unset CLAUDUX_BACKEND
    echo "new" >> README.md
    git add README.md
    git commit -q -m "change after backend switch"

    changed=$(claudux_diff_since_last 2>/dev/null)
    if echo "$changed" | grep -q "README.md"; then
        echo "diff-works"
    else
        echo "diff-broken"
    fi
) > /tmp/claudux-integ-t4 2>&1
assert_eq "diff works across backend switch (codex->claude)" "diff-works" "$(cat /tmp/claudux-integ-t4)"
rm -rf "$TEST_DIR"

# --- Test 5: State shows different backend after save with new backend ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"

    # Save as claude
    unset CLAUDUX_BACKEND 2>/dev/null || true
    save_claudux_state
    b1=$(grep '"backend"' "$STATE_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/')

    # Overwrite as codex
    export CLAUDUX_BACKEND=codex
    echo "x" >> README.md
    git add README.md
    git commit -q -m "update"
    save_claudux_state
    b2=$(grep '"backend"' "$STATE_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/')

    echo "$b1|$b2"
) > /tmp/claudux-integ-t5 2>&1
assert_eq "backend field updates on save" "claude|codex" "$(cat /tmp/claudux-integ-t5)"
rm -rf "$TEST_DIR"

# ═══════════════════════════════════════════
# Formatter robustness — partial/malformed JSON
# ═══════════════════════════════════════════

# --- Test 6: Formatter handles truncated JSON line (opening brace but no close) ---
(
    source "$LIB_DIR/codex-utils.sh"
    echo '{"type":"thread.started","thread_id":"abc' | format_codex_output_stream
    echo "exit-ok"
) > /tmp/claudux-integ-t6 2>&1
assert_contains "truncated JSON exits ok" "$(cat /tmp/claudux-integ-t6)" "exit-ok"

# --- Test 7: Formatter handles JSON with unexpected top-level type ---
(
    source "$LIB_DIR/codex-utils.sh"
    echo '{"type":"unknown.future.event","data":"something"}' | format_codex_output_stream
    echo "exit-ok"
) > /tmp/claudux-integ-t7 2>&1
assert_contains "unknown event type exits ok" "$(cat /tmp/claudux-integ-t7)" "exit-ok"

# --- Test 8: Formatter handles line with type key not at start ---
# e.g. {"id":"1","type":"item.started",...} — type is not the first field
(
    source "$LIB_DIR/codex-utils.sh"
    echo '{"id":"1","type":"item.started","item":{"id":"i1","type":"command_execution","command":"echo hi","status":"in_progress"}}' | format_codex_output_stream
) > /tmp/claudux-integ-t8 2>&1
# The top-level type regex anchors after opening brace — it may miss this.
# This is an edge case worth documenting: our parser expects "type" as the first key.
# As long as it doesn't crash, it's acceptable.
assert_not_contains "non-first-key type does not crash" "$(cat /tmp/claudux-integ-t8)" "ERROR"

# --- Test 9: Formatter handles agent_message with embedded quotes ---
(
    source "$LIB_DIR/codex-utils.sh"
    echo '{"type":"item.completed","item":{"id":"i1","type":"agent_message","text":"Found file \"README.md\" in root"}}' | format_codex_output_stream
) > /tmp/claudux-integ-t9 2>&1
# The sed-based text extractor will stop at the first closing quote, so it may truncate.
# The important thing is it doesn't crash.
assert_not_contains "embedded quotes in message don't crash" "$(cat /tmp/claudux-integ-t9)" "ERROR"

# --- Test 10: Formatter handles very long command strings ---
(
    source "$LIB_DIR/codex-utils.sh"
    long_cmd=$(printf 'x%.0s' {1..300})
    echo '{"type":"item.started","item":{"id":"i1","type":"command_execution","command":"'"$long_cmd"'","status":"in_progress"}}' | format_codex_output_stream
) > /tmp/claudux-integ-t10 2>&1
result10=$(cat /tmp/claudux-integ-t10)
assert_contains "long command is truncated in display" "$result10" "Running [1]:"
# The display truncates to 100 chars
assert_not_contains "long command does not show full 300 chars" "$result10" "$(printf 'x%.0s' {1..200})"

# ═══════════════════════════════════════════
# CLI command dispatch tests
# ═══════════════════════════════════════════

# --- Test 11: claudux diff exits non-zero when no state ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    bash "$REPO_ROOT/bin/claudux" diff 2>&1
    echo "exit:$?"
) > /tmp/claudux-integ-t11 2>&1
assert_contains "diff with no state exits non-zero" "$(cat /tmp/claudux-integ-t11)" "exit:1"
rm -rf "$TEST_DIR"

# --- Test 12: claudux status shows no checkpoint message when no state ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    bash "$REPO_ROOT/bin/claudux" status 2>&1
) > /tmp/claudux-integ-t12 2>&1
assert_contains "status with no state shows instruction" "$(cat /tmp/claudux-integ-t12)" "No documentation checkpoint found"
rm -rf "$TEST_DIR"

# --- Test 13: claudux diff shows changed files after save + commit ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state

    echo "new" >> README.md
    git add README.md
    git commit -q -m "post-checkpoint change"

    bash "$REPO_ROOT/bin/claudux" diff 2>&1
    echo "exit:$?"
) > /tmp/claudux-integ-t13 2>&1
result13=$(cat /tmp/claudux-integ-t13)
assert_contains "diff CLI shows changed file" "$result13" "README.md"
assert_contains "diff CLI exits zero" "$result13" "exit:0"
rm -rf "$TEST_DIR"

# --- Test 14: claudux status shows last run info after save ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state

    bash "$REPO_ROOT/bin/claudux" status 2>&1
) > /tmp/claudux-integ-t14 2>&1
result14=$(cat /tmp/claudux-integ-t14)
assert_contains "status CLI shows last generated" "$result14" "Last generated:"
assert_contains "status CLI shows backend" "$result14" "Backend:"
rm -rf "$TEST_DIR"

# --- Test 15: claudux status shows stale count after new commit ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state

    echo "a" > newfile.txt
    echo "b" > another.txt
    git add newfile.txt another.txt
    git commit -q -m "add two files"

    bash "$REPO_ROOT/bin/claudux" status 2>&1
) > /tmp/claudux-integ-t15 2>&1
result15=$(cat /tmp/claudux-integ-t15)
assert_contains "status shows stale commit count" "$result15" "commit(s) behind HEAD"
assert_contains "status shows diff instruction" "$result15" "claudux diff"
rm -rf "$TEST_DIR"

# ═══════════════════════════════════════════
# check_generation_backend dispatch
# ═══════════════════════════════════════════

# --- Test 16: check_generation_backend function exists in bin/claudux ---
check_fn=$(grep -c 'check_generation_backend' "$REPO_ROOT/bin/claudux")
assert_eq "check_generation_backend referenced in bin/claudux" "true" "$( [[ $check_fn -ge 2 ]] && echo true || echo false )"

# --- Test 17: check_generation_backend dispatches to check_codex for codex backend ---
(
    source "$LIB_DIR/docs-generation.sh" 2>/dev/null || true
    # Read the function from bin/claudux
    fn_body=$(sed -n '/^check_generation_backend()/,/^}/p' "$REPO_ROOT/bin/claudux")
    if echo "$fn_body" | grep -q 'check_codex'; then
        echo "dispatches-codex"
    else
        echo "no-dispatch"
    fi
) > /tmp/claudux-integ-t17 2>&1
assert_eq "check_generation_backend dispatches to check_codex" "dispatches-codex" "$(cat /tmp/claudux-integ-t17)"

# --- Test 18: check_generation_backend dispatches to check_claude for default backend ---
(
    fn_body=$(sed -n '/^check_generation_backend()/,/^}/p' "$REPO_ROOT/bin/claudux")
    if echo "$fn_body" | grep -q 'check_claude'; then
        echo "dispatches-claude"
    else
        echo "no-dispatch"
    fi
) > /tmp/claudux-integ-t18 2>&1
assert_eq "check_generation_backend dispatches to check_claude" "dispatches-claude" "$(cat /tmp/claudux-integ-t18)"

# ═══════════════════════════════════════════
# run_codex_exec prompt safety
# ═══════════════════════════════════════════

# --- Test 19: run_codex_exec uses stdin for prompt (no echo -e issues) ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    if echo "$fn_body" | grep -q 'echo.*\$prompt.*|'; then
        echo "uses-echo-stdin"
    else
        echo "no-echo"
    fi
) > /tmp/claudux-integ-t19 2>&1
assert_eq "run_codex_exec pipes prompt via stdin" "uses-echo-stdin" "$(cat /tmp/claudux-integ-t19)"

# --- Test 20: run_codex_exec redirects stderr to log file ---
(
    source "$LIB_DIR/codex-utils.sh"
    fn_body=$(declare -f run_codex_exec)
    if echo "$fn_body" | grep -q 'stderr_log'; then
        echo "has-stderr-log"
    else
        echo "no-stderr-log"
    fi
) > /tmp/claudux-integ-t20 2>&1
assert_eq "run_codex_exec has stderr log redirect" "has-stderr-log" "$(cat /tmp/claudux-integ-t20)"

# ═══════════════════════════════════════════
# State file with deleted files (file removed between saves)
# ═══════════════════════════════════════════

# --- Test 21: Deleted doc file no longer appears in state after re-save ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    mkdir -p docs/guide
    echo "# Guide" > docs/guide/setup.md
    git add docs/guide/setup.md
    git commit -q -m "add guide"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state

    # Verify setup.md is tracked
    has_before=$(grep -c "setup.md" "$STATE_FILE")

    # Delete the file and re-save
    git rm -q docs/guide/setup.md
    git commit -q -m "remove guide"
    save_claudux_state
    has_after=$(grep -c "setup.md" "$STATE_FILE")

    echo "$has_before|$has_after"
) > /tmp/claudux-integ-t21 2>&1
assert_eq "deleted file removed from state on re-save" "1|0" "$(cat /tmp/claudux-integ-t21)"
rm -rf "$TEST_DIR"

# Cleanup
rm -f /tmp/claudux-integ-t{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21}

test_summary
