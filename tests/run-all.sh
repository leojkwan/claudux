#!/bin/bash
# Run all claudux tests — plain bash, no dependencies
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_EXIT=0

echo "╔════════════════════════════════════════╗"
echo "║       claudux test suite               ║"
echo "╚════════════════════════════════════════╝"
echo ""

for test_file in "$SCRIPT_DIR"/test-*.sh; do
    # Skip the harness itself
    [[ "$(basename "$test_file")" == "test-harness.sh" ]] && continue

    echo ""
    bash "$test_file"
    ec=$?
    if [[ $ec -ne 0 ]]; then
        TOTAL_EXIT=1
    fi
    echo ""
done

echo ""
if [[ $TOTAL_EXIT -eq 0 ]]; then
    echo "All test suites passed."
else
    echo "Some tests failed."
fi

exit $TOTAL_EXIT
