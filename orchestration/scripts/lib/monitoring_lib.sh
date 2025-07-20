#!/bin/bash

# Monitoring Library - Testable agent monitoring and health check functions
# Provides core agent monitoring and health checking functionality

# Dependency injection for external commands (allows mocking in tests)
TMUX_CMD="${TMUX_CMD:-tmux}"
PS_CMD="${PS_CMD:-ps}"
TOP_CMD="${TOP_CMD:-top}"
DATE_CMD="${DATE_CMD:-date}"
AWK_CMD="${AWK_CMD:-awk}"
GREP_CMD="${GREP_CMD:-grep}"
HEAD_CMD="${HEAD_CMD:-head}"
CAT_CMD="${CAT_CMD:-cat}"
WC_CMD="${WC_CMD:-wc}"
CUT_CMD="${CUT_CMD:-cut}"
SORT_CMD="${SORT_CMD:-sort}"

# Agent health check functions
check_agent_health() {
    local session_name="$1"
    
    if [[ -z "$session_name" ]]; then
        return 1  # Empty session name
    fi
    
    # Check if session exists
    if ! $TMUX_CMD has-session -t "$session_name" 2>/dev/null; then
        return 2  # Session doesn't exist
    fi
    
    # Check if session has active panes
    local pane_count
    pane_count=$($TMUX_CMD list-panes -t "$session_name" 2>/dev/null | $WC_CMD -l)
    if [[ "$pane_count" -lt 1 ]]; then
        return 3  # No active panes
    fi
    
    # Check if panes are responsive (not hanging)
    local window_count
    window_count=$($TMUX_CMD list-windows -t "$session_name" 2>/dev/null | $WC_CMD -l)
    if [[ "$window_count" -lt 1 ]]; then
        return 4  # No windows
    fi
    
    return 0  # Healthy
}

get_agent_status() {
    local session_name="$1"
    
    if [[ -z "$session_name" ]]; then
        echo "Unknown"
        return 1
    fi
    
    check_agent_health "$session_name"
    local health_result=$?
    
    case $health_result in
        0) echo "Healthy" ;;
        2) echo "Not Found" ;;
        3) echo "No Panes" ;;
        4) echo "No Windows" ;;
        *) echo "Unhealthy" ;;
    esac
    
    return $health_result
}

check_session_activity() {
    local session_name="$1"
    local activity_threshold="${2:-300}"  # 5 minutes default
    
    if [[ -z "$session_name" ]]; then
        return 1  # Empty session name
    fi
    
    if ! $TMUX_CMD has-session -t "$session_name" 2>/dev/null; then
        return 2  # Session doesn't exist
    fi
    
    # Get last activity time
    local last_activity
    last_activity=$($TMUX_CMD display-message -t "$session_name" -p "#{session_last_attached}" 2>/dev/null)
    
    if [[ -z "$last_activity" ]]; then
        return 3  # Cannot determine activity
    fi
    
    # Calculate time since last activity
    local current_time
    current_time=$($DATE_CMD +%s)
    local time_diff=$((current_time - last_activity))
    
    if [[ $time_diff -gt $activity_threshold ]]; then
        return 4  # Inactive (beyond threshold)
    fi
    
    return 0  # Active
}

get_resource_usage() {
    local session_name="$1"
    
    if [[ -z "$session_name" ]]; then
        return 1  # Empty session name
    fi
    
    if ! $TMUX_CMD has-session -t "$session_name" 2>/dev/null; then
        return 2  # Session doesn't exist
    fi
    
    # Get PIDs of processes in this session
    local session_pids
    session_pids=$($TMUX_CMD list-panes -t "$session_name" -F "#{pane_pid}" 2>/dev/null)
    
    if [[ -z "$session_pids" ]]; then
        return 3  # No panes/processes
    fi
    
    # Calculate total CPU and memory usage
    local total_cpu=0
    local total_memory=0
    local process_count=0
    
    while read -r pid; do
        if [[ -n "$pid" ]]; then
            # Get CPU and memory for this process (including children)
            local cpu_mem
            cpu_mem=$($PS_CMD -o pcpu,pmem --ppid "$pid" --no-headers 2>/dev/null | $AWK_CMD '{cpu+=$1; mem+=$2} END {print cpu" "mem}')
            
            if [[ -n "$cpu_mem" ]]; then
                local cpu
                local mem
                cpu=$(echo "$cpu_mem" | $CUT_CMD -d' ' -f1)
                mem=$(echo "$cpu_mem" | $CUT_CMD -d' ' -f2)
                
                total_cpu=$(echo "$total_cpu + $cpu" | bc 2>/dev/null || echo "$total_cpu")
                total_memory=$(echo "$total_memory + $mem" | bc 2>/dev/null || echo "$total_memory")
                process_count=$((process_count + 1))
            fi
        fi
    done <<< "$session_pids"
    
    echo "CPU: ${total_cpu}% | Memory: ${total_memory}% | Processes: $process_count"
    return 0
}

