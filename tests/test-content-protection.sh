#!/bin/bash
# Tests: language-aware content protection markers
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-harness.sh"

echo "=== Content Protection Tests ==="
echo ""

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$REPO_ROOT/lib/content-protection.sh"

TEST_TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/claudux-content-protection-test.XXXXXX") || exit 1
trap 'rm -rf "$TEST_TMP_ROOT"' EXIT
TEST_DIR="$TEST_TMP_ROOT/content"
mkdir -p "$TEST_DIR"

MARKERS=$(get_protection_markers "$TEST_DIR/example.md")
assert_eq "markdown markers preserve spaces" $'<!-- skip -->\n<!-- /skip -->' "$MARKERS"

MARKERS=$(get_protection_markers "$TEST_DIR/example.ts")
assert_eq "typescript markers preserve spaces" $'// skip\n// /skip' "$MARKERS"

MARKERS=$(get_protection_markers "$TEST_DIR/example.css")
assert_eq "css markers preserve regex-looking text" $'/* skip */\n/* /skip */' "$MARKERS"

test_summary
