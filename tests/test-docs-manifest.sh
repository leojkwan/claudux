#!/bin/bash
# Tests: deterministic docs manifest validation and static index
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-harness.sh"

TEST_TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/claudux-docs-manifest-test.XXXXXX") || exit 1
trap 'rm -rf "$TEST_TMP_ROOT"' EXIT

echo "=== Docs Manifest Tests ==="
echo ""

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$REPO_ROOT/lib"

setup_manifest_repo() {
    local dir
    dir=$(mktemp -d "$TEST_TMP_ROOT/claudux-manifest-test-XXXXXX")
    (
        cd "$dir"
        git init -q
        git config user.email "test@test.com"
        git config user.name "Test"
        mkdir -p bin docs/api docs/guide docs/technical lib src tests
        printf '# Deterministic Generation\n\n## Pipeline\n\nBody.\n\n## Pinned Harness Example\n\nBody.\n\n## Generated Details\n\nOld generated body.\n\n## Unrelated Generated\n\nUnrelated body.\n' > docs/technical/deterministic-generation.md
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
            '  "deletion_policy": "manifest_pages_require_manifest_change",' \
            '  "generated_sections_default": "bounded_patch",' \
            '  "navigation": [' \
            '    { "id": "technical", "title": "Technical", "link": "/technical/deterministic-generation", "order": 1 },' \
            '    { "id": "api", "title": "API", "link": "/api/", "order": 2 }' \
            '  ],' \
            '  "pages": [' \
            '    {' \
            '      "id": "technical.deterministic-generation",' \
            '      "path": "docs/technical/deterministic-generation.md",' \
            '      "title": "Deterministic Generation",' \
            '      "nav_group": "technical",' \
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
            '          "id": "pinned-harness-example",' \
            '          "heading": "Pinned Harness Example",' \
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
            '      "nav_group": "api",' \
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
) > "$TEST_TMP_ROOT/claudux-manifest-t1" 2>&1
assert_contains "preflight manifest validation passes" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t1")" "[claudux:manifest] ok"
rm -rf "$TEST_DIR"

# --- Test 2: post-generation validates pinned headings on disk ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    validate_docs_structure_manifest --post-generation
) > "$TEST_TMP_ROOT/claudux-manifest-t2" 2>&1
assert_contains "post-generation validation passes" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t2")" "2 pinned sections"
rm -rf "$TEST_DIR"

# --- Test 3: post-generation fails when a pinned heading disappears ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    printf '# Deterministic Generation\n\n## Pipeline\n\nBody.\n' > docs/technical/deterministic-generation.md
    source "$LIB_DIR/docs-manifest.sh"
    if validate_docs_structure_manifest --post-generation >"$TEST_TMP_ROOT/claudux-manifest-t3-output" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t3-output"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t3" 2>&1
assert_contains "missing pinned heading fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t3")" 'missing required heading "Pinned Harness Example"'
rm -rf "$TEST_DIR"

# --- Test 3b: manifest page paths reject symlinks even when they stay inside docs ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    mv docs/technical/deterministic-generation.md docs/technical/deterministic-generation.real.md
    ln -s deterministic-generation.real.md docs/technical/deterministic-generation.md
    source "$LIB_DIR/docs-manifest.sh"
    if validate_docs_structure_manifest --post-generation >"$TEST_TMP_ROOT/claudux-manifest-t3b-output" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t3b-output"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t3b" 2>&1
assert_contains "manifest page symlink fails closed" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t3b")" "path must not traverse symlinks"
rm -rf "$TEST_DIR"

# --- Test 3c: manifest page paths cannot resolve outside repo/docs ---
TEST_DIR=$(setup_manifest_repo)
OUTSIDE_DIR=$(mktemp -d "$TEST_TMP_ROOT/claudux-manifest-outside-XXXXXX")
(
    cd "$TEST_DIR"
    cp docs/technical/deterministic-generation.md "$OUTSIDE_DIR/deterministic-generation.md"
    cp "$OUTSIDE_DIR/deterministic-generation.md" "$OUTSIDE_DIR/original.md"
    rm docs/technical/deterministic-generation.md
    rmdir docs/technical
    ln -s "$OUTSIDE_DIR" docs/technical
    source "$LIB_DIR/docs-manifest.sh"
    CLAUDUX_STATIC_INDEX_FILE="$TEST_DIR/.claudux/index/static-analysis.json"
    CLAUDUX_GUARD_SNAPSHOT_FILE="$TEST_DIR/.claudux/index/docs-guard-snapshot.json"
    printf '%s\n' \
        '{"patches":[{"page_id":"technical.deterministic-generation","section_id":"generated-details","body_markdown":"Must not escape."}]}' \
        > "$TEST_TMP_ROOT/claudux-section-patches-t3c.json"

    if build_static_analysis_index >"$TEST_TMP_ROOT/claudux-manifest-t3c-static" 2>&1; then
        echo "unexpected-static-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t3c-static"
    fi
    if capture_docs_structure_guard_snapshot >"$TEST_TMP_ROOT/claudux-manifest-t3c-guard" 2>&1; then
        echo "unexpected-guard-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t3c-guard"
    fi
    if apply_manifest_section_patches "$TEST_TMP_ROOT/claudux-section-patches-t3c.json" >"$TEST_TMP_ROOT/claudux-manifest-t3c-patch" 2>&1; then
        echo "unexpected-patch-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t3c-patch"
    fi
    cmp -s "$OUTSIDE_DIR/original.md" "$OUTSIDE_DIR/deterministic-generation.md" && echo "outside-target-unchanged:true"
) > "$TEST_TMP_ROOT/claudux-manifest-t3c" 2>&1
assert_contains "static index rejects outside manifest page" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t3c")" "manifest page path resolves outside repo/docs"
assert_contains "guard snapshot rejects outside manifest page" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t3c")" "technical.deterministic-generation: manifest page path resolves outside repo/docs"
assert_contains "section patcher rejects outside manifest page" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t3c")" "technical.deterministic-generation#generated-details manifest page path resolves outside repo/docs"
assert_contains "outside manifest target remains unchanged" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t3c")" "outside-target-unchanged:true"
rm -rf "$TEST_DIR" "$OUTSIDE_DIR"

