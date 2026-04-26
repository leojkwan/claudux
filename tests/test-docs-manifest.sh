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
        mkdir -p bin docs/api docs/guide docs/technical lib tests
        printf '# Deterministic Generation\n\n## Pipeline\n\nBody.\n\n## StrongYes Harness Example\n\nBody.\n\n## Generated Details\n\nOld generated body.\n\n## Unrelated Generated\n\nUnrelated body.\n' > docs/technical/deterministic-generation.md
        printf '# API\n\nDocumented commands.\n' > docs/api/index.md
        printf '# Guide\n\n[Commands](/guide/commands)\n' > docs/guide/index.md
        printf '# Commands\n\nCommand reference.\n' > docs/guide/commands.md
        printf '# Manual Notes\n\n<!-- skip -->\nHand-written deployment doctrine.\n<!-- /skip -->\n' > docs/manual.md
        printf '#!/bin/bash\nLIB_DIR="$SCRIPT_DIR/../lib"\nsource "$LIB_DIR/ui.sh"\ncase "${1:-}" in\n  "update") update ;;\n  "check"|"doctor") check ;;\nesac\n' > bin/claudux
        printf '#!/bin/bash\nupdate() { :; }\n' > lib/docs-generation.sh
        printf '#!/bin/bash\nvalidate_docs_structure_manifest() { :; }\n' > lib/docs-manifest.sh
        printf '#!/bin/bash\nshow_help() { :; }\n' > lib/ui.sh
        printf '#!/bin/bash\nsource "$SCRIPT_DIR/test-harness.sh"\n' > tests/run-all.sh
        printf '#!/bin/bash\nassert_contains() { :; }\n' > tests/test-harness.sh
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
            '        },' \
            '        {' \
            '          "id": "generated-details",' \
            '          "heading": "Generated Details",' \
            '          "level": 2,' \
            '          "source_patterns": ["lib/docs-manifest.sh"]' \
            '        },' \
            '        {' \
            '          "id": "unrelated-generated",' \
            '          "heading": "Unrelated Generated",' \
            '          "level": 2,' \
            '          "source_patterns": ["README.md"]' \
            '        }' \
            '      ]' \
            '    },' \
            '    {' \
            '      "id": "api.index",' \
            '      "path": "docs/api/index.md",' \
            '      "title": "API",' \
            '      "deletion_policy": "never_delete_without_manifest_change",' \
            '      "source_patterns": ["bin/claudux"]' \
            '    }' \
            '  ]' \
            '}' > docs-structure.json
        git add docs-structure.json docs/technical/deterministic-generation.md docs/api/index.md docs/guide/index.md docs/guide/commands.md docs/manual.md bin/claudux lib/docs-generation.sh lib/docs-manifest.sh lib/ui.sh tests/run-all.sh tests/test-harness.sh package.json
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

# --- Test 4: static analysis index records sources, docs, scripts, manifest, and dependencies ---
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
console.log(`edge=${(index.dependency_edges || []).some(edge => edge.from === 'bin/claudux' && edge.to === 'lib/ui.sh')}`);
console.log(`commands=${(index.cli_commands || []).join(',')}`);
console.log(`exports=${(index.exported_symbols || []).some(symbol => symbol.file === 'lib/ui.sh' && symbol.name === 'show_help')}`);
console.log(`tests=${(index.tests || []).some(test => test.path === 'tests/run-all.sh')}`);
console.log(`link=${(index.docs_links || []).some(link => link.from === 'docs/guide/index.md' && link.to === 'docs/guide/commands.md')}`);
NODE
) > /tmp/claudux-manifest-t4 2>&1
assert_contains "static index captures deterministic facts" "$(cat /tmp/claudux-manifest-t4)" "test"
assert_contains "static index captures shell dependency edges" "$(cat /tmp/claudux-manifest-t4)" "edge=true"
assert_contains "static index captures CLI commands" "$(cat /tmp/claudux-manifest-t4)" "commands=check,doctor,update"
assert_contains "static index captures exported shell functions" "$(cat /tmp/claudux-manifest-t4)" "exports=true"
assert_contains "static index captures test files" "$(cat /tmp/claudux-manifest-t4)" "tests=true"
assert_contains "static index captures docs links" "$(cat /tmp/claudux-manifest-t4)" "link=true"
rm -rf "$TEST_DIR"

