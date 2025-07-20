#!/bin/bash

# Orchestrator Library - Testable orchestration management functions
# Provides core orchestrator initialization and management functionality

# Dependency injection for external commands (allows mocking in tests)
DATE_CMD="${DATE_CMD:-date}"
MKDIR_CMD="${MKDIR_CMD:-mkdir}"
CAT_CMD="${CAT_CMD:-cat}"
ECHO_CMD="${ECHO_CMD:-echo}"
AWK_CMD="${AWK_CMD:-awk}"
GREP_CMD="${GREP_CMD:-grep}"
HEAD_CMD="${HEAD_CMD:-head}"
TAIL_CMD="${TAIL_CMD:-tail}"
SED_CMD="${SED_CMD:-sed}"
TR_CMD="${TR_CMD:-tr}"
CD_CMD="${CD_CMD:-cd}"

# Error message functions
get_orchestrator_error_message() {
    local error_code="$1"
    case "$error_code" in
        1) echo "Cannot access workspace directory" ;;
        2) echo "Failed to create directory structure" ;;
        3) echo "Failed to create memory files" ;;
        4) echo "Configuration validation failed" ;;
        5) echo "Project state file not found" ;;
        6) echo "Task assignments file not found" ;;
        7) echo "Failed to initialize logging" ;;
        8) echo "Invalid orchestrator command" ;;
        9) echo "Missing required parameters" ;;
        10) echo "Blockers file not accessible" ;;
        *) echo "Unknown orchestrator error" ;;
    esac
}

# Validation functions
validate_workspace_access() {
    local workspace_dir="$1"
    
    if [[ -z "$workspace_dir" ]]; then
        return 9  # Missing required parameter
    fi
    
    if [[ ! -d "$workspace_dir" ]]; then
        return 1  # Cannot access workspace directory
    fi
    
    # Test write access
    if ! touch "$workspace_dir/.orchestrator_test" 2>/dev/null; then
        return 1  # Cannot write to workspace directory
    fi
    
    # Clean up test file
    rm -f "$workspace_dir/.orchestrator_test" 2>/dev/null
    
    return 0
}

validate_orchestrator_environment() {
    local workspace_dir="$1"
    local orchestration_dir="$2"
    
    # Check workspace access
    if ! validate_workspace_access "$workspace_dir"; then
        return 1  # Cannot access workspace directory
    fi
    
    # Check if orchestration directory exists
    if [[ ! -d "$orchestration_dir" ]]; then
        return 1  # Orchestration directory missing
    fi
    
    # Check if configuration files exist (assumes config functions are available)
    if ! check_config_files_exist 2>/dev/null; then
        return 4  # Configuration validation failed
    fi
    
    return 0
}

# Directory management functions
create_directory_structure() {
    local memory_dir="$1"
    local logs_dir="$2"
    local agent_logs_dir="$3"
    
    if [[ -z "$memory_dir" ]] || [[ -z "$logs_dir" ]] || [[ -z "$agent_logs_dir" ]]; then
        return 9  # Missing required parameters
    fi
    
    # Create directories with proper error checking
    if ! $MKDIR_CMD -p "$memory_dir" 2>/dev/null; then
        return 2  # Failed to create memory directory
    fi
    
    if ! $MKDIR_CMD -p "$logs_dir" 2>/dev/null; then
        return 2  # Failed to create logs directory
    fi
    
    if ! $MKDIR_CMD -p "$agent_logs_dir" 2>/dev/null; then
        return 2  # Failed to create agent logs directory
    fi
    
    return 0
}

