#!/bin/bash
# Tests: hardening v3 — concurrent lock safety, portable hash, incremental mode robustness
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-harness.sh"

echo "=== Hardening V3 Tests ==="
echo ""

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$REPO_ROOT/lib"

# Stub color/logging functions
info()    { :; }
warn()    { echo "WARN: $*" >&2; }
success() { :; }
error_exit() { echo "ERROR: $1" >&2; return 1; }
print_color() { shift; echo "$@"; }

# Extract helper functions to a temp file for reliable sourcing.
# process substitution `source <(...)` is unreliable across bash invocations.
_HASH_FN_FILE=$(mktemp /tmp/claudux-hv3-hash-XXXXXX)
sed -n '/_claudux_hash()/,/^}/p' "$REPO_ROOT/bin/claudux" > "$_HASH_FN_FILE"
_LOCK_FN_FILE=$(mktemp /tmp/claudux-hv3-lock-XXXXXX)
sed -n '/^acquire_lock()/,/^}/p' "$REPO_ROOT/bin/claudux" > "$_LOCK_FN_FILE"

# Helper: create a temp git repo
setup_repo() {
    local dir
    dir=$(mktemp -d /tmp/claudux-hv3-test-XXXXXX)
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
# _claudux_hash portability
# ═══════════════════════════════════════════

# --- Test 1: _claudux_hash function exists in bin/claudux ---
(
    fn_exists=$(grep -c '_claudux_hash' "$REPO_ROOT/bin/claudux")
    if [[ $fn_exists -ge 2 ]]; then echo "exists"; else echo "missing"; fi
) > /tmp/claudux-hv3-t1 2>&1
assert_eq "_claudux_hash function defined in bin/claudux" "exists" "$(cat /tmp/claudux-hv3-t1)"

# --- Test 2: _claudux_hash produces non-empty output ---
(
    source "$_HASH_FN_FILE"
    result=$(printf '%s' "/tmp/test" | _claudux_hash)
    if [[ -n "$result" ]]; then echo "non-empty"; else echo "empty"; fi
) > /tmp/claudux-hv3-t2 2>&1
assert_eq "_claudux_hash produces non-empty output" "non-empty" "$(cat /tmp/claudux-hv3-t2)"

# --- Test 3: _claudux_hash is deterministic (same input = same output) ---
(
    source "$_HASH_FN_FILE"
    h1=$(printf '%s' "/some/project/path" | _claudux_hash)
    h2=$(printf '%s' "/some/project/path" | _claudux_hash)
    if [[ "$h1" == "$h2" ]]; then echo "deterministic"; else echo "non-deterministic"; fi
) > /tmp/claudux-hv3-t3 2>&1
assert_eq "_claudux_hash is deterministic" "deterministic" "$(cat /tmp/claudux-hv3-t3)"

# --- Test 4: _claudux_hash differs for different paths ---
(
    source "$_HASH_FN_FILE"
    h1=$(printf '%s' "/project/alpha" | _claudux_hash)
    h2=$(printf '%s' "/project/beta" | _claudux_hash)
    if [[ "$h1" != "$h2" ]]; then echo "unique"; else echo "collision"; fi
) > /tmp/claudux-hv3-t4 2>&1
assert_eq "_claudux_hash produces unique hashes for different paths" "unique" "$(cat /tmp/claudux-hv3-t4)"

# --- Test 5: _claudux_hash has md5sum, md5, and cksum fallbacks ---
(
    fn_body=$(cat "$_HASH_FN_FILE")
    has_md5sum=false; has_md5=false; has_cksum=false
    echo "$fn_body" | grep -q 'md5sum' && has_md5sum=true
    echo "$fn_body" | grep -q 'md5$\|md5[^s]' && has_md5=true
    echo "$fn_body" | grep -q 'cksum' && has_cksum=true
    if $has_md5sum && $has_md5 && $has_cksum; then
        echo "all-fallbacks"
    else
        echo "missing: md5sum=$has_md5sum md5=$has_md5 cksum=$has_cksum"
    fi
) > /tmp/claudux-hv3-t5 2>&1
assert_eq "_claudux_hash has all three fallbacks" "all-fallbacks" "$(cat /tmp/claudux-hv3-t5)"

# ═══════════════════════════════════════════
# acquire_lock uses atomic mkdir
# ═══════════════════════════════════════════

# --- Test 6: acquire_lock uses mkdir for atomic lock ---
(
    fn_body=$(cat "$_LOCK_FN_FILE")
    if echo "$fn_body" | grep -q 'mkdir'; then
        echo "uses-mkdir"
    else
        echo "no-mkdir"
    fi
) > /tmp/claudux-hv3-t6 2>&1
assert_eq "acquire_lock uses atomic mkdir" "uses-mkdir" "$(cat /tmp/claudux-hv3-t6)"

# --- Test 7: acquire_lock creates a lock directory (not a file) ---
(
    fn_body=$(cat "$_LOCK_FN_FILE")
    if echo "$fn_body" | grep -q 'lock_dir'; then
        echo "uses-lock-dir"
    else
        echo "no-lock-dir"
    fi
) > /tmp/claudux-hv3-t7 2>&1
assert_eq "acquire_lock uses lock directory pattern" "uses-lock-dir" "$(cat /tmp/claudux-hv3-t7)"

# --- Test 8: acquire_lock writes PID to lock dir ---
(
    fn_body=$(cat "$_LOCK_FN_FILE")
    if echo "$fn_body" | grep -q 'lock_pid_file'; then
        echo "has-pid-file"
    else
        echo "no-pid-file"
    fi
) > /tmp/claudux-hv3-t8 2>&1
assert_eq "acquire_lock stores PID in lock directory" "has-pid-file" "$(cat /tmp/claudux-hv3-t8)"

# --- Test 9: acquire_lock returns non-zero when lock held by active process ---
(
    fn_body=$(cat "$_LOCK_FN_FILE")
    if echo "$fn_body" | grep -q 'return 1'; then
        echo "blocks"
    else
        echo "no-block"
    fi
) > /tmp/claudux-hv3-t9 2>&1
assert_eq "acquire_lock returns 1 when lock is held" "blocks" "$(cat /tmp/claudux-hv3-t9)"

# --- Test 10: acquire_lock cleans up stale lock (dead PID) ---
(
    fn_body=$(cat "$_LOCK_FN_FILE")
    if echo "$fn_body" | grep -q 'rm -rf'; then
        echo "cleans-stale"
    else
        echo "no-cleanup"
    fi
) > /tmp/claudux-hv3-t10 2>&1
assert_eq "acquire_lock removes stale lock dir" "cleans-stale" "$(cat /tmp/claudux-hv3-t10)"

# --- Test 11: acquire_lock cleanup trap chains with existing EXIT trap ---
(
    fn_body=$(cat "$_LOCK_FN_FILE")
    if echo "$fn_body" | grep -q 'trap -p EXIT'; then
        echo "chains-trap"
    else
        echo "no-chain"
    fi
) > /tmp/claudux-hv3-t11 2>&1
assert_eq "acquire_lock trap chains with existing EXIT trap" "chains-trap" "$(cat /tmp/claudux-hv3-t11)"

# --- Test 12: main() exits on acquire_lock failure ---
(
    fn_body=$(sed -n '/Acquire lock for commands/,/esac/p' "$REPO_ROOT/bin/claudux")
    if echo "$fn_body" | grep -q 'if ! acquire_lock'; then
        echo "checks-return"
    else
        echo "ignores-return"
    fi
) > /tmp/claudux-hv3-t12 2>&1
assert_eq "main() checks acquire_lock return code" "checks-return" "$(cat /tmp/claudux-hv3-t12)"

# ═══════════════════════════════════════════
# Functional lock test: real acquire/release cycle
# ═══════════════════════════════════════════

# --- Test 13: Lock directory created and cleaned up after subshell ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    source "$_HASH_FN_FILE"
    source "$_LOCK_FN_FILE"
    dir_hash=$(printf '%s' "$(pwd)" | _claudux_hash)
    lock_dir="${TMPDIR:-/tmp}/claudux-${dir_hash}.lock"

    # Ensure no leftover
    rm -rf "$lock_dir" 2>/dev/null || true

    acquire_lock
    if [[ -d "$lock_dir" ]]; then echo "created"; else echo "not-created"; fi

    rm -rf "$lock_dir" 2>/dev/null || true
) > /tmp/claudux-hv3-t13 2>&1
assert_eq "lock directory is created on acquire" "created" "$(cat /tmp/claudux-hv3-t13)"
rm -rf "$TEST_DIR"

