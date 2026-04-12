#!/bin/bash
# Minimal test suite for claudux — no dependencies, plain bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$PROJECT_ROOT/lib"
BIN="$PROJECT_ROOT/bin/claudux"

passed=0
failed=0
total=0

pass() {
    ((passed++))
    ((total++))
    echo "  PASS: $1"
}

fail() {
    ((failed++))
    ((total++))
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && echo "        $2"
}

section() {
    echo ""
    echo "--- $1 ---"
}

# ─── Structure tests ───

section "File structure"

[[ -f "$BIN" ]] && pass "bin/claudux exists" || fail "bin/claudux missing"
[[ -x "$BIN" ]] && pass "bin/claudux is executable" || fail "bin/claudux not executable"
[[ -f "$LIB_DIR/claude-utils.sh" ]] && pass "lib/claude-utils.sh exists" || fail "lib/claude-utils.sh missing"
[[ -f "$LIB_DIR/docs-generation.sh" ]] && pass "lib/docs-generation.sh exists" || fail "lib/docs-generation.sh missing"
[[ -f "$LIB_DIR/colors.sh" ]] && pass "lib/colors.sh exists" || fail "lib/colors.sh missing"
[[ -f "$LIB_DIR/project.sh" ]] && pass "lib/project.sh exists" || fail "lib/project.sh missing"

# ─── Library sourcing tests ───

section "Library sourcing"

for lib in colors.sh project.sh content-protection.sh claude-utils.sh git-utils.sh cleanup.sh server.sh ui.sh; do
    if bash -n "$LIB_DIR/$lib" 2>/dev/null; then
        pass "$lib parses without syntax errors"
    else
        fail "$lib has syntax errors"
    fi
done

# ─── Codex adapter tests ───

section "Codex adapter"

if [[ -f "$LIB_DIR/codex-utils.sh" ]]; then
    pass "lib/codex-utils.sh exists"
    if bash -n "$LIB_DIR/codex-utils.sh" 2>/dev/null; then
        pass "codex-utils.sh parses without syntax errors"
    else
        fail "codex-utils.sh has syntax errors"
    fi
else
    echo "  SKIP: lib/codex-utils.sh not installed (Codex adapter is optional)"
fi

# ─── CLI tests ───

section "CLI"

version_output=$("$BIN" --version 2>&1 || true)
if [[ "$version_output" =~ [0-9]+\.[0-9]+ ]]; then
    pass "--version outputs a version number: $version_output"
else
    fail "--version didn't output a version" "$version_output"
fi

help_output=$("$BIN" --help 2>&1 || true)
if [[ "$help_output" =~ "update" ]] && [[ "$help_output" =~ "serve" ]]; then
    pass "--help mentions update and serve commands"
else
    fail "--help missing expected commands"
fi

# ─── Backend router tests ───

section "Backend router"

# These tests verify the Codex adapter integration — skip if not yet merged
if grep -q 'CLAUDUX_BACKEND' "$LIB_DIR/docs-generation.sh" 2>/dev/null; then
    pass "docs-generation.sh references CLAUDUX_BACKEND"

    if grep -q 'run_codex_once' "$LIB_DIR/docs-generation.sh" 2>/dev/null; then
        pass "docs-generation.sh has run_codex_once function"
    else
        fail "docs-generation.sh missing run_codex_once"
    fi

    if grep -q 'CLAUDUX_BACKEND.*codex' "$BIN" 2>/dev/null; then
        pass "bin/claudux conditionally sources codex-utils.sh"
    else
        fail "bin/claudux missing conditional codex sourcing"
    fi
else
    echo "  SKIP: Codex backend router not yet merged"
fi

# ─── Summary ───

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: $passed passed, $failed failed, $total total"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[[ $failed -eq 0 ]] && exit 0 || exit 1
