#!/bin/bash

# Agent Library - Testable agent management functions
# Provides core agent deployment and management functionality

# Dependency injection for external commands (allows mocking in tests)
TMUX_CMD="${TMUX_CMD:-tmux}"
DATE_CMD="${DATE_CMD:-date}"
AWK_CMD="${AWK_CMD:-awk}"
MV_CMD="${MV_CMD:-mv}"
GREP_CMD="${GREP_CMD:-grep}"
WC_CMD="${WC_CMD:-wc}"
HEAD_CMD="${HEAD_CMD:-head}"
CAT_CMD="${CAT_CMD:-cat}"

# Validation functions
validate_agent_deployment_args() {
    local agent_type="$1"
    local task_number="$2"
    
    if [[ -z "$agent_type" ]]; then
        return 1  # Missing agent type
    fi
    
    if [[ -z "$task_number" ]]; then
        return 2  # Missing task number
    fi
    
    # Validate task number is numeric
    if ! [[ "$task_number" =~ ^[0-9]+$ ]]; then
        return 3  # Invalid task number format
    fi
    
    return 0
}

validate_agent_type() {
    local agent_type="$1"
    
    # This function assumes get_agent_types is available from config_loader
    if ! get_agent_types | grep -q "^$agent_type$"; then
        return 1  # Invalid agent type
    fi
    
    return 0
}

# Session management functions
check_session_exists() {
    local session_name="$1"
    $TMUX_CMD has-session -t "$session_name" 2>/dev/null
}

kill_existing_session() {
    local session_name="$1"
    $TMUX_CMD kill-session -t "$session_name" 2>/dev/null
}

create_agent_session() {
    local session_name="$1"
    local workspace_dir="${2:-$PWD}"
    
    $TMUX_CMD new-session -d -s "$session_name" -c "$workspace_dir"
    return $?
}

send_session_command() {
    local session_name="$1"
    local command="$2"
    
    $TMUX_CMD send-keys -t "$session_name" "$command" Enter
    return $?
}

# Setup agent environment in session
setup_agent_environment() {
    local session_name="$1"
    local agent_name="$2"
    local task_number="$3"
    local prompt_file="$4"
    local memory_dir="$5"
    local github_owner="$6"
    local github_repo="$7"
    
    # Send setup commands
    send_session_command "$session_name" "clear"
    send_session_command "$session_name" "echo '🤖 Agent: $agent_name | Task: #$task_number | Session: $session_name'"
    send_session_command "$session_name" "echo '📋 Prompt: $prompt_file'"
    send_session_command "$session_name" "echo '💾 Memory: $memory_dir/'"
    send_session_command "$session_name" "echo '🔗 GitHub: https://github.com/$github_owner/$github_repo/issues/$task_number'"
    send_session_command "$session_name" "echo ''"
    send_session_command "$session_name" "echo 'Ready for Claude Code agent deployment...'"
    
    return 0
}

# Task assignment file management
update_task_assignment() {
    local agent_type="$1"
    local task_number="$2"
    local session_name="$3"
    local assignments_file="${4:-$TASK_ASSIGNMENTS_FILE}"
    
    # Return early if file doesn't exist
    if [[ ! -f "$assignments_file" ]]; then
        return 1
    fi
    
    local timestamp
    timestamp=$($DATE_CMD '+%Y-%m-%d %H:%M:%S')
    local agent_display="$(echo "$agent_type" | sed 's/^./\U&/') Agent"
    
    # Use AWK to update the assignments file
    $AWK_CMD -v agent="$agent_display" -v task="$task_number" -v ts="$timestamp" -v session="$session_name" '
        /^# Task Assignments/ { print $0 " - Updated: " ts; next }
        $0 ~ "^## " agent { 
            print $0
            print "- **Current**: Task #" task " (assigned " ts ")"
            print "- **Status**: Active"
            print "- **Session**: " session
            # Skip next 4 lines (old assignment info)
            getline; getline; getline; getline; getline
            next
        }
        { print }
    ' "$assignments_file" > "$assignments_file.tmp"
    
    # Atomic move
    $MV_CMD "$assignments_file.tmp" "$assignments_file"
    return $?
}

# Logging functions
log_deployment() {
    local agent_name="$1"
    local task_number="$2"
    local log_file="${3:-$ORCHESTRATOR_LOG}"
    
    local timestamp
    timestamp=$($DATE_CMD '+%Y-%m-%d %H:%M:%S')
    
    echo "$timestamp - Deployed $agent_name for task #$task_number" >> "$log_file"
    return $?
}