# --- Test 4: static analysis index records sources, docs, scripts, manifest, and dependencies ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    CLAUDUX_INDEX_DIR="$TEST_DIR/.claudux/index"
    CLAUDUX_STATIC_INDEX_FILE="$TEST_DIR/.claudux/index/static-analysis.json"
    build_static_analysis_index >"$TEST_TMP_ROOT/claudux-manifest-t4-output"
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
) > "$TEST_TMP_ROOT/claudux-manifest-t4" 2>&1
assert_contains "static index captures deterministic facts" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t4")" "test"
assert_contains "static index captures shell dependency edges" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t4")" "edge=true"
assert_contains "static index captures CLI commands" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t4")" "commands=check,doctor,update"
assert_contains "static index captures exported shell functions" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t4")" "exports=true"
assert_contains "static index captures test files" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t4")" "tests=true"
assert_contains "static index captures docs links" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t4")" "link=true"
assert_contains "static index captures slash protected blocks" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t4")" "protected-ts=true"
assert_contains "static index captures css protected blocks literally" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t4")" "protected-css=true"
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
) > "$TEST_TMP_ROOT/claudux-manifest-t5" 2>&1
assert_contains "source ownership maps changed file to page" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t5")" "technical.deterministic-generation"
assert_contains "source ownership maps changed file to section" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t5")" "#pipeline"
assert_contains "dependency expansion reports edge" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t5")" "dependency-expanded scope: lib/ui.sh -> bin/claudux"
assert_contains "dependency-expanded file maps to page" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t5")" "bin/claudux -> api.index"
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
    cp "$CLAUDUX_STATIC_INDEX_FILE" "$TEST_TMP_ROOT/claudux-manifest-t5b-static-first.json"
    cp "$CLAUDUX_GUARD_SNAPSHOT_FILE" "$TEST_TMP_ROOT/claudux-manifest-t5b-guard-first.json"
    cp "$CLAUDUX_IMPACT_ALLOWLIST_FILE" "$TEST_TMP_ROOT/claudux-manifest-t5b-impact-first.json"

    sleep 1

    build_static_analysis_index >/dev/null
    capture_docs_structure_guard_snapshot >/dev/null
    CLAUDUX_CHANGED_FILES=$'lib/docs-manifest.sh\nREADME.md' CLAUDUX_IMPACT_ALLOWLIST_FILE="$CLAUDUX_IMPACT_ALLOWLIST_FILE" resolve_impacted_docs_from_changed_files >/dev/null

    cmp -s "$TEST_TMP_ROOT/claudux-manifest-t5b-static-first.json" "$CLAUDUX_STATIC_INDEX_FILE" && echo "static-index-stable:true"
    cmp -s "$TEST_TMP_ROOT/claudux-manifest-t5b-guard-first.json" "$CLAUDUX_GUARD_SNAPSHOT_FILE" && echo "guard-snapshot-stable:true"
    cmp -s "$TEST_TMP_ROOT/claudux-manifest-t5b-impact-first.json" "$CLAUDUX_IMPACT_ALLOWLIST_FILE" && echo "impact-allowlist-stable:true"
    node - "$CLAUDUX_STATIC_INDEX_FILE" "$CLAUDUX_GUARD_SNAPSHOT_FILE" "$CLAUDUX_IMPACT_ALLOWLIST_FILE" <<'NODE'
const fs = require('fs');
for (const file of process.argv.slice(2)) {
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  console.log(`${file.split('/').pop()}:generated_at=${Object.prototype.hasOwnProperty.call(data, 'generated_at')}`);
}
NODE
) > "$TEST_TMP_ROOT/claudux-manifest-t5b" 2>&1
assert_contains "static index is reproducible" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t5b")" "static-index-stable:true"
assert_contains "guard snapshot is reproducible" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t5b")" "guard-snapshot-stable:true"
assert_contains "impact allowlist is reproducible" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t5b")" "impact-allowlist-stable:true"
assert_contains "static index omits wall-clock timestamp" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t5b")" "static-analysis.json:generated_at=false"
assert_contains "guard snapshot omits wall-clock timestamp" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t5b")" "docs-guard-snapshot.json:generated_at=false"
assert_contains "impact allowlist omits wall-clock timestamp" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t5b")" "impacted-docs.json:generated_at=false"
rm -rf "$TEST_DIR"

# --- Test 5c: post-patch deterministic cache refresh records final docs bytes ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    source "$LIB_DIR/docs-generation.sh"
    CLAUDUX_INDEX_DIR="$TEST_DIR/.claudux/index"
    CLAUDUX_STATIC_INDEX_FILE="$TEST_DIR/.claudux/index/static-analysis.json"
    CLAUDUX_GUARD_SNAPSHOT_FILE="$TEST_DIR/.claudux/index/docs-guard-snapshot.json"
    CLAUDUX_IMPACT_ALLOWLIST_FILE="$TEST_DIR/.claudux/index/impacted-docs.json"

    build_static_analysis_index >/dev/null
    capture_docs_structure_guard_snapshot >/dev/null
    CLAUDUX_CHANGED_FILES=$'lib/docs-manifest.sh' CLAUDUX_IMPACT_ALLOWLIST_FILE="$CLAUDUX_IMPACT_ALLOWLIST_FILE" resolve_impacted_docs_from_changed_files >/dev/null
    cp "$CLAUDUX_STATIC_INDEX_FILE" "$TEST_TMP_ROOT/claudux-manifest-t5c-static-before.json"
    cp "$CLAUDUX_GUARD_SNAPSHOT_FILE" "$TEST_TMP_ROOT/claudux-manifest-t5c-guard-before.json"

    printf '%s\n' \
        '{' \
        '  "patches": [' \
        '    {' \
        '      "page_id": "technical.deterministic-generation",' \
        '      "section_id": "generated-details",' \
        '      "body_markdown": "Refreshed generated body.\n\nExtra line that shifts following section anchors."' \
        '    }' \
        '  ]' \
        '}' > "$TEST_TMP_ROOT/claudux-section-patches-t5c.json"
    CLAUDUX_IMPACT_ALLOWLIST_FILE="$CLAUDUX_IMPACT_ALLOWLIST_FILE" apply_manifest_section_patches "$TEST_TMP_ROOT/claudux-section-patches-t5c.json" >/dev/null

    refresh_deterministic_generation_caches $'lib/docs-manifest.sh' "$CLAUDUX_IMPACT_ALLOWLIST_FILE" >/dev/null
    if ! cmp -s "$TEST_TMP_ROOT/claudux-manifest-t5c-static-before.json" "$CLAUDUX_STATIC_INDEX_FILE"; then
        echo "static-index-refreshed:true"
    fi
    if ! cmp -s "$TEST_TMP_ROOT/claudux-manifest-t5c-guard-before.json" "$CLAUDUX_GUARD_SNAPSHOT_FILE"; then
        echo "guard-snapshot-refreshed:true"
    fi
    cp "$CLAUDUX_STATIC_INDEX_FILE" "$TEST_TMP_ROOT/claudux-manifest-t5c-static-after.json"
    cp "$CLAUDUX_GUARD_SNAPSHOT_FILE" "$TEST_TMP_ROOT/claudux-manifest-t5c-guard-after.json"
    cp "$CLAUDUX_IMPACT_ALLOWLIST_FILE" "$TEST_TMP_ROOT/claudux-manifest-t5c-impact-after.json"

    sleep 1
    refresh_deterministic_generation_caches $'lib/docs-manifest.sh' "$CLAUDUX_IMPACT_ALLOWLIST_FILE" >/dev/null

    cmp -s "$TEST_TMP_ROOT/claudux-manifest-t5c-static-after.json" "$CLAUDUX_STATIC_INDEX_FILE" && echo "static-index-stable-after-refresh:true"
    cmp -s "$TEST_TMP_ROOT/claudux-manifest-t5c-guard-after.json" "$CLAUDUX_GUARD_SNAPSHOT_FILE" && echo "guard-snapshot-stable-after-refresh:true"
    cmp -s "$TEST_TMP_ROOT/claudux-manifest-t5c-impact-after.json" "$CLAUDUX_IMPACT_ALLOWLIST_FILE" && echo "impact-allowlist-stable-after-refresh:true"
    node - "$CLAUDUX_STATIC_INDEX_FILE" docs/technical/deterministic-generation.md <<'NODE'
