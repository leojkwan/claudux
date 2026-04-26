#!/bin/bash
# Tests: .claudux-state.json write/read cycle
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-harness.sh"

echo "=== State File Write/Read Tests ==="
echo ""

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$REPO_ROOT/lib"

# Stub color/logging functions so docs-generation.sh can be sourced
info()    { :; }
warn()    { :; }
success() { :; }
error_exit() { echo "ERROR: $1" >&2; return 1; }
print_color() { :; }

# Helper: create a temp git repo with a docs/ directory so save_claudux_state
# produces valid JSON (the files_json pipeline needs tracked files under docs/).
setup_repo() {
    local dir
    dir=$(mktemp -d /tmp/claudux-state-test-XXXXXX)
    (
        cd "$dir"
        git init -q
        git config user.email "test@test.com"
        git config user.name "Test"
        echo "hello" > README.md
        mkdir -p docs
        echo "# Index" > docs/index.md
        git add README.md docs/index.md
        git commit -q -m "initial"
    )
    echo "$dir"
}

# --- Test 1: save_claudux_state creates the state file ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    save_claudux_state
    if [[ -f "$STATE_FILE" ]]; then echo "exists"; else echo "missing"; fi
) > /tmp/claudux-state-t1 2>&1
assert_eq "save_claudux_state creates file" "exists" "$(cat /tmp/claudux-state-t1)"
rm -rf "$TEST_DIR"

# --- Test 2: State file contains valid JSON with expected fields ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    save_claudux_state
    cat "$STATE_FILE"
) > /tmp/claudux-state-t2 2>&1
state_content=$(cat /tmp/claudux-state-t2)
assert_contains "state has last_sha" "$state_content" '"last_sha"'
assert_contains "state has last_run" "$state_content" '"last_run"'
assert_contains "state has backend" "$state_content" '"backend"'
assert_contains "state has files_documented" "$state_content" '"files_documented"'
rm -rf "$TEST_DIR"

# --- Test 3: last_sha matches HEAD ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    save_claudux_state
    grep '"last_sha"' "$STATE_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/'
) > /tmp/claudux-state-t3 2>&1
expected_sha=$(cd "$TEST_DIR" && git rev-parse HEAD)
actual_sha=$(cat /tmp/claudux-state-t3)
assert_eq "last_sha matches HEAD" "$expected_sha" "$actual_sha"
rm -rf "$TEST_DIR"

# --- Test 4: backend defaults to "claude" ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    unset CLAUDUX_BACKEND 2>/dev/null || true
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    save_claudux_state
    grep '"backend"' "$STATE_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/'
) > /tmp/claudux-state-t4 2>&1
assert_eq "backend defaults to claude" "claude" "$(cat /tmp/claudux-state-t4)"
rm -rf "$TEST_DIR"

# --- Test 5: backend reflects CLAUDUX_BACKEND=codex ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    export CLAUDUX_BACKEND=codex
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    save_claudux_state
    grep '"backend"' "$STATE_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/'
) > /tmp/claudux-state-t5 2>&1
assert_eq "backend reflects codex" "codex" "$(cat /tmp/claudux-state-t5)"
rm -rf "$TEST_DIR"

# --- Test 6: load_claudux_state reads back the file ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    save_claudux_state
    loaded=$(load_claudux_state)
    echo "$loaded" | grep -c '"last_sha"'
) > /tmp/claudux-state-t6 2>&1
assert_eq "load_claudux_state returns state" "1" "$(cat /tmp/claudux-state-t6)"
rm -rf "$TEST_DIR"

# --- Test 7: load_claudux_state returns 1 when no state file ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    # Point STATE_FILE at a path that does not exist
    STATE_FILE="$TEST_DIR/.claudux-state-nonexistent-$$.json"
    source "$LIB_DIR/docs-generation.sh"
    # Override STATE_FILE again after sourcing (sourcing resets it)
    STATE_FILE="$TEST_DIR/.claudux-state-nonexistent-$$.json"
    if load_claudux_state >/dev/null 2>&1; then
        echo "found"
    else
        echo "not-found"
    fi
) > /tmp/claudux-state-t7 2>&1
assert_eq "load returns 1 when no file" "not-found" "$(cat /tmp/claudux-state-t7)"
rm -rf "$TEST_DIR"

# --- Test 8: last_run is a valid ISO timestamp ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    save_claudux_state
    ts=$(grep '"last_run"' "$STATE_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/')
    # Check ISO format: YYYY-MM-DDTHH:MM:SSZ
    if echo "$ts" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'; then
        echo "valid"
    else
        echo "invalid: $ts"
    fi
) > /tmp/claudux-state-t8 2>&1
assert_eq "last_run is ISO timestamp" "valid" "$(cat /tmp/claudux-state-t8)"
rm -rf "$TEST_DIR"

