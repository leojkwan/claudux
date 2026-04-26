#!/bin/bash
# claudux CLI integration test suite
# Zero dependencies — pure bash. Exit 1 on any failure.
#
# Usage:
#   bash tests/run-tests.sh          # run from repo root
#   bash tests/run-tests.sh -v       # verbose (show pass details)

set -uo pipefail

# ── Globals ──────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PASS=0
FAIL=0
SKIP=0
VERBOSE=false
[[ "${1:-}" == "-v" ]] && VERBOSE=true

# ── Helpers ──────────────────────────────────────────────────────────
pass() {
    PASS=$((PASS + 1))
    $VERBOSE && printf "  \033[32mPASS\033[0m  %s\n" "$1"
}

fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m  %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "        %s\n" "$2"
}

skip() {
    SKIP=$((SKIP + 1))
    $VERBOSE && printf "  \033[33mSKIP\033[0m  %s\n" "$1"
}

section() {
    echo ""
    printf "\033[1m── %s ──\033[0m\n" "$1"
}

# ── 1. File structure ────────────────────────────────────────────────
section "File structure"

required_files=(
    "bin/claudux"
    "lib/colors.sh"
    "lib/project.sh"
    "lib/content-protection.sh"
    "lib/claude-utils.sh"
    "lib/git-utils.sh"
    "lib/docs-manifest.sh"
    "lib/docs-generation.sh"
    "lib/cleanup.sh"
    "lib/server.sh"
    "lib/ui.sh"
    "lib/validate-links.sh"
    "package.json"
    "README.md"
    "LICENSE"
)

for f in "${required_files[@]}"; do
    if [[ -f "$REPO_ROOT/$f" ]]; then
        pass "exists: $f"
    else
        fail "missing: $f"
    fi
done

# bin/claudux must be executable
if [[ -x "$REPO_ROOT/bin/claudux" ]]; then
    pass "bin/claudux is executable"
else
    fail "bin/claudux is not executable"
fi

# ── 2. Library syntax ────────────────────────────────────────────────
section "Library syntax (bash -n)"

for lib in "$REPO_ROOT"/lib/*.sh; do
    name="$(basename "$lib")"
    if bash -n "$lib" 2>/dev/null; then
        pass "syntax OK: $name"
    else
        fail "syntax error: $name"
    fi
done

# bin/claudux syntax
if bash -n "$REPO_ROOT/bin/claudux" 2>/dev/null; then
    pass "syntax OK: bin/claudux"
else
    fail "syntax error: bin/claudux"
fi

# ── 3. Version command ───────────────────────────────────────────────
section "CLI: version"

version_output=$("$REPO_ROOT/bin/claudux" --version 2>/dev/null)
version_exit=$?

if [[ $version_exit -eq 0 ]]; then
    pass "--version exits 0"
else
    fail "--version exits $version_exit"
fi

# Output should start with "claudux "
if [[ "$version_output" == claudux\ * ]]; then
    pass "--version output starts with 'claudux '"
else
    fail "--version output unexpected: $version_output"
fi

# Version should match package.json
pkg_version=$(grep '"version"' "$REPO_ROOT/package.json" | head -1 | sed 's/.*"\([0-9][0-9.]*\)".*/\1/')
if [[ "$version_output" == "claudux $pkg_version" ]]; then
    pass "--version matches package.json ($pkg_version)"
else
    fail "--version mismatch: got '$version_output', expected 'claudux $pkg_version'"
fi

# All three aliases should produce the same output
for flag in "--version" "version" "-V"; do
    alt_output=$("$REPO_ROOT/bin/claudux" "$flag" 2>/dev/null)
    if [[ "$alt_output" == "$version_output" ]]; then
        pass "'$flag' produces consistent output"
    else
        fail "'$flag' output differs: $alt_output"
    fi
done

# ── 4. Help command ──────────────────────────────────────────────────
section "CLI: help"

help_output=$("$REPO_ROOT/bin/claudux" help 2>/dev/null)
help_exit=$?

if [[ $help_exit -eq 0 ]]; then
    pass "help exits 0"
else
    fail "help exits $help_exit"
fi

# Help should mention key commands
for keyword in "update" "serve" "recreate" "template" "help"; do
    if echo "$help_output" | grep -qi "$keyword"; then
        pass "help mentions '$keyword'"
    else
        fail "help missing '$keyword'"
    fi
done

# All help aliases produce the same output
for flag in "help" "-h" "--help"; do
    alt=$("$REPO_ROOT/bin/claudux" "$flag" 2>/dev/null)
    if [[ "$alt" == "$help_output" ]]; then
        pass "'$flag' produces consistent help"
    else
        fail "'$flag' help differs"
    fi
done

# ── 5. Help-to-CLI consistency ───────────────────────────────────────
section "Help-to-CLI consistency"