# Main deployment orchestration function
deploy_agent() {
    local agent_type="$1"
    local task_number="$2"
    
    # Validate arguments
    validate_agent_deployment_args "$agent_type" "$task_number"
    local validation_result=$?
    if [[ $validation_result -ne 0 ]]; then
        return $validation_result
    fi
    
    # Validate agent type (requires config_loader to be sourced)
    if ! validate_agent_type "$agent_type"; then
        return 10  # Invalid agent type
    fi
    
    # Load agent configuration (requires config_loader)
    if ! get_agent_config "$agent_type"; then
        return 11  # Failed to load agent config
    fi
    
    # Handle existing session
    if check_session_exists "$AGENT_SESSION_NAME"; then
        kill_existing_session "$AGENT_SESSION_NAME"
    fi
    
    # Create new session
    if ! create_agent_session "$AGENT_SESSION_NAME" "$WORKSPACE_DIR"; then
        return 12  # Failed to create session
    fi
    
    # Setup agent environment
    setup_agent_environment \
        "$AGENT_SESSION_NAME" \
        "$AGENT_NAME" \
        "$task_number" \
        "$AGENT_PROMPT_FILE" \
        "$MEMORY_DIR" \
        "$GITHUB_OWNER" \
        "$GITHUB_REPO"
    
    # Update task assignments
    update_task_assignment "$agent_type" "$task_number" "$AGENT_SESSION_NAME"
    
    # Log deployment
    log_deployment "$AGENT_NAME" "$task_number"
    
    return 0
}

# Error message helpers
get_deployment_error_message() {
    local error_code="$1"
    
    case $error_code in
        1) echo "❌ Missing agent type" ;;
        2) echo "❌ Missing task number" ;;
        3) echo "❌ Invalid task number format (must be numeric)" ;;
        10) echo "❌ Invalid agent type" ;;
        11) echo "❌ Failed to load agent configuration" ;;
        12) echo "❌ Failed to create tmux session" ;;
        *) echo "❌ Unknown deployment error (code: $error_code)" ;;
    esac
}

# Success message helpers
get_deployment_success_info() {
    local session_name="$1"
    local task_number="$2"
    local github_owner="$3"
    local github_repo="$4"
    local prompt_file="$5"
    local agent_type="$6"
    
    echo "✅ Deployed $session_name for task #$task_number"
    echo "📋 To attach: tmux attach -t $session_name"
    echo "🔍 To monitor: tmux list-sessions | grep $agent_type"
    echo "🔗 GitHub issue: https://github.com/$github_owner/$github_repo/issues/$task_number"
    echo "📝 Agent prompt: $prompt_file"
}

# Additional deployment workflow functions
validate_deployment_prerequisites() {
    local workspace_dir="$1"
    local prompt_file="$2"
    local memory_dir="$3"
    
    # Check workspace directory
    if [[ ! -d "$workspace_dir" ]]; then
        return 1  # Workspace directory missing
    fi
    
    # Check prompt file exists
    if [[ ! -f "$prompt_file" ]]; then
        return 2  # Prompt file missing
    fi
    
    # Check memory directory exists or can be created
    if [[ ! -d "$memory_dir" ]]; then
        if ! mkdir -p "$memory_dir" 2>/dev/null; then
            return 3  # Cannot create memory directory
        fi
    fi
    
    # Check tmux is available
    if ! command -v "$TMUX_CMD" &> /dev/null; then
        return 4  # tmux not available
    fi
    
    return 0
}

check_deployment_conflicts() {
    local session_name="$1"
    local task_number="$2"
    local task_assignments_file="${3:-$TASK_ASSIGNMENTS_FILE}"
    
    # Check if session already exists
    if check_session_exists "$session_name"; then
        return 1  # Session already exists
    fi
    
    # Check if task is already assigned to another agent
    if [[ -f "$task_assignments_file" ]]; then
        if $GREP_CMD -q "Task #$task_number" "$task_assignments_file"; then
            # Extract which agent has this task
            local assigned_agent
            assigned_agent=$($GREP_CMD -B 1 "Task #$task_number" "$task_assignments_file" | $GREP_CMD "^##" | $AWK_CMD '{print $2, $3}')
            if [[ -n "$assigned_agent" ]]; then
                echo "$assigned_agent"
                return 2  # Task already assigned
            fi
        fi
    fi
    
    return 0
}

prepare_deployment_environment() {
    local workspace_dir="$1"
    local memory_dir="$2"
    local logs_dir="$3"
    
    # Ensure all required directories exist
    local dirs=("$workspace_dir" "$memory_dir" "$logs_dir")
    
    for dir in "${dirs[@]}"; do
        if [[ -n "$dir" ]] && [[ ! -d "$dir" ]]; then
            if ! mkdir -p "$dir" 2>/dev/null; then
                return 1  # Failed to create directory
            fi
        fi
    done
    
    return 0
}

create_deployment_backup() {
    local task_assignments_file="$1"
    
    if [[ -f "$task_assignments_file" ]]; then
        local backup_file="${task_assignments_file}.backup.$(date +%Y%m%d_%H%M%S)"
        if ! cp "$task_assignments_file" "$backup_file" 2>/dev/null; then
            return 1  # Backup failed
        fi
    fi
    
    return 0
}

validate_agent_deployment_complete() {
    local session_name="$1"
    local workspace_dir="$2"
    
    # Verify session was created and is active
    if ! check_session_exists "$session_name"; then
        return 1  # Session not created
    fi
    
    # Verify session has at least one pane
    local pane_count
    pane_count=$($TMUX_CMD list-panes -t "$session_name" 2>/dev/null | $WC_CMD -l)
    if [[ "$pane_count" -lt 1 ]]; then
        return 2  # Session has no panes
    fi
    
    # Verify session is in correct directory
    local session_pwd
    session_pwd=$($TMUX_CMD display-message -t "$session_name" -p "#{pane_current_path}" 2>/dev/null)
    if [[ "$session_pwd" != "$workspace_dir" ]]; then
        return 3  # Session in wrong directory
    fi
    
    return 0
}

