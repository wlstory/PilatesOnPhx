#!/usr/bin/env bash
# Test Enforcer Hook - Enforce TDD by running tests after code changes
# Validates coverage stays above 90% threshold

set -euo pipefail

# Configuration
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${HOOKS_DIR}/hooks.log"
PROJECT_ROOT="$(cd "${HOOKS_DIR}/../.." && pwd)"
COVERAGE_THRESHOLD=90
TEMP_OUTPUT="/tmp/claude-hooks-test-enforcer-$$.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [test-enforcer] $*" >> "$LOG_FILE"
}

# Parse file path from JSON input
parse_file_path() {
    if command -v jq &> /dev/null; then
        jq -r '.file_path // .path // ""' 2>/dev/null || echo ""
    else
        # Portable fallback: use awk with POSIX character classes (works on BSD/macOS and GNU/Linux)
        # Matches: "file_path": "some/path" or "path": "some/path"
        local extracted=""
        extracted=$(awk -F'"' '/"(file_path|path)"[[:space:]]*:[[:space:]]*"/ {
            for (i=1; i<=NF; i++) {
                if ($i ~ /(file_path|path)/) {
                    print $(i+2)
                    exit
                }
            }
        }' 2>/dev/null) || true
        echo "${extracted:-}"
    fi
}

# Check if file is in lib/ or test/ directory (code that needs tests)
is_code_file() {
    local filepath="$1"

    if [[ "$filepath" =~ ^lib/ ]] || [[ "$filepath" =~ ^test/ ]]; then
        # Exclude certain files that don't need tests
        if [[ "$filepath" =~ _web\.ex$ ]] || [[ "$filepath" =~ application\.ex$ ]]; then
            return 1
        fi
        return 0
    fi
    return 1
}

# Find corresponding test file
find_test_file() {
    local code_file="$1"

    # Convert lib/catalio/foo/bar.ex -> test/catalio/foo/bar_test.exs
    local test_file="${code_file//lib\//test\/}"
    test_file="${test_file//.ex/_test.exs}"

    if [ -f "$PROJECT_ROOT/$test_file" ]; then
        echo "$test_file"
        return 0
    fi

    return 1
}

# Check if test file exists for the modified code
check_test_exists() {
    local filepath="$1"

    # If it's already a test file, it exists
    if [[ "$filepath" =~ _test\.exs$ ]]; then
        return 0
    fi

    # Check if corresponding test exists
    if find_test_file "$filepath" > /dev/null; then
        return 0
    fi

    return 1
}

# Run tests for specific file
run_tests_for_file() {
    local filepath="$1"

    log "Running tests for: $filepath"
    cd "$PROJECT_ROOT"

    # Determine test file path
    local test_file
    if [[ "$filepath" =~ _test\.exs$ ]]; then
        test_file="$filepath"
    else
        test_file=$(find_test_file "$filepath" || echo "")
    fi

    if [ -z "$test_file" ]; then
        log "No test file found for $filepath"
        return 0
    fi

    log "Test file: $test_file"

    # Run the specific test file with coverage
    if mix test "$test_file" --cover > "$TEMP_OUTPUT" 2>&1; then
        log "✓ Tests passed for $test_file"
        cat "$TEMP_OUTPUT" >> "$LOG_FILE"
        return 0
    else
        log "✗ Tests failed for $test_file"
        cat "$TEMP_OUTPUT" >> "$LOG_FILE"
        return 1
    fi
}

# Extract coverage percentage from test output
extract_coverage() {
    local output_file="$1"

    # Look for coverage line like "Coverage: 92.5%"
    # Use portable sed/awk instead of grep -oP (which is GNU-only)
    if grep -q "Coverage:" "$output_file" 2>/dev/null; then
        # Extract numeric coverage using sed (works on both BSD and GNU)
        local coverage
        coverage=$(grep "Coverage:" "$output_file" | sed -n 's/.*Coverage: *\([0-9][0-9]*\.[0-9][0-9]*\)%.*/\1/p' | head -1)

        # If sed didn't match, try simpler integer pattern
        if [ -z "$coverage" ]; then
            coverage=$(grep "Coverage:" "$output_file" | sed -n 's/.*Coverage: *\([0-9][0-9]*\)%.*/\1/p' | head -1)
        fi

        # Return coverage or 0 if extraction failed
        echo "${coverage:-0}"
    else
        echo "0"
    fi
}