const fs = require('fs');
const crypto = require('crypto');
const index = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const docPath = process.argv[3];
const expected = crypto.createHash('sha256').update(fs.readFileSync(docPath)).digest('hex');
const actual = (index.docs_files || []).find(file => file.path === docPath)?.sha256;
console.log(`static-index-doc-sha-current:${actual === expected}`);
NODE
) > "$TEST_TMP_ROOT/claudux-manifest-t5c" 2>&1
assert_contains "post-patch refresh updates static index" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t5c")" "static-index-refreshed:true"
assert_contains "post-patch refresh updates guard snapshot" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t5c")" "guard-snapshot-refreshed:true"
assert_contains "post-patch static index is byte-stable" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t5c")" "static-index-stable-after-refresh:true"
assert_contains "post-patch guard snapshot is byte-stable" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t5c")" "guard-snapshot-stable-after-refresh:true"
assert_contains "post-patch impact allowlist is byte-stable" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t5c")" "impact-allowlist-stable-after-refresh:true"
assert_contains "post-patch static index records final docs bytes" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t5c")" "static-index-doc-sha-current:true"
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
    if validate_docs_structure_manifest >"$TEST_TMP_ROOT/claudux-manifest-t6-output" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t6-output"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t6" 2>&1
assert_contains "duplicate page IDs fail validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t6")" "duplicate page id"
rm -rf "$TEST_DIR"

# --- Test 7: guard snapshot passes when pinned headings and skip blocks survive ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    CLAUDUX_GUARD_SNAPSHOT_FILE="$TEST_DIR/.claudux/index/docs-guard-snapshot.json"
    capture_docs_structure_guard_snapshot >"$TEST_TMP_ROOT/claudux-manifest-t7-output"
    validate_docs_structure_guard_snapshot
) > "$TEST_TMP_ROOT/claudux-manifest-t7" 2>&1
assert_contains "guard snapshot validates unchanged docs" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t7")" "[claudux:guard] ok"
rm -rf "$TEST_DIR"

# --- Test 8: guard snapshot fails when protected skip content changes ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    CLAUDUX_GUARD_SNAPSHOT_FILE="$TEST_DIR/.claudux/index/docs-guard-snapshot.json"
    capture_docs_structure_guard_snapshot >"$TEST_TMP_ROOT/claudux-manifest-t8-output"
    printf '# Manual Notes\n\n<!-- skip -->\nRewritten generic text.\n<!-- /skip -->\n' > docs/manual.md
    if validate_docs_structure_guard_snapshot >"$TEST_TMP_ROOT/claudux-manifest-t8-validate" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t8-validate"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t8" 2>&1
assert_contains "guard snapshot catches changed protected content" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t8")" "protected skip block 1 changed"
rm -rf "$TEST_DIR"

# --- Test 8b: guard snapshot fails when source-language skip content changes ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    CLAUDUX_GUARD_SNAPSHOT_FILE="$TEST_DIR/.claudux/index/docs-guard-snapshot.json"
    capture_docs_structure_guard_snapshot >"$TEST_TMP_ROOT/claudux-manifest-t8b-output"
    printf 'export const publicValue = 1;\n\n// skip\nconst sourceOwnedSecret = "rewritten-generic-advice";\n// /skip\n\nexport const laterValue = 2;\n' > src/protected.ts
    if validate_docs_structure_guard_snapshot >"$TEST_TMP_ROOT/claudux-manifest-t8b-validate" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t8b-validate"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t8b" 2>&1
assert_contains "guard snapshot catches source protected content" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t8b")" "src/protected.ts: protected skip block 1 changed"
rm -rf "$TEST_DIR"

# --- Test 8c: static index and guard capture reject malformed protection markers ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    CLAUDUX_STATIC_INDEX_FILE="$TEST_DIR/.claudux/index/static-analysis.json"
    CLAUDUX_GUARD_SNAPSHOT_FILE="$TEST_DIR/.claudux/index/docs-guard-snapshot.json"
    build_static_analysis_index >/dev/null
    capture_docs_structure_guard_snapshot >/dev/null
    cp "$CLAUDUX_STATIC_INDEX_FILE" "$TEST_DIR/static-baseline.json"
    cp "$CLAUDUX_GUARD_SNAPSHOT_FILE" "$TEST_DIR/guard-baseline.json"

    run_malformed_marker_case() {
        local name="$1"
        local content="$2"
        printf '%s' "$content" > src/protected.ts

        if build_static_analysis_index >"$TEST_DIR/static-$name.log" 2>&1; then
            echo "unexpected-static-$name-pass"
        else
            cat "$TEST_DIR/static-$name.log"
        fi
        if capture_docs_structure_guard_snapshot >"$TEST_DIR/guard-$name.log" 2>&1; then
            echo "unexpected-guard-$name-pass"
        else
            cat "$TEST_DIR/guard-$name.log"
        fi
        cmp -s "$TEST_DIR/static-baseline.json" "$CLAUDUX_STATIC_INDEX_FILE" && echo "static-cache-$name-unchanged:true"
        cmp -s "$TEST_DIR/guard-baseline.json" "$CLAUDUX_GUARD_SNAPSHOT_FILE" && echo "guard-cache-$name-unchanged:true"
    }

    run_malformed_marker_case "unmatched-start" $'export const publicValue = 1;\n// skip\nconst protectedValue = 2;\n'
    run_malformed_marker_case "nested-start" $'// skip\nconst protectedValue = 2;\n// skip\n// /skip\n'
    run_malformed_marker_case "extra-end" $'export const publicValue = 1;\n// /skip\n'
) > "$TEST_TMP_ROOT/claudux-manifest-t8c" 2>&1
assert_contains "unmatched protection start marker fails closed" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t8c")" "unmatched protection start marker"
assert_contains "nested protection start marker fails closed" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t8c")" "nested protection start marker"
assert_contains "extra protection end marker fails closed" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t8c")" "unmatched protection end marker"
assert_contains "static index cache stays unchanged after marker failures" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t8c")" "static-cache-extra-end-unchanged:true"
assert_contains "guard snapshot cache stays unchanged after marker failures" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t8c")" "guard-cache-extra-end-unchanged:true"
rm -rf "$TEST_DIR"

# --- Test 9: guard snapshot fails when pinned heading order changes ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    CLAUDUX_GUARD_SNAPSHOT_FILE="$TEST_DIR/.claudux/index/docs-guard-snapshot.json"
    capture_docs_structure_guard_snapshot >"$TEST_TMP_ROOT/claudux-manifest-t9-output"
    printf '# Deterministic Generation\n\n## Pinned Harness Example\n\nBody.\n\n## Pipeline\n\nBody.\n' > docs/technical/deterministic-generation.md
    if validate_docs_structure_guard_snapshot >"$TEST_TMP_ROOT/claudux-manifest-t9-validate" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t9-validate"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t9" 2>&1
assert_contains "guard snapshot catches pinned heading reorder" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t9")" "pinned heading order changed"
rm -rf "$TEST_DIR"

