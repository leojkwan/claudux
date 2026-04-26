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
        mkdir -p bin docs/api docs/guide docs/technical lib src tests
        printf '# Deterministic Generation\n\n## Pipeline\n\nBody.\n\n## StrongYes Harness Example\n\nBody.\n\n## Generated Details\n\nOld generated body.\n\n## Unrelated Generated\n\nUnrelated body.\n' > docs/technical/deterministic-generation.md
        printf '# API\n\nDocumented commands.\n' > docs/api/index.md
        printf '# Guide\n\n[Commands](/guide/commands)\n' > docs/guide/index.md
        printf '# Commands\n\nCommand reference.\n' > docs/guide/commands.md
        printf '# Manual Notes\n\n<!-- skip -->\nHand-written deployment doctrine.\n<!-- /skip -->\n' > docs/manual.md
        printf '#!/bin/bash\nLIB_DIR="$SCRIPT_DIR/../lib"\nsource "$LIB_DIR/ui.sh"\ncase "${1:-}" in\n  "update") update ;;\n  "check"|"doctor") check ;;\nesac\n' > bin/claudux
        printf '#!/bin/bash\nupdate() { :; }\n' > lib/docs-generation.sh
        printf '#!/bin/bash\nvalidate_docs_structure_manifest() { :; }\n' > lib/docs-manifest.sh
        printf '#!/bin/bash\nshow_help() { :; }\n' > lib/ui.sh
        printf 'export const publicValue = 1;\n\n// skip\nconst sourceOwnedSecret = "do-not-document";\n// /skip\n\nexport const laterValue = 2;\n' > src/protected.ts
        printf '.public { color: red; }\n\n/* skip */\n.secret { token: "do-not-document"; }\n/* /skip */\n\n.card { color: blue; }\n' > src/protected.css
        printf '#!/bin/bash\nsource "$SCRIPT_DIR/test-harness.sh"\n' > tests/run-all.sh
        printf '#!/bin/bash\nassert_contains() { :; }\n' > tests/test-harness.sh
        printf '{"scripts":{"test":"bash tests/run-all.sh"}}\n' > package.json
        printf '%s\n' \
            '{' \
            '  "version": 1,' \
            '  "navigation": [' \
            '    { "id": "technical", "title": "Technical", "link": "/technical/", "order": 1 },' \
            '    { "id": "api", "title": "API", "link": "/api/", "order": 2 }' \
            '  ],' \
            '  "pages": [' \
            '    {' \
            '      "id": "technical.deterministic-generation",' \
            '      "path": "docs/technical/deterministic-generation.md",' \
            '      "title": "Deterministic Generation",' \
            '      "order": 110,' \
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
            '      "order": 120,' \
            '      "deletion_policy": "never_delete_without_manifest_change",' \
            '      "source_patterns": ["bin/claudux"]' \
            '    }' \
            '  ]' \
            '}' > docs-structure.json
        git add docs-structure.json docs/technical/deterministic-generation.md docs/api/index.md docs/guide/index.md docs/guide/commands.md docs/manual.md bin/claudux lib/docs-generation.sh lib/docs-manifest.sh lib/ui.sh src/protected.ts src/protected.css tests/run-all.sh tests/test-harness.sh package.json
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
console.log(`protected-ts=${(index.protected_blocks || []).some(block => block.path === 'src/protected.ts' && block.start_marker === '// skip')}`);
console.log(`protected-css=${(index.protected_blocks || []).some(block => block.path === 'src/protected.css' && block.start_marker === '/* skip */')}`);
NODE
) > /tmp/claudux-manifest-t4 2>&1
assert_contains "static index captures deterministic facts" "$(cat /tmp/claudux-manifest-t4)" "test"
assert_contains "static index captures shell dependency edges" "$(cat /tmp/claudux-manifest-t4)" "edge=true"
assert_contains "static index captures CLI commands" "$(cat /tmp/claudux-manifest-t4)" "commands=check,doctor,update"
assert_contains "static index captures exported shell functions" "$(cat /tmp/claudux-manifest-t4)" "exports=true"
assert_contains "static index captures test files" "$(cat /tmp/claudux-manifest-t4)" "tests=true"
assert_contains "static index captures docs links" "$(cat /tmp/claudux-manifest-t4)" "link=true"
assert_contains "static index captures slash protected blocks" "$(cat /tmp/claudux-manifest-t4)" "protected-ts=true"
assert_contains "static index captures css protected blocks literally" "$(cat /tmp/claudux-manifest-t4)" "protected-css=true"
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