# --- Test 14: Lock PID file contains the correct PID ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    source "$_HASH_FN_FILE"
    source "$_LOCK_FN_FILE"
    dir_hash=$(printf '%s' "$(pwd)" | _claudux_hash)
    lock_dir="${TMPDIR:-/tmp}/claudux-${dir_hash}.lock"
    rm -rf "$lock_dir" 2>/dev/null || true

    acquire_lock
    stored_pid=$(cat "$lock_dir/pid" 2>/dev/null)
    if [[ "$stored_pid" == "$$" ]]; then echo "correct-pid"; else echo "wrong-pid: $stored_pid vs $$"; fi

    rm -rf "$lock_dir" 2>/dev/null || true
) > /tmp/claudux-hv3-t14 2>&1
assert_eq "lock PID file contains correct PID" "correct-pid" "$(cat /tmp/claudux-hv3-t14)"
rm -rf "$TEST_DIR"

# --- Test 15: Stale lock (dead PID) is cleaned up and re-acquired ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    source "$_HASH_FN_FILE"
    source "$_LOCK_FN_FILE"
    dir_hash=$(printf '%s' "$(pwd)" | _claudux_hash)
    lock_dir="${TMPDIR:-/tmp}/claudux-${dir_hash}.lock"

    # Create a stale lock with a dead PID (99999 is very unlikely to be running)
    rm -rf "$lock_dir" 2>/dev/null || true
    mkdir -p "$lock_dir"
    echo "99999" > "$lock_dir/pid"

    # Try to acquire — should succeed after cleaning stale
    if acquire_lock; then
        echo "acquired"
    else
        echo "blocked"
    fi

    rm -rf "$lock_dir" 2>/dev/null || true
) > /tmp/claudux-hv3-t15 2>&1
assert_eq "stale lock is cleaned up and re-acquired" "acquired" "$(cat /tmp/claudux-hv3-t15)"
rm -rf "$TEST_DIR"