# --- Test 9b: guard snapshot fails when a pinned section body changes without unlock ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    CLAUDUX_GUARD_SNAPSHOT_FILE="$TEST_DIR/.claudux/index/docs-guard-snapshot.json"
    capture_docs_structure_guard_snapshot >"$TEST_TMP_ROOT/claudux-manifest-t9b-output"
    printf '# Deterministic Generation\n\n## Pipeline\n\nRewritten generic test advice.\n\n## Pinned Harness Example\n\nBody.\n\n## Generated Details\n\nOld generated body.\n\n## Unrelated Generated\n\nUnrelated body.\n' > docs/technical/deterministic-generation.md
    if validate_docs_structure_guard_snapshot >"$TEST_TMP_ROOT/claudux-manifest-t9b-validate" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t9b-validate"
    fi
    CLAUDUX_UNLOCK_PINNED_SECTIONS=1 validate_docs_structure_guard_snapshot
) > "$TEST_TMP_ROOT/claudux-manifest-t9b" 2>&1
assert_contains "guard snapshot catches pinned body rewrite" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t9b")" "pinned section body changed"
assert_contains "guard snapshot permits explicit pinned unlock" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t9b")" "[claudux:guard] ok"
rm -rf "$TEST_DIR"

# --- Test 10: section patch contract lists generated sections and pins read-only doctrine ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    format_section_patch_contract
) > "$TEST_TMP_ROOT/claudux-manifest-t10" 2>&1
assert_contains "section patch contract lists generated section" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t10")" "technical.deterministic-generation#generated-details"
assert_contains "section patch contract lists pinned section as read-only" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t10")" "technical.deterministic-generation#pipeline"
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
        '}' > "$TEST_TMP_ROOT/claudux-section-patches-t11.json"
    apply_manifest_section_patches "$TEST_TMP_ROOT/claudux-section-patches-t11.json"
    cat docs/technical/deterministic-generation.md
) > "$TEST_TMP_ROOT/claudux-manifest-t11" 2>&1
assert_contains "section patcher applies generated body" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t11")" "New generated body."
assert_contains "section patcher permits code-fenced markdown headings" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t11")" "## Example inside code fence"
assert_contains "section patcher permits deeper generated subheadings" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t11")" "### Generated Subheading"
assert_contains "section patcher preserves pinned pipeline body" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t11")" "## Pipeline"
assert_contains "section patcher preserves pinned harness body" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t11")" "## Pinned Harness Example"
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
        '}' > "$TEST_TMP_ROOT/claudux-section-patches-t12.json"
    if apply_manifest_section_patches "$TEST_TMP_ROOT/claudux-section-patches-t12.json" >"$TEST_TMP_ROOT/claudux-manifest-t12-output" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t12-output"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t12" 2>&1
assert_contains "section patcher rejects pinned edits" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t12")" "is pinned/read-only"
rm -rf "$TEST_DIR"

# --- Test 13: section patch payload extraction reads JSONL assistant text ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    printf '%s\n' '{"type":"result","result":"CLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[{\"page_id\":\"technical.deterministic-generation\",\"section_id\":\"generated-details\",\"body_markdown\":\"Extracted body.\"}]}\nCLAUDUX_SECTION_PATCHES_JSON_END"}' > "$TEST_TMP_ROOT/claudux-manifest-t13-log.jsonl"
    extract_section_patch_payload "$TEST_TMP_ROOT/claudux-manifest-t13-log.jsonl" "$TEST_TMP_ROOT/claudux-manifest-t13-patches.json"
    node - "$TEST_TMP_ROOT/claudux-manifest-t13-patches.json" <<'NODE'
const fs = require('fs');
const payload = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
console.log(`${payload.patches.length}:${payload.patches[0].section_id}:${payload.patches[0].body_markdown}`);
NODE
) > "$TEST_TMP_ROOT/claudux-manifest-t13" 2>&1
assert_contains "section patch extraction captures payload" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t13")" "1:generated-details:Extracted body."
rm -rf "$TEST_DIR"

# --- Test 13b: section patch payload extraction tolerates repeated identical marker pairs ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    printf '%s\n' '{"type":"result","result":"CLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[{\"page_id\":\"technical.deterministic-generation\",\"section_id\":\"generated-details\",\"body_markdown\":\"Repeated body.\"}]}\nCLAUDUX_SECTION_PATCHES_JSON_END\nCLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[{\"page_id\":\"technical.deterministic-generation\",\"section_id\":\"generated-details\",\"body_markdown\":\"Repeated body.\"}]}\nCLAUDUX_SECTION_PATCHES_JSON_END"}' > "$TEST_TMP_ROOT/claudux-manifest-t13b-log.jsonl"
    extract_section_patch_payload "$TEST_TMP_ROOT/claudux-manifest-t13b-log.jsonl" "$TEST_TMP_ROOT/claudux-manifest-t13b-patches.json"
    node - "$TEST_TMP_ROOT/claudux-manifest-t13b-patches.json" <<'NODE'
const fs = require('fs');
const payload = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
console.log(`${payload.patches.length}:${payload.patches[0].section_id}:${payload.patches[0].body_markdown}`);
NODE
) > "$TEST_TMP_ROOT/claudux-manifest-t13b" 2>&1
assert_contains "section patch extraction deduplicates repeated marker pairs" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t13b")" "1:generated-details:Repeated body."
rm -rf "$TEST_DIR"

# --- Test 13c: section patch payload extraction rejects conflicting marker pairs ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    printf '%s\n' '{"type":"result","result":"CLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[{\"page_id\":\"technical.deterministic-generation\",\"section_id\":\"generated-details\",\"body_markdown\":\"First body.\"}]}\nCLAUDUX_SECTION_PATCHES_JSON_END\nCLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[{\"page_id\":\"technical.deterministic-generation\",\"section_id\":\"generated-details\",\"body_markdown\":\"Second body.\"}]}\nCLAUDUX_SECTION_PATCHES_JSON_END"}' > "$TEST_TMP_ROOT/claudux-manifest-t13c-log.jsonl"
    if extract_section_patch_payload "$TEST_TMP_ROOT/claudux-manifest-t13c-log.jsonl" "$TEST_TMP_ROOT/claudux-manifest-t13c-patches.json" >"$TEST_TMP_ROOT/claudux-manifest-t13c-output" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t13c-output"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t13c" 2>&1
assert_contains "section patch extraction rejects conflicting repeated payloads" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t13c")" "expected exactly one unique section patch payload"
rm -rf "$TEST_DIR"

# --- Test 13d: section patch payload extraction rejects orphaned markers ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    printf '%s\n' '{"type":"result","result":"CLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[]}"}' > "$TEST_TMP_ROOT/claudux-manifest-t13d-log.jsonl"
    if extract_section_patch_payload "$TEST_TMP_ROOT/claudux-manifest-t13d-log.jsonl" "$TEST_TMP_ROOT/claudux-manifest-t13d-patches.json" >"$TEST_TMP_ROOT/claudux-manifest-t13d-output" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t13d-output"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t13d" 2>&1
assert_contains "section patch extraction rejects orphaned markers" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t13d")" "section patch payload markers must be paired"
rm -rf "$TEST_DIR"

# --- Test 13e: section patch payload extraction tolerates duplicate JSONL echoes ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    printf '%s\n' \
        '{"type":"item.completed","item":{"type":"agent_message","text":"CLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[{\"page_id\":\"technical.deterministic-generation\",\"section_id\":\"generated-details\",\"body_markdown\":\"Echoed body.\"}]}\nCLAUDUX_SECTION_PATCHES_JSON_END"}}' \
        '{"type":"result","message":"CLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[{\"page_id\":\"technical.deterministic-generation\",\"section_id\":\"generated-details\",\"body_markdown\":\"Echoed body.\"}]}\nCLAUDUX_SECTION_PATCHES_JSON_END"}' \
        > "$TEST_TMP_ROOT/claudux-manifest-t13d-log.jsonl"
    extract_section_patch_payload "$TEST_TMP_ROOT/claudux-manifest-t13d-log.jsonl" "$TEST_TMP_ROOT/claudux-manifest-t13d-patches.json"
    node - "$TEST_TMP_ROOT/claudux-manifest-t13d-patches.json" <<'NODE'
