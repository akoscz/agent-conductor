#!/usr/bin/env bats

# Unit tests for monitoring_lib.sh functionality

setup() {
    # Load the library
    source "$BATS_TEST_DIRNAME/../../lib/monitoring_lib.sh"
    
    # Set up mocks
    export TMUX_CMD="echo tmux"
    export PS_CMD="echo ps"
    export TOP_CMD="echo top"
    export DATE_CMD="echo 2024-01-15_10:30:00"
    export AWK_CMD="echo awk"
    export GREP_CMD="echo grep"
    export HEAD_CMD="echo head"
    export CAT_CMD="echo cat"
    export WC_CMD="echo wc"
    export CUT_CMD="echo cut"
    export SORT_CMD="echo sort"
}

@test "check_agent_health returns 1 for empty session name" {
    run check_agent_health ""
    [ "$status" -eq 1 ]
}

@test "check_agent_health returns 2 when session doesn't exist" {
    export TMUX_CMD="false"
    
    run check_agent_health "nonexistent-session"
    [ "$status" -eq 2 ]
}

@test "check_agent_health returns 0 for healthy session" {
    # Mock tmux commands to simulate healthy session
    export TMUX_CMD="true"
    export WC_CMD="echo 2"  # 2 panes and 1 window
    
    run check_agent_health "healthy-session"
    [ "$status" -eq 0 ]
}

@test "get_agent_status returns 'Unknown' for empty session name" {
    run get_agent_status ""
    [ "$status" -eq 1 ]
    [[ "$output" == "Unknown" ]]
}

@test "get_agent_status returns 'Healthy' for healthy session" {
    # Mock check_agent_health to return 0
    check_agent_health() { return 0; }
    export -f check_agent_health
    
    run get_agent_status "healthy-session"
    [ "$status" -eq 0 ]
    [[ "$output" == "Healthy" ]]
}

@test "get_agent_status returns 'Not Found' for non-existent session" {
    # Mock check_agent_health to return 2
    check_agent_health() { return 2; }
    export -f check_agent_health
    
    run get_agent_status "missing-session"
    [ "$status" -eq 2 ]
    [[ "$output" == "Not Found" ]]
}

@test "get_agent_status returns 'No Panes' for session without panes" {
    # Mock check_agent_health to return 3
    check_agent_health() { return 3; }
    export -f check_agent_health
    
    run get_agent_status "no-panes-session"
    [ "$status" -eq 3 ]
    [[ "$output" == "No Panes" ]]
}

@test "get_agent_status returns 'No Windows' for session without windows" {
    # Mock check_agent_health to return 4
    check_agent_health() { return 4; }
    export -f check_agent_health
    
    run get_agent_status "no-windows-session"
    [ "$status" -eq 4 ]
    [[ "$output" == "No Windows" ]]
}

@test "check_session_activity returns 1 for empty session name" {
    run check_session_activity ""
    [ "$status" -eq 1 ]
}

@test "check_session_activity returns 2 when session doesn't exist" {
    export TMUX_CMD="false"
    
    run check_session_activity "nonexistent-session"
    [ "$status" -eq 2 ]
}

@test "check_session_activity returns 0 for active session" {
    # Create a mock tmux that handles different subcommands
    cat > /tmp/mock_tmux << 'EOF'
#!/bin/bash
case "$1" in
    "has-session") exit 0 ;;  # Session exists
    "display-message") echo "1642262400" ;;  # Last activity timestamp
    *) echo "tmux $*" ;;
esac
EOF
    chmod +x /tmp/mock_tmux
    export TMUX_CMD="/tmp/mock_tmux"
    # Create a mock date command that handles +%s
    cat > /tmp/mock_date << 'EOF'
#!/bin/bash
if [[ "$1" == "+%s" ]]; then
    echo "1642262450"  # Current time (50 seconds later)
else
    echo "date $*"
fi
EOF
    chmod +x /tmp/mock_date
    export DATE_CMD="/tmp/mock_date"
    
    run check_session_activity "active-session" 300
    [ "$status" -eq 0 ]
    
    # Clean up
    rm -f /tmp/mock_tmux /tmp/mock_date
}

@test "get_resource_usage returns 1 for empty session name" {
    run get_resource_usage ""
    [ "$status" -eq 1 ]
}

@test "get_resource_usage returns 2 when session doesn't exist" {
    export TMUX_CMD="false"
    
    run get_resource_usage "nonexistent-session"
    [ "$status" -eq 2 ]
}

@test "get_resource_usage returns 3 when no panes found" {
    # Mock tmux to exist but return empty panes
    export TMUX_CMD="true"
    
    # Override tmux function to return empty for list-panes
    tmux() {
        if [[ "$1" == "has-session" ]]; then
            return 0
        elif [[ "$1" == "list-panes" ]]; then
            echo ""
        fi
    }
    export -f tmux
    
    run get_resource_usage "empty-session"
    [ "$status" -eq 3 ]
}