# Extract commands advertised in show_help (lines matching "claudux <word>")
advertised_cmds=$(echo "$help_output" | grep -oE 'claudux [a-z]+' | awk '{print $2}' | sort -u)

# Extract commands handled in main()'s case statement
handled_cmds=$(grep -E '^\s+"[a-z]' "$REPO_ROOT/bin/claudux" | grep -oE '"[a-z]+"' | tr -d '"' | sort -u)

# Every advertised command should be handled
for cmd in $advertised_cmds; do
    # skip "claudux" itself (the bare invocation)
    [[ "$cmd" == "claudux" ]] && continue
    if echo "$handled_cmds" | grep -qx "$cmd"; then
        pass "advertised '$cmd' is handled in main()"
    else
        fail "advertised '$cmd' has NO handler in main()" "help says it exists but running it would hit 'Unknown command'"
    fi
done

# Every advertised short/long option must be handled by at least one case arm.
# Catches phantom flags like a prior "-q" in help with no parser entry.
# Matches either quoted ("--opt") or alternation (-m|--message) case arms.
# Only grab flags that appear at the left of an option line (i.e. preceded
# by whitespace or start-of-line), not mid-word hyphens like "high-level".
advertised_opts=$(echo "$help_output" \
    | awk '/^Options:/,/^$/' \
    | grep -oE '(^|[[:space:]])(-{1,2}[A-Za-z][A-Za-z-]*)' \
    | awk '{print $NF}' \
    | sort -u)
