#!/bin/bash
# Standalone fixture tests for VitePress config and Markdown link validation.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VALIDATOR="$REPO_ROOT/lib/validate-links.sh"

source "$SCRIPT_DIR/test-harness.sh"

FIXTURE_ROOT=$(mktemp -d /tmp/claudux-link-validation-XXXXXX)
trap 'rm -rf "$FIXTURE_ROOT"' EXIT

create_config() {
    local fixture="$1"
    local links="$2"
    mkdir -p "$fixture/docs/.vitepress"
    cat > "$fixture/docs/.vitepress/config.ts" <<EOF
export default {
  themeConfig: {
    nav: [
$links
    ]
  }
}
EOF
}

run_validator() {
    local fixture="$1"
    local output_file="$2"
    VALIDATION_OUTPUT=$(cd "$fixture" && bash "$VALIDATOR" --output "$output_file" 2>&1)
    VALIDATION_RC=$?
}

echo "=== Link Validation Tests ==="
echo ""

run_validator "$REPO_ROOT" "$FIXTURE_ROOT/current-repo-broken-targets.txt"
assert_exit_code "current repository links pass" 0 "$VALIDATION_RC"
assert_contains "current repository reports success" "$VALIDATION_OUTPUT" "All internal links validated successfully"

# Extensionless repository files such as LICENSE are not Markdown routes.
LICENSE_FIXTURE="$FIXTURE_ROOT/license"
create_config "$LICENSE_FIXTURE" "      { text: 'Home', link: '/' }"
printf '# Home\n' > "$LICENSE_FIXTURE/docs/index.md"
printf '# Project\n\n[License](LICENSE)\n' > "$LICENSE_FIXTURE/README.md"
printf 'MIT License\n' > "$LICENSE_FIXTURE/LICENSE"
run_validator "$LICENSE_FIXTURE" "$LICENSE_FIXTURE/broken-targets.txt"
assert_exit_code "extensionless repository file passes" 0 "$VALIDATION_RC"

# Valid config routes, Markdown routes, assets, generated anchors, explicit
# anchors, repeated VitePress slugs, and reference links.
VALID_FIXTURE="$FIXTURE_ROOT/valid"
mkdir -p \
    "$VALID_FIXTURE/docs/guide" \
    "$VALID_FIXTURE/docs/assets" \
    "$VALID_FIXTURE/assets" \
    "$VALID_FIXTURE/docs/public/images"
create_config "$VALID_FIXTURE" \
"      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide/' },
      { text: 'Custom anchor', link: '/guide/page#custom-id' },
      { text: 'External', link: 'https://example.invalid/not-fetched' },
      { text: 'Mail', link: 'mailto:docs@example.invalid' },
      { text: 'Phone', link: 'tel:+15555550100' }"
cat > "$VALID_FIXTURE/README.md" <<'EOF'
# Project

[Architecture](./ARCHITECTURE.md)
[Guide](./docs/guide/)
![Banner](./assets/banner.svg)
EOF
printf '# Architecture\n' > "$VALID_FIXTURE/ARCHITECTURE.md"
printf '<svg xmlns="http://www.w3.org/2000/svg"/>\n' > "$VALID_FIXTURE/assets/banner.svg"
cat > "$VALID_FIXTURE/docs/index.md" <<'EOF'
# Home Heading