@test "validate_agent_environment returns 1 for empty session name" {
    run validate_agent_environment ""
    [ "$status" -eq 1 ]
}

@test "validate_agent_environment returns 2 when session doesn't exist" {
    export TMUX_CMD="false"
    
    run validate_agent_environment "nonexistent-session"
    [ "$status" -eq 2 ]
}

@test "validate_agent_environment returns 3 for wrong workspace" {
    # Mock tmux to exist and return different path
    export TMUX_CMD="true"
    
    tmux() {
        if [[ "$1" == "has-session" ]]; then
            return 0
        elif [[ "$1" == "display-message" ]]; then
            echo "/wrong/path"
        fi
    }
    export -f tmux
    
    run validate_agent_environment "test-session" "/expected/path"
    [ "$status" -eq 3 ]
}

@test "validate_agent_environment returns 4 for missing files" {
    # Mock tmux to exist and return correct path
    export TMUX_CMD="true"
    
    tmux() {
        if [[ "$1" == "has-session" ]]; then
            return 0
        elif [[ "$1" == "display-message" ]]; then
            echo "/expected/path"
        fi
    }
    export -f tmux
    
    run validate_agent_environment "test-session" "/expected/path" "/nonexistent/file.txt"
    [ "$status" -eq 4 ]
    [[ "$output" == *"Missing files:"* ]]
}

@test "check_agent_dependencies returns 1 for empty session name" {
    run check_agent_dependencies ""
    [ "$status" -eq 1 ]
}

@test "check_agent_dependencies returns 2 when session doesn't exist" {
    export TMUX_CMD="false"
    
    run check_agent_dependencies "nonexistent-session" "cargo npm"
    [ "$status" -eq 2 ]
}

@test "check_agent_dependencies returns 0 when no dependencies to check" {
    export TMUX_CMD="true"
    
    run check_agent_dependencies "test-session" ""
    [ "$status" -eq 0 ]
}

@test "list_active_agent_sessions returns 1 when no tmux sessions" {
    # Mock tmux list-sessions to fail
    export TMUX_CMD="false"
    
    run list_active_agent_sessions "agent"
    [ "$status" -eq 1 ]
}

@test "list_active_agent_sessions returns 0 when sessions exist" {
    # Mock tmux list-sessions to succeed
    tmux() {
        if [[ "$1" == "list-sessions" ]]; then
            echo "rust-agent"
            echo "react-agent"
            return 0
        fi
        return 0
    }
    export -f tmux
    
    # Mock grep to filter
    grep() {
        if [[ "$1" == "-q" && "$2" == "." ]]; then
            return 0  # Sessions exist
        elif [[ "$1" == "-E" ]]; then
            echo "rust-agent"
            echo "react-agent"
            return 0
        fi
    }
    export -f grep
    
    run list_active_agent_sessions "agent"
    [ "$status" -eq 0 ]
}

@test "get_agent_session_info returns 1 for empty session name" {
    run get_agent_session_info ""
    [ "$status" -eq 1 ]
}

@test "get_agent_session_info returns 2 when session doesn't exist" {
    export TMUX_CMD="false"
    
    run get_agent_session_info "nonexistent-session"
    [ "$status" -eq 2 ]
}

@test "get_agent_session_info returns session information when session exists" {
    # Mock tmux to return session info
    tmux() {
        case "$1" in
            "has-session") return 0 ;;
            "display-message")
                if [[ "$4" == "#{session_created}" ]]; then
                    echo "1642262400"
                elif [[ "$4" == "#{session_last_attached}" ]]; then
                    echo "1642262450"
                fi
                ;;
            "list-windows") echo "window1" ;;
            "list-panes") echo "pane1" ;;
        esac
    }
    export -f tmux
    
    # Mock get_agent_status
    get_agent_status() { echo "Healthy"; }
    export -f get_agent_status
    
    run get_agent_session_info "test-session"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Created:"* ]]
    [[ "$output" == *"Status: Healthy"* ]]
}

@test "get_memory_file_status returns 1 for invalid memory directory" {
    run get_memory_file_status ""
    [ "$status" -eq 1 ]
    
    run get_memory_file_status "/nonexistent/directory"
    [ "$status" -eq 1 ]
}

@test "get_memory_file_status returns 2 when no memory files found" {
    # Create empty temp directory
    local temp_dir="/tmp/empty_memory_$$"
    mkdir -p "$temp_dir"
    
    run get_memory_file_status "$temp_dir"
    [ "$status" -eq 2 ]
    [[ "$output" == *"No memory files found"* ]]
    
    # Clean up
    rmdir "$temp_dir"
}

@test "check_task_assignments returns 1 for missing file" {
    run check_task_assignments "/nonexistent/assignments.md"
    [ "$status" -eq 1 ]
    [[ "$output" == *"No task assignments file found"* ]]
}