for opt in $advertised_opts; do
    # Skip option-list header artifacts
    case "$opt" in "-"|"--") continue ;; esac
    # Escape dashes for grep; match "--opt") OR -m|...) OR |--opt)
    esc_opt=$(printf '%s' "$opt" | sed 's/[][\.*^$/]/\\&/g')
    if grep -rqE "\"${esc_opt}\"\\)|(\\||^|[[:space:]])${esc_opt}(\\)|\\|)" \
            "$REPO_ROOT/bin/claudux" "$REPO_ROOT/lib"/*.sh; then
        pass "advertised option '$opt' has a parser entry"
    else
        fail "advertised option '$opt' has NO parser entry" "help says it exists but invoking it would fail"
    fi
done

# Regression: phantom -q / --quiet must never be advertised (removed 2026-04-13)
if echo "$help_output" | grep -qE '^\s*-q\b|--quiet'; then
    fail "help advertises phantom '-q/--quiet' flag" "no such flag is implemented"
else
    pass "help does not advertise phantom '-q/--quiet' flag"
fi

# ── 6. Unknown command ───────────────────────────────────────────────
section "CLI: unknown command"

unknown_output=$("$REPO_ROOT/bin/claudux" this-is-not-a-command 2>&1)
unknown_exit=$?

if [[ $unknown_exit -ne 0 ]]; then
    pass "unknown command exits non-zero ($unknown_exit)"
else
    fail "unknown command should exit non-zero but exited 0"
fi

if echo "$unknown_output" | grep -qi "unknown"; then
    pass "unknown command mentions 'unknown' in output"
else
    fail "unknown command should say 'Unknown command'" "got: $unknown_output"
fi

# Regression: unknown commands must NOT trigger dependency validation (GH CI has no claude CLI)
if echo "$unknown_output" | grep -qi "required but not installed"; then
    fail "unknown command should not trigger dependency validation" "got: $unknown_output"
else
    pass "unknown command skips dependency validation"
fi

# ── 7. Check command ────────────────────────────────────────────────
section "CLI: check"

check_output=$("$REPO_ROOT/bin/claudux" check 2>&1)
check_exit=$?

if [[ $check_exit -eq 0 ]]; then
    pass "check exits 0"
else
    # check may fail if dependencies are missing (e.g., claude CLI) — that's OK in CI
    skip "check exited $check_exit (likely missing claude CLI)"
fi

if echo "$check_output" | grep -qi "node"; then
    pass "check reports Node status"
else
    fail "check should report Node status"
fi

# ── 8. Project type detection ─────────────────────────────────────────
section "Project detection"

# Source project.sh to get detect_project_type
(
    export LIB_DIR="$REPO_ROOT/lib"
    source "$REPO_ROOT/lib/project.sh"

    # Test in repo root (has package.json → should detect javascript)
    cd "$REPO_ROOT" || exit 1
    result=$(detect_project_type)
    echo "CLAUDUX_TYPE=$result"

    # Test with a fake iOS project
    tmp=$(mktemp -d)
    cd "$tmp" || exit 1
    mkdir -p Test.xcodeproj
    result=$(detect_project_type)
    echo "IOS_TYPE=$result"
    rm -rf "$tmp"

    # Test with a fake Python project
    tmp=$(mktemp -d)
    cd "$tmp" || exit 1
    touch requirements.txt
    result=$(detect_project_type)
    echo "PY_TYPE=$result"
    rm -rf "$tmp"

    # Test with a fake Go project
    tmp=$(mktemp -d)
    cd "$tmp" || exit 1
    touch go.mod
    result=$(detect_project_type)
    echo "GO_TYPE=$result"
    rm -rf "$tmp"

    # Test with empty dir (generic)
    tmp=$(mktemp -d)
    cd "$tmp" || exit 1
    result=$(detect_project_type)
    echo "EMPTY_TYPE=$result"
    rm -rf "$tmp"
) > /tmp/claudux-detect-test 2>&1

detect_result=$(cat /tmp/claudux-detect-test)
rm -f /tmp/claudux-detect-test

if echo "$detect_result" | grep -q "CLAUDUX_TYPE=javascript"; then
    pass "detect_project_type: claudux repo -> javascript"
else
    actual=$(echo "$detect_result" | grep CLAUDUX_TYPE | head -1)
    fail "detect_project_type: claudux repo expected 'javascript'" "$actual"
fi

if echo "$detect_result" | grep -q "IOS_TYPE=ios"; then
    pass "detect_project_type: .xcodeproj -> ios"
else
    actual=$(echo "$detect_result" | grep IOS_TYPE | head -1)
    fail "detect_project_type: .xcodeproj expected 'ios'" "$actual"
fi

if echo "$detect_result" | grep -q "PY_TYPE=python"; then
    pass "detect_project_type: requirements.txt -> python"
else
    actual=$(echo "$detect_result" | grep PY_TYPE | head -1)
    fail "detect_project_type: requirements.txt expected 'python'" "$actual"
fi

if echo "$detect_result" | grep -q "GO_TYPE=go"; then
    pass "detect_project_type: go.mod -> go"
else
    actual=$(echo "$detect_result" | grep GO_TYPE | head -1)
    fail "detect_project_type: go.mod expected 'go'" "$actual"
fi

if echo "$detect_result" | grep -q "EMPTY_TYPE=generic"; then
    pass "detect_project_type: empty dir -> generic"
else
    actual=$(echo "$detect_result" | grep EMPTY_TYPE | head -1)
    fail "detect_project_type: empty dir expected 'generic'" "$actual"
fi

# ── 9. Package.json consistency ───────────────────────────────────────
section "Package.json"

# Verify required fields exist
for field in "name" "version" "description" "bin" "license" "engines"; do
    if grep -q "\"$field\"" "$REPO_ROOT/package.json"; then
        pass "package.json has '$field'"
    else
        fail "package.json missing '$field'"
    fi
done

# Verify bin points to existing file
bin_path=$(grep -o '"./[^"]*"' "$REPO_ROOT/package.json" | head -1 | tr -d '"')
if [[ -n "$bin_path" ]] && [[ -f "$REPO_ROOT/$bin_path" ]]; then
    pass "bin target exists: $bin_path"
else
    fail "bin target missing: $bin_path"
fi

# Verify no dependencies (claudux is zero-dep)
dep_count=$(grep -c '"dependencies"' "$REPO_ROOT/package.json")
if [[ $dep_count -gt 0 ]]; then
    # Check that dependencies is empty
    dep_block=$(python3 -c "import json; d=json.load(open('$REPO_ROOT/package.json')); print(len(d.get('dependencies',{})))" 2>/dev/null || echo "unknown")
    if [[ "$dep_block" == "0" ]]; then
        pass "zero runtime dependencies"
    elif [[ "$dep_block" == "unknown" ]]; then
        skip "could not parse dependencies (no python3)"
    else
        fail "expected zero dependencies, found $dep_block"
    fi
fi

# ── 10. README accuracy ──────────────────────────────────────────────
section "README accuracy"

readme="$REPO_ROOT/README.md"

# README should mention the npm package name
if grep -q "claudux" "$readme"; then
    pass "README mentions package name"
else
    fail "README should mention 'claudux'"
fi

# README should have install instructions
if grep -q "npm install" "$readme"; then
    pass "README has install instructions"
else
    fail "README missing install instructions"
fi

# README should mention Node requirement
if grep -qi "node" "$readme"; then
    pass "README mentions Node requirement"
else
    fail "README should mention Node requirement"
fi

# README should mention Claude CLI requirement
if grep -qi "claude" "$readme"; then
    pass "README mentions Claude CLI"
else
    fail "README should mention Claude CLI"
fi

# README Commands section should list all CLI subcommands from help
for cmd in update serve diff status validate check template recreate; do
    if grep -q "claudux $cmd" "$readme"; then
        pass "README documents '$cmd' command"
    else
        fail "README missing '$cmd' command"
    fi
done

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
total=$((PASS + FAIL + SKIP))
printf "Results: \033[32m%d passed\033[0m" "$PASS"
[[ $FAIL -gt 0 ]] && printf ", \033[31m%d failed\033[0m" "$FAIL"
[[ $SKIP -gt 0 ]] && printf ", \033[33m%d skipped\033[0m" "$SKIP"
printf " / %d total\n" "$total"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
