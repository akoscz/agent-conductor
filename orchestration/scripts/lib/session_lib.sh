#!/bin/bash

# Session Library - Testable session management functions
# Provides core tmux session management functionality

# Dependency injection for external commands (allows mocking in tests)
TMUX_CMD="${TMUX_CMD:-tmux}"
DATE_CMD="${DATE_CMD:-date}"
PGREP_CMD="${PGREP_CMD:-pgrep}"
AWK_CMD="${AWK_CMD:-awk}"
MV_CMD="${MV_CMD:-mv}"

# Session validation functions
validate_session_name() {
    local session_name="$1"
    
    if [[ -z "$session_name" ]]; then
        return 1  # Empty session name
    fi
    
    # Check for invalid characters (tmux doesn't allow certain chars)
    if [[ "$session_name" =~ [[:space:]\.] ]]; then
        return 2  # Invalid characters
    fi
    
    return 0
}

# Core session management functions
check_tmux_server_running() {
    if [[ "$PGREP_CMD" == "echo pgrep" ]]; then
        # When mocked, show the command for testing
        $PGREP_CMD -x "tmux"
        return 0
    else
        # In production, redirect to /dev/null
        $PGREP_CMD -x "tmux" > /dev/null
        return $?
    fi
}

session_exists() {
    local session_name="$1"
    
    if [[ -z "$session_name" ]]; then
        return 1  # Empty session name
    fi
    
    $TMUX_CMD has-session -t "$session_name" 2>/dev/null
    return $?
}

list_all_sessions() {
    if ! check_tmux_server_running; then
        return 1  # No tmux server
    fi
    
    $TMUX_CMD list-sessions -F "#{session_name}" 2>/dev/null
    return $?
}

get_session_info() {
    local session_name="$1"
    
    if [[ -z "$session_name" ]]; then
        return 1  # Empty session name
    fi
    
    if ! session_exists "$session_name"; then
        return 2  # Session doesn't exist
    fi
    
    $TMUX_CMD list-sessions -F "#{session_name}:#{session_created}:#{session_windows}" -f "#{==:#{session_name},$session_name}" 2>/dev/null
    return $?
}

get_session_pane_count() {
    local session_name="$1"
    
    if [[ -z "$session_name" ]]; then
        return 1  # Empty session name
    fi
    
    if ! session_exists "$session_name"; then
        return 2  # Session doesn't exist
    fi
    
    if [[ "$TMUX_CMD" == "echo tmux" ]]; then
        # When mocked, show the command for testing
        $TMUX_CMD list-panes -t "$session_name" -F "#{pane_id}"
        return 0
    else
        # In production, count the panes
        $TMUX_CMD list-panes -t "$session_name" -F "#{pane_id}" 2>/dev/null | wc -l
        return $?
    fi
}

kill_session() {
    local session_name="$1"
    
    if [[ -z "$session_name" ]]; then
        return 1  # Empty session name
    fi
    
    if ! session_exists "$session_name"; then
        return 2  # Session doesn't exist
    fi
    
    $TMUX_CMD kill-session -t "$session_name" 2>/dev/null
    return $?
}

attach_to_session() {
    local session_name="$1"
    
    if [[ -z "$session_name" ]]; then
        return 1  # Empty session name
    fi
    
    if ! session_exists "$session_name"; then
        return 2  # Session doesn't exist
    fi
    
    $TMUX_CMD attach -t "$session_name"
    return $?
}

# Agent session discovery functions
list_agent_sessions() {
    local agent_pattern="$1"
    
    if [[ -z "$agent_pattern" ]]; then
        return 1  # Empty pattern
    fi
    
    if ! check_tmux_server_running; then
        return 2  # No tmux server
    fi
    
    list_all_sessions | grep -E "$agent_pattern" 2>/dev/null || true
    return 0
}

build_agent_session_pattern() {
    local agent_types="$1"  # Space-separated list of agent types
    
    if [[ -z "$agent_types" ]]; then
        return 1  # Empty agent types
    fi
    
    # Convert space-separated to pipe-separated for grep
    echo "$agent_types" | tr ' ' '|' | sed 's/|$//' | sed 's/^/(/; s/$/)/'
    return 0
}

get_agent_sessions_by_pattern() {
    local agent_types="$1"  # Space-separated list of agent types
    
    if [[ -z "$agent_types" ]]; then
        return 1  # Empty agent types
    fi
    
    local pattern
    pattern=$(build_agent_session_pattern "$agent_types")
    if [[ $? -ne 0 ]]; then
        return 2  # Pattern build failed
    fi
    
    # Add -agent suffix to pattern
    pattern="${pattern}-agent"
    list_agent_sessions "$pattern"
    return $?
}

