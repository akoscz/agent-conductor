#!/bin/bash

# SurveyForge AI Agent Orchestrator - Agent Deployment Script
# Thin CLI wrapper around agent_lib.sh functionality

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies
source "$SCRIPT_DIR/../core/config_loader.sh" || {
    echo "❌ Failed to load configuration"
    exit 1
}

source "$SCRIPT_DIR/../lib/agent_lib.sh" || {
    echo "❌ Failed to load agent library"
    exit 1
}

# Parse command line arguments
AGENT_TYPE="$1"
TASK_NUMBER="$2"

# Show usage if arguments missing
show_usage() {
    echo "Usage: ./deploy_agent.sh <agent-type> <task-number>"
    echo "Example: ./deploy_agent.sh rust 21"
    echo ""
    echo "Available agent types:"
    get_agent_types | while read -r agent; do
        if get_agent_config "$agent" &>/dev/null; then
            echo "  - $agent ($AGENT_NAME)"
        fi
    done
}

# Validate arguments
if ! validate_agent_deployment_args "$AGENT_TYPE" "$TASK_NUMBER"; then
    show_usage
    exit 1
fi

# Show available agents if invalid type provided
if ! validate_agent_type "$AGENT_TYPE"; then
    echo "❌ Invalid agent type: $AGENT_TYPE"
    echo "Available agents: $(get_agent_types | tr '\n' ', ' | sed 's/, $//')"
    exit 1
fi

# Perform deployment
echo "🚀 Deploying ${AGENT_TYPE^} Agent for task #$TASK_NUMBER..."

if deploy_agent "$AGENT_TYPE" "$TASK_NUMBER"; then
    # Get agent config for success message
    get_agent_config "$AGENT_TYPE"
    
    get_deployment_success_info \
        "$AGENT_SESSION_NAME" \
        "$TASK_NUMBER" \
        "$GITHUB_OWNER" \
        "$GITHUB_REPO" \
        "$AGENT_PROMPT_FILE" \
        "$AGENT_TYPE"
else
    error_code=$?
    get_deployment_error_message "$error_code"
    exit $error_code
fi