const fs = require('fs');
const payload = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
console.log(`${payload.patches.length}:${payload.patches[0].section_id}:${payload.patches[0].body_markdown}`);
NODE
) > "$TEST_TMP_ROOT/claudux-manifest-t13e" 2>&1
assert_contains "section patch extraction deduplicates echoed payloads" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t13e")" "1:generated-details:Echoed body."
rm -rf "$TEST_DIR"

# --- Test 13f: section patch payload extraction rejects conflicting JSONL echoes ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    printf '%s\n' \
        '{"type":"item.completed","item":{"type":"agent_message","text":"CLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[{\"page_id\":\"technical.deterministic-generation\",\"section_id\":\"generated-details\",\"body_markdown\":\"First body.\"}]}\nCLAUDUX_SECTION_PATCHES_JSON_END"}}' \
        '{"type":"result","message":"CLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[{\"page_id\":\"technical.deterministic-generation\",\"section_id\":\"generated-details\",\"body_markdown\":\"Second body.\"}]}\nCLAUDUX_SECTION_PATCHES_JSON_END"}' \
        > "$TEST_TMP_ROOT/claudux-manifest-t13e-log.jsonl"
    if extract_section_patch_payload "$TEST_TMP_ROOT/claudux-manifest-t13e-log.jsonl" "$TEST_TMP_ROOT/claudux-manifest-t13e-patches.json" >"$TEST_TMP_ROOT/claudux-manifest-t13e-output" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t13e-output"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t13e" 2>&1
assert_contains "section patch extraction rejects conflicting payload echoes" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t13e")" "expected exactly one unique section patch payload"
rm -rf "$TEST_DIR"

# --- Test 13g: section patch payload extraction ignores truncated summary previews ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    printf '%s\n' \
        '{"type":"item.completed","item":{"type":"agent_message","text":"CLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[{\"page_id\":\"technical.deterministic-generation\",\"section_id\":\"generated-details\",\"body_markdown\":\"Summary-safe body.\"}]}\nCLAUDUX_SECTION_PATCHES_JSON_END"}}' \
        '{"type":"turn.completed","summary":"CLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[{\"page_id\":\"technical.deterministic-generation\""}' \
        > "$TEST_TMP_ROOT/claudux-manifest-t13g-log.jsonl"
    extract_section_patch_payload "$TEST_TMP_ROOT/claudux-manifest-t13g-log.jsonl" "$TEST_TMP_ROOT/claudux-manifest-t13g-patches.json"
    node - "$TEST_TMP_ROOT/claudux-manifest-t13g-patches.json" <<'NODE'
const fs = require('fs');
const payload = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
console.log(`${payload.patches.length}:${payload.patches[0].section_id}:${payload.patches[0].body_markdown}`);
NODE
) > "$TEST_TMP_ROOT/claudux-manifest-t13g" 2>&1
assert_contains "section patch extraction ignores truncated summary markers" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t13g")" "1:generated-details:Summary-safe body."
rm -rf "$TEST_DIR"

# --- Test 13h: section patch payload extraction ignores prompt/tool echoes ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    printf '%s\n' \
        '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"fixture: CLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[{\"page_id\":\"technical.deterministic-generation\",\"section_id\":\"generated-details\",\"body_markdown\":\"Fixture body.\"}]}\nCLAUDUX_SECTION_PATCHES_JSON_END"}]}}' \
        '{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","input":{"prompt":"CLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[{\"page_id\":\"technical.deterministic-generation\",\"section_id\":\"generated-details\",\"body_markdown\":\"Tool-use body.\"}]}\nCLAUDUX_SECTION_PATCHES_JSON_END"}},{"type":"text","text":"CLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[{\"page_id\":\"technical.deterministic-generation\",\"section_id\":\"generated-details\",\"body_markdown\":\"Generated body.\"}]}\nCLAUDUX_SECTION_PATCHES_JSON_END"}]}}' \
        '{"type":"result","result":"CLAUDUX_SECTION_PATCHES_JSON_START\n{\"patches\":[{\"page_id\":\"technical.deterministic-generation\",\"section_id\":\"generated-details\",\"body_markdown\":\"Generated body.\"}]}\nCLAUDUX_SECTION_PATCHES_JSON_END"}' \
        > "$TEST_TMP_ROOT/claudux-manifest-t13h-log.jsonl"
    extract_section_patch_payload "$TEST_TMP_ROOT/claudux-manifest-t13h-log.jsonl" "$TEST_TMP_ROOT/claudux-manifest-t13h-patches.json"
    node - "$TEST_TMP_ROOT/claudux-manifest-t13h-patches.json" <<'NODE'
const fs = require('fs');
const payload = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
console.log(`${payload.patches.length}:${payload.patches[0].section_id}:${payload.patches[0].body_markdown}`);
NODE
) > "$TEST_TMP_ROOT/claudux-manifest-t13h" 2>&1
assert_contains "section patch extraction ignores prompt/tool echoes" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t13h")" "1:generated-details:Generated body."
assert_not_contains "section patch extraction ignores fixture echo" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t13h")" "Fixture body."
assert_not_contains "section patch extraction ignores tool-use echo" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t13h")" "Tool-use body."
rm -rf "$TEST_DIR"

# --- Test 13i: section patch payload extraction preserves raw JSON lines inside plain marker blocks ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    printf '%s\n' \
        'CLAUDUX_SECTION_PATCHES_JSON_START' \
        '{"patches":[{"page_id":"technical.deterministic-generation","section_id":"generated-details","body_markdown":"First raw body."}]}' \
        'CLAUDUX_SECTION_PATCHES_JSON_END' \
        'CLAUDUX_SECTION_PATCHES_JSON_START' \
        '{"patches":[{"page_id":"technical.deterministic-generation","section_id":"generated-details","body_markdown":"Second raw body."}]}' \
        'CLAUDUX_SECTION_PATCHES_JSON_END' \
        > "$TEST_TMP_ROOT/claudux-manifest-t13i-log.txt"
    if extract_section_patch_payload "$TEST_TMP_ROOT/claudux-manifest-t13i-log.txt" "$TEST_TMP_ROOT/claudux-manifest-t13i-patches.json" >"$TEST_TMP_ROOT/claudux-manifest-t13i-output" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t13i-output"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t13i" 2>&1
assert_contains "section patch extraction rejects conflicting raw payload blocks" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t13i")" "expected exactly one unique section patch payload"
rm -rf "$TEST_DIR"

