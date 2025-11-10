#!/usr/bin/env bash
# Notification Hook - Send desktop notifications for important events
# Platform-specific notification support

set -euo pipefail

# Configuration
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${HOOKS_DIR}/hooks.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [notify] $*" >> "$LOG_FILE"
}

# Parse notification data from JSON input
parse_notification() {
    if command -v jq &> /dev/null; then
        local title
        local message
        title=$(jq -r '.title // "Claude Code"' 2>/dev/null || echo "Claude Code")
        message=$(jq -r '.message // .body // ""' 2>/dev/null || echo "")
        echo "$title|$message"
    else
        echo "Claude Code|Notification"
    fi
}

# Detect platform
detect_platform() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "mac";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

# Send notification on Linux
notify_linux() {
    local title="$1"
    local message="$2"

    if command -v notify-send &> /dev/null; then
        notify-send "$title" "$message" --icon=dialog-information --urgency=normal
        return 0
    else
        log "⚠ notify-send not available on Linux"
        return 1
    fi
}

# Send notification on macOS
notify_mac() {
    local title="$1"
    local message="$2"

    if command -v osascript &> /dev/null; then
        # Escape backslashes and double quotes for AppleScript string safety
        # Must escape backslashes first, then quotes
        local title_escaped="${title//\\/\\\\}"
        title_escaped="${title_escaped//\"/\\\"}"

        local message_escaped="${message//\\/\\\\}"
        message_escaped="${message_escaped//\"/\\\"}"

        osascript -e "display notification \"$message_escaped\" with title \"$title_escaped\""
        return 0
    else
        log "⚠ osascript not available on macOS"
        return 1
    fi
}

# Send notification on Windows
notify_windows() {
    local title="$1"
    local message="$2"

    # Use PowerShell for Windows notifications
    if command -v powershell.exe &> /dev/null; then
        # Base64-encode title and message to safely handle special characters
        # (single quotes, backticks, etc. that would break PowerShell interpolation)
        local title_b64
        local message_b64
        title_b64=$(echo -n "$title" | base64 -w 0 2>/dev/null || echo -n "$title" | base64)
        message_b64=$(echo -n "$message" | base64 -w 0 2>/dev/null || echo -n "$message" | base64)

        powershell.exe -Command "
            Add-Type -AssemblyName System.Windows.Forms
            \$titleB64 = '$title_b64'
            \$messageB64 = '$message_b64'
            \$title = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(\$titleB64))
            \$message = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(\$messageB64))
            \$notification = New-Object System.Windows.Forms.NotifyIcon
            \$notification.Icon = [System.Drawing.SystemIcons]::Information
            \$notification.BalloonTipTitle = \$title
            \$notification.BalloonTipText = \$message
            \$notification.Visible = \$true
            \$notification.ShowBalloonTip(3000)
        "
        return 0
    else
        log "⚠ PowerShell not available on Windows"
        return 1
    fi
}

# Check if notification should be sent based on content
should_notify() {
    local message="$1"

    # Keywords that trigger notifications
    local keywords=(
        "complete"
        "finished"
        "done"
        "ready"
        "failed"
        "error"
        "success"
        "test"
        "build"
        "check"
    )

    for keyword in "${keywords[@]}"; do
        if [[ "$message" =~ $keyword ]] || [[ "$message" =~ ${keyword^} ]]; then
            return 0
        fi
    done

    return 1
}

# Main function
main() {
    log "=== Notification hook started ==="

    # Read and parse input
    local input
    input=$(cat)

    # Parse notification data
    local notification_data
    notification_data=$(echo "$input" | parse_notification)

    local title
    local message
    IFS='|' read -r title message <<< "$notification_data"

    log "Notification request - Title: $title, Message: ${message:0:100}"

    # Check if we should send notification
    if ! should_notify "$message"; then
        log "Message does not match notification criteria, skipping"
        exit 0
    fi

    # Detect platform
    local platform
    platform=$(detect_platform)
    log "Platform detected: $platform"

    # Send notification based on platform
    case "$platform" in
        linux)
            if notify_linux "$title" "$message"; then
                log "✓ Notification sent successfully (Linux)"
            else
                log "✗ Failed to send notification (Linux)"
            fi
            ;;
        mac)
            if notify_mac "$title" "$message"; then
                log "✓ Notification sent successfully (macOS)"
            else
                log "✗ Failed to send notification (macOS)"
            fi
            ;;
        windows)
            if notify_windows "$title" "$message"; then
                log "✓ Notification sent successfully (Windows)"
            else
                log "✗ Failed to send notification (Windows)"
            fi
            ;;
        *)
            log "⚠ Unknown platform, cannot send notification"
            ;;
    esac

    log "=== Notification hook completed ==="
    exit 0
}

# Execute main function
main "$@"
