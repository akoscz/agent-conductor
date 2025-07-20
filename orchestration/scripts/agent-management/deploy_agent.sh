#!/bin/bash

# SurveyForge AI Agent Orchestrator - Agent Deployment Script
# Configuration-driven agent deployment using testable libraries

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source configuration and libraries
source "$SCRIPT_DIR/../core/config_loader.sh" || {
    echo "❌ Failed to load configuration"
    exit 1
}

source "$SCRIPT_DIR/../lib/agent_lib.sh" || {
    echo "❌ Failed to load agent library"
    exit 1
}

AGENT_TYPE=$1
TASK_NUMBER=$2
FORCE_DEPLOY="false"

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)
            FORCE_DEPLOY="true"
            shift
            ;;
        *)
            if [[ -z "$AGENT_TYPE" ]]; then
                AGENT_TYPE="$1"
            elif [[ -z "$TASK_NUMBER" ]]; then
                TASK_NUMBER="$1"
            fi
            shift
            ;;
    esac
done

# Display usage if missing parameters
if [[ -z "$AGENT_TYPE" ]] || [[ -z "$TASK_NUMBER" ]]; then
    echo "Usage: ./deploy_agent.sh [options] <agent-type> <task-number>"
    echo "Example: ./deploy_agent.sh rust 21"
    echo ""
    echo "Options:"
    echo "  --force, -f    Force deployment even if session exists"
    echo ""
    echo "Available agent types:"
    get_agent_types | while read -r agent; do
        if get_agent_config "$agent" &>/dev/null; then
            echo "  - $agent ($AGENT_NAME)"
        fi
    done
    exit 1
fi

# Load configuration to ensure environment variables are set
load_config

echo "🚀 Deploying $AGENT_TYPE agent for task #$TASK_NUMBER..."

# Use enhanced deployment function with validation
deploy_agent_with_validation "$AGENT_TYPE" "$TASK_NUMBER" "$FORCE_DEPLOY"
deployment_result=$?

if [[ $deployment_result -eq 0 ]]; then
    # Successful deployment - show success info
    get_deployment_success_info \
        "$AGENT_SESSION_NAME" \
        "$TASK_NUMBER" \
        "$GITHUB_OWNER" \
        "$GITHUB_REPO" \
        "$AGENT_PROMPT_FILE" \
        "$AGENT_TYPE"
else
    # Deployment failed - show error message
    echo "$(get_enhanced_deployment_error_message $deployment_result)"
    
    # Show additional context for specific errors
    case $deployment_result in
        26)
            # Task already assigned - show which agent has it
            conflict_info=$(check_deployment_conflicts "$AGENT_SESSION_NAME" "$TASK_NUMBER" 2>&1)
            if [[ -n "$conflict_info" ]]; then
                echo "Current assignment: $conflict_info"
            fi
            ;;
        25)
            # Session exists - suggest force option
            echo "💡 Use --force to override the existing session"
            ;;
        22)
            # Prompt file missing
            echo "💡 Expected prompt file: $AGENT_PROMPT_FILE"
            echo "💡 Create the prompt file or check the agent configuration"
            ;;
    esac
    
    exit $deployment_result
fi