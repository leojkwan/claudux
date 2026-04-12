#!/bin/bash
# Minimal bash test harness — no dependencies
# Usage: source this file, then call assert_eq / assert_contains / assert_exit_code

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAIL_MESSAGES=()

# Colors (plain if not a tty)
if [[ -t 1 ]]; then
    _GREEN='\033[0;32m'
    _RED='\033[0;31m'
    _NC='\033[0m'
else
    _GREEN=''
    _RED=''
    _NC=''
fi

assert_eq() {
    local label="$1"
    local expected="$2"
    local actual="$3"
    ((TESTS_RUN++))
    if [[ "$expected" == "$actual" ]]; then
        ((TESTS_PASSED++))
        printf "${_GREEN}  PASS${_NC} %s\n" "$label"
    else
        ((TESTS_FAILED++))
        FAIL_MESSAGES+=("$label: expected '$expected', got '$actual'")
        printf "${_RED}  FAIL${_NC} %s\n" "$label"
        printf "       expected: %s\n" "$expected"
        printf "       actual:   %s\n" "$actual"
    fi
}

assert_contains() {
    local label="$1"
    local haystack="$2"
    local needle="$3"
    ((TESTS_RUN++))
    if echo "$haystack" | grep -qF "$needle"; then
        ((TESTS_PASSED++))
        printf "${_GREEN}  PASS${_NC} %s\n" "$label"
    else
        ((TESTS_FAILED++))
        FAIL_MESSAGES+=("$label: output does not contain '$needle'")
        printf "${_RED}  FAIL${_NC} %s\n" "$label"
        printf "       needle:   %s\n" "$needle"
        printf "       haystack: %s\n" "$(echo "$haystack" | head -5)"
    fi
}

assert_not_contains() {
    local label="$1"
    local haystack="$2"
    local needle="$3"
    ((TESTS_RUN++))
    if ! echo "$haystack" | grep -qF "$needle"; then
        ((TESTS_PASSED++))
        printf "${_GREEN}  PASS${_NC} %s\n" "$label"
    else
        ((TESTS_FAILED++))
        FAIL_MESSAGES+=("$label: output should not contain '$needle'")
        printf "${_RED}  FAIL${_NC} %s\n" "$label"
        printf "       unwanted: %s\n" "$needle"
    fi
}

assert_file_exists() {
    local label="$1"
    local path="$2"
    ((TESTS_RUN++))
    if [[ -f "$path" ]]; then
        ((TESTS_PASSED++))
        printf "${_GREEN}  PASS${_NC} %s\n" "$label"
    else
        ((TESTS_FAILED++))
        FAIL_MESSAGES+=("$label: file not found: $path")
        printf "${_RED}  FAIL${_NC} %s\n" "$label"
        printf "       missing:  %s\n" "$path"
    fi
}

assert_exit_code() {
    local label="$1"
    local expected="$2"
    local actual="$3"
    assert_eq "$label (exit code)" "$expected" "$actual"
}

# Print summary and return appropriate exit code
test_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "  %d tests: %d passed, %d failed\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo ""
        printf "${_RED}Failures:${_NC}\n"
        for msg in "${FAIL_MESSAGES[@]}"; do
            printf "  - %s\n" "$msg"
        done
        return 1
    fi
    return 0
}