# --- Test 14: incremental impact allowlist blocks unrelated generated sections ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    build_static_analysis_index >"$TEST_TMP_ROOT/claudux-manifest-t14-index"
    CLAUDUX_CHANGED_FILES=$'lib/docs-manifest.sh' CLAUDUX_IMPACT_ALLOWLIST_FILE="$TEST_TMP_ROOT/claudux-manifest-t14-allowlist.json" resolve_impacted_docs_from_changed_files >"$TEST_TMP_ROOT/claudux-manifest-t14-impact"
    printf '%s\n' \
        '{' \
        '  "patches": [' \
        '    {' \
        '      "page_id": "technical.deterministic-generation",' \
        '      "section_id": "generated-details",' \
        '      "body_markdown": "Allowed incremental body."' \
        '    }' \
        '  ]' \
        '}' > "$TEST_TMP_ROOT/claudux-section-patches-t14-allowed.json"
    CLAUDUX_IMPACT_ALLOWLIST_FILE="$TEST_TMP_ROOT/claudux-manifest-t14-allowlist.json" apply_manifest_section_patches "$TEST_TMP_ROOT/claudux-section-patches-t14-allowed.json"
    printf '%s\n' \
        '{' \
        '  "patches": [' \
        '    {' \
        '      "page_id": "technical.deterministic-generation",' \
        '      "section_id": "unrelated-generated",' \
        '      "body_markdown": "Out of scope body."' \
        '    }' \
        '  ]' \
        '}' > "$TEST_TMP_ROOT/claudux-section-patches-t14-blocked.json"
    if CLAUDUX_IMPACT_ALLOWLIST_FILE="$TEST_TMP_ROOT/claudux-manifest-t14-allowlist.json" apply_manifest_section_patches "$TEST_TMP_ROOT/claudux-section-patches-t14-blocked.json" >"$TEST_TMP_ROOT/claudux-manifest-t14-blocked" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t14-blocked"
    fi
    unset CLAUDUX_IMPACT_ALLOWLIST_FILE
    apply_manifest_section_patches "$TEST_TMP_ROOT/claudux-section-patches-t14-blocked.json"
    cat docs/technical/deterministic-generation.md
) > "$TEST_TMP_ROOT/claudux-manifest-t14" 2>&1
assert_contains "impact allowlist records section" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t14-impact")" "lib/docs-manifest.sh -> technical.deterministic-generation#generated-details"
assert_contains "incremental allowlist permits impacted section" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t14")" "Allowed incremental body."
assert_contains "incremental allowlist blocks unrelated section" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t14")" "outside incremental impact allowlist"
assert_contains "full scan still allows generated section" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t14")" "Out of scope body."
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
        '}' > "$TEST_TMP_ROOT/claudux-section-patches-t15.json"
    if apply_manifest_section_patches "$TEST_TMP_ROOT/claudux-section-patches-t15.json" >"$TEST_TMP_ROOT/claudux-manifest-t15-output" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t15-output"
    fi
    cat docs/technical/deterministic-generation.md
) > "$TEST_TMP_ROOT/claudux-manifest-t15" 2>&1
assert_contains "section patcher rejects invalid mixed batch" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t15")" "is pinned/read-only"
assert_contains "section patcher leaves original generated body after failed batch" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t15")" "Old generated body."
assert_not_contains "section patcher does not partially write failed batch" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t15")" "Should not land."
rm -rf "$TEST_DIR"

# --- Test 15b: multi-file section patch commits roll back on later I/O failure ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    node - <<'NODE'
const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync('docs-structure.json', 'utf8'));
manifest.pages[1].sections = [{
  id: 'generated-api',
  heading: 'Generated API',
  level: 2,
  source_patterns: ['bin/claudux'],
}];
fs.writeFileSync('docs-structure.json', `${JSON.stringify(manifest, null, 2)}\n`);
NODE
    printf '# API\n\nDocumented commands.\n\n## Generated API\n\nOld API body.\n' > docs/api/index.md
    cp docs/api/index.md "$TEST_DIR/api-before.md"
    cp docs/technical/deterministic-generation.md "$TEST_DIR/technical-before.md"
    source "$LIB_DIR/docs-manifest.sh"
    printf '%s\n' \
        '{' \
        '  "patches": [' \
        '    {' \
        '      "page_id": "technical.deterministic-generation",' \
        '      "section_id": "generated-details",' \
        '      "body_markdown": "New technical body."' \
        '    },' \
        '    {' \
        '      "page_id": "api.index",' \
        '      "section_id": "generated-api",' \
        '      "body_markdown": "New API body."' \
        '    }' \
        '  ]' \
        '}' > "$TEST_TMP_ROOT/claudux-section-patches-t15b.json"
    if CLAUDUX_TEST_MODE=1 CLAUDUX_TEST_FAIL_SECTION_PATCH_COMMIT_AT=2 \
        apply_manifest_section_patches "$TEST_TMP_ROOT/claudux-section-patches-t15b.json" >"$TEST_TMP_ROOT/claudux-manifest-t15b-output" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t15b-output"
    fi
    cmp -s "$TEST_DIR/api-before.md" docs/api/index.md && echo "api-rollback:true"
    cmp -s "$TEST_DIR/technical-before.md" docs/technical/deterministic-generation.md && echo "technical-rollback:true"
    if ! find docs -type d -name '.claudux-section-patch-*' -print -quit | grep -q .; then
        echo "transaction-staging-clean:true"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t15b" 2>&1
assert_contains "later-file patch I/O failure is reported" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t15b")" "transactional commit failed (EIO: test-injected I/O failure"
assert_contains "earlier committed page is rolled back" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t15b")" "api-rollback:true"
assert_contains "later page remains unchanged" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t15b")" "technical-rollback:true"
assert_contains "transaction staging files are cleaned" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t15b")" "transaction-staging-clean:true"
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
        '}' > "$TEST_TMP_ROOT/claudux-section-patches-t16.json"
    if apply_manifest_section_patches "$TEST_TMP_ROOT/claudux-section-patches-t16.json" >"$TEST_TMP_ROOT/claudux-manifest-t16-output" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t16-output"
    fi
    cat docs/technical/deterministic-generation.md
) > "$TEST_TMP_ROOT/claudux-manifest-t16" 2>&1
assert_contains "section patcher rejects same-level headings in body" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t16")" "section patches cannot create same-or-higher-level headings"
assert_contains "section patcher preserves original body after boundary rejection" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t16")" "Old generated body."
assert_not_contains "section patcher does not write escaping body" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t16")" "This would become a sibling section."
rm -rf "$TEST_DIR"

# --- Test 16b: section patcher rejects transient cache-provenance prose ---
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
        '      "body_markdown": "For this dogfood refresh, the current static-analysis snapshot reports 75 source files, 15 documentation files, 34 dependency edges, and ownership hash `9d2f1eae1fa5`."' \
        '    }' \
        '  ]' \
        '}' > "$TEST_TMP_ROOT/claudux-section-patches-t16b.json"
    if apply_manifest_section_patches "$TEST_TMP_ROOT/claudux-section-patches-t16b.json" >"$TEST_TMP_ROOT/claudux-manifest-t16b-output" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t16b-output"
    fi
    cat docs/technical/deterministic-generation.md
) > "$TEST_TMP_ROOT/claudux-manifest-t16b" 2>&1
assert_contains "section patcher rejects cache provenance prose" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t16b")" "transient cache-provenance prose"
assert_contains "section patcher preserves original body after provenance rejection" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t16b")" "Old generated body."
assert_not_contains "section patcher does not write transient cache prose" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t16b")" "For this dogfood refresh"
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
) > "$TEST_TMP_ROOT/claudux-manifest-t17" 2>&1
assert_contains "cleanup guard blocks AI deletion with manifest" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t17")" "Manifest deletion guard active"
assert_contains "cleanup guard preserves manifest page" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t17")" "manifest-page-still-exists"
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
    if validate_docs_structure_manifest >"$TEST_TMP_ROOT/claudux-manifest-t19-output" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t19-output"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t19" 2>&1