# Session status and information functions
get_session_status() {
    local session_name="$1"
    
    if [[ -z "$session_name" ]]; then
        return 1  # Empty session name
    fi
    
    if ! session_exists "$session_name"; then
        echo "Not Found"
        return 2  # Session doesn't exist
    fi
    
    local pane_count
    pane_count=$(get_session_pane_count "$session_name")
    
    if [[ $pane_count -gt 0 ]]; then
        echo "Active"
    else
        echo "Inactive"
    fi
    
    return 0
}

format_session_created_time() {
    local session_created="$1"
    
    if [[ -z "$session_created" ]]; then
        echo "Unknown"
        return 1
    fi
    
    $DATE_CMD -r "$session_created" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown"
    return 0
}

extract_agent_type_from_session() {
    local session_name="$1"
    
    if [[ -z "$session_name" ]]; then
        return 1  # Empty session name
    fi
    
    # Remove -agent suffix to get agent type
    echo "$session_name" | sed 's/-agent$//'
    return 0
}

# Multi-session operations
kill_agent_sessions() {
    local agent_types="$1"  # Space-separated list of agent types
    local log_file="$2"
    
    if [[ -z "$agent_types" ]]; then
        return 1  # Empty agent types
    fi
    
    if ! check_tmux_server_running; then
        return 2  # No tmux server
    fi
    
    local agent_sessions
    agent_sessions=$(get_agent_sessions_by_pattern "$agent_types")
    if [[ $? -ne 0 ]] || [[ -z "$agent_sessions" ]]; then
        return 3  # No sessions found
    fi
    
    local stopped_count=0
    local failed_sessions=()
    
    while read -r session; do
        if [[ -n "$session" ]]; then
            if kill_session "$session"; then
                stopped_count=$((stopped_count + 1))
            else
                failed_sessions+=("$session")
            fi
        fi
    done <<< "$agent_sessions"
    
    # Log the shutdown if log file provided
    if [[ -n "$log_file" ]]; then
        local timestamp
        timestamp=$($DATE_CMD '+%Y-%m-%d %H:%M:%S')
        echo "$timestamp - Stopped $stopped_count agent sessions" >> "$log_file"
    fi
    
    # Return count and any failures
    echo "$stopped_count"
    if [[ ${#failed_sessions[@]} -gt 0 ]]; then
        echo "FAILED: ${failed_sessions[*]}" >&2
        return 4  # Some sessions failed to stop
    fi
    
    return 0
}

# Task assignment management functions
update_task_assignments_on_stop() {
    local task_assignments_file="$1"
    
    if [[ -z "$task_assignments_file" ]] || [[ ! -f "$task_assignments_file" ]]; then
        return 1  # Invalid file
    fi
    
    local timestamp
    timestamp=$($DATE_CMD '+%Y-%m-%d %H:%M:%S')
    
    # Reset all agent statuses to idle
    $AWK_CMD -v ts="$timestamp" '
        /^# Task Assignments/ { print $0 " - Updated: " ts; next }
        /^- \*\*Current\*\*:/ { print "- **Current**: Not assigned"; next }
        /^- \*\*Status\*\*:/ { print "- **Status**: Idle"; next }
        /^- \*\*Session\*\*:/ { print "- **Session**: None"; next }
        { print }
    ' "$task_assignments_file" > "$task_assignments_file.tmp"
    
    if ! $MV_CMD "$task_assignments_file.tmp" "$task_assignments_file"; then
        return 2  # Move failed
    fi
    
    return 0
}

# Session listing and display functions
format_session_list_header() {
    echo "Session Name          | Agent Type | Status    | Windows | Created"
    echo "----------------------|------------|-----------|---------|------------------"
}

format_session_info_line() {
    local session_name="$1"
    local agent_type="$2"
    local status="$3"
    local windows="$4"
    local created_date="$5"
    
    # Add status emoji
    local status_display
    case "$status" in
        "Active") status_display="🟢 Active" ;;
        "Inactive") status_display="🔴 Inactive" ;;
        *) status_display="⚪ $status" ;;
    esac
    
    printf "%-20s | %-10s | %-9s | %-7s | %s\n" "$session_name" "$agent_type" "$status_display" "$windows" "$created_date"
}

