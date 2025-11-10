#!/usr/bin/env bash
# Smart Dispatcher - Central routing logic for Claude Code hooks
# Routes hook events to appropriate specialized handlers

set -euo pipefail

# Configuration
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${HOOKS_DIR}/hooks.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [smart-dispatcher] $*" >> "$LOG_FILE"
}

# Parse JSON input from stdin
parse_input() {
    local input
    input=$(cat)

    if command -v jq &> /dev/null; then
        echo "$input" | jq -r '.toolName // .event // "unknown"' 2>/dev/null || echo "unknown"
    else
        # Portable POSIX fallback: extract "toolName" or "event" field value
        # Uses awk with POSIX character classes (works on BSD/macOS and GNU/Linux)
        local value

        # Try to extract "toolName" field first
        value=$(echo "$input" | awk -F'"' '/"toolName"[[:space:]]*:[[:space:]]*"/ {
            for (i=1; i<=NF; i++) {
                if ($i == "toolName") {
                    print $(i+2)
                    exit
                }
            }
        }' 2>/dev/null) || true

        # If toolName not found or empty, try "event" field
        if [ -z "$value" ]; then
            value=$(echo "$input" | awk -F'"' '/"event"[[:space:]]*:[[:space:]]*"/ {
                for (i=1; i<=NF; i++) {
                    if ($i == "event") {
                        print $(i+2)
                        exit
                    }
                }
            }' 2>/dev/null) || true
        fi

        # Return the extracted value or "unknown" if neither field found
        echo "${value:-unknown}"
    fi
}

# Main dispatcher logic
main() {
    log "=== Hook invocation started ==="

    # Read and parse input
    local input
    input=$(cat)
    log "Input received: ${input:0:200}..."  # Log first 200 chars

    # Parse tool/event name
    local tool_name
    tool_name=$(echo "$input" | parse_input)
    log "Tool/Event: $tool_name"

    # Route to appropriate handler
    case "$tool_name" in
        Edit|Write)
            log "Routing to auto-format handler"
            echo "$input" | "${HOOKS_DIR}/auto-format.sh"
            ;;
        Bash)
            log "Routing to safety-commit handler"
            echo "$input" | "${HOOKS_DIR}/safety-commit.sh"
            ;;
        Stop)
            log "Routing to quality-gate handler"
            "${HOOKS_DIR}/quality-gate.sh"
            ;;
        Notification)
            log "Routing to notify handler"
            echo "$input" | "${HOOKS_DIR}/notify.sh"
            ;;
        *)
            log "No specific handler for $tool_name, passing through"
            ;;
    esac

    log "=== Hook invocation completed ==="
    exit 0
}

# Execute main function
main "$@"