assert_contains "empty source pattern fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t19")" "source_patterns[2] must not be empty"
assert_contains "non-string section source pattern fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t19")" "source_patterns[1] must be a string"
rm -rf "$TEST_DIR"

# --- Test 20: manifest rejects source patterns that escape the repo root ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    node - <<'NODE'
const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync('docs-structure.json', 'utf8'));
manifest.pages[0].source_patterns.push('/tmp/outside.sh');
manifest.pages[0].source_patterns.push('C:tmp/outside.sh');
manifest.pages[0].sections[0].source_patterns.push('../demo-app/scripts/run-local-harness.mjs');
fs.writeFileSync('docs-structure.json', `${JSON.stringify(manifest, null, 2)}\n`);
NODE
    source "$LIB_DIR/docs-manifest.sh"
    if validate_docs_structure_manifest >"$TEST_TMP_ROOT/claudux-manifest-t20-output" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t20-output"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t20" 2>&1
assert_contains "absolute source pattern fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t20")" "source_patterns[2] must be repo-root relative"
assert_contains "windows drive-relative source pattern fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t20")" "source_patterns[3] must be repo-root relative"
assert_contains "parent traversal source pattern fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t20")" "source_patterns[1] must be repo-root relative"
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
    if validate_docs_structure_manifest >"$TEST_TMP_ROOT/claudux-manifest-t21-output" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t21-output"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t21" 2>&1
assert_contains "duplicate navigation order fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t21")" "duplicate navigation order 1"
assert_contains "duplicate page order fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t21")" "duplicate page order 110"
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
    if validate_docs_structure_manifest >"$TEST_TMP_ROOT/claudux-manifest-t22-schema-output" 2>&1; then
        echo "unexpected-schema-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t22-schema-output"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t22-schema" 2>&1
assert_contains "duplicate manifest section anchor fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t22-schema")" 'duplicate section heading anchor h2 "Pipeline"'
rm -rf "$TEST_DIR"

TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    printf '\n## Generated Details\n\nAmbiguous generated body.\n' >> docs/technical/deterministic-generation.md
    source "$LIB_DIR/docs-manifest.sh"
    if validate_docs_structure_manifest --post-generation >"$TEST_TMP_ROOT/claudux-manifest-t22-disk-output" 2>&1; then
        echo "unexpected-disk-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t22-disk-output"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t22-disk" 2>&1
assert_contains "duplicate on-disk section anchor fails post-generation validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t22-disk")" 'duplicate manifest heading anchor h2 "Generated Details"'
rm -rf "$TEST_DIR"

# --- Test 23: docs-structure.json takes prompt precedence over legacy docs-map.md ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    printf '# Legacy Docs Map\n\nLoose advisory structure.\n' > docs-map.md
    source "$LIB_DIR/docs-manifest.sh"
    source "$LIB_DIR/docs-generation.sh"
    build_generation_prompt "generic" "Prompt Precedence Test"
) > "$TEST_TMP_ROOT/claudux-manifest-t23" 2>&1
assert_contains "prompt reads docs-structure as deterministic manifest when docs-map also exists" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t23")" "Read docs-structure.json as the deterministic docs manifest"
assert_contains "prompt keeps docs-map as supplemental legacy guidance" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t23")" "Read docs-map.md as supplemental legacy guidance only"
assert_not_contains "prompt does not demote docs-map to primary loose guidance" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t23")" "Read docs-map.md for loose documentation guidance"
rm -rf "$TEST_DIR"

# --- Test 24: manifest boolean authority fields must be real booleans ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    node - <<'NODE'
const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync('docs-structure.json', 'utf8'));
manifest.pages[0].sections[0].pinned = 'true';
manifest.pages[0].sections[1].required = 'false';
manifest.pages[0].sections[2].generated = 'false';
fs.writeFileSync('docs-structure.json', `${JSON.stringify(manifest, null, 2)}\n`);
NODE
    source "$LIB_DIR/docs-manifest.sh"
    if validate_docs_structure_manifest >"$TEST_TMP_ROOT/claudux-manifest-t24-output" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t24-output"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t24" 2>&1
assert_contains "string pinned field fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t24")" "pipeline: pinned must be a boolean"
assert_contains "string required field fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t24")" "pinned-harness-example: required must be a boolean"
assert_contains "string generated field fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t24")" "generated-details: generated must be a boolean"
rm -rf "$TEST_DIR"

# --- Test 25: manifest policy fields must use known deterministic enums ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    node - <<'NODE'
const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync('docs-structure.json', 'utf8'));
manifest.deletion_policy = 'model_may_delete_unused_pages';
manifest.generated_sections_default = 'direct_write';
manifest.pages[0].deletion_policy = 'delete_when_model_says_obsolete';
fs.writeFileSync('docs-structure.json', `${JSON.stringify(manifest, null, 2)}\n`);
NODE
    source "$LIB_DIR/docs-manifest.sh"
    if validate_docs_structure_manifest >"$TEST_TMP_ROOT/claudux-manifest-t25-output" 2>&1; then
        echo "unexpected-pass"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t25-output"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t25" 2>&1
assert_contains "unknown root deletion policy fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t25")" "root: deletion_policy must be one of: manifest_pages_require_manifest_change"
assert_contains "unknown generated section default fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t25")" "root: generated_sections_default must be one of: bounded_patch"
assert_contains "unknown page deletion policy fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t25")" "technical.deterministic-generation: deletion_policy must be one of: never_delete_without_manifest_change"
rm -rf "$TEST_DIR"

# --- Test 26: manifest navigation links must resolve to manifest pages ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    node - <<'NODE'
const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync('docs-structure.json', 'utf8'));
manifest.navigation[0].title = '   ';
manifest.navigation[0].link = 'https://example.com/docs';
manifest.navigation[1].link = '/missing/';
fs.writeFileSync('docs-structure.json', `${JSON.stringify(manifest, null, 2)}\n`);
NODE
    source "$LIB_DIR/docs-manifest.sh"
    if validate_docs_structure_manifest >"$TEST_TMP_ROOT/claudux-manifest-t26-output" 2>&1; then
        echo "expected navigation link validation to fail"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t26-output"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t26" 2>&1
assert_contains "blank navigation title fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t26")" "technical: missing string title"
assert_contains "external navigation link fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t26")" "technical: link must be a root-relative docs link"
assert_contains "missing navigation target fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t26")" 'api: link "/missing/" must resolve to a manifest page (docs/missing/index.md)'
rm -rf "$TEST_DIR"

