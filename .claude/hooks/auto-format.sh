#!/usr/bin/env bash
# Auto-Format Hook - Automatically format code after Edit/Write operations
# Runs appropriate formatter based on file extension

set -euo pipefail

# Configuration
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${HOOKS_DIR}/hooks.log"
PROJECT_ROOT="$(cd "${HOOKS_DIR}/../.." && pwd)"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [auto-format] $*" >> "$LOG_FILE"
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

# Get file extension
get_extension() {
    local filepath="$1"
    echo "${filepath##*.}"
}

# Format Elixir files
format_elixir() {
    local filepath="$1"
    log "Formatting Elixir file: $filepath"

    cd "$PROJECT_ROOT"
    if mix format "$filepath" 2>&1 | tee -a "$LOG_FILE"; then
        log "✓ Elixir formatting successful"
        return 0
    else
        log "✗ Elixir formatting failed"
        return 1
    fi
}

# Format JavaScript/TypeScript files
format_javascript() {
    local filepath="$1"
    log "Formatting JavaScript file: $filepath"

    cd "$PROJECT_ROOT"
    if [ -f "./assets/node_modules/.bin/prettier" ]; then
        if ./assets/node_modules/.bin/prettier --write "$filepath" 2>&1 | tee -a "$LOG_FILE"; then
            log "✓ JavaScript formatting successful"
            return 0
        else
            log "✗ JavaScript formatting failed"
            return 1
        fi
    else
        log "⚠ Prettier not found, skipping JavaScript formatting"
        return 0
    fi
}

# Format Markdown files
format_markdown() {
    local filepath="$1"
    log "Formatting Markdown file: $filepath"

    cd "$PROJECT_ROOT"
    if [ -f "./assets/node_modules/.bin/markdownlint-cli2" ]; then
        if ./assets/node_modules/.bin/markdownlint-cli2 --fix "$filepath" 2>&1 | tee -a "$LOG_FILE"; then
            log "✓ Markdown formatting successful"
            return 0
        else
            log "✗ Markdown formatting failed"
            return 1
        fi
    else
        log "⚠ markdownlint-cli2 not found, skipping Markdown formatting"
        return 0
    fi
}

# Main function
main() {
    log "=== Auto-format hook started ==="

    # Read and parse input
    local input
    input=$(cat)

    # Extract file path
    local filepath
    filepath=$(echo "$input" | parse_file_path)

    if [ -z "$filepath" ]; then
        log "No file path found in input, skipping formatting"
        exit 0
    fi

    # Make path absolute if relative
    if [[ ! "$filepath" =~ ^/ ]]; then
        filepath="${PROJECT_ROOT}/${filepath}"
    fi

    log "File path: $filepath"

    # Check if file exists
    if [ ! -f "$filepath" ]; then
        log "File does not exist: $filepath"
        exit 0
    fi

    # Get file extension
    local ext
    ext=$(get_extension "$filepath")
    log "File extension: $ext"

    # Format based on extension
    case "$ext" in
        ex|exs)
            format_elixir "$filepath"
            ;;
        js|jsx|ts|tsx)
            format_javascript "$filepath"
            ;;
        md)
            format_markdown "$filepath"
            ;;
        *)
            log "No formatter configured for .$ext files"
            ;;
    esac

    log "=== Auto-format hook completed ==="
    exit 0
}

# Execute main function
main "$@"
