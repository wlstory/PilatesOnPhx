#!/usr/bin/env bash
# Safety Commit Hook - Create WIP commits before destructive operations
# Enables easy rollback following project's WIP commit conventions

set -euo pipefail

# Configuration
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${HOOKS_DIR}/hooks.log"
PROJECT_ROOT="$(cd "${HOOKS_DIR}/../.." && pwd)"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [safety-commit] $*" >> "$LOG_FILE"
}

# Parse command from JSON input
parse_command() {
    if command -v jq &> /dev/null; then
        jq -r '.command // ""' 2>/dev/null || echo ""
    else
        # Portable fallback: use awk with POSIX character classes (works on BSD/macOS and GNU/Linux)
        # Matches: "command": "some command"
        local extracted=""
        extracted=$(awk -F'"' '/"command"[[:space:]]*:[[:space:]]*"/ {
            for (i=1; i<=NF; i++) {
                if ($i == "command") {
                    print $(i+2)
                    exit
                }
            }
        }' 2>/dev/null) || true
        echo "${extracted:-}"
    fi
}

# Check if operation is destructive
is_destructive_operation() {
    local cmd="$1"

    # Check for destructive bash commands
    if [[ "$cmd" =~ ^rm ]] || [[ "$cmd" =~ ^rm\ -rf ]] || [[ "$cmd" =~ ^git\ reset ]]; then
        return 0
    fi

    # Check for significant file changes (more than 5 files being edited)
    if [[ "$cmd" =~ Edit ]] || [[ "$cmd" =~ Write ]]; then
        # For now, we'll be conservative and consider all edits potentially significant
        # In practice, this would track file count
        return 0
    fi

    return 1
}

# Check if there are uncommitted changes
has_uncommitted_changes() {
    cd "$PROJECT_ROOT"

    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        return 0
    fi

    # Check for untracked files that were created
    local untracked
    untracked=$(git ls-files --others --exclude-standard | wc -l)

    if [ "$untracked" -gt 0 ]; then
        return 0
    fi

    return 1
}

# Get summary of changes for commit message
get_changes_summary() {
    cd "$PROJECT_ROOT"

    local summary=""

    # Count modified files
    local modified
    modified=$(git diff --name-only | wc -l)

    # Count staged files
    local staged
    staged=$(git diff --cached --name-only | wc -l)

    # Count untracked files
    local untracked
    untracked=$(git ls-files --others --exclude-standard | wc -l)

    if [ "$modified" -gt 0 ]; then
        summary="${summary}${modified} modified"
    fi

    if [ "$staged" -gt 0 ]; then
        if [ -n "$summary" ]; then
            summary="${summary}, "
        fi
        summary="${summary}${staged} staged"
    fi

    if [ "$untracked" -gt 0 ]; then
        if [ -n "$summary" ]; then
            summary="${summary}, "
        fi
        summary="${summary}${untracked} new"
    fi

    echo "$summary"
}

# Create safety WIP commit
create_safety_commit() {
    local operation="$1"

    cd "$PROJECT_ROOT"
    log "Creating safety WIP commit before: $operation"

    # Get changes summary
    local changes
    changes=$(get_changes_summary)

    # Stage all changes (including untracked files)
    git add -A 2>&1 | tee -a "$LOG_FILE"

    # Create WIP commit with descriptive message
    local commit_msg="WIP: [automated safety checkpoint] before ${operation}

Changes: ${changes}

This is an automated safety commit created by Claude Code hooks
to enable easy rollback if needed."

    if git commit -m "$commit_msg" 2>&1 | tee -a "$LOG_FILE"; then
        local commit_hash
        commit_hash=$(git rev-parse --short HEAD)
        log "✓ Safety commit created: $commit_hash"
        echo ""
        echo "✓ Safety checkpoint created: $commit_hash"
        echo "  Changes: $changes"
        echo "  You can rollback with: git reset --soft HEAD~1"
        echo ""
        return 0
    else
        log "✗ Failed to create safety commit"
        echo ""
        echo "⚠️  Could not create safety commit"
        echo "  This may be because there are no changes to commit"
        echo ""
        return 1
    fi
}

# Check if we should skip (e.g., during git operations)
should_skip() {
    local cmd="$1"

    # Skip during git commit/push operations
    if [[ "$cmd" =~ ^git\ commit ]] || [[ "$cmd" =~ ^git\ push ]]; then
        return 0
    fi

    # Skip if last commit was a safety commit AND working tree is clean (prevent loops)
    cd "$PROJECT_ROOT"
    if git log -1 --pretty=%B 2>/dev/null | grep -q "automated safety checkpoint"; then
        # Last commit was a safety commit - check if working tree is clean
        # Only skip if there are no new changes since that safety commit
        if git diff-index --quiet HEAD -- 2>/dev/null && \
           [ "$(git ls-files --others --exclude-standard | wc -l)" -eq 0 ]; then
            # Working tree is clean - skip to prevent creating duplicate safety commits
            return 0
        fi
        # Working tree has changes - proceed with new safety commit
    fi

    return 1
}

# Main function
main() {
    log "=== Safety commit hook started ==="

    # Read and parse input
    local input
    input=$(cat)

    # Extract command
    local command
    command=$(echo "$input" | parse_command)

    if [ -z "$command" ]; then
        log "No command found in input"
        exit 0
    fi

    log "Command: $command"

    # Check if we should skip
    if should_skip "$command"; then
        log "Skipping safety commit (git operation or recent safety commit detected)"
        exit 0
    fi

    # Check if operation is destructive
    if ! is_destructive_operation "$command"; then
        log "Operation is not destructive, skipping safety commit"
        exit 0
    fi

    log "Destructive operation detected: $command"

    # Check if there are changes to commit
    if ! has_uncommitted_changes; then
        log "No uncommitted changes, skipping safety commit"
        exit 0
    fi

    # Create safety commit
    create_safety_commit "$command"

    log "=== Safety commit hook completed ==="
    exit 0
}

# Execute main function
main "$@"