# --- Test 9: Overwrite cycle — second save replaces first ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"

    # First save
    save_claudux_state
    sha1=$(grep '"last_sha"' "$STATE_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/')

    # Make a new commit so HEAD changes
    echo "change" >> README.md
    git add README.md
    git commit -q -m "second"

    # Second save
    save_claudux_state
    sha2=$(grep '"last_sha"' "$STATE_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/')

    if [[ "$sha1" != "$sha2" ]]; then
        echo "updated"
    else
        echo "stale"
    fi
) > /tmp/claudux-state-t9 2>&1
assert_eq "second save updates SHA" "updated" "$(cat /tmp/claudux-state-t9)"
rm -rf "$TEST_DIR"

# --- Test 10: files_documented includes docs/ files ---
TEST_DIR=$(setup_repo)
(
    cd "$TEST_DIR"
    STATE_FILE="$TEST_DIR/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    save_claudux_state
    cat "$STATE_FILE"
) > /tmp/claudux-state-t10 2>&1
assert_contains "files_documented includes docs/index.md" "$(cat /tmp/claudux-state-t10)" "docs/index.md"
rm -rf "$TEST_DIR"

# --- Test 11: State file is valid JSON (jq parse) ---
TEST_DIR=$(setup_repo)
if command -v jq >/dev/null 2>&1; then
    (
        cd "$TEST_DIR"
        STATE_FILE="$TEST_DIR/.claudux-state.json"
        source "$LIB_DIR/docs-generation.sh"
        save_claudux_state
        if jq . "$STATE_FILE" >/dev/null 2>&1; then
            echo "valid-json"
        else
            echo "invalid-json"
        fi
    ) > /tmp/claudux-state-t11 2>&1
    assert_eq "state file is valid JSON" "valid-json" "$(cat /tmp/claudux-state-t11)"
else
    echo "  SKIP state file is valid JSON (jq not available)"
fi
rm -rf "$TEST_DIR"

# --- Test 12: REGRESSION — save_claudux_state with empty docs/ produces valid JSON ---
# Bug: when docs/ has no tracked files, files_json pipeline returned empty string
# instead of "[]", producing invalid JSON like:  "files_documented":
TEST_DIR_EMPTY=$(mktemp -d /tmp/claudux-state-test-XXXXXX)
(
    cd "$TEST_DIR_EMPTY"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "hello" > README.md
    git add README.md
    git commit -q -m "init with no docs dir"
    STATE_FILE="$TEST_DIR_EMPTY/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR_EMPTY/.claudux-state.json"
    save_claudux_state
    cat "$STATE_FILE"
) > /tmp/claudux-state-t12 2>&1
state12=$(cat /tmp/claudux-state-t12)
assert_contains "empty docs has files_documented field" "$state12" '"files_documented"'
assert_contains "empty docs files_documented is []" "$state12" '"files_documented": []'
rm -rf "$TEST_DIR_EMPTY"

# --- Test 13: REGRESSION — empty docs/ produces valid JSON parseable by jq ---
TEST_DIR_EMPTY2=$(mktemp -d /tmp/claudux-state-test-XXXXXX)
if command -v jq >/dev/null 2>&1; then
    (
        cd "$TEST_DIR_EMPTY2"
        git init -q
        git config user.email "test@test.com"
        git config user.name "Test"
        echo "hello" > README.md
        git add README.md
        git commit -q -m "init with no docs"
        STATE_FILE="$TEST_DIR_EMPTY2/.claudux-state.json"
        source "$LIB_DIR/docs-generation.sh"
        STATE_FILE="$TEST_DIR_EMPTY2/.claudux-state.json"
        save_claudux_state
        if jq . "$STATE_FILE" >/dev/null 2>&1; then
            echo "valid-json"
        else
            echo "invalid-json"
            echo "--- content ---"
            cat "$STATE_FILE"
        fi
    ) > /tmp/claudux-state-t13 2>&1
    assert_eq "empty docs state file is valid JSON" "valid-json" "$(head -1 /tmp/claudux-state-t13)"
else
    echo "  SKIP empty docs valid JSON test (jq not available)"
fi
rm -rf "$TEST_DIR_EMPTY2"

# --- Test 14: docs/ exists but only has untracked files — valid JSON ---
TEST_DIR_UNTRACKED=$(mktemp -d /tmp/claudux-state-test-XXXXXX)
(
    cd "$TEST_DIR_UNTRACKED"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "hello" > README.md
    mkdir -p docs
    echo "# Untracked" > docs/untracked.md
    git add README.md
    git commit -q -m "init with untracked docs"
    STATE_FILE="$TEST_DIR_UNTRACKED/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR_UNTRACKED/.claudux-state.json"
    save_claudux_state
    cat "$STATE_FILE"
) > /tmp/claudux-state-t14 2>&1
assert_contains "untracked docs files_documented is []" "$(cat /tmp/claudux-state-t14)" '"files_documented": []'
rm -rf "$TEST_DIR_UNTRACKED"

# --- Test 15: load_claudux_state returns 2 when JSON is corrupt ---
TEST_DIR_CORRUPT=$(mktemp -d)
(
    cd "$TEST_DIR_CORRUPT"
    git init -q
    STATE_FILE="$TEST_DIR_CORRUPT/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR_CORRUPT/.claudux-state.json"
    echo "not valid json {{{" > "$STATE_FILE"
    load_claudux_state >/dev/null 2>&1
    echo "rc:$?"
) > /tmp/claudux-state-t15 2>&1
# jq is expected to be available in CI; if not, corrupt detection is best-effort
if command -v jq >/dev/null 2>&1; then
    assert_contains "load_claudux_state returns 2 on corrupt JSON" "$(cat /tmp/claudux-state-t15)" "rc:2"
else
    echo "  SKIP load_claudux_state corrupt detection (jq not installed)"
fi
rm -rf "$TEST_DIR_CORRUPT"

# --- Test 16: load_claudux_state returns 1 when file missing ---
TEST_DIR_MISSING=$(mktemp -d)
(
    cd "$TEST_DIR_MISSING"
    git init -q
    STATE_FILE="$TEST_DIR_MISSING/.claudux-state-nope.json"
    source "$LIB_DIR/docs-generation.sh"
    STATE_FILE="$TEST_DIR_MISSING/.claudux-state-nope.json"
    load_claudux_state >/dev/null 2>&1
    echo "rc:$?"
) > /tmp/claudux-state-t16 2>&1
assert_contains "load_claudux_state returns 1 when missing" "$(cat /tmp/claudux-state-t16)" "rc:1"
rm -rf "$TEST_DIR_MISSING"

# --- Test 17: deterministic metadata records manifest/index coverage ---
TEST_DIR_DETERMINISTIC=$(mktemp -d /tmp/claudux-state-test-XXXXXX)
(
    cd "$TEST_DIR_DETERMINISTIC"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    mkdir -p docs/technical lib
    printf '# Deterministic Generation\n\n## Pipeline\n\nPatch bounded sections only.\n' > docs/technical/deterministic-generation.md
    printf '#!/bin/bash\nupdate() { :; }\n' > lib/docs-generation.sh
    printf '%s\n' \
        '{' \
        '  "version": 1,' \
        '  "pages": [' \
        '    {' \
        '      "id": "technical.deterministic-generation",' \
        '      "path": "docs/technical/deterministic-generation.md",' \
        '      "title": "Deterministic Generation",' \
        '      "deletion_policy": "never_delete_without_manifest_change",' \
        '      "source_patterns": ["lib/docs-generation.sh"],' \
        '      "sections": [' \
        '        {' \
        '          "id": "pipeline",' \
        '          "heading": "Pipeline",' \
        '          "level": 2,' \
        '          "pinned": true,' \
        '          "source_patterns": ["lib/docs-generation.sh"]' \
        '        }' \
        '      ]' \
        '    }' \
        '  ]' \
        '}' > docs-structure.json
    git add docs-structure.json docs/technical/deterministic-generation.md lib/docs-generation.sh
    git commit -q -m "deterministic fixture"
    source "$LIB_DIR/docs-manifest.sh"
    CLAUDUX_INDEX_DIR="$TEST_DIR_DETERMINISTIC/.claudux/index"
    CLAUDUX_STATIC_INDEX_FILE="$TEST_DIR_DETERMINISTIC/.claudux/index/static-analysis.json"
    build_static_analysis_index >/dev/null
    STATE_FILE="$TEST_DIR_DETERMINISTIC/.claudux-state.json"
    source "$LIB_DIR/docs-generation.sh"
    save_claudux_state
    node - "$STATE_FILE" <<'NODE'
const fs = require('fs');
const state = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const deterministic = state.deterministic || {};
console.log(`prompt=${deterministic.prompt_version}`);
console.log(`index=${deterministic.index?.version}`);
console.log(`manifest=${Boolean(deterministic.manifest_hash)}`);
console.log(`source=${(deterministic.source_hashes || []).some(file => file.path === 'lib/docs-generation.sh')}`);
console.log(`section=${(deterministic.doc_section_hashes || []).some(section => section.section_id === 'pipeline' && section.pinned === true)}`);
console.log(`coverage=${(deterministic.source_to_section_coverage || []).some(entry => entry.section_id === 'pipeline' && entry.source_pattern === 'lib/docs-generation.sh')}`);
NODE
) > /tmp/claudux-state-t17 2>&1
state17=$(cat /tmp/claudux-state-t17)
assert_contains "deterministic state records prompt version" "$state17" "prompt=docs-generation-v1"
assert_contains "deterministic state records index version" "$state17" "index=1"
assert_contains "deterministic state records manifest hash" "$state17" "manifest=true"
assert_contains "deterministic state records source hashes" "$state17" "source=true"
assert_contains "deterministic state records doc section hashes" "$state17" "section=true"
assert_contains "deterministic state records source-to-section coverage" "$state17" "coverage=true"
rm -rf "$TEST_DIR_DETERMINISTIC"

# Cleanup
rm -f /tmp/claudux-state-t{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17}

test_summary
