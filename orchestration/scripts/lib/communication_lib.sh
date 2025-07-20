#!/bin/bash

# Communication Library - Testable communication management functions
# Provides command sending and message handling functionality

# Dependency injection for external commands (allows mocking in tests)
TMUX_CMD="${TMUX_CMD:-tmux}"
DATE_CMD="${DATE_CMD:-date}"
AWK_CMD="${AWK_CMD:-awk}"
GREP_CMD="${GREP_CMD:-grep}"
ECHO_CMD="${ECHO_CMD:-echo}"
HEAD_CMD="${HEAD_CMD:-head}"
TR_CMD="${TR_CMD:-tr}"
SED_CMD="${SED_CMD:-sed}"

# Error message functions
get_communication_error_message() {
    local error_code="$1"
    case "$error_code" in
        1) echo "Missing agent type parameter" ;;
        2) echo "Missing command parameter" ;;
        3) echo "Invalid agent type" ;;
        4) echo "Session not found" ;;
        5) echo "Command validation failed" ;;
        6) echo "Failed to send command" ;;
        7) echo "Agent configuration not found" ;;
        8) echo "Command queue full" ;;
        9) echo "Invalid command syntax" ;;
        10) echo "Response timeout" ;;
        *) echo "Unknown communication error" ;;
    esac
}

# Validation functions
validate_command_parameters() {
    local agent_type="$1"
    local command="$2"
    
    if [[ -z "$agent_type" ]]; then
        return 1  # Missing agent type
    fi
    
    if [[ -z "$command" ]]; then
        return 2  # Missing command
    fi
    
    return 0
}

validate_command_syntax() {
    local command="$1"
    
    # Basic command validation - check for dangerous commands
    case "$command" in
        *"rm -rf"*|*"sudo"*|*"format"*|*"> /dev/"*)
            return 5  # Dangerous command detected
            ;;
        "")
            return 2  # Empty command
            ;;
        *)
            return 0  # Valid command
            ;;
    esac
}

validate_agent_exists() {
    local agent_type="$1"
    
    # This function assumes get_agent_config is available from config_loader
    if ! get_agent_config "$agent_type" &>/dev/null; then
        return 3  # Invalid agent type
    fi
    
    return 0
}

# Session management functions
check_agent_session_exists() {
    local session_name="$1"
    
    if [[ -z "$session_name" ]]; then
        return 1  # Missing session name
    fi
    
    $TMUX_CMD has-session -t "$session_name" 2>/dev/null
    return $?
}

get_agent_session_name() {
    local agent_type="$1"
    
    # This assumes AGENT_SESSION_NAME is set by get_agent_config
    if ! get_agent_config "$agent_type" &>/dev/null; then
        return 7  # Agent configuration not found
    fi
    
    echo "$AGENT_SESSION_NAME"
    return 0
}

# Core communication functions
send_command_to_agent() {
    local agent_type="$1"
    local command="$2"
    local log_file="${3:-}"
    
    # Validate parameters
    validate_command_parameters "$agent_type" "$command"
    local error_code=$?
    if [[ $error_code -ne 0 ]]; then
        return $error_code
    fi
    
    # Validate command syntax
    if ! validate_command_syntax "$command"; then
        return 5  # Command validation failed
    fi
    
    # Validate agent exists and get session name
    if ! validate_agent_exists "$agent_type"; then
        return 3  # Invalid agent type
    fi
    
    local session_name
    session_name=$(get_agent_session_name "$agent_type")
    if [[ $? -ne 0 ]]; then
        return 7  # Agent configuration not found
    fi
    
    # Check if session exists
    if ! check_agent_session_exists "$session_name"; then
        return 4  # Session not found
    fi
    
    # Send the command
    if ! $TMUX_CMD send-keys -t "$session_name" "$command" Enter; then
        return 6  # Failed to send command
    fi
    
    # Log the command if log file specified
    if [[ -n "$log_file" ]]; then
        log_command_execution "$agent_type" "$command" "$log_file"
    fi
    
    return 0
}

