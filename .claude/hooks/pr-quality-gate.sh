#!/usr/bin/env bash
# PR Quality Gate Hook - Enforce mix precommit before PR creation
# This hook runs BEFORE any gh pr create command executes
# Exit code 0 = Allow PR creation, Exit code 1 = Block PR creation

set -euo pipefail

# Configuration
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${HOOKS_DIR}/hooks.log"
PROJECT_ROOT="$(cd "${HOOKS_DIR}/../.." && pwd)"
TEMP_OUTPUT="/tmp/claude-hooks-pr-quality-gate-$$.log"

# Ensure log directory and file exist
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Cleanup trap to ensure temp files are always removed
trap 'rm -f "$TEMP_OUTPUT" /tmp/pr-quality-gate-input-$$.json' EXIT INT TERM

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [pr-quality-gate] $*" >> "$LOG_FILE"
}

# Parse stdin to check if this is a PR creation command
is_pr_create_command() {
    local input
    if [ -t 0 ]; then
        # No stdin available (terminal mode)
        return 1
    fi

    input=$(cat)
    echo "$input" > /tmp/pr-quality-gate-input-$$.json

    # Check if this is a Bash tool call with gh pr create
    if echo "$input" | grep -q '"command"' && echo "$input" | grep -q 'gh pr create'; then
        log "Detected gh pr create command"
        return 0
    fi

    return 1
}

# Run mix precommit and capture output
run_mix_precommit() {
    log "Running mix precommit before PR creation..."
    cd "$PROJECT_ROOT"

    local exit_code
    if command -v mise >/dev/null 2>&1; then
        log "Using mise to run mix precommit"
        mise exec -- mix precommit > "$TEMP_OUTPUT" 2>&1
        exit_code=$?
    else
        log "WARNING: mise not found, falling back to direct mix precommit"
        mix precommit > "$TEMP_OUTPUT" 2>&1
        exit_code=$?
    fi

    # Log the full output
    cat "$TEMP_OUTPUT" >> "$LOG_FILE"

    return $exit_code
}

# Count warnings from output
count_warnings() {
    local output_file="$1"
    local total=0

    # Compiler warnings
    local compiler_warnings
    compiler_warnings=$(grep -c "warning:" "$output_file" 2>/dev/null || echo "0")
    total=$((total + compiler_warnings))

    # Credo warnings
    local credo_warnings
    credo_warnings=$(grep -c "\[R\]\|\[F\]" "$output_file" 2>/dev/null || echo "0")
    total=$((total + credo_warnings))

    # Dialyzer warnings
    local dialyzer_warnings
    dialyzer_warnings=$(grep -c "dialyzer" "$output_file" 2>/dev/null || echo "0")
    total=$((total + dialyzer_warnings))

    # Test failures
    local test_failures
    # Use anchored patterns to match real test failure summaries
    test_failures=$(grep -E -c '^(FAIL|FAILED\b|[0-9]+ failed\b|ERROR\b)' "$output_file" 2>/dev/null || echo "0")
    total=$((total + test_failures))

    echo "$total"
}

# Format error message for user
format_error_message() {
    local output_file="$1"

    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚫 PR CREATION BLOCKED - Quality Gate Failed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The PR Quality Gate has BLOCKED this PR creation because
mix precommit reported warnings or errors.

Per project requirements: ALL warnings must be fixed before
creating a Pull Request.

Issues detected in mix precommit:
$(if grep -q "warning:" "$output_file" 2>/dev/null; then
    echo ""
    echo "📋 Compilation Warnings:"
    grep "warning:" "$output_file" | head -10
fi)
$(if grep -q "\[R\]\|\[F\]" "$output_file" 2>/dev/null; then
    echo ""
    echo "📋 Credo Issues:"
    grep "\[R\]\|\[F\]" "$output_file" | head -10
fi)
$(if grep -q "failed" "$output_file" 2>/dev/null; then
    echo ""
    echo "📋 Test Failures:"
    grep "failed" "$output_file" | head -10
fi)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Required Actions:
  1. Run 'mix precommit' locally to see full error details
  2. Fix ALL warnings and errors
  3. Re-run 'mix precommit' to verify fixes (exit code must be 0)
  4. Only then retry PR creation

Recommended Approach:
  • Use the catalio-debugger agent to fix quality issues
  • Ensure all tests pass
  • Ensure code is properly formatted
  • Ensure no security warnings exist

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This enforcement ensures that only high-quality, fully-tested
code makes it into Pull Requests.

EOF
}

# Main function
main() {
    log "=== PR Quality Gate hook started ==="

    # Check if this is a PR creation command
    if ! is_pr_create_command; then
        log "Not a PR creation command, allowing through"
        exit 0
    fi

    log "PR creation detected - enforcing quality gate"

    # Run mix precommit
    if run_mix_precommit; then
        log "✓ Quality gate passed - allowing PR creation"
        echo "✅ Quality gate passed - PR creation allowed"
        exit 0
    fi

    # Count warnings
    local warning_count
    warning_count=$(count_warnings "$TEMP_OUTPUT")

    log "✗ Quality gate FAILED - $warning_count issue(s) detected - BLOCKING PR creation"

    # Display error message to user
    format_error_message "$TEMP_OUTPUT"

    log "=== PR Quality Gate hook completed - PR BLOCKED ==="

    # Return non-zero to BLOCK the PR creation command from executing
    exit 1
}

# Execute main function
main "$@"
