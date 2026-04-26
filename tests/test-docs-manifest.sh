#!/bin/bash
# Tests: deterministic docs manifest validation and static index
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-harness.sh"

echo "=== Docs Manifest Tests ==="
echo ""

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$REPO_ROOT/lib"

setup_manifest_repo() {
    local dir
    dir=$(mktemp -d /tmp/claudux-manifest-test-XXXXXX)
    (
        cd "$dir"
        git init -q
        git config user.email "test@test.com"
        git config user.name "Test"
        mkdir -p docs/technical lib tests
        printf '# Deterministic Generation\n\n## Pipeline\n\nBody.\n\n## StrongYes Harness Example\n\nBody.\n' > docs/technical/deterministic-generation.md
        printf '#!/bin/bash\nupdate() { :; }\n' > lib/docs-generation.sh
        printf '#!/bin/bash\nvalidate_docs_structure_manifest() { :; }\n' > lib/docs-manifest.sh
        printf '{"scripts":{"test":"bash tests/run-all.sh"}}\n' > package.json
        printf '%s\n' \
            '{' \
            '  "version": 1,' \
            '  "pages": [' \
            '    {' \
            '      "id": "technical.deterministic-generation",' \
            '      "path": "docs/technical/deterministic-generation.md",' \
            '      "title": "Deterministic Generation",' \
            '      "deletion_policy": "never_delete_without_manifest_change",' \
            '      "source_patterns": ["lib/docs-generation.sh", "lib/docs-manifest.sh"],' \
            '      "sections": [' \
            '        {' \
            '          "id": "pipeline",' \
            '          "heading": "Pipeline",' \
            '          "level": 2,' \
            '          "pinned": true,' \
            '          "source_patterns": ["lib/docs-generation.sh"]' \
            '        },' \
            '        {' \
            '          "id": "strongyes-harness-example",' \
            '          "heading": "StrongYes Harness Example",' \
            '          "level": 2,' \
            '          "pinned": true' \
            '        }' \
            '      ]' \
            '    }' \
            '  ]' \
            '}' > docs-structure.json
        git add docs-structure.json docs/technical/deterministic-generation.md lib/docs-generation.sh lib/docs-manifest.sh package.json
    )
    echo "$dir"
}

# --- Test 1: preflight validates a well-formed manifest ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    validate_docs_structure_manifest
) > /tmp/claudux-manifest-t1 2>&1
assert_contains "preflight manifest validation passes" "$(cat /tmp/claudux-manifest-t1)" "[claudux:manifest] ok"
rm -rf "$TEST_DIR"

# --- Test 2: post-generation validates pinned headings on disk ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    validate_docs_structure_manifest --post-generation
) > /tmp/claudux-manifest-t2 2>&1
assert_contains "post-generation validation passes" "$(cat /tmp/claudux-manifest-t2)" "2 pinned sections"
rm -rf "$TEST_DIR"

# --- Test 3: post-generation fails when a pinned heading disappears ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    printf '# Deterministic Generation\n\n## Pipeline\n\nBody.\n' > docs/technical/deterministic-generation.md
    source "$LIB_DIR/docs-manifest.sh"
    if validate_docs_structure_manifest --post-generation >/tmp/claudux-manifest-t3-output 2>&1; then
        echo "unexpected-pass"
    else
        cat /tmp/claudux-manifest-t3-output
    fi
) > /tmp/claudux-manifest-t3 2>&1
assert_contains "missing pinned heading fails validation" "$(cat /tmp/claudux-manifest-t3)" 'missing required heading "StrongYes Harness Example"'
rm -rf "$TEST_DIR"

# --- Test 4: static analysis index records sources, docs, scripts, manifest ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    CLAUDUX_INDEX_DIR="$TEST_DIR/.claudux/index"
    CLAUDUX_STATIC_INDEX_FILE="$TEST_DIR/.claudux/index/static-analysis.json"
    build_static_analysis_index >/tmp/claudux-manifest-t4-output
    node - "$CLAUDUX_STATIC_INDEX_FILE" <<'NODE'
const fs = require('fs');
const index = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
console.log(`${index.source_files.length}:${index.docs_files.length}:${index.manifest.pages}:${Object.keys(index.package_scripts).join(',')}`);
NODE
) > /tmp/claudux-manifest-t4 2>&1
assert_contains "static index captures deterministic facts" "$(cat /tmp/claudux-manifest-t4)" "test"
rm -rf "$TEST_DIR"

# --- Test 5: changed source files resolve to manifest-owned docs ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    CLAUDUX_CHANGED_FILES=$'lib/docs-generation.sh\nREADME.md' resolve_impacted_docs_from_changed_files
) > /tmp/claudux-manifest-t5 2>&1
assert_contains "source ownership maps changed file to page" "$(cat /tmp/claudux-manifest-t5)" "technical.deterministic-generation"
assert_contains "source ownership maps changed file to section" "$(cat /tmp/claudux-manifest-t5)" "#pipeline"
rm -rf "$TEST_DIR"

# --- Test 6: duplicate page IDs fail schema validation ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    node - <<'NODE'
const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync('docs-structure.json', 'utf8'));
manifest.pages.push({ ...manifest.pages[0], path: 'docs/technical/duplicate.md' });
fs.writeFileSync('docs-structure.json', `${JSON.stringify(manifest, null, 2)}\n`);
NODE
    source "$LIB_DIR/docs-manifest.sh"
    if validate_docs_structure_manifest >/tmp/claudux-manifest-t6-output 2>&1; then
        echo "unexpected-pass"
    else
        cat /tmp/claudux-manifest-t6-output
    fi
) > /tmp/claudux-manifest-t6 2>&1
assert_contains "duplicate page IDs fail validation" "$(cat /tmp/claudux-manifest-t6)" "duplicate page id"
rm -rf "$TEST_DIR"

rm -f /tmp/claudux-manifest-t1 /tmp/claudux-manifest-t2 /tmp/claudux-manifest-t3
rm -f /tmp/claudux-manifest-t4 /tmp/claudux-manifest-t5 /tmp/claudux-manifest-t6
rm -f /tmp/claudux-manifest-t3-output /tmp/claudux-manifest-t4-output /tmp/claudux-manifest-t6-output

test_summary