[Guide](/guide/)
[Same page](#home-heading)
[Entity heading](#fish-amp-chips)
[Cross page](./guide/page#cafe-setup)
[Repeated heading](/guide/page#repeated-heading-1)
[Explicit heading][custom-heading]
[custom-heading]: ./guide/page.md#custom-id

![Relative asset](./assets/local.svg)
![Root public asset](/images/public.svg)

[External](https://example.invalid/not-fetched)
[Email](mailto:docs@example.invalid)
[Phone](tel:+15555550100)

`[Ignored inline code](./missing-inline.md)`

## Fish &amp; Chips

```md
[Ignored fenced code](./missing-fenced.md)
```
EOF
cat > "$VALID_FIXTURE/docs/guide/index.md" <<'EOF'
# Guide

[Page](./page#generated-heading)
EOF
cat > "$VALID_FIXTURE/docs/guide/page.md" <<'EOF'
# Generated Heading

## Café & Setup

## Repeated Heading

## Repeated Heading

## Custom Heading {#custom-id}
EOF
printf '<svg xmlns="http://www.w3.org/2000/svg"/>\n' > "$VALID_FIXTURE/docs/assets/local.svg"
printf '<svg xmlns="http://www.w3.org/2000/svg"/>\n' > "$VALID_FIXTURE/docs/public/images/public.svg"

run_validator "$VALID_FIXTURE" "$VALID_FIXTURE/broken-targets.txt"
assert_exit_code "valid routes, assets, and anchors pass" 0 "$VALIDATION_RC"
assert_contains "valid fixture reports success" "$VALIDATION_OUTPUT" "All internal links validated successfully"
assert_contains "external, mail, and tel links are skipped" "$VALIDATION_OUTPUT" "External links:"
if [[ -s "$VALID_FIXTURE/broken-targets.txt" ]]; then
    assert_eq "valid fixture leaves no broken-target report" "empty" "non-empty"
else
    assert_eq "valid fixture leaves no broken-target report" "empty" "empty"
fi

printf 'stale-target.md\n' > "$VALID_FIXTURE/broken-targets.txt"
run_validator "$VALID_FIXTURE" "$VALID_FIXTURE/broken-targets.txt"
if [[ -s "$VALID_FIXTURE/broken-targets.txt" ]]; then
    assert_eq "successful validation clears stale broken-target output" "empty" "non-empty"
else
    assert_eq "successful validation clears stale broken-target output" "empty" "empty"
fi

# Missing Markdown page, local image asset, and cross-page anchor are all
# reported with resolved targets.
BROKEN_FIXTURE="$FIXTURE_ROOT/broken"
mkdir -p "$BROKEN_FIXTURE/docs/.vitepress"
create_config "$BROKEN_FIXTURE" "      { text: 'Home', link: '/' }"
cat > "$BROKEN_FIXTURE/README.md" <<'EOF'
# Project

[Missing root page](./ARCHITECTURE-missing.md)
EOF
cat > "$BROKEN_FIXTURE/docs/index.md" <<'EOF'
# Home

[Missing page](./missing-page.md)
![Missing asset](./assets/missing.svg)
[Missing anchor](./target.md#not-present)
EOF
cat > "$BROKEN_FIXTURE/docs/target.md" <<'EOF'
# Present Anchor
EOF

run_validator "$BROKEN_FIXTURE" "$BROKEN_FIXTURE/broken-targets.txt"
assert_exit_code "broken Markdown targets fail validation" 1 "$VALIDATION_RC"
assert_contains "summary counts README and docs targets" "$VALIDATION_OUTPUT" "Broken links: 4"
assert_contains "missing README page is named" "$VALIDATION_OUTPUT" "Missing page: ARCHITECTURE-missing.md"
assert_contains "missing Markdown page is named" "$VALIDATION_OUTPUT" "Missing page: docs/missing-page.md"
assert_contains "missing image asset is named" "$VALIDATION_OUTPUT" "Missing asset: docs/assets/missing.svg"
assert_contains "missing cross-page anchor is named" "$VALIDATION_OUTPUT" "Missing anchor '#not-present' in docs/target.md"
BROKEN_TARGETS=$(cat "$BROKEN_FIXTURE/broken-targets.txt")
assert_contains "output report includes missing README page" "$BROKEN_TARGETS" "ARCHITECTURE-missing.md"
assert_contains "output report includes missing page" "$BROKEN_TARGETS" "docs/missing-page.md"
assert_contains "output report includes missing asset" "$BROKEN_TARGETS" "docs/assets/missing.svg"
assert_contains "output report includes missing anchor" "$BROKEN_TARGETS" "docs/target.md#not-present"

# A real file outside docs must not make a traversal link valid.
ESCAPE_FIXTURE="$FIXTURE_ROOT/escape"
mkdir -p "$ESCAPE_FIXTURE/docs"
create_config "$ESCAPE_FIXTURE" "      { text: 'Home', link: '/' }"
cat > "$ESCAPE_FIXTURE/README.md" <<'EOF'
# Project

[Outside repository](../outside-root.md)
EOF
cat > "$ESCAPE_FIXTURE/docs/index.md" <<'EOF'
# Home

[Outside docs](../outside.md)
EOF
printf '# Outside\n' > "$ESCAPE_FIXTURE/outside.md"
printf '# Outside root\n' > "$FIXTURE_ROOT/outside-root.md"

run_validator "$ESCAPE_FIXTURE" "$ESCAPE_FIXTURE/broken-targets.txt"
assert_exit_code "path traversal fails validation" 1 "$VALIDATION_RC"
assert_contains "path traversal explains the boundary failure" "$VALIDATION_OUTPUT" "Path escapes documentation root"
assert_contains "README traversal explains the repository boundary" "$VALIDATION_OUTPUT" "Path escapes repository root"
assert_contains "path traversal target is preserved in output report" \
    "$(cat "$ESCAPE_FIXTURE/broken-targets.txt")" \
    "../outside.md"
assert_contains "README traversal target is preserved in output report" \
    "$(cat "$ESCAPE_FIXTURE/broken-targets.txt")" \
    "../outside-root.md"

# Existing VitePress config route validation remains part of the same report.
CONFIG_FIXTURE="$FIXTURE_ROOT/config"
mkdir -p "$CONFIG_FIXTURE/docs"
create_config "$CONFIG_FIXTURE" "      { text: 'Missing', link: '/missing-config-route' }"
printf '# Home\n' > "$CONFIG_FIXTURE/docs/index.md"

run_validator "$CONFIG_FIXTURE" "$CONFIG_FIXTURE/broken-targets.txt"
assert_exit_code "missing VitePress config route fails validation" 1 "$VALIDATION_RC"
assert_contains "config route resolves to its Markdown target" \
    "$(cat "$CONFIG_FIXTURE/broken-targets.txt")" \
    "docs/missing-config-route.md"

test_summary
