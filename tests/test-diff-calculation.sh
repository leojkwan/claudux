#!/bin/bash
# Tests: claudux_diff_since_last — diff calculation against checkpoint SHA
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-harness.sh"

echo "=== Diff Calculation Tests ==="
echo ""

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$REPO_ROOT/lib"

# Stub color/logging functions
info()    { :; }
warn()    { :; }
success() { :; }
error_exit() { echo "ERROR: $1" >&2; return 1; }
print_color() { :; }

# Helper: create a temp git repo with a docs/ directory
setup_repo() {
    local dir
    dir=$(mktemp -d /tmp/claudux-diff-test-XXXXXX)
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

# --- Test 1: No state file — returns error message ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    # Ensure no state file exists
    rm -f "$STATE_FILE"
    output=$(claudux_diff_since_last 2>&1)
    ec=$?
    echo "$ec|$output"
) > /tmp/claudux-diff-t1 2>&1
result=$(cat /tmp/claudux-diff-t1)
assert_contains "no state returns error" "$result" "No previous checkpoint"
assert_contains "no state exits non-zero" "$result" "1|"
rm -rf "$TEST_DIR"

# --- Test 2: No changes since checkpoint — empty diff ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state
    output=$(claudux_diff_since_last 2>&1)
    if [[ -z "$output" ]]; then echo "empty"; else echo "has-output: $output"; fi
) > /tmp/claudux-diff-t2 2>&1
assert_eq "no changes gives empty diff" "empty" "$(cat /tmp/claudux-diff-t2)"
rm -rf "$TEST_DIR"

# --- Test 3: One file changed — shows that file ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state

    echo "modified" >> README.md
    git add README.md
    git commit -q -m "modify readme"

    claudux_diff_since_last 2>&1
) > /tmp/claudux-diff-t3 2>&1
assert_contains "changed file appears in diff" "$(cat /tmp/claudux-diff-t3)" "README.md"
rm -rf "$TEST_DIR"

# --- Test 4: New file added — shows new file ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state

    echo "new content" > newfile.txt
    git add newfile.txt
    git commit -q -m "add newfile"

    claudux_diff_since_last 2>&1
) > /tmp/claudux-diff-t4 2>&1
assert_contains "new file appears in diff" "$(cat /tmp/claudux-diff-t4)" "newfile.txt"
rm -rf "$TEST_DIR"

# --- Test 5: Multiple files changed — all appear ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state

    echo "a" > file-a.txt
    echo "b" > file-b.txt
    echo "c" > file-c.txt
    git add file-a.txt file-b.txt file-c.txt
    git commit -q -m "add three files"

    claudux_diff_since_last 2>&1
) > /tmp/claudux-diff-t5 2>&1
diff_output=$(cat /tmp/claudux-diff-t5)
assert_contains "file-a in diff" "$diff_output" "file-a.txt"
assert_contains "file-b in diff" "$diff_output" "file-b.txt"
assert_contains "file-c in diff" "$diff_output" "file-c.txt"
rm -rf "$TEST_DIR"

# --- Test 6: Unknown SHA (simulated rebase) — error message ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"

    cat > "$STATE_FILE" <<'EOF'
{
  "last_sha": "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
  "last_run": "2026-01-01T00:00:00Z",
  "backend": "claude",
  "files_documented": []
}
EOF

    output=$(claudux_diff_since_last 2>&1)
    ec=$?
    echo "$ec|$output"
) > /tmp/claudux-diff-t6 2>&1
result=$(cat /tmp/claudux-diff-t6)
assert_contains "bogus SHA returns error" "$result" "no longer in history"
assert_contains "bogus SHA exits non-zero" "$result" "1|"
rm -rf "$TEST_DIR"

# --- Test 7: SHA is "unknown" — error message ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"

    cat > "$STATE_FILE" <<'EOF'
{
  "last_sha": "unknown",
  "last_run": "2026-01-01T00:00:00Z",
  "backend": "claude",
  "files_documented": []
}
EOF

    output=$(claudux_diff_since_last 2>&1)
    ec=$?
    echo "$ec|$output"
) > /tmp/claudux-diff-t7 2>&1
result=$(cat /tmp/claudux-diff-t7)
assert_contains "unknown SHA returns error" "$result" "unknown"
assert_contains "unknown SHA exits non-zero" "$result" "1|"
rm -rf "$TEST_DIR"

# --- Test 8: Multiple commits since checkpoint — all changes shown ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state

    # Commit 1
    echo "x" > first.txt
    git add first.txt
    git commit -q -m "commit one"

    # Commit 2
    echo "y" > second.txt
    git add second.txt
    git commit -q -m "commit two"

    claudux_diff_since_last 2>&1
) > /tmp/claudux-diff-t8 2>&1
diff_output=$(cat /tmp/claudux-diff-t8)
assert_contains "first.txt across commits" "$diff_output" "first.txt"
assert_contains "second.txt across commits" "$diff_output" "second.txt"
rm -rf "$TEST_DIR"

# --- Test 9: Diff works with jq fallback (grep/sed path) ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state

    # Parse SHA using the same grep/sed as the fallback code
    state=$(cat "$STATE_FILE")
    parsed_sha=$(echo "$state" | grep '"last_sha"' | sed 's/.*: *"\([^"]*\)".*/\1/')
    actual_head=$(git rev-parse HEAD)
    if [[ "$parsed_sha" == "$actual_head" ]]; then
        echo "match"
    else
        echo "mismatch: parsed=$parsed_sha head=$actual_head"
    fi
) > /tmp/claudux-diff-t9 2>&1
assert_eq "grep/sed SHA parsing works" "match" "$(cat /tmp/claudux-diff-t9)"
rm -rf "$TEST_DIR"

# Cleanup
rm -f /tmp/claudux-diff-t{1,2,3,4,5,6,7,8,9}

test_summary
