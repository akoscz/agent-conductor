#!/bin/bash

# SurveyForge AI Agent Orchestrator - Initialization Script (Thin CLI wrapper)
# Configuration-driven setup using orchestrator library

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source configuration and libraries
source "$SCRIPT_DIR/config_loader.sh" || {
    echo "❌ Failed to load configuration"
    exit 1
}

source "$SCRIPT_DIR/../lib/orchestrator_lib.sh" || {
    echo "❌ Failed to load orchestrator library"
    exit 1
}

echo "🚀 Initializing $PROJECT_NAME AI Orchestrator..."
echo "Workspace: $WORKSPACE_DIR"
echo "Orchestration: $ORCHESTRATION_DIR"
echo ""

# Initialize using library function
initialize_orchestrator "$WORKSPACE_DIR" "$ORCHESTRATION_DIR" "$PROJECT_NAME" \
                       "$MEMORY_DIR" "$LOGS_DIR" "$AGENT_LOGS_DIR" \
                       "$PROJECT_STATE_FILE" "$TASK_ASSIGNMENTS_FILE" \
                       "$BLOCKERS_FILE" "$DECISIONS_FILE" "$ORCHESTRATOR_LOG"
result=$?

case $result in
    0)
        echo ""
        echo "✅ $PROJECT_NAME Orchestrator initialized successfully!"
        echo ""
        echo "📁 Directory Structure:"
        echo "  $MEMORY_DIR - Shared state files"
        echo "  $PROMPTS_DIR - Agent prompt templates" 
        echo "  $LOGS_DIR - Activity logs"
        echo "  $SCRIPTS_DIR - Orchestration scripts"
        echo ""
        echo "🔧 Configuration:"
        echo "  Project config: $PROJECT_CONFIG_FILE"
        echo "  Agents config: $AGENTS_CONFIG_FILE"
        echo "  Available agents: $(get_agent_types | tr '\n' ', ' | sed 's/, $//')"
        echo ""
        echo "🚀 Next steps:"
        echo "  1. Deploy agents: ./orchestration/scripts/orchestrator.sh deploy <agent-type> <task-id>"
        echo "  2. Check status: ./orchestration/scripts/orchestrator.sh status"
        echo "  3. List agents: ./orchestration/scripts/orchestrator.sh list"
        ;;
    *)
        echo "❌ $(get_orchestrator_error_message $result)"
        exit 1
        ;;
esac