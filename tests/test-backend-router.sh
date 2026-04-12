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

# Cleanup
rm -f /tmp/claudux-test-backend-default /tmp/claudux-test-backend-codex /tmp/claudux-test-missing

test_summary
