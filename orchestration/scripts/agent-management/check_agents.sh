#!/bin/bash

# SurveyForge AI Agent Orchestrator - Agent Health Check Script
# Comprehensive agent monitoring using testable libraries

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source configuration and libraries
source "$SCRIPT_DIR/../core/config_loader.sh" || {
    echo "❌ Failed to load configuration"
    exit 1
}

source "$SCRIPT_DIR/../lib/monitoring_lib.sh" || {
    echo "❌ Failed to load monitoring library"
    exit 1
}

# Load configuration to ensure environment variables are set
load_config

# Parse options
DETAILED_MODE="false"
HEALTH_CHECK_ONLY="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        --detailed|-d)
            DETAILED_MODE="true"
            shift
            ;;
        --health|-h)
            HEALTH_CHECK_ONLY="true"
            shift
            ;;
        --help)
            echo "Usage: ./check_agents.sh [options]"
            echo ""
            echo "Options:"
            echo "  --detailed, -d    Show detailed monitoring information"
            echo "  --health, -h      Show only health summary"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Get available agent types
AGENT_TYPES=$(get_agent_types | tr '\n' ' ')

if [[ "$HEALTH_CHECK_ONLY" == "true" ]]; then
    # Just show health summary
    get_health_summary "$AGENT_TYPES"
    exit $?
fi

if [[ "$DETAILED_MODE" == "true" ]]; then
    # Show comprehensive monitoring report
    generate_monitoring_report \
        "$AGENT_TYPES" \
        "$MEMORY_DIR" \
        "$TASK_ASSIGNMENTS_FILE" \
        "$PROJECT_STATE_FILE" \
        "$BLOCKERS_FILE"
else
    # Standard monitoring output with improved formatting
    echo "🤖 Active Agent Sessions:"
    
    active_sessions=$(list_active_agent_sessions "agent")
    if [[ -z "$active_sessions" ]]; then
        echo "   No agent sessions running"
        echo ""
        echo "💡 To deploy an agent:"
        echo "   ./scripts/agent-management/deploy_agent.sh <agent-type> <task-number>"
        echo ""
        echo "Available agent types: $(echo "$AGENT_TYPES" | tr ' ' ', ' | sed 's/, $//')"
    else
        echo ""
        printf "%-20s %-12s %-15s %s\n" "Session" "Status" "Activity" "Resources"
        printf "%-20s %-12s %-15s %s\n" "-------" "------" "--------" "---------"
        
        while read -r session; do
            if [[ -n "$session" ]]; then
                local status
                local activity_check
                local resources=""
                
                status=$(get_agent_status "$session")
                
                check_session_activity "$session" 300  # 5 minute threshold
                local activity_result=$?
                case $activity_result in
                    0) activity_check="🟢 Active" ;;
                    4) activity_check="🟡 Idle (>5min)" ;;
                    *) activity_check="🔴 Inactive" ;;
                esac
                
                # Get resource usage if healthy
                if [[ "$status" == "Healthy" ]]; then
                    resources=$(get_resource_usage "$session" 2>/dev/null | cut -c1-25)
                fi
                
                format_agent_status_line "$session" "$status" "$activity_check" "$resources"
            fi
        done <<< "$active_sessions"
    fi
    
    echo ""
    
    # Current assignments
    echo "📊 Current Assignments:"
    check_task_assignments "$TASK_ASSIGNMENTS_FILE"
    
    echo ""
    
    # Project state
    echo "📈 Project State:"
    check_project_state "$PROJECT_STATE_FILE"
    
    echo ""
    
    # Blockers
    echo "🚨 Blockers:"
    check_blockers "$BLOCKERS_FILE"
    
    echo ""
    
    # Health summary
    echo "💊 Health Summary:"
    get_health_summary "$AGENT_TYPES"
    health_result=$?
    
    if [[ $health_result -ne 0 ]]; then
        echo ""
        echo "💡 Use './check_agents.sh --detailed' for more information"
        echo "💡 Use './check_agents.sh --health' for health-only summary"
    fi
fi