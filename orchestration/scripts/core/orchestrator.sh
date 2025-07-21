#!/bin/bash

# SurveyForge AI Agent Orchestrator - Main Script (Thin CLI wrapper)
# Configuration-driven orchestration system using orchestrator library

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

COMMAND=$1

show_help() {
    echo "🤖 $PROJECT_NAME AI Agent Orchestrator"
    echo "====================================="
    echo ""
    echo "Usage: ./orchestration/scripts/orchestrator.sh <command> [args...]"
    echo ""
    echo "Commands:"
    echo "  init                           Initialize orchestrator environment"
    echo "  deploy <agent-type> <task-id>  Deploy specific agent for task"
    echo "  list                           List all active agent sessions"
    echo "  list-available                 List all configured agent types"
    echo "  attach <agent-type>            Attach to specific agent session"  
    echo "  send <agent-type> '<command>'  Send command to agent session"
    echo "  stop-all                       Stop all agent sessions"
    echo "  status                         Show project status and assignments"
    echo "  config                         Show configuration details"
    echo "  validate                       Validate configuration and tools"
    echo ""
    echo "Agent Types: $(get_agent_types | tr '\n' ', ' | sed 's/, $//')"
    echo ""
    echo "Examples:"
    echo "  ./orchestration/scripts/orchestrator.sh init"
    echo "  ./orchestration/scripts/orchestrator.sh deploy rust 21"
    echo "  ./orchestration/scripts/orchestrator.sh deploy react 22"
    echo "  ./orchestration/scripts/orchestrator.sh list"
    echo "  ./orchestration/scripts/orchestrator.sh attach rust"
    echo "  ./orchestration/scripts/orchestrator.sh send rust 'cargo --version'"
    echo "  ./orchestration/scripts/orchestrator.sh stop-all"
}

case "$COMMAND" in
    "status")
        show_orchestrator_status "$PROJECT_NAME" "$PROJECT_STATE_FILE" "$TASK_ASSIGNMENTS_FILE" "$BLOCKERS_FILE" "$SCRIPTS_DIR"
        ;;
    "config")
        show_orchestrator_configuration "$WORKSPACE_DIR" "$ORCHESTRATION_DIR" "$PROJECT_CONFIG_FILE" "$AGENTS_CONFIG_FILE" "$MEMORY_DIR" "$PROMPTS_DIR" "$LOGS_DIR" "$SCRIPTS_DIR"
        ;;
    "validate")
        validate_config
        ;;
    "help"|"-h"|"--help"|"")
        show_help
        ;;
    *)
        # Handle all other commands through the library
        shift  # Remove the command from arguments
        handle_orchestrator_command "$COMMAND" "$SCRIPTS_DIR" "$@"
        result=$?
        
        case $result in
            0)
                # Command succeeded, no additional output needed
                ;;
            8)
                echo "❌ Unknown command: $COMMAND"
                echo ""
                show_help
                exit 1
                ;;
            9)
                case "$COMMAND" in
                    "deploy")
                        echo "❌ Usage: orchestrator.sh deploy <agent-type> <task-id>"
                        echo "Available agents: $(get_agent_types | tr '\n' ', ' | sed 's/, $//')"
                        echo "Example: orchestrator.sh deploy rust 21"
                        ;;
                    "attach")
                        echo "❌ Usage: orchestrator.sh attach <agent-type>"
                        echo "Available: $(get_agent_types | tr '\n' ', ' | sed 's/, $//')"
                        ;;
                    "send")
                        echo "❌ Usage: orchestrator.sh send <agent-type> '<command>'"
                        echo "Example: orchestrator.sh send rust 'cargo --version'"
                        ;;
                    *)
                        echo "❌ $(get_orchestrator_error_message $result)"
                        ;;
                esac
                exit 1
                ;;
            *)
                echo "❌ $(get_orchestrator_error_message $result)"
                exit 1
                ;;
        esac
        ;;
esac