# --- Test 27: manifest IDs and nav groups must be stable patch keys ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    node - <<'NODE'
const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync('docs-structure.json', 'utf8'));
manifest.navigation[0].id = 'technical/docs';
manifest.pages[0].id = 'technical#deterministic-generation';
manifest.pages[0].nav_group = 'tech docs';
manifest.pages[0].sections[0].id = 'pipeline#rewrite';
fs.writeFileSync('docs-structure.json', `${JSON.stringify(manifest, null, 2)}\n`);
NODE
    source "$LIB_DIR/docs-manifest.sh"
    if validate_docs_structure_manifest >"$TEST_TMP_ROOT/claudux-manifest-t27-output" 2>&1; then
        echo "expected manifest key validation to fail"
    else
        cat "$TEST_TMP_ROOT/claudux-manifest-t27-output"
    fi
) > "$TEST_TMP_ROOT/claudux-manifest-t27" 2>&1
assert_contains "unsafe navigation id fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t27")" "technical/docs: id must be a stable manifest key"
assert_contains "unsafe page id fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t27")" "technical#deterministic-generation: id must be a stable manifest key"
assert_contains "unsafe nav group fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t27")" "technical#deterministic-generation: nav_group must be a stable manifest key"
assert_contains "unsafe section id fails validation" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t27")" "pipeline#rewrite: id must be a stable manifest key"
rm -rf "$TEST_DIR"

# --- Test 28: check mode reports drift and writes nothing ---
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
        '      "body_markdown": "New generated body that differs from disk."' \
        '    }' \
        '  ]' \
        '}' > "$TEST_TMP_ROOT/claudux-section-patches-t28.json"
    rc=0
    CLAUDUX_CHECK_MODE=1 apply_manifest_section_patches "$TEST_TMP_ROOT/claudux-section-patches-t28.json" >"$TEST_TMP_ROOT/claudux-manifest-t28-output" 2>&1 || rc=$?
    echo "rc=$rc"
    cat "$TEST_TMP_ROOT/claudux-manifest-t28-output"
    echo "-- disk state --"
    cat docs/technical/deterministic-generation.md
) > "$TEST_TMP_ROOT/claudux-manifest-t28" 2>&1
assert_contains "check mode exits 2 on drift" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t28")" "rc=2"
assert_contains "check mode reports drift" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t28")" "drift detected"
assert_contains "check mode names the drifting file" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t28")" "docs/technical/deterministic-generation.md"
assert_contains "check mode leaves old body on disk" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t28")" "Old generated body."
assert_not_contains "check mode never writes the new body" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t28")" "New generated body that differs from disk."
rm -rf "$TEST_DIR"

# --- Test 28b: an unchanged proposal cannot establish source coverage ---
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    printf '\nnew_public_command() { echo undocumented; }\n' >> lib/docs-manifest.sh
    printf '%s\n' \
        '{' \
        '  "patches": [' \
        '    {' \
        '      "page_id": "technical.deterministic-generation",' \
        '      "section_id": "generated-details",' \
        '      "body_markdown": "Old generated body."' \
        '    }' \
        '  ]' \
        '}' > "$TEST_TMP_ROOT/claudux-section-patches-t28b.json"
    rc=0
    CLAUDUX_CHECK_MODE=1 apply_manifest_section_patches "$TEST_TMP_ROOT/claudux-section-patches-t28b.json" >"$TEST_TMP_ROOT/claudux-manifest-t28b-output" 2>&1 || rc=$?
    echo "rc=$rc"
    cat "$TEST_TMP_ROOT/claudux-manifest-t28b-output"
) > "$TEST_TMP_ROOT/claudux-manifest-t28b" 2>&1
assert_contains "check mode exits 0 when clean" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t28b")" "rc=0"
assert_contains "check mode reports no drift" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t28b")" "no drift"
assert_not_contains "unchanged proposal cannot claim source coverage" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t28b")" "documentation matches sources"
rm -rf "$TEST_DIR"

# --- Test 28c: check mode still fails hard on pinned violations ---
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
        '}' > "$TEST_TMP_ROOT/claudux-section-patches-t28c.json"
    rc=0
    CLAUDUX_CHECK_MODE=1 apply_manifest_section_patches "$TEST_TMP_ROOT/claudux-section-patches-t28c.json" >"$TEST_TMP_ROOT/claudux-manifest-t28c-output" 2>&1 || rc=$?
    echo "rc=$rc"
    cat "$TEST_TMP_ROOT/claudux-manifest-t28c-output"
) > "$TEST_TMP_ROOT/claudux-manifest-t28c" 2>&1
assert_contains "check mode rejects pinned edits with error rc" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t28c")" "rc=1"
assert_contains "check mode rejects pinned edits" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t28c")" "is pinned/read-only"
rm -rf "$TEST_DIR"

# --- Test 28d: a section patch never rewrites bytes outside its own section ---
# The pinned section holds a fenced block with two consecutive blank lines.
# An identical proposal must report no drift, and a real patch to the
# generated section must leave the pinned section byte-identical.
TEST_DIR=$(setup_manifest_repo)
(
    cd "$TEST_DIR"
    source "$LIB_DIR/docs-manifest.sh"
    printf '# Deterministic Generation\n\n## Pipeline\n\n```text\nline one\n\n\nline four\n```\n\n## Pinned Harness Example\n\nBody.\n\n## Generated Details\n\nOld generated body.\n\n## Unrelated Generated\n\nUnrelated body.\n' > docs/technical/deterministic-generation.md
    git add docs/technical/deterministic-generation.md
    git -c user.email=t@t -c user.name=T commit -q -m "pinned fence with blank lines"
    printf '%s\n' \
        '{' \
        '  "patches": [' \
        '    {' \
        '      "page_id": "technical.deterministic-generation",' \
        '      "section_id": "generated-details",' \
        '      "body_markdown": "Old generated body."' \
        '    }' \
        '  ]' \
        '}' > "$TEST_TMP_ROOT/claudux-section-patches-t28d-same.json"
    rc=0
    CLAUDUX_CHECK_MODE=1 apply_manifest_section_patches "$TEST_TMP_ROOT/claudux-section-patches-t28d-same.json" >"$TEST_TMP_ROOT/claudux-manifest-t28d-check" 2>&1 || rc=$?
    echo "check rc=$rc"
    cat "$TEST_TMP_ROOT/claudux-manifest-t28d-check"

    capture_docs_structure_guard_snapshot >/dev/null
    printf '%s\n' \
        '{' \
        '  "patches": [' \
        '    {' \
        '      "page_id": "technical.deterministic-generation",' \
        '      "section_id": "generated-details",' \
        '      "body_markdown": "New generated body."' \
        '    }' \
        '  ]' \
        '}' > "$TEST_TMP_ROOT/claudux-section-patches-t28d-new.json"
    apply_manifest_section_patches "$TEST_TMP_ROOT/claudux-section-patches-t28d-new.json" >/dev/null 2>&1
    rc=0
    validate_docs_structure_guard_snapshot >"$TEST_TMP_ROOT/claudux-manifest-t28d-guard" 2>&1 || rc=$?
    echo "guard rc=$rc"
    cat "$TEST_TMP_ROOT/claudux-manifest-t28d-guard"
    echo "-- numstat --"
    git diff --numstat -- docs/technical/deterministic-generation.md | cut -f1,2
) > "$TEST_TMP_ROOT/claudux-manifest-t28d" 2>&1
assert_contains "identical proposal reports no drift despite blank lines elsewhere" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t28d")" "check rc=0"
assert_contains "pinned fence survives a patch to another section" "$(cat "$TEST_TMP_ROOT/claudux-manifest-t28d")" "guard rc=0"
assert_eq "only the generated section changed (one line in, one line out)" $'1\t1' "$(sed -n '/-- numstat --/,$p' "$TEST_TMP_ROOT/claudux-manifest-t28d" | tail -n +2)"
rm -rf "$TEST_DIR"

test_summary
