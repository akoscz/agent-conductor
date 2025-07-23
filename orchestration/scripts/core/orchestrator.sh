#!/bin/bash

# SurveyForge AI Agent Orchestrator - Main Script (Thin CLI wrapper)
# Configuration-driven orchestration system using orchestrator library

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

COMMAND=$1

# Define help function (available throughout script)
show_help() {
    echo "🤖 Agent Conductor"
    echo "====================================="
    echo ""
    echo "Usage: conductor <command> [args...]"
    echo ""
    echo "Commands:"
    echo "  init                           Initialize conductor environment"
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
    echo "Examples:"
    echo "  conductor init"
    echo "  conductor deploy rust 21"
    echo "  conductor deploy react 22"
    echo "  conductor list"
    echo "  conductor attach rust"
    echo "  conductor send rust 'cargo --version'"
    echo "  conductor stop-all"
}

# Handle help commands without loading configuration
if [[ "$COMMAND" == "help" ]] || [[ "$COMMAND" == "-h" ]] || [[ "$COMMAND" == "--help" ]] || [[ -z "$COMMAND" ]]; then
    show_help
    exit 0
fi

# For all other commands, load configuration and libraries
source "$SCRIPT_DIR/config_loader.sh" || {
    echo "❌ Failed to load configuration"
    exit 1
}

source "$SCRIPT_DIR/../lib/orchestrator_lib.sh" || {
    echo "❌ Failed to load orchestrator library"
    exit 1
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
                
                # Suggest similar commands for common typos
                case "$COMMAND" in
                    "deply"|"deplyo"|"depoly")
                        echo "💡 Did you mean: conductor deploy <agent-type> <task-id>"
                        ;;
                    "lst"|"lis")
                        echo "💡 Did you mean: conductor list"
                        ;;
                    "attch"|"atach")
                        echo "💡 Did you mean: conductor attach <agent-type>"
                        ;;
                    "stp"|"stop")
                        echo "💡 Did you mean: conductor stop-all"
                        ;;
                    "stat"|"stats")
                        echo "💡 Did you mean: conductor status"
                        ;;
                    "conf"|"cfg")
                        echo "💡 Did you mean: conductor config"
                        ;;
                esac
                
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