# --- Test 5: changed source files resolve to manifest-owned docs and reverse dependencies ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    CLAUDUX_INDEX_DIR="$TEST_DIR/.claudux/index"
    CLAUDUX_STATIC_INDEX_FILE="$TEST_DIR/.claudux/index/static-analysis.json"
    build_static_analysis_index >/dev/null
    CLAUDUX_CHANGED_FILES=$'lib/docs-generation.sh\nlib/ui.sh\nREADME.md' resolve_impacted_docs_from_changed_files
) > /tmp/claudux-manifest-t5 2>&1
assert_contains "source ownership maps changed file to page" "$(cat /tmp/claudux-manifest-t5)" "technical.deterministic-generation"
assert_contains "source ownership maps changed file to section" "$(cat /tmp/claudux-manifest-t5)" "#pipeline"
assert_contains "dependency expansion reports edge" "$(cat /tmp/claudux-manifest-t5)" "dependency-expanded scope: lib/ui.sh -> bin/claudux"
assert_contains "dependency-expanded file maps to page" "$(cat /tmp/claudux-manifest-t5)" "bin/claudux -> api.index"
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

# --- Test 7: guard snapshot passes when pinned headings and skip blocks survive ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    CLAUDUX_GUARD_SNAPSHOT_FILE="$TEST_DIR/.claudux/index/docs-guard-snapshot.json"
    capture_docs_structure_guard_snapshot >/tmp/claudux-manifest-t7-output
    validate_docs_structure_guard_snapshot
) > /tmp/claudux-manifest-t7 2>&1
assert_contains "guard snapshot validates unchanged docs" "$(cat /tmp/claudux-manifest-t7)" "[claudux:guard] ok"
rm -rf "$TEST_DIR"

# --- Test 8: guard snapshot fails when protected skip content changes ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    CLAUDUX_GUARD_SNAPSHOT_FILE="$TEST_DIR/.claudux/index/docs-guard-snapshot.json"
    capture_docs_structure_guard_snapshot >/tmp/claudux-manifest-t8-output
    printf '# Manual Notes\n\n<!-- skip -->\nRewritten generic text.\n<!-- /skip -->\n' > docs/manual.md
    if validate_docs_structure_guard_snapshot >/tmp/claudux-manifest-t8-validate 2>&1; then
        echo "unexpected-pass"
    else
        cat /tmp/claudux-manifest-t8-validate
    fi
) > /tmp/claudux-manifest-t8 2>&1
assert_contains "guard snapshot catches changed protected content" "$(cat /tmp/claudux-manifest-t8)" "protected skip block 1 changed"
rm -rf "$TEST_DIR"

# --- Test 9: guard snapshot fails when pinned heading order changes ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    CLAUDUX_GUARD_SNAPSHOT_FILE="$TEST_DIR/.claudux/index/docs-guard-snapshot.json"
    capture_docs_structure_guard_snapshot >/tmp/claudux-manifest-t9-output
    printf '# Deterministic Generation\n\n## StrongYes Harness Example\n\nBody.\n\n## Pipeline\n\nBody.\n' > docs/technical/deterministic-generation.md
    if validate_docs_structure_guard_snapshot >/tmp/claudux-manifest-t9-validate 2>&1; then
        echo "unexpected-pass"
    else
        cat /tmp/claudux-manifest-t9-validate
    fi
) > /tmp/claudux-manifest-t9 2>&1
assert_contains "guard snapshot catches pinned heading reorder" "$(cat /tmp/claudux-manifest-t9)" "pinned heading order changed"
rm -rf "$TEST_DIR"

# --- Test 10: section patch contract lists generated sections and pins read-only doctrine ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    format_section_patch_contract
) > /tmp/claudux-manifest-t10 2>&1
assert_contains "section patch contract lists generated section" "$(cat /tmp/claudux-manifest-t10)" "technical.deterministic-generation#generated-details"
assert_contains "section patch contract lists pinned section as read-only" "$(cat /tmp/claudux-manifest-t10)" "technical.deterministic-generation#pipeline"
rm -rf "$TEST_DIR"

# --- Test 11: section patcher updates only the manifest-owned generated section ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    printf '%s\n' \
        '{' \
        '  "patches": [' \
        '    {' \
        '      "page_id": "technical.deterministic-generation",' \
        '      "section_id": "generated-details",' \
        '      "body_markdown": "New generated body.\n\n```md\n## Example inside code fence\n```\n\n### Generated Subheading\n\n- Source-owned fact."' \
        '    }' \
        '  ]' \
        '}' > /tmp/claudux-section-patches-t11.json
    apply_manifest_section_patches /tmp/claudux-section-patches-t11.json
    cat docs/technical/deterministic-generation.md
) > /tmp/claudux-manifest-t11 2>&1
assert_contains "section patcher applies generated body" "$(cat /tmp/claudux-manifest-t11)" "New generated body."
assert_contains "section patcher permits code-fenced markdown headings" "$(cat /tmp/claudux-manifest-t11)" "## Example inside code fence"
assert_contains "section patcher permits deeper generated subheadings" "$(cat /tmp/claudux-manifest-t11)" "### Generated Subheading"
assert_contains "section patcher preserves pinned pipeline body" "$(cat /tmp/claudux-manifest-t11)" "## Pipeline"
assert_contains "section patcher preserves pinned harness body" "$(cat /tmp/claudux-manifest-t11)" "## StrongYes Harness Example"
rm -rf "$TEST_DIR"

