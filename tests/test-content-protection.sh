#!/bin/bash
# Tests: language-aware content protection markers
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-harness.sh"

echo "=== Content Protection Tests ==="
echo ""

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$REPO_ROOT/lib/content-protection.sh"

TEST_DIR=$(mktemp -d /tmp/claudux-content-protection-XXXXXX)

MARKERS=$(get_protection_markers "$TEST_DIR/example.md")
assert_eq "markdown markers preserve spaces" $'<!-- skip -->\n<!-- /skip -->' "$MARKERS"

MARKERS=$(get_protection_markers "$TEST_DIR/example.ts")
assert_eq "typescript markers preserve spaces" $'// skip\n// /skip' "$MARKERS"

MARKERS=$(get_protection_markers "$TEST_DIR/example.css")
assert_eq "css markers preserve regex-looking text" $'/* skip */\n/* /skip */' "$MARKERS"

cat > "$TEST_DIR/example.md" <<'EOF'
# Public Notes

Keep this.

<!-- skip -->
Private doctrine.
<!-- /skip -->

Keep this too.
EOF

STRIPPED=$(strip_protected_content "$TEST_DIR/example.md")
STRIPPED_CONTENT=$(cat "$STRIPPED")
assert_contains "markdown strip keeps public content" "$STRIPPED_CONTENT" "Keep this."
assert_contains "markdown strip keeps later public content" "$STRIPPED_CONTENT" "Keep this too."
assert_not_contains "markdown strip removes protected body" "$STRIPPED_CONTENT" "Private doctrine."
rm -f "$STRIPPED"

cat > "$TEST_DIR/example.css" <<'EOF'
.button { color: red; }

/* skip */
.secret { token: "do-not-document"; }
/* /skip */

.card { color: blue; }
EOF

STRIPPED=$(strip_protected_content "$TEST_DIR/example.css")
STRIPPED_CONTENT=$(cat "$STRIPPED")
assert_contains "css strip keeps public content" "$STRIPPED_CONTENT" ".button"
assert_contains "css strip keeps later public content" "$STRIPPED_CONTENT" ".card"
assert_not_contains "css strip treats markers literally" "$STRIPPED_CONTENT" "do-not-document"
rm -f "$STRIPPED"

cat > "$TEST_DIR/example.ts" <<'EOF'
export const publicValue = 1;

  // skip
const secret = "do-not-document";
  // /skip

export const laterValue = 2;
EOF

STRIPPED=$(strip_protected_content "$TEST_DIR/example.ts")
STRIPPED_CONTENT=$(cat "$STRIPPED")
assert_contains "indented slash markers strip protected body" "$STRIPPED_CONTENT" "publicValue"
assert_contains "indented slash markers keep later body" "$STRIPPED_CONTENT" "laterValue"
assert_not_contains "indented slash markers remove protected body" "$STRIPPED_CONTENT" "do-not-document"
rm -f "$STRIPPED"

rm -rf "$TEST_DIR"

test_summary