# Memory file creation functions
create_initial_memory_files() {
    local project_state_file="$1"
    local task_assignments_file="$2"
    local blockers_file="$3"
    local decisions_file="$4"
    local project_name="$5"
    
    if [[ -z "$project_state_file" ]] || [[ -z "$task_assignments_file" ]] || 
       [[ -z "$blockers_file" ]] || [[ -z "$decisions_file" ]] || [[ -z "$project_name" ]]; then
        return 9  # Missing required parameters
    fi
    
    # Create project state file
    if ! create_project_state_file "$project_state_file" "$project_name"; then
        return 3  # Failed to create project state file
    fi
    
    # Create task assignments file
    if ! create_task_assignments_file "$task_assignments_file"; then
        return 3  # Failed to create task assignments file
    fi
    
    # Create blockers file
    if ! create_blockers_file "$blockers_file"; then
        return 3  # Failed to create blockers file
    fi
    
    # Create decisions file
    if ! create_decisions_file "$decisions_file"; then
        return 3  # Failed to create decisions file
    fi
    
    return 0
}

create_project_state_file() {
    local project_state_file="$1"
    local project_name="$2"
    local timestamp
    
    timestamp=$($DATE_CMD)
    
    $CAT_CMD > "$project_state_file" << EOF
# $project_name Project State

## Current Phase: Phase 1 - Foundation

## Active Tasks
- [ ] #19: Development Environment Setup
- [ ] #20: Project Architecture Setup

## Completed Tasks
None yet

## Blockers
None

Last Updated: $timestamp
EOF
    
    return $?
}

create_task_assignments_file() {
    local task_assignments_file="$1"
    local timestamp
    
    timestamp=$($DATE_CMD)
    
    # Start the file
    {
        echo "# Task Assignments - Updated: $timestamp"
        echo ""
        
        # Generate assignments for each configured agent
        get_agent_types 2>/dev/null | while read -r agent; do
            get_agent_config "$agent" &>/dev/null
            local agent_display_name="$(echo "$agent" | sed 's/^./\U&/') Agent"
            
            echo "## $agent_display_name"
            echo "- **Current**: Not assigned"
            echo "- **Status**: Idle"
            echo "- **Session**: None"
            
            # Generate next task suggestion based on agent type
            case "$agent" in
                rust) echo "- **Next**: Backend implementation tasks" ;;
                react) echo "- **Next**: Frontend component tasks" ;;
                devops) echo "- **Next**: Infrastructure and deployment tasks" ;;
                qa) echo "- **Next**: Review completed implementations" ;;
                pm) echo "- **Next**: Coordinate project workflow" ;;
                docs) echo "- **Next**: Update documentation" ;;
                *) echo "- **Next**: Available for assignment" ;;
            esac
            echo ""
        done
    } > "$task_assignments_file"
    
    return $?
}

create_blockers_file() {
    local blockers_file="$1"
    local timestamp
    
    timestamp=$($DATE_CMD)
    
    $CAT_CMD > "$blockers_file" << EOF
# Project Blockers

## Current Blockers
None

## Resolved Blockers
None

Last Updated: $timestamp
EOF
    
    return $?
}

create_decisions_file() {
    local decisions_file="$1"
    local timestamp
    
    timestamp=$($DATE_CMD)
    
    $CAT_CMD > "$decisions_file" << EOF
# Technical Decisions Log

## Architecture Decisions
- **Framework**: Tauri v2 (Rust + React)
- **Data Processing**: Polars for performance
- **State Management**: Zustand for React
- **UI Components**: Ant Design

## Implementation Decisions
To be documented as agents make choices...

Last Updated: $timestamp
EOF
    
    return $?
}

# Logging functions
setup_logging() {
    local orchestrator_log="$1"
    local project_name="$2"
    local timestamp
    
    if [[ -z "$orchestrator_log" ]] || [[ -z "$project_name" ]]; then
        return 9  # Missing required parameters
    fi
    
    timestamp=$($DATE_CMD '+%Y-%m-%d %H:%M:%S')
    
    if ! echo "$timestamp - Orchestrator initialized for $project_name" > "$orchestrator_log"; then
        return 7  # Failed to initialize logging
    fi
    
    return 0
}

