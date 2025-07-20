#!/bin/bash

# List Active AI Agents - Fully Dynamic
# Uses configuration to discover agent types instead of hardcoded patterns

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
source "$SCRIPT_DIR/../lib/config_lib.sh" || {
    echo "❌ Failed to load configuration library"
    exit 1
}

source "$SCRIPT_DIR/../lib/session_lib.sh" || {
    echo "❌ Failed to load session library"
    exit 1
}

# Load configuration
if ! load_full_configuration "$SCRIPT_DIR"; then
    echo "❌ Failed to load configuration"
    exit 1
fi

# Get all configured agent types
agent_types=$(get_agent_types "$AGENTS_CONFIG_FILE" | tr '\n' ' ')

# Display agent sessions using library function
display_agent_sessions "$agent_types" "$PROJECT_NAME"
exit_code=$?

# Handle different exit codes
case $exit_code in
    0)
        # Success - sessions displayed
        show_session_commands
        ;;
    2|3)
        # No tmux server or no agents deployed - already handled by display function
        ;;
    *)
        echo "❌ Error displaying agent sessions (code: $exit_code)"
        exit $exit_code
        ;;
esac

# Show recent orchestrator activity
if [[ -f "$ORCHESTRATOR_LOG" ]]; then
    echo "📊 Recent Activity:"
    tail -5 "$ORCHESTRATOR_LOG" | sed 's/^/  /'
fi