# Enhanced deployment orchestration with comprehensive validation
deploy_agent_with_validation() {
    local agent_type="$1"
    local task_number="$2"
    local force_deploy="${3:-false}"
    
    # Pre-deployment validation
    validate_agent_deployment_args "$agent_type" "$task_number"
    local validation_result=$?
    if [[ $validation_result -ne 0 ]]; then
        return $validation_result
    fi
    
    # Validate agent type (requires config_loader to be sourced)
    if ! validate_agent_type "$agent_type"; then
        return 10  # Invalid agent type
    fi
    
    # Load agent configuration (requires config_loader)
    if ! get_agent_config "$agent_type"; then
        return 11  # Failed to load agent config
    fi
    
    # Validate deployment prerequisites
    validate_deployment_prerequisites "$WORKSPACE_DIR" "$AGENT_PROMPT_FILE" "$MEMORY_DIR"
    local prereq_result=$?
    if [[ $prereq_result -ne 0 ]]; then
        return $((20 + prereq_result))  # 21-24: Prerequisite failures
    fi
    
    # Check for deployment conflicts
    local conflict_check
    conflict_check=$(check_deployment_conflicts "$AGENT_SESSION_NAME" "$task_number")
    local conflict_result=$?
    if [[ $conflict_result -eq 1 ]] && [[ "$force_deploy" != "true" ]]; then
        return 25  # Session already exists (use force to override)
    elif [[ $conflict_result -eq 2 ]]; then
        echo "CONFLICT: $conflict_check"
        return 26  # Task already assigned to another agent
    fi
    
    # Prepare environment
    if ! prepare_deployment_environment "$WORKSPACE_DIR" "$MEMORY_DIR" "$LOGS_DIR"; then
        return 27  # Failed to prepare environment
    fi
    
    # Create backup of task assignments
    if ! create_deployment_backup "$TASK_ASSIGNMENTS_FILE"; then
        return 28  # Backup failed
    fi
    
    # Handle existing session if force deploy
    if [[ "$force_deploy" == "true" ]] && check_session_exists "$AGENT_SESSION_NAME"; then
        kill_existing_session "$AGENT_SESSION_NAME"
    fi
    
    # Create new session
    if ! create_agent_session "$AGENT_SESSION_NAME" "$WORKSPACE_DIR"; then
        return 12  # Failed to create session
    fi
    
    # Setup agent environment
    setup_agent_environment \
        "$AGENT_SESSION_NAME" \
        "$AGENT_NAME" \
        "$task_number" \
        "$AGENT_PROMPT_FILE" \
        "$MEMORY_DIR" \
        "$GITHUB_OWNER" \
        "$GITHUB_REPO"
    
    # Validate deployment completed successfully
    validate_agent_deployment_complete "$AGENT_SESSION_NAME" "$WORKSPACE_DIR"
    local completion_result=$?
    if [[ $completion_result -ne 0 ]]; then
        # Cleanup failed deployment
        kill_existing_session "$AGENT_SESSION_NAME" 2>/dev/null
        return $((30 + completion_result))  # 31-33: Completion validation failures
    fi
    
    # Update task assignments
    update_task_assignment "$agent_type" "$task_number" "$AGENT_SESSION_NAME"
    
    # Log deployment
    log_deployment "$AGENT_NAME" "$task_number"
    
    return 0
}

# Enhanced error messages for new functions
get_enhanced_deployment_error_message() {
    local error_code="$1"
    
    case $error_code in
        # Original errors (1-19)
        1) echo "❌ Missing agent type" ;;
        2) echo "❌ Missing task number" ;;
        3) echo "❌ Invalid task number format (must be numeric)" ;;
        10) echo "❌ Invalid agent type" ;;
        11) echo "❌ Failed to load agent configuration" ;;
        12) echo "❌ Failed to create tmux session" ;;
        
        # Prerequisite errors (21-24)
        21) echo "❌ Workspace directory missing or inaccessible" ;;
        22) echo "❌ Agent prompt file not found" ;;
        23) echo "❌ Cannot create or access memory directory" ;;
        24) echo "❌ tmux is not installed or not available" ;;
        
        # Conflict errors (25-26)
        25) echo "❌ Session already exists (use --force to override)" ;;
        26) echo "❌ Task already assigned to another agent" ;;
        
        # Environment errors (27-28)
        27) echo "❌ Failed to prepare deployment environment" ;;
        28) echo "❌ Failed to create backup of task assignments" ;;
        
        # Completion validation errors (31-33)
        31) echo "❌ Session was created but is not accessible" ;;
        32) echo "❌ Session created but has no active panes" ;;
        33) echo "❌ Session created but is in wrong directory" ;;
        
        *) echo "❌ Unknown deployment error (code: $error_code)" ;;
    esac
}