# --- Test 12: section patcher rejects pinned section edits by default ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    printf '%s\n' \
        '{' \
        '  "patches": [' \
        '    {' \
        '      "page_id": "technical.deterministic-generation",' \
        '      "section_id": "pipeline",' \
        '      "body_markdown": "Rewrite pinned doctrine."' \
        '    }' \
        '  ]' \
        '}' > /tmp/claudux-section-patches-t12.json
    if apply_manifest_section_patches /tmp/claudux-section-patches-t12.json >/tmp/claudux-manifest-t12-output 2>&1; then
        echo "unexpected-pass"
    else
        cat /tmp/claudux-manifest-t12-output
    fi
) > /tmp/claudux-manifest-t12 2>&1
assert_contains "section patcher rejects pinned edits" "$(cat /tmp/claudux-manifest-t12)" "is pinned/read-only"
rm -rf "$TEST_DIR"

# --- Test 13: section patch payload extraction reads JSONL assistant text ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    printf '%s\n' '{"type":"result","result":"CLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[{\"page_id\":\"technical.deterministic-generation\",\"section_id\":\"generated-details\",\"body_markdown\":\"Extracted body.\"}]}\nCLAUDUX_SECTION_PATCHES_JSON_END"}' > /tmp/claudux-manifest-t13-log.jsonl
    extract_section_patch_payload /tmp/claudux-manifest-t13-log.jsonl /tmp/claudux-manifest-t13-patches.json
    node - /tmp/claudux-manifest-t13-patches.json <<'NODE'
const fs = require('fs');
const payload = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
console.log(`${payload.patches.length}:${payload.patches[0].section_id}:${payload.patches[0].body_markdown}`);
NODE
) > /tmp/claudux-manifest-t13 2>&1
assert_contains "section patch extraction captures payload" "$(cat /tmp/claudux-manifest-t13)" "1:generated-details:Extracted body."
rm -rf "$TEST_DIR"

# --- Test 14: incremental impact allowlist blocks unrelated generated sections ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    build_static_analysis_index >/tmp/claudux-manifest-t14-index
    CLAUDUX_CHANGED_FILES=$'lib/docs-manifest.sh' CLAUDUX_IMPACT_ALLOWLIST_FILE=/tmp/claudux-manifest-t14-allowlist.json resolve_impacted_docs_from_changed_files >/tmp/claudux-manifest-t14-impact
    printf '%s\n' \
        '{' \
        '  "patches": [' \
        '    {' \
        '      "page_id": "technical.deterministic-generation",' \
        '      "section_id": "generated-details",' \
        '      "body_markdown": "Allowed incremental body."' \
        '    }' \
        '  ]' \
        '}' > /tmp/claudux-section-patches-t14-allowed.json
    CLAUDUX_IMPACT_ALLOWLIST_FILE=/tmp/claudux-manifest-t14-allowlist.json apply_manifest_section_patches /tmp/claudux-section-patches-t14-allowed.json
    printf '%s\n' \
        '{' \
        '  "patches": [' \
        '    {' \
        '      "page_id": "technical.deterministic-generation",' \
        '      "section_id": "unrelated-generated",' \
        '      "body_markdown": "Out of scope body."' \
        '    }' \
        '  ]' \
        '}' > /tmp/claudux-section-patches-t14-blocked.json
    if CLAUDUX_IMPACT_ALLOWLIST_FILE=/tmp/claudux-manifest-t14-allowlist.json apply_manifest_section_patches /tmp/claudux-section-patches-t14-blocked.json >/tmp/claudux-manifest-t14-blocked 2>&1; then
        echo "unexpected-pass"
    else
        cat /tmp/claudux-manifest-t14-blocked
    fi
    unset CLAUDUX_IMPACT_ALLOWLIST_FILE
    apply_manifest_section_patches /tmp/claudux-section-patches-t14-blocked.json
    cat docs/technical/deterministic-generation.md
) > /tmp/claudux-manifest-t14 2>&1
assert_contains "impact allowlist records section" "$(cat /tmp/claudux-manifest-t14-impact)" "lib/docs-manifest.sh -> technical.deterministic-generation#generated-details"
assert_contains "incremental allowlist permits impacted section" "$(cat /tmp/claudux-manifest-t14)" "Allowed incremental body."
assert_contains "incremental allowlist blocks unrelated section" "$(cat /tmp/claudux-manifest-t14)" "outside incremental impact allowlist"
assert_contains "full scan still allows generated section" "$(cat /tmp/claudux-manifest-t14)" "Out of scope body."
rm -rf "$TEST_DIR"