validate_agent_environment() {
    local session_name="$1"
    local expected_workspace="$2"
    local expected_files="$3"  # Space-separated list of files that should exist
    
    if [[ -z "$session_name" ]]; then
        return 1  # Empty session name
    fi
    
    if ! $TMUX_CMD has-session -t "$session_name" 2>/dev/null; then
        return 2  # Session doesn't exist
    fi
    
    # Check if session is in expected workspace
    if [[ -n "$expected_workspace" ]]; then
        local current_path
        current_path=$($TMUX_CMD display-message -t "$session_name" -p "#{pane_current_path}" 2>/dev/null)
        
        # If we got a path, validate it
        if [[ -n "$current_path" ]]; then
            if [[ "$current_path" != "$expected_workspace" ]]; then
                return 3  # Wrong workspace
            fi
        elif [[ -z "$expected_files" ]]; then
            # If we couldn't get the path and there are no files to check,
            # treat it as wrong workspace
            return 3  # Cannot verify workspace
        fi
        # If we couldn't get the path but there are files to check,
        # continue to the file checks
    fi
    
    # Check if expected files exist
    if [[ -n "$expected_files" ]]; then
        local missing_files=()
        
        for file in $expected_files; do
            if [[ ! -f "$file" ]]; then
                missing_files+=("$file")
            fi
        done
        
        if [[ ${#missing_files[@]} -gt 0 ]]; then
            echo "Missing files: ${missing_files[*]}"
            return 4  # Missing files
        fi
    fi
    
    return 0  # Environment valid
}

check_agent_dependencies() {
    local session_name="$1"
    local required_commands="$2"  # Space-separated list of commands
    
    if [[ -z "$session_name" ]]; then
        return 1  # Empty session name
    fi
    
    if ! $TMUX_CMD has-session -t "$session_name" 2>/dev/null; then
        return 2  # Session doesn't exist
    fi
    
    if [[ -z "$required_commands" ]]; then
        return 0  # No dependencies to check
    fi
    
    local missing_commands=()
    
    # Check each required command
    for cmd in $required_commands; do
        # Send command to check if it exists in the session
        local check_result
        check_result=$($TMUX_CMD send-keys -t "$session_name" "command -v $cmd" Enter 2>/dev/null; sleep 0.1; $TMUX_CMD capture-pane -t "$session_name" -p | tail -1)
        
        if [[ -z "$check_result" ]] || [[ "$check_result" == *"not found"* ]]; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        echo "Missing commands: ${missing_commands[*]}"
        return 3  # Missing dependencies
    fi
    
    return 0  # All dependencies available
}

# Agent discovery and listing functions
list_active_agent_sessions() {
    local agent_pattern="${1:-agent}"
    
    # First check if tmux can list sessions at all
    if ! $TMUX_CMD list-sessions &>/dev/null; then
        return 1  # No tmux sessions or tmux not available
    fi
    
    # Now check if there are any sessions
    local sessions
    sessions=$($TMUX_CMD list-sessions -F "#{session_name}" 2>/dev/null)
    if [[ -z "$sessions" ]]; then
        return 1  # No sessions found
    fi
    
    # Filter by pattern if provided
    echo "$sessions" | $GREP_CMD -E "$agent_pattern" || true
}

get_agent_session_info() {
    local session_name="$1"
    
    if [[ -z "$session_name" ]]; then
        return 1  # Empty session name
    fi
    
    if ! $TMUX_CMD has-session -t "$session_name" 2>/dev/null; then
        return 2  # Session doesn't exist
    fi
    
    # Get comprehensive session information
    local created
    local attached
    local windows
    local panes
    
    created=$($TMUX_CMD display-message -t "$session_name" -p "#{session_created}" 2>/dev/null)
    attached=$($TMUX_CMD display-message -t "$session_name" -p "#{session_last_attached}" 2>/dev/null)
    windows=$($TMUX_CMD list-windows -t "$session_name" 2>/dev/null | $WC_CMD -l)
    panes=$($TMUX_CMD list-panes -t "$session_name" 2>/dev/null | $WC_CMD -l)
    
    echo "Created: $($DATE_CMD -r "$created" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Unknown")"
    echo "Last Attached: $($DATE_CMD -r "$attached" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Never")"
    echo "Windows: $windows"
    echo "Panes: $panes"
    echo "Status: $(get_agent_status "$session_name")"
    
    return 0
}

# Memory and task file monitoring functions
get_memory_file_status() {
    local memory_dir="$1"
    local file_pattern="$2"  # Optional file pattern to filter
    
    if [[ -z "$memory_dir" ]] || [[ ! -d "$memory_dir" ]]; then
        return 1  # Invalid memory directory
    fi
    
    local files
    if [[ -n "$file_pattern" ]]; then
        files=$(find "$memory_dir" -name "$file_pattern" -type f 2>/dev/null)
    else
        files=$(find "$memory_dir" -name "*.md" -type f 2>/dev/null)
    fi
    
    if [[ -z "$files" ]]; then
        echo "No memory files found"
        return 2
    fi
    
    echo "Memory files in $memory_dir:"
    while read -r file; do
        if [[ -n "$file" ]]; then
            local size
            local modified
            size=$(du -h "$file" 2>/dev/null | $CUT_CMD -f1)
            modified=$($DATE_CMD -r "$file" "+%Y-%m-%d %H:%M" 2>/dev/null)
            
            echo "  $(basename "$file"): $size (modified: $modified)"
        fi
    done <<< "$files"
    
    return 0
}

check_task_assignments() {
    local assignments_file="$1"
    
    if [[ ! -f "$assignments_file" ]]; then
        echo "No task assignments file found"
        return 1
    fi
    
    # Check if file is empty
    if [[ ! -s "$assignments_file" ]]; then
        echo "Task assignments file is empty"
        return 2
    fi
    
    # Extract current assignments
    echo "Current Task Assignments:"
    $GREP_CMD -A 3 "^## " "$assignments_file" | $GREP_CMD -E "(^##|Current:|Status:|Session:)" || echo "No active assignments found"
    
    return 0
}

check_project_state() {
    local state_file="$1"
    local line_limit="${2:-15}"
    
    if [[ ! -f "$state_file" ]]; then
        echo "No project state file found"
        return 1
    fi
    
    if [[ ! -s "$state_file" ]]; then
        echo "Project state file is empty"
        return 2
    fi
    
    echo "Project State (first $line_limit lines):"
    $HEAD_CMD -n "$line_limit" "$state_file"
    
    return 0
}

check_blockers() {
    local blockers_file="$1"
    
    if [[ ! -f "$blockers_file" ]]; then
        echo "No blockers reported"
        return 1
    fi
    
    if [[ ! -s "$blockers_file" ]]; then
        echo "No blockers reported"
        return 2
    fi
    
    echo "Current Blockers:"
    $CAT_CMD "$blockers_file"
    
    return 0
}

# Comprehensive monitoring report
generate_monitoring_report() {
    local agent_types="$1"      # Space-separated list of agent types
    local memory_dir="$2"
    local assignments_file="$3"
    local state_file="$4"
    local blockers_file="$5"
    
    local timestamp
    timestamp=$($DATE_CMD '+%Y-%m-%d %H:%M:%S')
    
    echo "🤖 Agent Monitoring Report - $timestamp"
    echo "================================================="
    echo ""
    
    # Active agent sessions
    echo "📱 Active Agent Sessions:"
    local active_sessions
    active_sessions=$(list_active_agent_sessions "agent")
    
    if [[ -z "$active_sessions" ]]; then
        echo "   No agent sessions running"
    else
        while read -r session; do
            if [[ -n "$session" ]]; then
                local status
                local activity_check
                status=$(get_agent_status "$session")
                
                check_session_activity "$session" 300  # 5 minute threshold
                local activity_result=$?
                case $activity_result in
                    0) activity_check="🟢 Active" ;;
                    4) activity_check="🟡 Idle (>5min)" ;;
                    *) activity_check="🔴 Inactive" ;;
                esac
                
                echo "   $session: $status | $activity_check"
                
                # Get resource usage if healthy
                if [[ "$status" == "Healthy" ]]; then
                    local resources
                    resources=$(get_resource_usage "$session" 2>/dev/null)
                    if [[ -n "$resources" ]]; then
                        echo "     Resources: $resources"
                    fi
                fi
            fi
        done <<< "$active_sessions"
    fi
    
    echo ""
    
    # Task assignments
    echo "📊 Current Assignments:"
    check_task_assignments "$assignments_file"
    
    echo ""
    
    # Project state
    echo "📈 Project State:"
    check_project_state "$state_file"
    
    echo ""
    
    # Blockers
    echo "🚨 Blockers:"
    check_blockers "$blockers_file"
    
    echo ""
    
    # Memory status
    if [[ -n "$memory_dir" ]]; then
        echo "💾 Memory Files:"
        get_memory_file_status "$memory_dir"
        echo ""
    fi
    
    return 0
}

