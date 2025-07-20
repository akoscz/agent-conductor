#!/bin/bash

# Send Command to Agent - Thin CLI wrapper
# Uses communication library for core functionality

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source configuration and libraries
source "$SCRIPT_DIR/../core/config_loader.sh" || {
    echo "❌ Failed to load configuration"
    exit 1
}

source "$SCRIPT_DIR/../lib/communication_lib.sh" || {
    echo "❌ Failed to load communication library"
    exit 1
}

AGENT_TYPE=$1
COMMAND=$2

# Show help if parameters missing
if [ -z "$AGENT_TYPE" ] || [ -z "$COMMAND" ]; then
    echo "Usage: ./send_command.sh <agent-type> '<command>'"
    echo ""
    echo "Examples:"
    show_command_examples
    echo ""
    echo "Available agent types: $(show_available_agents)"
    exit 1
fi

# Send command using library function
send_command_to_agent "$AGENT_TYPE" "$COMMAND"
result=$?

case $result in
    0)
        echo "📤 Sending command to $AGENT_SESSION_NAME ($AGENT_NAME): $COMMAND"
        echo "✅ Command sent successfully"
        echo ""
        echo "💡 To see the output:"
        echo "   ./orchestration/scripts/orchestrator.sh attach $AGENT_TYPE"
        echo "   # or"
        echo "   tmux capture-pane -t $AGENT_SESSION_NAME -p"
        ;;
    1|2)
        echo "❌ $(get_communication_error_message $result)"
        echo "Usage: ./send_command.sh <agent-type> '<command>'"
        exit 1
        ;;
    3)
        echo "❌ Invalid agent type: $AGENT_TYPE"
        echo "Available agents: $(show_available_agents)"
        exit 1
        ;;
    4)
        echo "❌ No session found for $AGENT_SESSION_NAME"
        echo ""
        echo "💡 Deploy the agent first:"
        echo "   ./orchestration/scripts/orchestrator.sh deploy $AGENT_TYPE <task-number>"
        exit 1
        ;;
    5)
        echo "❌ $(get_communication_error_message $result)"
        echo "Command rejected for security reasons"
        exit 1
        ;;
    *)
        echo "❌ $(get_communication_error_message $result)"
        exit 1
        ;;
esac