# --- Test 15: section patcher rejects mixed valid/invalid batches without partial writes ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    printf '%s\n' \
        '{' \
        '  "patches": [' \
        '    {' \
        '      "page_id": "technical.deterministic-generation",' \
        '      "section_id": "generated-details",' \
        '      "body_markdown": "Should not land."' \
        '    },' \
        '    {' \
        '      "page_id": "technical.deterministic-generation",' \
        '      "section_id": "pipeline",' \
        '      "body_markdown": "Invalid pinned rewrite."' \
        '    }' \
        '  ]' \
        '}' > /tmp/claudux-section-patches-t15.json
    if apply_manifest_section_patches /tmp/claudux-section-patches-t15.json >/tmp/claudux-manifest-t15-output 2>&1; then
        echo "unexpected-pass"
    else
        cat /tmp/claudux-manifest-t15-output
    fi
    cat docs/technical/deterministic-generation.md
) > /tmp/claudux-manifest-t15 2>&1
assert_contains "section patcher rejects invalid mixed batch" "$(cat /tmp/claudux-manifest-t15)" "is pinned/read-only"
assert_contains "section patcher leaves original generated body after failed batch" "$(cat /tmp/claudux-manifest-t15)" "Old generated body."
assert_not_contains "section patcher does not partially write failed batch" "$(cat /tmp/claudux-manifest-t15)" "Should not land."
rm -rf "$TEST_DIR"

# --- Test 16: section patcher rejects body headings that escape the bounded section ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    printf '%s\n' \
        '{' \
        '  "patches": [' \
        '    {' \
        '      "page_id": "technical.deterministic-generation",' \
        '      "section_id": "generated-details",' \
        '      "body_markdown": "Intro.\n\n## Escaped Heading\n\nThis would become a sibling section."' \
        '    }' \
        '  ]' \
        '}' > /tmp/claudux-section-patches-t16.json
    if apply_manifest_section_patches /tmp/claudux-section-patches-t16.json >/tmp/claudux-manifest-t16-output 2>&1; then
        echo "unexpected-pass"
    else
        cat /tmp/claudux-manifest-t16-output
    fi
    cat docs/technical/deterministic-generation.md
) > /tmp/claudux-manifest-t16 2>&1
assert_contains "section patcher rejects same-level headings in body" "$(cat /tmp/claudux-manifest-t16)" "section patches cannot create same-or-higher-level headings"
assert_contains "section patcher preserves original body after boundary rejection" "$(cat /tmp/claudux-manifest-t16)" "Old generated body."
assert_not_contains "section patcher does not write escaping body" "$(cat /tmp/claudux-manifest-t16)" "This would become a sibling section."
rm -rf "$TEST_DIR"

rm -f /tmp/claudux-manifest-t1 /tmp/claudux-manifest-t2 /tmp/claudux-manifest-t3
rm -f /tmp/claudux-manifest-t4 /tmp/claudux-manifest-t5 /tmp/claudux-manifest-t6
rm -f /tmp/claudux-manifest-t7 /tmp/claudux-manifest-t8 /tmp/claudux-manifest-t9
rm -f /tmp/claudux-manifest-t10 /tmp/claudux-manifest-t11 /tmp/claudux-manifest-t12 /tmp/claudux-manifest-t13 /tmp/claudux-manifest-t14
rm -f /tmp/claudux-manifest-t15 /tmp/claudux-manifest-t16
rm -f /tmp/claudux-manifest-t3-output /tmp/claudux-manifest-t4-output /tmp/claudux-manifest-t6-output
rm -f /tmp/claudux-manifest-t7-output /tmp/claudux-manifest-t8-output /tmp/claudux-manifest-t8-validate
rm -f /tmp/claudux-manifest-t9-output /tmp/claudux-manifest-t9-validate
rm -f /tmp/claudux-manifest-t12-output /tmp/claudux-manifest-t13-log.jsonl /tmp/claudux-manifest-t13-patches.json
rm -f /tmp/claudux-manifest-t14-index /tmp/claudux-manifest-t14-impact /tmp/claudux-manifest-t14-allowlist.json /tmp/claudux-manifest-t14-blocked
rm -f /tmp/claudux-manifest-t15-output /tmp/claudux-manifest-t16-output
rm -f /tmp/claudux-section-patches-t11.json /tmp/claudux-section-patches-t12.json /tmp/claudux-section-patches-t14-allowed.json /tmp/claudux-section-patches-t14-blocked.json
rm -f /tmp/claudux-section-patches-t15.json /tmp/claudux-section-patches-t16.json

test_summary