# Health check summary
get_health_summary() {
    local agent_types="$1"  # Space-separated list
    
    local total_agents=0
    local healthy_agents=0
    local unhealthy_agents=0
    local missing_agents=0
    
    if [[ -n "$agent_types" ]]; then
        for agent_type in $agent_types; do
            local session_name="${agent_type}-agent"
            total_agents=$((total_agents + 1))
            
            local status
            status=$(get_agent_status "$session_name")
            
            case "$status" in
                "Healthy") healthy_agents=$((healthy_agents + 1)) ;;
                "Not Found") missing_agents=$((missing_agents + 1)) ;;
                *) unhealthy_agents=$((unhealthy_agents + 1)) ;;
            esac
        done
    fi
    
    echo "Health Summary: $healthy_agents healthy, $unhealthy_agents unhealthy, $missing_agents not deployed (of $total_agents total)"
    
    # Return appropriate exit code
    if [[ $unhealthy_agents -gt 0 ]] || [[ $missing_agents -gt 0 ]]; then
        return 1  # Some issues found
    fi
    
    return 0  # All healthy
}

# Error message helpers
get_monitoring_error_message() {
    local error_code="$1"
    local context="$2"
    
    case $error_code in
        1) echo "❌ Invalid input or missing parameter: $context" ;;
        2) echo "❌ Session not found: $context" ;;
        3) echo "❌ Health check failed: $context" ;;
        4) echo "❌ Environment validation failed: $context" ;;
        *) echo "❌ Unknown monitoring error (code: $error_code)" ;;
    esac
}

get_health_status_emoji() {
    local status="$1"
    
    case "$status" in
        "Healthy") echo "🟢" ;;
        "Not Found") echo "⚪" ;;
        "No Panes") echo "🟡" ;;
        "No Windows") echo "🟡" ;;
        *) echo "🔴" ;;
    esac
}

# Display formatters
format_monitoring_header() {
    local title="$1"
    local width="${2:-50}"
    
    echo ""
    echo "$title"
    printf '%*s\n' "$width" '' | tr ' ' '='
}

format_agent_status_line() {
    local session_name="$1"
    local status="$2"
    local activity="$3"
    local resources="$4"
    
    local emoji
    emoji=$(get_health_status_emoji "$status")
    
    printf "%-20s %s %-10s | %-15s" "$session_name" "$emoji" "$status" "$activity"
    
    if [[ -n "$resources" ]]; then
        echo " | $resources"
    else
        echo ""
    fi
}