# --- Test 5b: deterministic cache artifacts are byte-stable for identical inputs ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    CLAUDUX_INDEX_DIR="$TEST_DIR/.claudux/index"
    CLAUDUX_STATIC_INDEX_FILE="$TEST_DIR/.claudux/index/static-analysis.json"
    CLAUDUX_GUARD_SNAPSHOT_FILE="$TEST_DIR/.claudux/index/docs-guard-snapshot.json"
    CLAUDUX_IMPACT_ALLOWLIST_FILE="$TEST_DIR/.claudux/index/impacted-docs.json"

    build_static_analysis_index >/dev/null
    capture_docs_structure_guard_snapshot >/dev/null
    CLAUDUX_CHANGED_FILES=$'lib/docs-manifest.sh\nREADME.md' CLAUDUX_IMPACT_ALLOWLIST_FILE="$CLAUDUX_IMPACT_ALLOWLIST_FILE" resolve_impacted_docs_from_changed_files >/dev/null
    cp "$CLAUDUX_STATIC_INDEX_FILE" /tmp/claudux-manifest-t5b-static-first.json
    cp "$CLAUDUX_GUARD_SNAPSHOT_FILE" /tmp/claudux-manifest-t5b-guard-first.json
    cp "$CLAUDUX_IMPACT_ALLOWLIST_FILE" /tmp/claudux-manifest-t5b-impact-first.json

    sleep 1

    build_static_analysis_index >/dev/null
    capture_docs_structure_guard_snapshot >/dev/null
    CLAUDUX_CHANGED_FILES=$'lib/docs-manifest.sh\nREADME.md' CLAUDUX_IMPACT_ALLOWLIST_FILE="$CLAUDUX_IMPACT_ALLOWLIST_FILE" resolve_impacted_docs_from_changed_files >/dev/null

    cmp -s /tmp/claudux-manifest-t5b-static-first.json "$CLAUDUX_STATIC_INDEX_FILE" && echo "static-index-stable:true"
    cmp -s /tmp/claudux-manifest-t5b-guard-first.json "$CLAUDUX_GUARD_SNAPSHOT_FILE" && echo "guard-snapshot-stable:true"
    cmp -s /tmp/claudux-manifest-t5b-impact-first.json "$CLAUDUX_IMPACT_ALLOWLIST_FILE" && echo "impact-allowlist-stable:true"
    node - "$CLAUDUX_STATIC_INDEX_FILE" "$CLAUDUX_GUARD_SNAPSHOT_FILE" "$CLAUDUX_IMPACT_ALLOWLIST_FILE" <<'NODE'
const fs = require('fs');
for (const file of process.argv.slice(2)) {
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  console.log(`${file.split('/').pop()}:generated_at=${Object.prototype.hasOwnProperty.call(data, 'generated_at')}`);
}
NODE
) > /tmp/claudux-manifest-t5b 2>&1
assert_contains "static index is reproducible" "$(cat /tmp/claudux-manifest-t5b)" "static-index-stable:true"
assert_contains "guard snapshot is reproducible" "$(cat /tmp/claudux-manifest-t5b)" "guard-snapshot-stable:true"
assert_contains "impact allowlist is reproducible" "$(cat /tmp/claudux-manifest-t5b)" "impact-allowlist-stable:true"
assert_contains "static index omits wall-clock timestamp" "$(cat /tmp/claudux-manifest-t5b)" "static-analysis.json:generated_at=false"
assert_contains "guard snapshot omits wall-clock timestamp" "$(cat /tmp/claudux-manifest-t5b)" "docs-guard-snapshot.json:generated_at=false"
assert_contains "impact allowlist omits wall-clock timestamp" "$(cat /tmp/claudux-manifest-t5b)" "impacted-docs.json:generated_at=false"
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

# --- Test 8b: guard snapshot fails when source-language skip content changes ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    CLAUDUX_GUARD_SNAPSHOT_FILE="$TEST_DIR/.claudux/index/docs-guard-snapshot.json"
    capture_docs_structure_guard_snapshot >/tmp/claudux-manifest-t8b-output
    printf 'export const publicValue = 1;\n\n// skip\nconst sourceOwnedSecret = "rewritten-generic-advice";\n// /skip\n\nexport const laterValue = 2;\n' > src/protected.ts
    if validate_docs_structure_guard_snapshot >/tmp/claudux-manifest-t8b-validate 2>&1; then
        echo "unexpected-pass"
    else
        cat /tmp/claudux-manifest-t8b-validate
    fi
) > /tmp/claudux-manifest-t8b 2>&1
assert_contains "guard snapshot catches source protected content" "$(cat /tmp/claudux-manifest-t8b)" "src/protected.ts: protected skip block 1 changed"
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

