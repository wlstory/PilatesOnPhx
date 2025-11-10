#!/usr/bin/env bash
# Quality Gate Hook - Run mix precommit and enforce quality standards
# Enforces: ALL warnings must be fixed (per catalio-debugger requirements)

set -euo pipefail

# Configuration
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${HOOKS_DIR}/hooks.log"
PROJECT_ROOT="$(cd "${HOOKS_DIR}/../.." && pwd)"
TEMP_OUTPUT="/tmp/claude-hooks-quality-gate-$$.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [quality-gate] $*" >> "$LOG_FILE"
}

# Check if we should skip (e.g., during read-only operations)
should_skip() {
    # Skip if last commit message indicates hook execution
    if git log -1 --pretty=%B 2>/dev/null | grep -q "Claude Code quality gate"; then
        return 0
    fi
    return 1
}

# Run mix precommit and capture output
run_mix_precommit() {
    log "Running mix precommit..."
    cd "$PROJECT_ROOT"

    # Check if mise is available
    local exit_code
    if command -v mise >/dev/null 2>&1; then
        log "Using mise to run mix precommit"
        # Run mix precommit using mise to ensure proper Elixir environment
        mise exec -- mix precommit > "$TEMP_OUTPUT" 2>&1
        exit_code=$?
    else
        log "WARNING: mise not found, falling back to direct mix precommit"
        # Fallback to running mix precommit directly
        mix precommit >> "$TEMP_OUTPUT" 2>&1
        exit_code=$?
    fi

    # Log the full output
    cat "$TEMP_OUTPUT" >> "$LOG_FILE"

    return $exit_code
}

# Parse warnings from output
count_warnings() {
    local output_file="$1"

    # Count various types of warnings
    local total=0

    # Compiler warnings
    local compiler_warnings
    compiler_warnings=$(grep -c "warning:" "$output_file" 2>/dev/null || echo "0")
    total=$((total + compiler_warnings))

    # Credo warnings
    local credo_warnings
    credo_warnings=$(grep -c "\\[R\\]\\|\\[F\\]" "$output_file" 2>/dev/null || echo "0")
    total=$((total + credo_warnings))

    # Dialyzer warnings
    local dialyzer_warnings
    dialyzer_warnings=$(grep -c "dialyzer" "$output_file" 2>/dev/null || echo "0")
    total=$((total + dialyzer_warnings))

    # Unused deps
    local unused_deps
    unused_deps=$(grep -c "Unused" "$output_file" 2>/dev/null || echo "0")
    total=$((total + unused_deps))

    echo "$total"
}

# Format warnings for display
format_warnings() {
    local output_file="$1"

    echo ""
    echo "⚠️  QUALITY GATE FAILURE - Warnings Detected"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Per catalio-debugger requirements:"
    echo "ALL warnings from mix precommit must be fixed."
    echo ""
    echo "Issues found:"
    echo ""

    # Show compiler warnings
    if grep -q "warning:" "$output_file" 2>/dev/null; then
        echo "📋 Compilation Warnings:"
        grep "warning:" "$output_file" | head -10
        echo ""
    fi

    # Show Credo issues
    if grep -q "\\[R\\]\\|\\[F\\]" "$output_file" 2>/dev/null; then
        echo "📋 Credo Issues:"
        grep "\\[R\\]\\|\\[F\\]" "$output_file" | head -10
        echo ""
    fi

    # Show Dialyzer issues
    if grep -q "dialyzer" "$output_file" 2>/dev/null; then
        echo "📋 Dialyzer Issues:"
        grep "dialyzer" "$output_file" | head -10
        echo ""
    fi

    # Show unused deps
    if grep -q "Unused" "$output_file" 2>/dev/null; then
        echo "📋 Unused Dependencies:"
        grep "Unused" "$output_file"
        echo ""
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "To fix these issues:"
    echo "  1. Review the warnings above"
    echo "  2. Run 'mix precommit' locally to see full details"
    echo "  3. Fix all issues"
    echo ""
}

# Main function
main() {
    log "=== Quality gate hook started ==="

    # Check if we should skip
    if should_skip; then
        log "Skipping quality gate (hook execution detected)"
        exit 0
    fi

    # Run mix precommit
    if run_mix_precommit; then
        log "✓ Quality gate passed - no warnings"
        echo "✓ Quality gate passed - code meets all standards"
        rm -f "$TEMP_OUTPUT"
        exit 0
    fi

    # Count warnings
    local warning_count
    warning_count=$(count_warnings "$TEMP_OUTPUT")

    log "✗ Quality gate failed - $warning_count warning(s) detected"

    # Format and display warnings
    format_warnings "$TEMP_OUTPUT"

    # Clean up
    rm -f "$TEMP_OUTPUT"

    log "=== Quality gate hook completed with failures ==="

    # Return non-zero to indicate failure and block operations
    # This ensures PR creation and other critical operations are blocked
    # until all quality issues are resolved
    exit 1  # Non-zero exit code signals failure
}

# Execute main function
main "$@"
