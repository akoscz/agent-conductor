#!/usr/bin/env bats

# Unit tests for session_lib.sh functionality

setup() {
    # Load the library
    source "$BATS_TEST_DIRNAME/../../lib/session_lib.sh"
    
    # Set up mocks
    export TMUX_CMD="echo tmux"
    export DATE_CMD="echo 2024-01-15_10:30:00"
    export PGREP_CMD="echo pgrep"
    export AWK_CMD="echo awk"
    export MV_CMD="echo mv"
}

@test "validate_session_name returns 1 for empty session name" {
    run validate_session_name ""
    [ "$status" -eq 1 ]
}

@test "validate_session_name returns 2 for session name with spaces" {
    run validate_session_name "session with spaces"
    [ "$status" -eq 2 ]
}

@test "validate_session_name returns 2 for session name with dots" {
    run validate_session_name "session.with.dots"
    [ "$status" -eq 2 ]
}

@test "validate_session_name returns 0 for valid session name" {
    run validate_session_name "valid-session-name"
    [ "$status" -eq 0 ]
}

@test "check_tmux_server_running calls pgrep with correct arguments" {
    run check_tmux_server_running
    [ "$status" -eq 0 ]
    [[ "$output" == *"pgrep -x tmux"* ]]
}

@test "session_exists returns 1 for empty session name" {
    run session_exists ""
    [ "$status" -eq 1 ]
}

@test "session_exists calls tmux has-session with correct arguments" {
    run session_exists "test-session"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux has-session -t test-session"* ]]
}

@test "list_all_sessions returns 1 when no tmux server running" {
    export PGREP_CMD="false"
    
    run list_all_sessions
    [ "$status" -eq 1 ]
}

@test "list_all_sessions calls tmux list-sessions when server running" {
    export PGREP_CMD="true"
    
    run list_all_sessions
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux list-sessions"* ]]
}

@test "get_session_info returns 1 for empty session name" {
    run get_session_info ""
    [ "$status" -eq 1 ]
}

@test "get_session_info returns 2 when session doesn't exist" {
    # Mock session_exists to return false
    session_exists() { return 1; }
    export -f session_exists
    
    run get_session_info "nonexistent-session"
    [ "$status" -eq 2 ]
}

@test "get_session_info calls tmux list-sessions when session exists" {
    # Mock session_exists to return true
    session_exists() { return 0; }
    export -f session_exists
    
    run get_session_info "test-session"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux list-sessions"* ]]
}

@test "get_session_pane_count returns 1 for empty session name" {
    run get_session_pane_count ""
    [ "$status" -eq 1 ]
}

@test "get_session_pane_count returns 2 when session doesn't exist" {
    # Mock session_exists to return false
    session_exists() { return 1; }
    export -f session_exists
    
    run get_session_pane_count "nonexistent-session"
    [ "$status" -eq 2 ]
}

@test "get_session_pane_count calls tmux list-panes when session exists" {
    # Mock session_exists to return true
    session_exists() { return 0; }
    export -f session_exists
    
    run get_session_pane_count "test-session"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux list-panes -t test-session"* ]]
}

@test "kill_session returns 1 for empty session name" {
    run kill_session ""
    [ "$status" -eq 1 ]
}

@test "kill_session returns 2 when session doesn't exist" {
    # Mock session_exists to return false
    session_exists() { return 1; }
    export -f session_exists
    
    run kill_session "nonexistent-session"
    [ "$status" -eq 2 ]
}

@test "kill_session calls tmux kill-session when session exists" {
    # Mock session_exists to return true
    session_exists() { return 0; }
    export -f session_exists
    
    run kill_session "test-session"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux kill-session -t test-session"* ]]
}

@test "attach_to_session returns 1 for empty session name" {
    run attach_to_session ""
    [ "$status" -eq 1 ]
}

@test "attach_to_session returns 2 when session doesn't exist" {
    # Mock session_exists to return false
    session_exists() { return 1; }
    export -f session_exists
    
    run attach_to_session "nonexistent-session"
    [ "$status" -eq 2 ]
}

@test "attach_to_session calls tmux attach when session exists" {
    # Mock session_exists to return true
    session_exists() { return 0; }
    export -f session_exists
    
    run attach_to_session "test-session"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux attach -t test-session"* ]]
}

@test "list_agent_sessions returns 1 for empty pattern" {
    run list_agent_sessions ""
    [ "$status" -eq 1 ]
}

@test "list_agent_sessions returns 2 when no tmux server running" {
    # Mock check_tmux_server_running to return false
    check_tmux_server_running() { return 1; }
    export -f check_tmux_server_running
    
    run list_agent_sessions "agent"
    [ "$status" -eq 2 ]
}

@test "list_agent_sessions returns 0 when tmux server running" {
    # Mock check_tmux_server_running to return true
    check_tmux_server_running() { return 0; }
    export -f check_tmux_server_running
    
    # Mock list_all_sessions
    list_all_sessions() { echo "rust-agent"; }
    export -f list_all_sessions
    
    run list_agent_sessions "agent"
    [ "$status" -eq 0 ]
}