# --- Test 9b: guard snapshot fails when a pinned section body changes without unlock ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    CLAUDUX_GUARD_SNAPSHOT_FILE="$TEST_DIR/.claudux/index/docs-guard-snapshot.json"
    capture_docs_structure_guard_snapshot >/tmp/claudux-manifest-t9b-output
    printf '# Deterministic Generation\n\n## Pipeline\n\nRewritten generic test advice.\n\n## StrongYes Harness Example\n\nBody.\n\n## Generated Details\n\nOld generated body.\n\n## Unrelated Generated\n\nUnrelated body.\n' > docs/technical/deterministic-generation.md
    if validate_docs_structure_guard_snapshot >/tmp/claudux-manifest-t9b-validate 2>&1; then
        echo "unexpected-pass"
    else
        cat /tmp/claudux-manifest-t9b-validate
    fi
    CLAUDUX_UNLOCK_PINNED_SECTIONS=1 validate_docs_structure_guard_snapshot
) > /tmp/claudux-manifest-t9b 2>&1
assert_contains "guard snapshot catches pinned body rewrite" "$(cat /tmp/claudux-manifest-t9b)" "pinned section body changed"
assert_contains "guard snapshot permits explicit pinned unlock" "$(cat /tmp/claudux-manifest-t9b)" "[claudux:guard] ok"
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

# --- Test 13b: section patch payload extraction rejects multiple marker pairs ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    printf '%s\n' '{"type":"result","result":"CLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[]}\nCLAUDUX_SECTION_PATCHES_JSON_END\nCLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[]}\nCLAUDUX_SECTION_PATCHES_JSON_END"}' > /tmp/claudux-manifest-t13b-log.jsonl
    if extract_section_patch_payload /tmp/claudux-manifest-t13b-log.jsonl /tmp/claudux-manifest-t13b-patches.json >/tmp/claudux-manifest-t13b-output 2>&1; then
        echo "unexpected-pass"
    else
        cat /tmp/claudux-manifest-t13b-output
    fi
) > /tmp/claudux-manifest-t13b 2>&1
assert_contains "section patch extraction rejects multiple payloads" "$(cat /tmp/claudux-manifest-t13b)" "expected exactly one section patch payload marker pair"
rm -rf "$TEST_DIR"

# --- Test 13c: section patch payload extraction rejects orphaned markers ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    printf '%s\n' '{"type":"result","result":"CLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[]}"}' > /tmp/claudux-manifest-t13c-log.jsonl
    if extract_section_patch_payload /tmp/claudux-manifest-t13c-log.jsonl /tmp/claudux-manifest-t13c-patches.json >/tmp/claudux-manifest-t13c-output 2>&1; then
        echo "unexpected-pass"
    else
        cat /tmp/claudux-manifest-t13c-output
    fi
) > /tmp/claudux-manifest-t13c 2>&1
assert_contains "section patch extraction rejects orphaned markers" "$(cat /tmp/claudux-manifest-t13c)" "section patch payload markers must be paired"
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

# --- Test 17: cleanup refuses AI deletion when a manifest owns docs structure ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/colors.sh"
    source "$LIB_DIR/docs-manifest.sh"
    source "$LIB_DIR/cleanup.sh"
    cleanup_docs
    test -f docs/technical/deterministic-generation.md && echo "manifest-page-still-exists"
) > /tmp/claudux-manifest-t17 2>&1
assert_contains "cleanup guard blocks AI deletion with manifest" "$(cat /tmp/claudux-manifest-t17)" "Manifest deletion guard active"
assert_contains "cleanup guard preserves manifest page" "$(cat /tmp/claudux-manifest-t17)" "manifest-page-still-exists"
rm -rf "$TEST_DIR"

# --- Test 18: recreate refuses to rm -rf manifest-owned docs by default ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    if bash -c "source '$LIB_DIR/colors.sh'; source '$LIB_DIR/docs-manifest.sh'; source '$LIB_DIR/cleanup.sh'; recreate_docs" >/tmp/claudux-manifest-t18-output 2>&1; then
        echo "unexpected-pass"
    else
        cat /tmp/claudux-manifest-t18-output
    fi
    test -f docs/technical/deterministic-generation.md && echo "manifest-page-still-exists"
) > /tmp/claudux-manifest-t18 2>&1
assert_contains "recreate guard blocks manifest docs deletion" "$(cat /tmp/claudux-manifest-t18)" "Recreate would delete manifest-owned documentation"
assert_contains "recreate guard preserves manifest page" "$(cat /tmp/claudux-manifest-t18)" "manifest-page-still-exists"
rm -rf "$TEST_DIR"