log_command_execution() {
    local agent_type="$1"
    local command="$2"
    local log_file="$3"
    local timestamp
    
    timestamp=$($DATE_CMD '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $agent_type: $command" >> "$log_file" 2>/dev/null || true
}

get_command_response() {
    local session_name="$1"
    local timeout="${2:-5}"
    
    if [[ -z "$session_name" ]]; then
        return 1  # Missing session name
    fi
    
    # Check if session exists
    if ! check_agent_session_exists "$session_name"; then
        return 4  # Session not found
    fi
    
    # Capture the pane content
    if ! $TMUX_CMD capture-pane -t "$session_name" -p; then
        return 10  # Response timeout or capture failed
    fi
    
    return 0
}

broadcast_message_to_agents() {
    local message="$1"
    local agent_types_list="$2"
    local failed_agents=()
    local success_count=0
    
    if [[ -z "$message" ]]; then
        return 2  # Missing message
    fi
    
    # If no specific agent list provided, use all available agents
    if [[ -z "$agent_types_list" ]]; then
        agent_types_list=$(get_agent_types 2>/dev/null | $TR_CMD '\n' ' ')
    fi
    
    # Send to each agent
    for agent_type in $agent_types_list; do
        if send_command_to_agent "$agent_type" "$message"; then
            ((success_count++))
        else
            failed_agents+=("$agent_type")
        fi
    done
    
    # Return success if at least one agent received the message
    if [[ $success_count -gt 0 ]]; then
        return 0
    else
        return 6  # Failed to send to any agent
    fi
}

queue_command_for_agent() {
    local agent_type="$1"
    local command="$2"
    local queue_file="${3:-/tmp/agent_command_queue_$agent_type}"
    local max_queue_size="${4:-100}"
    
    # Validate parameters
    validate_command_parameters "$agent_type" "$command"
    local error_code=$?
    if [[ $error_code -ne 0 ]]; then
        return $error_code
    fi
    
    # Check queue size
    if [[ -f "$queue_file" ]]; then
        local queue_size
        queue_size=$($WC_CMD -l < "$queue_file" 2>/dev/null || echo "0")
        if [[ $queue_size -ge $max_queue_size ]]; then
            return 8  # Queue full
        fi
    fi
    
    # Add command to queue with timestamp
    local timestamp
    timestamp=$($DATE_CMD '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $command" >> "$queue_file"
    
    return 0
}

check_command_status() {
    local agent_type="$1"
    local command_pattern="$2"
    
    if [[ -z "$agent_type" ]]; then
        return 1  # Missing agent type
    fi
    
    # Get session name
    local session_name
    session_name=$(get_agent_session_name "$agent_type")
    if [[ $? -ne 0 ]]; then
        return 7  # Agent configuration not found
    fi
    
    # Check if session exists
    if ! check_agent_session_exists "$session_name"; then
        return 4  # Session not found
    fi
    
    # If no specific pattern, just check if session is responsive
    if [[ -z "$command_pattern" ]]; then
        return 0  # Session exists, assume responsive
    fi
    
    # Check for command pattern in session output
    local session_output
    session_output=$(get_command_response "$session_name" 2>/dev/null)
    if [[ $? -eq 0 ]] && echo "$session_output" | $GREP_CMD -q "$command_pattern"; then
        return 0  # Command pattern found
    fi
    
    return 10  # Command not found or timeout
}

# Display functions for command execution
show_command_examples() {
    local agent_type="$1"
    
    if [[ -z "$agent_type" ]]; then
        # Show examples for first 3 agent types
        get_agent_types 2>/dev/null | $HEAD_CMD -3 | while read -r agent; do
            get_agent_config "$agent" &>/dev/null
            case "$agent" in
                *rust*) local example_cmd="cargo --version" ;;
                *react*) local example_cmd="npm run test" ;;
                *devops*) local example_cmd="docker --version" ;;
                *) local example_cmd="echo 'Hello from $agent agent'" ;;
            esac
            echo "  ./send_command.sh $agent '$example_cmd'"
        done
    else
        # Show specific examples for the agent type
        case "$agent_type" in
            *rust*) echo "  ./send_command.sh $agent_type 'cargo --version'" ;;
            *react*) echo "  ./send_command.sh $agent_type 'npm run test'" ;;
            *devops*) echo "  ./send_command.sh $agent_type 'docker --version'" ;;
            *) echo "  ./send_command.sh $agent_type 'echo \"Hello from $agent_type agent\"'" ;;
        esac
    fi
}

show_available_agents() {
    get_agent_types 2>/dev/null | $TR_CMD '\n' ', ' | $SED_CMD 's/, $//'
}

# Helper functions for command responses
format_command_output() {
    local output="$1"
    local max_lines="${2:-20}"
    
    if [[ -z "$output" ]]; then
        echo "No output available"
        return 0
    fi
    
    echo "$output" | $HEAD_CMD -n "$max_lines"
    
    local total_lines
    total_lines=$(echo "$output" | $WC_CMD -l)
    if [[ $total_lines -gt $max_lines ]]; then
        echo "... (output truncated, showing first $max_lines of $total_lines lines)"
    fi
}

# Command history functions
save_command_to_history() {
    local agent_type="$1"
    local command="$2"
    local history_file="${3:-/tmp/agent_command_history_$agent_type}"
    local max_history="${4:-1000}"
    
    if [[ -z "$agent_type" ]] || [[ -z "$command" ]]; then
        return 1
    fi
    
    local timestamp
    timestamp=$($DATE_CMD '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $command" >> "$history_file"
    
    # Trim history if it gets too long
    if [[ -f "$history_file" ]]; then
        local history_size
        history_size=$($WC_CMD -l < "$history_file" 2>/dev/null || echo "0")
        if [[ $history_size -gt $max_history ]]; then
            # Keep only the last max_history lines
            local temp_file
            temp_file=$(mktemp)
            tail -n "$max_history" "$history_file" > "$temp_file"
            mv "$temp_file" "$history_file"
        fi
    fi
    
    return 0
}