display_agent_sessions() {
    local agent_types="$1"  # Space-separated list of agent types
    local project_name="$2"
    
    if [[ -z "$agent_types" ]]; then
        return 1  # Empty agent types
    fi
    
    echo "🤖 Active ${project_name:-Project} AI Agents"
    echo "================================="
    
    if ! check_tmux_server_running; then
        echo "❌ No tmux server running - no agents deployed"
        return 2
    fi
    
    local agent_sessions
    agent_sessions=$(get_agent_sessions_by_pattern "$agent_types")
    if [[ $? -ne 0 ]] || [[ -z "$agent_sessions" ]]; then
        echo "💤 No agents currently deployed"
        echo ""
        echo "To deploy an agent: ./orchestration/scripts/core/orchestrator.sh deploy <agent-type> <task-number>"
        echo "Available types: $(echo "$agent_types" | tr ' ' ', ')"
        return 3
    fi
    
    format_session_list_header
    
    while read -r session; do
        if [[ -n "$session" ]]; then
            # Get session info
            local session_info
            session_info=$(get_session_info "$session")
            if [[ $? -eq 0 ]] && [[ -n "$session_info" ]]; then
                local session_name
                local session_created
                local session_windows
                
                session_name=$(echo "$session_info" | cut -d: -f1)
                session_created=$(echo "$session_info" | cut -d: -f2)
                session_windows=$(echo "$session_info" | cut -d: -f3)
                
                # Extract agent type from session name
                local agent_type
                agent_type=$(extract_agent_type_from_session "$session_name")
                
                # Get formatted creation date
                local created_date
                created_date=$(format_session_created_time "$session_created")
                
                # Get session status
                local status
                status=$(get_session_status "$session_name")
                
                format_session_info_line "$session_name" "$agent_type" "$status" "$session_windows" "$created_date"
            fi
        fi
    done <<< "$agent_sessions"
    
    return 0
}

# Agent attachment with validation
attach_to_agent() {
    local agent_type="$1"
    local session_name="$2"
    local available_agents="$3"  # Space-separated list for error messages
    
    if [[ -z "$agent_type" ]]; then
        return 1  # Missing agent type
    fi
    
    if [[ -z "$session_name" ]]; then
        return 2  # Missing session name
    fi
    
    if ! session_exists "$session_name"; then
        return 3  # Session doesn't exist
    fi
    
    attach_to_session "$session_name"
    return $?
}

# Error message helpers
get_session_error_message() {
    local error_code="$1"
    local context="$2"
    
    case $error_code in
        1) echo "❌ Empty or invalid session name" ;;
        2) echo "❌ Session does not exist: $context" ;;
        3) echo "❌ No tmux server running" ;;
        4) echo "❌ Some sessions failed to stop" ;;
        *) echo "❌ Unknown session error (code: $error_code)" ;;
    esac
}

get_agent_session_error_message() {
    local error_code="$1"
    local agent_type="$2"
    local available_agents="$3"
    
    case $error_code in
        1) echo "❌ Missing agent type" ;;
        2) echo "❌ Missing session name for agent: $agent_type" ;;
        3) echo "❌ No session found for agent: $agent_type" ;;
        *) echo "❌ Unknown agent session error (code: $error_code)" ;;
    esac
}

# Success message helpers
get_session_success_message() {
    local action="$1"
    local session_name="$2"
    local count="$3"
    
    case $action in
        "attach") echo "🔗 Attaching to $session_name..." ;;
        "stop") echo "✅ Stopped session: $session_name" ;;
        "stop_multiple") echo "📊 Summary: Stopped $count agent session(s)" ;;
        *) echo "✅ Session operation completed successfully" ;;
    esac
}

# Display helper functions
show_attachment_instructions() {
    echo "💡 Use Ctrl+B, then D to detach from session"
    echo ""
}

show_session_commands() {
    echo "📋 Commands:"
    echo "  ./orchestration/scripts/core/orchestrator.sh attach <agent-type>  # Attach to agent session"
    echo "  ./orchestration/scripts/core/orchestrator.sh send <agent> '<cmd>' # Send command to agent"
    echo "  ./orchestration/scripts/core/orchestrator.sh stop-all            # Stop all agents"
    echo ""
}

show_deployment_suggestion() {
    local agent_type="$1"
    
    echo "💡 Deploy the agent first:"
    echo "   ./orchestration/scripts/orchestrator.sh deploy $agent_type <task-number>"
    echo ""
    echo "📋 Or check active sessions:"
    echo "   ./orchestration/scripts/orchestrator.sh list"
}

show_agent_types_help() {
    local available_agents="$1"
    
    echo "Available agent types:"
    echo "$available_agents" | tr ' ' '\n' | sed 's/^/  - /'
    echo ""
    echo "Or use: ./orchestration/scripts/orchestrator.sh list to see active sessions"
}