add_log_entry() {
    local log_file="$1"
    local message="$2"
    local timestamp
    
    if [[ -z "$log_file" ]] || [[ -z "$message" ]]; then
        return 9  # Missing required parameters
    fi
    
    timestamp=$($DATE_CMD '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp - $message" >> "$log_file" 2>/dev/null
    
    return $?
}

# Status and summary functions
get_project_state_summary() {
    local project_state_file="$1"
    
    if [[ -z "$project_state_file" ]]; then
        return 9  # Missing required parameter
    fi
    
    if [[ ! -f "$project_state_file" ]]; then
        echo "No project state file found"
        return 5  # Project state file not found
    fi
    
    # Extract key sections
    $GREP_CMD -E "^## (Current Phase|Active Tasks|Completed Tasks|Blockers)" "$project_state_file" | 
    $SED_CMD 's/^##/  •/' 2>/dev/null || echo "  • No structured status found"
    
    return 0
}

get_agent_assignments_summary() {
    local task_assignments_file="$1"
    
    if [[ -z "$task_assignments_file" ]]; then
        return 9  # Missing required parameter
    fi
    
    if [[ ! -f "$task_assignments_file" ]]; then
        echo "No assignments found"
        return 6  # Task assignments file not found
    fi
    
    # Parse agent assignments
    $AWK_CMD '/^## / { 
        agent=$2; 
        getline; 
        if(/Current.*Not assigned/) 
            status="💤 Idle"; 
        else 
            status="🔄 Active"; 
        print "  • " agent ": " status 
    }' "$task_assignments_file" 2>/dev/null || echo "  • No assignments found"
    
    return 0
}

get_current_blockers() {
    local blockers_file="$1"
    
    if [[ -z "$blockers_file" ]]; then
        return 9  # Missing required parameter
    fi
    
    if [[ ! -f "$blockers_file" ]]; then
        return 10  # Blockers file not accessible
    fi
    
    # Check if there are actual blockers
    if ! $GREP_CMD -q "## Current Blockers" "$blockers_file"; then
        return 0  # No blockers section
    fi
    
    local blockers
    blockers=$($AWK_CMD '/^## Current Blockers/,/^## / {
        if(!/^##/ && !/^$/ && !/^None/) print
    }' "$blockers_file" 2>/dev/null)
    
    if [[ -n "$blockers" ]]; then
        echo "$blockers" | $SED_CMD 's/^/  • /'
        return 0
    fi
    
    return 0  # No current blockers
}

# Orchestrator command handling
handle_orchestrator_command() {
    local command="$1"
    local scripts_dir="$2"
    shift 2
    local args=("$@")
    
    if [[ -z "$command" ]] || [[ -z "$scripts_dir" ]]; then
        return 9  # Missing required parameters
    fi
    
    case "$command" in
        "init")
            "$scripts_dir/core/init_orchestrator.sh"
            return $?
            ;;
        "deploy")
            if [[ ${#args[@]} -lt 2 ]]; then
                return 9  # Missing required parameters for deploy
            fi
            "$scripts_dir/agent-management/deploy_agent.sh" "${args[0]}" "${args[1]}"
            return $?
            ;;
        "list")
            "$scripts_dir/agent-management/list_agents.sh"
            return $?
            ;;
        "attach")
            if [[ ${#args[@]} -lt 1 ]]; then
                return 9  # Missing required parameters for attach
            fi
            "$scripts_dir/agent-management/attach_agent.sh" "${args[0]}"
            return $?
            ;;
        "send")
            if [[ ${#args[@]} -lt 2 ]]; then
                return 9  # Missing required parameters for send
            fi
            "$scripts_dir/communication/send_command.sh" "${args[0]}" "${args[1]}"
            return $?
            ;;
        "stop-all")
            "$scripts_dir/agent-management/stop_all_agents.sh"
            return $?
            ;;
        "status")
            return 0  # Status handled by calling function
            ;;
        "config")
            return 0  # Config handled by calling function
            ;;
        "validate")
            return 0  # Validate handled by calling function
            ;;
        *)
            return 8  # Invalid orchestrator command
            ;;
    esac
}

