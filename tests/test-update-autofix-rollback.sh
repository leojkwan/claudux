#!/bin/bash
# Tests: the link auto-fix second pass keeps the backend failure path and the
# source-boundary rollback. A stray `set -e` after link validation used to
# turn a failing second pass into a silent exit with source edits left behind.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-harness.sh"

echo "=== Update Auto-fix Rollback Tests ==="
echo ""

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/claudux-autofix-test.XXXXXX") || exit 1
trap 'rm -rf "$TEST_TMP_ROOT"' EXIT

if ! command -v node >/dev/null 2>&1; then
    echo "  SKIP node is required for this test"
    exit 0
fi

STUB_DIR="$TEST_TMP_ROOT/stubs"
mkdir -p "$STUB_DIR" "$TEST_TMP_ROOT/home"

# Stub backend. Pass 1 writes a config.ts whose only link has no page, so
# the link validator fails and update re-runs itself once. Pass 2 edits a
# source file and exits 3 — the case the boundary rollback exists for.
cat > "$STUB_DIR/claude" <<'STUB'
#!/bin/bash
case "${1:-}" in
    --version) echo "1.0.0 (stub)"; exit 0 ;;
    auth) exit 0 ;;
    --help) echo "usage: claude"; exit 0 ;;
esac
count_file="$CLAUDE_STUB_STATE/calls"
n=$(cat "$count_file" 2>/dev/null || echo 0)
n=$((n + 1))
echo "$n" > "$count_file"
if [[ $n -eq 1 ]]; then
    mkdir -p docs/.vitepress
    printf '# Home\n' > docs/index.md
    printf "export default { themeConfig: { sidebar: [{ text: 'Missing', link: '/guide/missing' }] } }\n" > docs/.vitepress/config.ts
    echo "Writing docs/index.md"
    exit 0
fi
printf 'export const value = 2;\n' > src/app.js
echo "second pass: backend edited source and failed"
exit 3
STUB
chmod +x "$STUB_DIR/claude"

PROJECT="$TEST_TMP_ROOT/project"
mkdir -p "$PROJECT/src"
(
    cd "$PROJECT" || exit 1
    git init -q
    git config user.email test@example.com
    git config user.name "Claudux Test"
    printf 'export const value = 1;\n' > src/app.js
    git add .
    git commit -q -m baseline
)

rc=0
(
    cd "$PROJECT" || exit 1
    PATH="$STUB_DIR:$PATH" \
    HOME="$TEST_TMP_ROOT/home" \
    XDG_STATE_HOME="$TEST_TMP_ROOT/home/state" \
    CLAUDE_STUB_STATE="$TEST_TMP_ROOT" \
    bash "$REPO_ROOT/bin/claudux" update
) > "$TEST_TMP_ROOT/update-output" 2>&1 || rc=$?
OUTPUT=$(sed 's/\x1b\[[0-9;]*m//g' "$TEST_TMP_ROOT/update-output")

assert_eq "backend ran twice (auto-fix pass happened)" "2" "$(cat "$TEST_TMP_ROOT/calls")"
# The boundary violation is the reported failure (exit 1); the backend code
# is still named in the output.
assert_eq "update exits nonzero" "1" "$rc"
assert_contains "second-pass backend failure is reported" "$OUTPUT" "exited with code: 3"
assert_contains "second-pass source mutation is rolled back" "$OUTPUT" "Rolled back unrelated source changes"
assert_eq "source file is restored" "export const value = 1;" "$(cat "$PROJECT/src/app.js")"

test_summary
