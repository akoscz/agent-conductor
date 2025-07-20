#!/bin/bash

# Stop All AI Agents - Fully Dynamic
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

echo "🛑 Stopping all $PROJECT_NAME AI agents..."

# Get all configured agent types
agent_types=$(get_agent_types "$AGENTS_CONFIG_FILE" | tr '\n' ' ')

# Kill all agent sessions using library function
result=$(kill_agent_sessions "$agent_types" "$ORCHESTRATOR_LOG")
exit_code=$?

case $exit_code in
    0)
        # Success - extract stopped count from result
        stopped_count=$(echo "$result" | head -n1)
        echo ""
        echo "$(get_session_success_message "stop_multiple" "" "$stopped_count")"
        ;;
    2)
        echo "❌ No tmux server running"
        exit 0
        ;;
    3)
        echo "💤 No agent sessions found"
        exit 0
        ;;
    4)
        # Some sessions failed - extract counts and show failures
        stopped_count=$(echo "$result" | head -n1)
        failed_sessions=$(echo "$result" | tail -n+2 | grep "^FAILED:" | sed 's/FAILED: //')
        echo ""
        echo "$(get_session_success_message "stop_multiple" "" "$stopped_count")"
        echo "❌ Failed to stop: $failed_sessions"
        ;;
    *)
        echo "❌ Error stopping agent sessions (code: $exit_code)"
        exit $exit_code
        ;;
esac

# Update task assignments to reflect stopped agents
if update_task_assignments_on_stop "$TASK_ASSIGNMENTS_FILE"; then
    echo "📝 Updated task assignments to reflect stopped agents"
else
    echo "⚠️ Warning: Could not update task assignments file"
fi

echo "🏁 All agents stopped. Ready for fresh deployment."