@test "build_agent_session_pattern returns 1 for empty agent types" {
    run build_agent_session_pattern ""
    [ "$status" -eq 1 ]
}

@test "build_agent_session_pattern formats pattern correctly" {
    run build_agent_session_pattern "rust react devops"
    [ "$status" -eq 0 ]
    [[ "$output" == "(rust|react|devops)" ]]
}

@test "get_agent_sessions_by_pattern returns 1 for empty agent types" {
    run get_agent_sessions_by_pattern ""
    [ "$status" -eq 1 ]
}

@test "get_agent_sessions_by_pattern returns 2 when pattern build fails" {
    # Mock build_agent_session_pattern to fail
    build_agent_session_pattern() { return 1; }
    export -f build_agent_session_pattern
    
    run get_agent_sessions_by_pattern "rust"
    [ "$status" -eq 2 ]
}

@test "get_session_status returns 1 for empty session name" {
    run get_session_status ""
    [ "$status" -eq 1 ]
}

@test "get_session_status returns 'Not Found' for non-existent session" {
    # Mock session_exists to return false
    session_exists() { return 1; }
    export -f session_exists
    
    run get_session_status "nonexistent-session"
    [ "$status" -eq 2 ]
    [[ "$output" == "Not Found" ]]
}

@test "get_session_status returns 'Active' for session with panes" {
    # Mock session_exists to return true
    session_exists() { return 0; }
    export -f session_exists
    
    # Mock get_session_pane_count to return positive number
    get_session_pane_count() { echo "2"; }
    export -f get_session_pane_count
    
    run get_session_status "test-session"
    [ "$status" -eq 0 ]
    [[ "$output" == "Active" ]]
}

@test "get_session_status returns 'Inactive' for session with no panes" {
    # Mock session_exists to return true
    session_exists() { return 0; }
    export -f session_exists
    
    # Mock get_session_pane_count to return zero
    get_session_pane_count() { echo "0"; }
    export -f get_session_pane_count
    
    run get_session_status "test-session"
    [ "$status" -eq 0 ]
    [[ "$output" == "Inactive" ]]
}

@test "format_session_created_time returns 'Unknown' for empty timestamp" {
    run format_session_created_time ""
    [ "$status" -eq 1 ]
    [[ "$output" == "Unknown" ]]
}

@test "format_session_created_time calls date with correct arguments" {
    run format_session_created_time "1642262400"
    [ "$status" -eq 0 ]
}

@test "extract_agent_type_from_session returns 1 for empty session name" {
    run extract_agent_type_from_session ""
    [ "$status" -eq 1 ]
}

@test "extract_agent_type_from_session removes -agent suffix correctly" {
    run extract_agent_type_from_session "rust-agent"
    [ "$status" -eq 0 ]
    [[ "$output" == "rust" ]]
}

@test "kill_agent_sessions returns 1 for empty agent types" {
    run kill_agent_sessions ""
    [ "$status" -eq 1 ]
}

@test "kill_agent_sessions returns 2 when no tmux server running" {
    # Mock check_tmux_server_running to return false
    check_tmux_server_running() { return 1; }
    export -f check_tmux_server_running
    
    run kill_agent_sessions "rust"
    [ "$status" -eq 2 ]
}

@test "kill_agent_sessions returns 3 when no sessions found" {
    # Mock check_tmux_server_running to return true
    check_tmux_server_running() { return 0; }
    export -f check_tmux_server_running
    
    # Mock get_agent_sessions_by_pattern to fail
    get_agent_sessions_by_pattern() { return 1; }
    export -f get_agent_sessions_by_pattern
    
    run kill_agent_sessions "rust"
    [ "$status" -eq 3 ]
}

@test "update_task_assignments_on_stop returns 1 for invalid file" {
    run update_task_assignments_on_stop "/nonexistent/file"
    [ "$status" -eq 1 ]
}

@test "attach_to_agent returns 1 for missing agent type" {
    run attach_to_agent ""
    [ "$status" -eq 1 ]
}

@test "attach_to_agent returns 2 for missing session name" {
    run attach_to_agent "rust" ""
    [ "$status" -eq 2 ]
}

@test "attach_to_agent returns 3 when session doesn't exist" {
    # Mock session_exists to return false
    session_exists() { return 1; }
    export -f session_exists
    
    run attach_to_agent "rust" "rust-agent"
    [ "$status" -eq 3 ]
}

@test "get_session_error_message returns correct message for error code 1" {
    run get_session_error_message 1
    [[ "$output" == *"Empty or invalid session name"* ]]
}

@test "get_session_error_message returns correct message for error code 2" {
    run get_session_error_message 2 "test-session"
    [[ "$output" == *"Session does not exist: test-session"* ]]
}

@test "get_agent_session_error_message returns correct message for error code 1" {
    run get_agent_session_error_message 1
    [[ "$output" == *"Missing agent type"* ]]
}

@test "get_session_success_message returns correct message for attach action" {
    run get_session_success_message "attach" "test-session"
    [[ "$output" == *"Attaching to test-session"* ]]
}

@test "get_session_success_message returns correct message for stop action" {
    run get_session_success_message "stop" "test-session"
    [[ "$output" == *"Stopped session: test-session"* ]]
}