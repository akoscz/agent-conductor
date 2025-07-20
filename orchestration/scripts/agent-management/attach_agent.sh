#!/bin/bash

# Attach to Agent Session - Fully Dynamic
# Uses configuration to validate agent types instead of hardcoded list

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

AGENT_TYPE=$1

if [[ -z "$AGENT_TYPE" ]]; then
    echo "Usage: ./attach_agent.sh <agent-type>"
    echo ""
    show_agent_types_help "$(get_agent_types "$AGENTS_CONFIG_FILE" | tr '\n' ' ')"
    exit 1
fi

# Load agent configuration to get session name
if ! load_agent_config "$AGENT_TYPE" "$AGENTS_CONFIG_FILE"; then
    exit_code=$?
    echo "$(get_agent_config_error_message $exit_code "$AGENT_TYPE")"
    if [[ $exit_code -eq 3 ]]; then
        echo "Available agents: $(get_agent_types "$AGENTS_CONFIG_FILE" | tr '\n' ', ' | sed 's/, $//')"
    fi
    exit $exit_code
fi

# Validate session name
if ! validate_session_name "$AGENT_SESSION_NAME"; then
    echo "❌ Invalid session name: $AGENT_SESSION_NAME"
    exit 1
fi

# Check if session exists and attach
available_agents=$(get_agent_types "$AGENTS_CONFIG_FILE" | tr '\n' ' ')

result=$(attach_to_agent "$AGENT_TYPE" "$AGENT_SESSION_NAME" "$available_agents")
exit_code=$?

case $exit_code in
    0)
        echo "$(get_session_success_message "attach" "$AGENT_SESSION_NAME")"
        show_attachment_instructions
        ;;
    3)
        echo "$(get_agent_session_error_message $exit_code "$AGENT_TYPE")"
        show_deployment_suggestion "$AGENT_TYPE"
        exit $exit_code
        ;;
    *)
        echo "$(get_agent_session_error_message $exit_code "$AGENT_TYPE")"
        exit $exit_code
        ;;
esac