@test "check_task_assignments returns 2 for empty file" {
    local temp_file="/tmp/empty_assignments.md"
    touch "$temp_file"
    
    run check_task_assignments "$temp_file"
    [ "$status" -eq 2 ]
    [[ "$output" == *"Task assignments file is empty"* ]]
    
    # Clean up
    rm -f "$temp_file"
}

@test "check_project_state returns 1 for missing file" {
    run check_project_state "/nonexistent/state.md"
    [ "$status" -eq 1 ]
    [[ "$output" == *"No project state file found"* ]]
}

@test "check_project_state returns 2 for empty file" {
    local temp_file="/tmp/empty_state.md"
    touch "$temp_file"
    
    run check_project_state "$temp_file"
    [ "$status" -eq 2 ]
    [[ "$output" == *"Project state file is empty"* ]]
    
    # Clean up
    rm -f "$temp_file"
}

@test "check_blockers returns 1 for missing file" {
    run check_blockers "/nonexistent/blockers.md"
    [ "$status" -eq 1 ]
    [[ "$output" == *"No blockers reported"* ]]
}

@test "check_blockers returns 2 for empty file" {
    local temp_file="/tmp/empty_blockers.md"
    touch "$temp_file"
    
    run check_blockers "$temp_file"
    [ "$status" -eq 2 ]
    [[ "$output" == *"No blockers reported"* ]]
    
    # Clean up
    rm -f "$temp_file"
}

@test "generate_monitoring_report includes timestamp and sections" {
    # Mock list_active_agent_sessions to return no sessions
    list_active_agent_sessions() { echo ""; }
    export -f list_active_agent_sessions
    
    # Mock other functions
    check_task_assignments() { echo "No assignments"; }
    check_project_state() { echo "No state"; }
    check_blockers() { echo "No blockers"; }
    get_memory_file_status() { echo "No memory files"; }
    export -f check_task_assignments check_project_state check_blockers get_memory_file_status
    
    run generate_monitoring_report "rust react" "/tmp/memory" "/tmp/assignments" "/tmp/state" "/tmp/blockers"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Agent Monitoring Report"* ]]
    [[ "$output" == *"Active Agent Sessions:"* ]]
    [[ "$output" == *"Current Assignments:"* ]]
    [[ "$output" == *"Project State:"* ]]
    [[ "$output" == *"Blockers:"* ]]
}

@test "get_health_summary returns correct counts" {
    # Mock get_agent_status for different scenarios
    get_agent_status() {
        case "$1" in
            "rust-agent") echo "Healthy" ;;
            "react-agent") echo "Not Found" ;;
            "devops-agent") echo "Unhealthy" ;;
        esac
    }
    export -f get_agent_status
    
    run get_health_summary "rust react devops"
    [ "$status" -eq 1 ]  # Should return 1 since there are unhealthy/missing agents
    [[ "$output" == *"1 healthy, 1 unhealthy, 1 not deployed"* ]]
}

@test "get_health_summary returns 0 when all agents healthy" {
    # Mock get_agent_status to return healthy for all
    get_agent_status() { echo "Healthy"; }
    export -f get_agent_status
    
    run get_health_summary "rust react"
    [ "$status" -eq 0 ]
    [[ "$output" == *"2 healthy, 0 unhealthy, 0 not deployed"* ]]
}

@test "get_monitoring_error_message returns correct messages" {
    run get_monitoring_error_message 1 "test-context"
    [[ "$output" == *"Invalid input or missing parameter: test-context"* ]]
    
    run get_monitoring_error_message 2 "test-session"
    [[ "$output" == *"Session not found: test-session"* ]]
    
    run get_monitoring_error_message 3 "health-check"
    [[ "$output" == *"Health check failed: health-check"* ]]
}

@test "get_health_status_emoji returns correct emojis" {
    run get_health_status_emoji "Healthy"
    [[ "$output" == "🟢" ]]
    
    run get_health_status_emoji "Not Found"
    [[ "$output" == "⚪" ]]
    
    run get_health_status_emoji "No Panes"
    [[ "$output" == "🟡" ]]
    
    run get_health_status_emoji "Unknown"
    [[ "$output" == "🔴" ]]
}

@test "format_monitoring_header creates formatted header" {
    run format_monitoring_header "Test Title" 20
    [[ "$output" == *"Test Title"* ]]
    [[ "$output" == *"="* ]]
}

@test "format_agent_status_line formats status line correctly" {
    # Mock get_health_status_emoji
    get_health_status_emoji() { echo "🟢"; }
    export -f get_health_status_emoji
    
    run format_agent_status_line "test-session" "Healthy" "Active" "CPU: 10%"
    [[ "$output" == *"test-session"* ]]
    [[ "$output" == *"🟢"* ]]
    [[ "$output" == *"Healthy"* ]]
    [[ "$output" == *"Active"* ]]
    [[ "$output" == *"CPU: 10%"* ]]
}