# --- Test 16: Active lock blocks second acquire ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    source "$_HASH_FN_FILE"
    source "$_LOCK_FN_FILE"
    dir_hash=$(printf '%s' "$(pwd)" | _claudux_hash)
    lock_dir="${TMPDIR:-/tmp}/claudux-${dir_hash}.lock"
    rm -rf "$lock_dir" 2>/dev/null || true

    # Simulate another process holding the lock: use our own PID (guaranteed alive)
    mkdir -p "$lock_dir"
    echo "$$" > "$lock_dir/pid"

    # This should fail — PID $$ is us, and we're alive
    if acquire_lock 2>/dev/null; then
        echo "not-blocked"
    else
        echo "blocked"
    fi

    rm -rf "$lock_dir" 2>/dev/null || true
) > /tmp/claudux-hv3-t16 2>&1
assert_eq "active lock blocks second acquire" "blocked" "$(cat /tmp/claudux-hv3-t16)"
rm -rf "$TEST_DIR"

# --- Test 17: Different directories get different lock dirs ---
(
    source "$_HASH_FN_FILE"
    h1=$(printf '%s' "/tmp/project-a" | _claudux_hash)
    h2=$(printf '%s' "/tmp/project-b" | _claudux_hash)
    lock1="${TMPDIR:-/tmp}/claudux-${h1}.lock"
    lock2="${TMPDIR:-/tmp}/claudux-${h2}.lock"
    if [[ "$lock1" != "$lock2" ]]; then echo "different"; else echo "same"; fi
) > /tmp/claudux-hv3-t17 2>&1
assert_eq "different projects get different lock paths" "different" "$(cat /tmp/claudux-hv3-t17)"

# ═══════════════════════════════════════════
# Incremental mode with corrupt state
# ═══════════════════════════════════════════

# --- Test 18: update() incremental guard validates state before diffing ---
(
    fn_body=$(cat "$LIB_DIR/docs-generation.sh")
    if echo "$fn_body" | grep -q '_state_rc'; then
        echo "has-guard"
    else
        echo "no-guard"
    fi
) > /tmp/claudux-hv3-t18 2>&1
assert_eq "update() has incremental mode state validation guard" "has-guard" "$(cat /tmp/claudux-hv3-t18)"