# Initialization functions
initialize_orchestrator() {
    local workspace_dir="$1"
    local orchestration_dir="$2"
    local project_name="$3"
    local memory_dir="$4"
    local logs_dir="$5"
    local agent_logs_dir="$6"
    local project_state_file="$7"
    local task_assignments_file="$8"
    local blockers_file="$9"
    local decisions_file="${10}"
    local orchestrator_log="${11}"
    
    # Validate environment
    validate_orchestrator_environment "$workspace_dir" "$orchestration_dir"
    local error_code=$?
    if [[ $error_code -ne 0 ]]; then
        return $error_code
    fi
    
    # Ensure we're in the workspace directory
    if ! $CD_CMD "$workspace_dir" 2>/dev/null; then
        return 1  # Cannot access workspace directory
    fi
    
    # Create directory structure
    if ! create_directory_structure "$memory_dir" "$logs_dir" "$agent_logs_dir"; then
        local error_code=$?
        return $error_code
    fi
    
    # Create initial memory files
    if ! create_initial_memory_files "$project_state_file" "$task_assignments_file" \
                                   "$blockers_file" "$decisions_file" "$project_name"; then
        local error_code=$?
        return $error_code
    fi
    
    # Setup logging
    if ! setup_logging "$orchestrator_log" "$project_name"; then
        local error_code=$?
        return $error_code
    fi
    
    return 0
}

# Display functions
show_orchestrator_status() {
    local project_name="$1"
    local project_state_file="$2"
    local task_assignments_file="$3"
    local blockers_file="$4"
    local scripts_dir="$5"
    
    echo "📊 $project_name Project Status"
    echo "==============================="
    echo ""
    
    # Show project state
    echo "🏗️  Project State:"
    get_project_state_summary "$project_state_file"
    echo ""
    
    # Show agent assignments
    echo "👥 Agent Assignments:"
    get_agent_assignments_summary "$task_assignments_file"
    echo ""
    
    # Show active sessions
    echo "🖥️  Active Sessions:"
    if [[ -f "$scripts_dir/agent-management/list_agents.sh" ]]; then
        "$scripts_dir/agent-management/list_agents.sh" 2>/dev/null | 
        $TAIL_CMD -n +4 | $HEAD_CMD -n -6 | $SED_CMD 's/^/  /' || echo "  • No active sessions"
    else
        echo "  • Agent management script not found"
    fi
    echo ""
    
    # Show current blockers
    echo "⚠️  Current Blockers:"
    local blockers_output
    blockers_output=$(get_current_blockers "$blockers_file")
    if [[ -n "$blockers_output" ]]; then
        echo "$blockers_output"
    else
        echo "  • None"
    fi
    echo ""
    
    return 0
}

# Configuration display
show_orchestrator_configuration() {
    local workspace_dir="$1"
    local orchestration_dir="$2"
    local project_config_file="$3"
    local agents_config_file="$4"
    local memory_dir="$5"
    local prompts_dir="$6"
    local logs_dir="$7"
    local scripts_dir="$8"
    
    echo "🔧 Orchestrator Configuration"
    echo "============================="
    echo ""
    echo "📁 Directory Structure:"
    echo "  Workspace: $workspace_dir"
    echo "  Orchestration: $orchestration_dir"
    echo "  Memory: $memory_dir"
    echo "  Prompts: $prompts_dir"
    echo "  Logs: $logs_dir"
    echo "  Scripts: $scripts_dir"
    echo ""
    echo "⚙️  Configuration Files:"
    echo "  Project config: $project_config_file"
    echo "  Agents config: $agents_config_file"
    echo ""
    echo "🤖 Available Agents:"
    local agents_list
    agents_list=$(get_agent_types 2>/dev/null | $TR_CMD '\n' ', ' | $SED_CMD 's/, $//')
    echo "  $agents_list"
    echo ""
    
    return 0
}