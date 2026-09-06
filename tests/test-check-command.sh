#!/bin/bash
# Tests: `claudux check` exit code — a check that cannot fail is decoration.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-harness.sh"

echo "=== Check Command Exit Code Tests ==="
echo ""

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/claudux-check-test.XXXXXX") || exit 1
trap 'rm -rf "$TEST_TMP_ROOT"' EXIT

# Build a stub PATH so the result never depends on what this machine has
# installed. Stubs cover every external the check path touches; the failure
# case simply omits the backend CLI stub.
STUB_DIR="$TEST_TMP_ROOT/stubs"
mkdir -p "$STUB_DIR"

make_stub() {
    printf '#!/bin/sh\necho "%s"\n' "$2" > "$STUB_DIR/$1"
    chmod +x "$STUB_DIR/$1"
}

make_stub node "v20.0.0"

# ── All dependencies present → exit 0 ────────────────────────────────
cat > "$STUB_DIR/claude" <<'EOF'
#!/bin/sh
case "${1:-}" in
    --version)
        echo "1.0.0 (stub)"
        ;;
    auth)
        if [ "${2:-}" = "status" ] && [ "${CLAUDE_STUB_AUTH:-authenticated}" = "authenticated" ]; then
            exit 0
        fi
        exit 1
        ;;
    config)
        echo "sonnet"
        ;;
esac
EOF
chmod +x "$STUB_DIR/claude"
output=$(cd "$STUB_DIR" && PATH="$STUB_DIR:/usr/bin:/bin" bash "$REPO_ROOT/bin/claudux" check 2>&1)
rc=$?
assert_exit_code "check passes with node + claude present" 0 "$rc"
assert_contains "check reports success" "$output" "Environment check passed"

# ── Reported model follows the generation resolution chain ───────────
# FORCE_MODEL > claudux.json project.model > sonnet. A diagnostic that
# reports a model generation will not use is worse than no diagnostic.
printf '{\n  "project": {\n    "name": "stub",\n    "type": "javascript",\n    "model": "fable"\n  }\n}\n' > "$STUB_DIR/claudux.json"
output=$(cd "$STUB_DIR" && PATH="$STUB_DIR:/usr/bin:/bin" bash "$REPO_ROOT/bin/claudux" check 2>&1)
assert_contains "check reports configured project.model" "$output" "Model: fable"

output=$(cd "$STUB_DIR" && PATH="$STUB_DIR:/usr/bin:/bin" FORCE_MODEL=opus bash "$REPO_ROOT/bin/claudux" check 2>&1)
assert_contains "FORCE_MODEL overrides configured model" "$output" "Model: opus"

rm -f "$STUB_DIR/claudux.json"
output=$(cd "$STUB_DIR" && PATH="$STUB_DIR:/usr/bin:/bin" bash "$REPO_ROOT/bin/claudux" check 2>&1)
assert_contains "check falls back to sonnet with no config" "$output" "Model: sonnet"

# ── Run from a subdirectory → reports the project root's state ───────
# `check` skips the "must be a git repo" gate so it answers from anywhere,
# but inside a repo it must still answer for the project root: run from
# docs/ it used to report "docs/: not present" and detect the wrong type.
SUBDIR_REPO="$TEST_TMP_ROOT/subdir-repo"
mkdir -p "$SUBDIR_REPO/docs/guide"
(
    cd "$SUBDIR_REPO" || exit 1
    git init -q
    printf '{"name":"root-package"}\n' > package.json
)
output=$(cd "$SUBDIR_REPO/docs/guide" && PATH="$STUB_DIR:/usr/bin:/bin" bash "$REPO_ROOT/bin/claudux" check 2>&1)
rc=$?
assert_exit_code "check from a subdirectory passes" 0 "$rc"
assert_contains "check from a subdirectory reports the root docs/ dir" "$output" "docs/: present"
assert_contains "check from a subdirectory detects the root project type" "$output" "Detected project type: javascript"

# ── Backend CLI unauthenticated → exit 1 ─────────────────────────────
output=$(cd "$STUB_DIR" && PATH="$STUB_DIR:/usr/bin:/bin" CLAUDE_STUB_AUTH=unauthenticated bash "$REPO_ROOT/bin/claudux" check 2>&1)
rc=$?
assert_exit_code "check fails when Claude CLI is unauthenticated" 1 "$rc"
assert_contains "check names the authentication failure" "$output" "Claude CLI is not authenticated"
assert_contains "unauthenticated check reports failure" "$output" "Environment check failed"

# ── Backend CLI missing → exit 1 ─────────────────────────────────────
# /usr/bin:/bin stay on PATH for coreutils; no platform installs the
# Claude CLI there, so removing the stub removes the backend.
rm -f "$STUB_DIR/claude"
output=$(cd "$STUB_DIR" && PATH="$STUB_DIR:/usr/bin:/bin" bash "$REPO_ROOT/bin/claudux" check 2>&1)
rc=$?
assert_exit_code "check fails when backend CLI is missing" 1 "$rc"
assert_contains "check names the missing dependency" "$output" "Claude CLI not found"
assert_contains "check reports failure" "$output" "Environment check failed"

test_summary