# Format test failure message
format_test_failure() {
    local filepath="$1"
    local test_file="$2"

    echo ""
    echo "❌ TEST FAILURE - Tests did not pass"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "File modified: $filepath"
    echo "Test file: $test_file"
    echo ""
    echo "Test output (last 20 lines):"
    echo ""
    tail -20 "$TEMP_OUTPUT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Action required:"
    echo "  1. Review the test failures above"
    echo "  2. Run 'mix test $test_file' locally to see full details"
    echo "  3. Fix the failing tests"
    echo "  4. Ensure business logic is properly tested"
    echo ""
}

# Format missing test warning
format_missing_test() {
    local filepath="$1"

    echo ""
    echo "⚠️  MISSING TESTS - No test file found"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "File modified: $filepath"
    echo ""
    echo "Per TDD requirements:"
    echo "All business logic must have comprehensive test coverage (90%+ target)."
    echo ""
    echo "Recommended action:"
    echo "  1. Consider using the catalio-test-strategist agent to design tests"
    echo "  2. Create test file with proper coverage of business logic"
    echo "  3. Focus on testing Catalio-specific features, not framework basics"
    echo ""
    echo "To invoke test strategist, you can ask:"
    echo "  'Can you help design comprehensive tests for this file?'"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Main function
main() {
    log "=== Test enforcer hook started ==="

    # Read and parse input
    local input
    input=$(cat)

    # Extract file path
    local filepath
    filepath=$(echo "$input" | parse_file_path)

    if [ -z "$filepath" ]; then
        log "No file path found in input"
        exit 0
    fi

    # Make path relative to project root
    filepath="${filepath#$PROJECT_ROOT/}"
    log "Checking file: $filepath"

    # Check if this is a code file that needs tests
    if ! is_code_file "$filepath"; then
        log "File is not in lib/ or test/, skipping test enforcement"
        exit 0
    fi

    # Check if test exists
    if ! check_test_exists "$filepath"; then
        log "⚠ No test file found for $filepath"
        format_missing_test "$filepath"
        exit 0  # Don't block, but show warning
    fi

    # Run tests for the file
    if ! run_tests_for_file "$filepath"; then
        local test_file
        test_file=$(find_test_file "$filepath" || echo "$filepath")
        format_test_failure "$filepath" "$test_file"

        # Clean up
        rm -f "$TEMP_OUTPUT"

        # Don't block completely, but show the failure
        exit 0
    fi

    # Check coverage
    local coverage
    coverage=$(extract_coverage "$TEMP_OUTPUT")
    log "Coverage: ${coverage}%"

    # Use awk for portable floating-point comparison (works on BSD and GNU)
    if awk -v cov="$coverage" -v thresh="$COVERAGE_THRESHOLD" 'BEGIN { exit !(cov < thresh) }'; then
        log "⚠ Coverage ${coverage}% is below threshold ${COVERAGE_THRESHOLD}%"
        echo ""
        echo "⚠️  Coverage below threshold: ${coverage}% (target: ${COVERAGE_THRESHOLD}%)"
        echo ""
        echo "Consider using catalio-test-strategist to improve test coverage."
        echo ""
    else
        log "✓ Coverage ${coverage}% meets threshold ${COVERAGE_THRESHOLD}%"
        echo "✓ Tests passed with ${coverage}% coverage"
    fi

    # Clean up
    rm -f "$TEMP_OUTPUT"

    log "=== Test enforcer hook completed ==="
    exit 0
}

# Execute main function
main "$@"