# --- Test 19: manifest rejects malformed source pattern entries before impact mapping ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    node - <<'NODE'
const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync('docs-structure.json', 'utf8'));
manifest.pages[0].source_patterns.push('');
manifest.pages[0].sections[0].source_patterns.push(42);
fs.writeFileSync('docs-structure.json', `${JSON.stringify(manifest, null, 2)}\n`);
NODE
    source "$LIB_DIR/docs-manifest.sh"
    if validate_docs_structure_manifest >/tmp/claudux-manifest-t19-output 2>&1; then
        echo "unexpected-pass"
    else
        cat /tmp/claudux-manifest-t19-output
    fi
) > /tmp/claudux-manifest-t19 2>&1
assert_contains "empty source pattern fails validation" "$(cat /tmp/claudux-manifest-t19)" "source_patterns[2] must not be empty"
assert_contains "non-string section source pattern fails validation" "$(cat /tmp/claudux-manifest-t19)" "source_patterns[1] must be a string"
rm -rf "$TEST_DIR"

# --- Test 20: manifest rejects source patterns that escape the repo root ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    node - <<'NODE'
const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync('docs-structure.json', 'utf8'));
manifest.pages[0].source_patterns.push('/tmp/outside.sh');
manifest.pages[0].sections[0].source_patterns.push('../strongyes-web/scripts/run-local-supabase-test.mjs');
fs.writeFileSync('docs-structure.json', `${JSON.stringify(manifest, null, 2)}\n`);
NODE
    source "$LIB_DIR/docs-manifest.sh"
    if validate_docs_structure_manifest >/tmp/claudux-manifest-t20-output 2>&1; then
        echo "unexpected-pass"
    else
        cat /tmp/claudux-manifest-t20-output
    fi
) > /tmp/claudux-manifest-t20 2>&1
assert_contains "absolute source pattern fails validation" "$(cat /tmp/claudux-manifest-t20)" "source_patterns[2] must be repo-root relative"
assert_contains "parent traversal source pattern fails validation" "$(cat /tmp/claudux-manifest-t20)" "source_patterns[1] must be repo-root relative"
rm -rf "$TEST_DIR"

# --- Test 21: manifest rejects duplicate deterministic order values ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    node - <<'NODE'
const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync('docs-structure.json', 'utf8'));
manifest.navigation[1].order = manifest.navigation[0].order;
manifest.pages[1].order = manifest.pages[0].order;
fs.writeFileSync('docs-structure.json', `${JSON.stringify(manifest, null, 2)}\n`);
NODE
    source "$LIB_DIR/docs-manifest.sh"
    if validate_docs_structure_manifest >/tmp/claudux-manifest-t21-output 2>&1; then
        echo "unexpected-pass"
    else
        cat /tmp/claudux-manifest-t21-output
    fi
) > /tmp/claudux-manifest-t21 2>&1
assert_contains "duplicate navigation order fails validation" "$(cat /tmp/claudux-manifest-t21)" "duplicate navigation order 1"
assert_contains "duplicate page order fails validation" "$(cat /tmp/claudux-manifest-t21)" "duplicate page order 110"
rm -rf "$TEST_DIR"

# --- Test 22: manifest section heading anchors must stay unambiguous ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    node - <<'NODE'
const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync('docs-structure.json', 'utf8'));
manifest.pages[0].sections[1].heading = manifest.pages[0].sections[0].heading;
manifest.pages[0].sections[1].level = manifest.pages[0].sections[0].level;
fs.writeFileSync('docs-structure.json', `${JSON.stringify(manifest, null, 2)}\n`);
NODE
    source "$LIB_DIR/docs-manifest.sh"
    if validate_docs_structure_manifest >/tmp/claudux-manifest-t22-schema-output 2>&1; then
        echo "unexpected-schema-pass"
    else
        cat /tmp/claudux-manifest-t22-schema-output
    fi
) > /tmp/claudux-manifest-t22-schema 2>&1
assert_contains "duplicate manifest section anchor fails validation" "$(cat /tmp/claudux-manifest-t22-schema)" 'duplicate section heading anchor h2 "Pipeline"'
rm -rf "$TEST_DIR"

TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    printf '\n## Generated Details\n\nAmbiguous generated body.\n' >> docs/technical/deterministic-generation.md
    source "$LIB_DIR/docs-manifest.sh"
    if validate_docs_structure_manifest --post-generation >/tmp/claudux-manifest-t22-disk-output 2>&1; then
        echo "unexpected-disk-pass"
    else
        cat /tmp/claudux-manifest-t22-disk-output
    fi
) > /tmp/claudux-manifest-t22-disk 2>&1
assert_contains "duplicate on-disk section anchor fails post-generation validation" "$(cat /tmp/claudux-manifest-t22-disk)" 'duplicate manifest heading anchor h2 "Generated Details"'
rm -rf "$TEST_DIR"