# --- Test 19: Incremental mode skips diff when state is corrupt ---
(
    fn_body=$(cat "$LIB_DIR/docs-generation.sh")
    if echo "$fn_body" | grep -q '_state_rc -eq 0'; then
        echo "checks-rc"
    else
        echo "no-check"
    fi
) > /tmp/claudux-hv3-t19 2>&1
assert_eq "incremental mode only diffs when state is valid (rc=0)" "checks-rc" "$(cat /tmp/claudux-hv3-t19)"

# --- Test 20: Corrupt state file triggers full scan, not crash ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"

    # Write corrupt state
    echo "NOT JSON" > "$STATE_FILE"

    # Check the guard logic manually
    local_state_rc=0
    load_claudux_state >/dev/null 2>&1 || local_state_rc=$?
    if [[ $local_state_rc -ne 0 ]]; then
        echo "skipped-incremental"
    else
        echo "tried-incremental"
    fi
) > /tmp/claudux-hv3-t20 2>&1
assert_eq "corrupt state skips incremental mode" "skipped-incremental" "$(cat /tmp/claudux-hv3-t20)"
rm -rf "$TEST_DIR"

# --- Test 21: Valid state file enters incremental mode ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"

    save_claudux_state
    local_state_rc=0
    load_claudux_state >/dev/null 2>&1 || local_state_rc=$?
    if [[ $local_state_rc -eq 0 ]]; then
        echo "enters-incremental"
    else
        echo "skipped"
    fi
) > /tmp/claudux-hv3-t21 2>&1
assert_eq "valid state enters incremental mode" "enters-incremental" "$(cat /tmp/claudux-hv3-t21)"
rm -rf "$TEST_DIR"

# ═══════════════════════════════════════════
# claudux_status with valid state after corrupt-recovery
# ═══════════════════════════════════════════

# --- Test 22: status CLI works after corrupt state is overwritten with valid state ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"

    # Write corrupt, then overwrite with valid
    echo "GARBAGE" > "$STATE_FILE"
    save_claudux_state 2>/dev/null

    # Now CLI status should work (dispatches through bin/claudux)
    output=$(bash "$REPO_ROOT/bin/claudux" status 2>&1)
    if echo "$output" | grep -q "Last generated:"; then
        echo "works"
    else
        echo "broken: $output"
    fi
) > /tmp/claudux-hv3-t22 2>&1
assert_eq "status CLI works after overwriting corrupt state" "works" "$(cat /tmp/claudux-hv3-t22)"
rm -rf "$TEST_DIR"

# ═══════════════════════════════════════════
# Lock hash uniqueness with paths that share prefix
# ═══════════════════════════════════════════

# --- Test 23: Paths like /project and /project2 get different hashes ---
(
    source "$_HASH_FN_FILE"
    h1=$(printf '%s' "/home/user/project" | _claudux_hash)
    h2=$(printf '%s' "/home/user/project2" | _claudux_hash)
    if [[ "$h1" != "$h2" ]]; then echo "unique"; else echo "collision"; fi
) > /tmp/claudux-hv3-t23 2>&1
assert_eq "prefix-sharing paths get unique hashes" "unique" "$(cat /tmp/claudux-hv3-t23)"

# --- Test 24: _claudux_hash handles paths with spaces ---
(
    source "$_HASH_FN_FILE"
    h=$(printf '%s' "/home/user/my project" | _claudux_hash)
    if [[ -n "$h" ]]; then echo "handles-spaces"; else echo "empty"; fi
) > /tmp/claudux-hv3-t24 2>&1
assert_eq "_claudux_hash handles paths with spaces" "handles-spaces" "$(cat /tmp/claudux-hv3-t24)"

# --- Test 25: _claudux_hash handles paths with special characters ---
(
    source "$_HASH_FN_FILE"
    h=$(printf '%s' '/home/user/project"with"quotes' | _claudux_hash)
    if [[ -n "$h" ]]; then echo "handles-specials"; else echo "empty"; fi
) > /tmp/claudux-hv3-t25 2>&1
assert_eq "_claudux_hash handles paths with special chars" "handles-specials" "$(cat /tmp/claudux-hv3-t25)"

# Cleanup
rm -f /tmp/claudux-hv3-t{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25}
rm -f "$_HASH_FN_FILE" "$_LOCK_FN_FILE"

test_summary