# --- Test 23: docs-structure.json takes prompt precedence over legacy docs-map.md ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    printf '# Legacy Docs Map\n\nLoose advisory structure.\n' > docs-map.md
    source "$LIB_DIR/docs-manifest.sh"
    source "$LIB_DIR/docs-generation.sh"
    build_generation_prompt "generic" "Prompt Precedence Test"
) > /tmp/claudux-manifest-t23 2>&1
assert_contains "prompt reads docs-structure as deterministic manifest when docs-map also exists" "$(cat /tmp/claudux-manifest-t23)" "Read docs-structure.json as the deterministic docs manifest"
assert_contains "prompt keeps docs-map as supplemental legacy guidance" "$(cat /tmp/claudux-manifest-t23)" "Read docs-map.md as supplemental legacy guidance only"
assert_not_contains "prompt does not demote docs-map to primary loose guidance" "$(cat /tmp/claudux-manifest-t23)" "Read docs-map.md for loose documentation guidance"
rm -rf "$TEST_DIR"

rm -f /tmp/claudux-manifest-t1 /tmp/claudux-manifest-t2 /tmp/claudux-manifest-t3
rm -f /tmp/claudux-manifest-t4 /tmp/claudux-manifest-t5 /tmp/claudux-manifest-t6
rm -f /tmp/claudux-manifest-t5b /tmp/claudux-manifest-t5b-static-first.json /tmp/claudux-manifest-t5b-guard-first.json /tmp/claudux-manifest-t5b-impact-first.json
rm -f /tmp/claudux-manifest-t7 /tmp/claudux-manifest-t8 /tmp/claudux-manifest-t9
rm -f /tmp/claudux-manifest-t10 /tmp/claudux-manifest-t11 /tmp/claudux-manifest-t12 /tmp/claudux-manifest-t13 /tmp/claudux-manifest-t14
rm -f /tmp/claudux-manifest-t15 /tmp/claudux-manifest-t16 /tmp/claudux-manifest-t17 /tmp/claudux-manifest-t18
rm -f /tmp/claudux-manifest-t3-output /tmp/claudux-manifest-t4-output /tmp/claudux-manifest-t6-output
rm -f /tmp/claudux-manifest-t7-output /tmp/claudux-manifest-t8-output /tmp/claudux-manifest-t8-validate
rm -f /tmp/claudux-manifest-t9-output /tmp/claudux-manifest-t9-validate
rm -f /tmp/claudux-manifest-t9b /tmp/claudux-manifest-t9b-output /tmp/claudux-manifest-t9b-validate
rm -f /tmp/claudux-manifest-t12-output /tmp/claudux-manifest-t13-log.jsonl /tmp/claudux-manifest-t13-patches.json
rm -f /tmp/claudux-manifest-t13b /tmp/claudux-manifest-t13b-log.jsonl /tmp/claudux-manifest-t13b-output /tmp/claudux-manifest-t13b-patches.json
rm -f /tmp/claudux-manifest-t13c /tmp/claudux-manifest-t13c-log.jsonl /tmp/claudux-manifest-t13c-output /tmp/claudux-manifest-t13c-patches.json
rm -f /tmp/claudux-manifest-t14-index /tmp/claudux-manifest-t14-impact /tmp/claudux-manifest-t14-allowlist.json /tmp/claudux-manifest-t14-blocked
rm -f /tmp/claudux-manifest-t15-output /tmp/claudux-manifest-t16-output /tmp/claudux-manifest-t18-output
rm -f /tmp/claudux-manifest-t19 /tmp/claudux-manifest-t19-output /tmp/claudux-manifest-t20 /tmp/claudux-manifest-t20-output
rm -f /tmp/claudux-manifest-t21 /tmp/claudux-manifest-t21-output
rm -f /tmp/claudux-manifest-t22-schema /tmp/claudux-manifest-t22-schema-output /tmp/claudux-manifest-t22-disk /tmp/claudux-manifest-t22-disk-output
rm -f /tmp/claudux-manifest-t23
rm -f /tmp/claudux-section-patches-t11.json /tmp/claudux-section-patches-t12.json /tmp/claudux-section-patches-t14-allowed.json /tmp/claudux-section-patches-t14-blocked.json
rm -f /tmp/claudux-section-patches-t15.json /tmp/claudux-section-patches-t16.json

test_summary
