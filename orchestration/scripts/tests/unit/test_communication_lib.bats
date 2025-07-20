#!/usr/bin/env bats

# Unit tests for communication_lib.sh functionality

setup() {
    # Load the library
    source "$BATS_TEST_DIRNAME/../../lib/communication_lib.sh"
    
    # Set up mocks
    export TMUX_CMD="echo tmux"
    export DATE_CMD="echo 2024-01-15_10:30:00"
    export AWK_CMD="echo awk"
    export GREP_CMD="echo grep"
    export ECHO_CMD="echo echo"
    export HEAD_CMD="echo head"
    export TR_CMD="echo tr"
    export SED_CMD="echo sed"
    export WC_CMD="echo wc"
    
    # Mock agent session name
    export AGENT_SESSION_NAME="test-agent"
}

@test "get_communication_error_message returns correct messages" {
    run get_communication_error_message 1
    [[ "$output" == "Missing agent type parameter" ]]
    
    run get_communication_error_message 2
    [[ "$output" == "Missing command parameter" ]]
    
    run get_communication_error_message 5
    [[ "$output" == "Command validation failed" ]]
    
    run get_communication_error_message 99
    [[ "$output" == "Unknown communication error" ]]
}

@test "validate_command_parameters returns 1 for missing agent type" {
    run validate_command_parameters "" "test command"
    [ "$status" -eq 1 ]
}

@test "validate_command_parameters returns 2 for missing command" {
    run validate_command_parameters "rust" ""
    [ "$status" -eq 2 ]
}

@test "validate_command_parameters returns 0 for valid parameters" {
    run validate_command_parameters "rust" "cargo --version"
    [ "$status" -eq 0 ]
}

@test "validate_command_syntax returns 5 for dangerous rm -rf command" {
    run validate_command_syntax "rm -rf /"
    [ "$status" -eq 5 ]
}

@test "validate_command_syntax returns 5 for sudo commands" {
    run validate_command_syntax "sudo dangerous-command"
    [ "$status" -eq 5 ]
}

@test "validate_command_syntax returns 5 for format commands" {
    run validate_command_syntax "format /dev/sda"
    [ "$status" -eq 5 ]
}

@test "validate_command_syntax returns 5 for dev redirects" {
    run validate_command_syntax "echo test > /dev/sda"
    [ "$status" -eq 5 ]
}

@test "validate_command_syntax returns 2 for empty command" {
    run validate_command_syntax ""
    [ "$status" -eq 2 ]
}

@test "validate_command_syntax returns 0 for safe commands" {
    run validate_command_syntax "cargo --version"
    [ "$status" -eq 0 ]
    
    run validate_command_syntax "npm test"
    [ "$status" -eq 0 ]
    
    run validate_command_syntax "echo hello"
    [ "$status" -eq 0 ]
}

@test "validate_agent_exists returns 3 when get_agent_config fails" {
    # Mock get_agent_config to fail
    get_agent_config() { return 1; }
    export -f get_agent_config
    
    run validate_agent_exists "nonexistent"
    [ "$status" -eq 3 ]
}

@test "validate_agent_exists returns 0 when get_agent_config succeeds" {
    # Mock get_agent_config to succeed
    get_agent_config() { return 0; }
    export -f get_agent_config
    
    run validate_agent_exists "rust"
    [ "$status" -eq 0 ]
}

@test "check_agent_session_exists returns 1 for missing session name" {
    run check_agent_session_exists ""
    [ "$status" -eq 1 ]
}

@test "check_agent_session_exists calls tmux has-session" {
    run check_agent_session_exists "test-session"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux has-session -t test-session"* ]]
}

@test "get_agent_session_name returns 7 when get_agent_config fails" {
    # Mock get_agent_config to fail
    get_agent_config() { return 1; }
    export -f get_agent_config
    
    run get_agent_session_name "nonexistent"
    [ "$status" -eq 7 ]
}

@test "get_agent_session_name returns session name when config succeeds" {
    # Mock get_agent_config to succeed
    get_agent_config() { return 0; }
    export -f get_agent_config
    
    run get_agent_session_name "rust"
    [ "$status" -eq 0 ]
    [[ "$output" == "test-agent" ]]
}

@test "send_command_to_agent validates parameters first" {
    # Mock get_agent_types to return empty
    get_agent_types() { echo ""; }
    export -f get_agent_types
    
    run send_command_to_agent "" ""
    [ "$status" -eq 1 ]  # Should fail on missing agent type
}

@test "send_command_to_agent validates command syntax" {
    run send_command_to_agent "rust" "rm -rf /"
    [ "$status" -eq 5 ]  # Should fail on dangerous command
}

@test "send_command_to_agent validates agent exists" {
    # Mock validate functions to pass, but agent validation to fail
    validate_command_parameters() { return 0; }
    validate_command_syntax() { return 0; }
    validate_agent_exists() { return 3; }
    export -f validate_command_parameters validate_command_syntax validate_agent_exists
    
    run send_command_to_agent "nonexistent" "safe command"
    [ "$status" -eq 3 ]
}

@test "send_command_to_agent returns 7 when session name retrieval fails" {
    # Mock all validations to pass, but session name retrieval to fail
    validate_command_parameters() { return 0; }
    validate_command_syntax() { return 0; }
    validate_agent_exists() { return 0; }
    get_agent_session_name() { return 7; }
    export -f validate_command_parameters validate_command_syntax validate_agent_exists get_agent_session_name
    
    run send_command_to_agent "rust" "safe command"
    [ "$status" -eq 7 ]
}

@test "send_command_to_agent returns 4 when session doesn't exist" {
    # Mock all validations to pass, but session check to fail
    validate_command_parameters() { return 0; }
    validate_command_syntax() { return 0; }
    validate_agent_exists() { return 0; }
    get_agent_session_name() { echo "test-agent"; return 0; }
    check_agent_session_exists() { return 1; }
    export -f validate_command_parameters validate_command_syntax validate_agent_exists
    export -f get_agent_session_name check_agent_session_exists
    
    run send_command_to_agent "rust" "safe command"
    [ "$status" -eq 4 ]
}

@test "send_command_to_agent succeeds when all validations pass" {
    # Mock all functions to succeed
    validate_command_parameters() { return 0; }
    validate_command_syntax() { return 0; }
    validate_agent_exists() { return 0; }
    get_agent_session_name() { echo "test-agent"; return 0; }
    check_agent_session_exists() { return 0; }
    log_command_execution() { return 0; }
    export -f validate_command_parameters validate_command_syntax validate_agent_exists
    export -f get_agent_session_name check_agent_session_exists log_command_execution
    
    run send_command_to_agent "rust" "safe command" "/tmp/test.log"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux send-keys -t test-agent safe command Enter"* ]]
}

@test "log_command_execution creates log entry" {
    local temp_log="/tmp/test_command.log"
    
    run log_command_execution "rust" "test command" "$temp_log"
    [ "$status" -eq 0 ]
    
    # Clean up
    rm -f "$temp_log"
}

@test "get_command_response returns 1 for missing session name" {
    run get_command_response ""
    [ "$status" -eq 1 ]
}

@test "get_command_response returns 4 when session doesn't exist" {
    # Mock check_agent_session_exists to fail
    check_agent_session_exists() { return 1; }
    export -f check_agent_session_exists
    
    run get_command_response "nonexistent-session"
    [ "$status" -eq 4 ]
}

@test "get_command_response calls tmux capture-pane when session exists" {
    # Mock check_agent_session_exists to succeed
    check_agent_session_exists() { return 0; }
    export -f check_agent_session_exists
    
    run get_command_response "test-session"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux capture-pane -t test-session -p"* ]]
}

@test "broadcast_message_to_agents returns 2 for missing message" {
    run broadcast_message_to_agents ""
    [ "$status" -eq 2 ]
}

@test "broadcast_message_to_agents uses all agent types when none specified" {
    # Mock get_agent_types and send_command_to_agent
    get_agent_types() { echo -e "rust\nreact"; }
    send_command_to_agent() { return 0; }
    export -f get_agent_types send_command_to_agent
    
    run broadcast_message_to_agents "test message"
    [ "$status" -eq 0 ]
}

@test "broadcast_message_to_agents returns 6 when all sends fail" {
    # Mock send_command_to_agent to always fail
    send_command_to_agent() { return 1; }
    export -f send_command_to_agent
    
    run broadcast_message_to_agents "test message" "rust react"
    [ "$status" -eq 6 ]
}

@test "queue_command_for_agent validates parameters" {
    run queue_command_for_agent "" ""
    [ "$status" -eq 1 ]  # Should fail on missing agent type
}

@test "queue_command_for_agent returns 8 when queue is full" {
    # Create a queue file with max lines
    local temp_queue="/tmp/test_queue"
    for i in {1..101}; do
        echo "command $i" >> "$temp_queue"
    done
    
    # Use real wc command for this test
    export WC_CMD="wc"
    
    run queue_command_for_agent "rust" "new command" "$temp_queue" 100
    [ "$status" -eq 8 ]
    
    # Clean up
    rm -f "$temp_queue"
}

@test "queue_command_for_agent adds command to queue" {
    local temp_queue="/tmp/test_queue"
    
    run queue_command_for_agent "rust" "test command" "$temp_queue"
    [ "$status" -eq 0 ]
    
    # Clean up
    rm -f "$temp_queue"
}

@test "check_command_status returns 1 for missing agent type" {
    run check_command_status ""
    [ "$status" -eq 1 ]
}

@test "check_command_status returns 7 when session name retrieval fails" {
    # Mock get_agent_session_name to fail
    get_agent_session_name() { return 7; }
    export -f get_agent_session_name
    
    run check_command_status "rust"
    [ "$status" -eq 7 ]
}

@test "check_command_status returns 4 when session doesn't exist" {
    # Mock get_agent_session_name to succeed but session check to fail
    get_agent_session_name() { echo "test-agent"; return 0; }
    check_agent_session_exists() { return 1; }
    export -f get_agent_session_name check_agent_session_exists
    
    run check_command_status "rust"
    [ "$status" -eq 4 ]
}

@test "check_command_status returns 0 when session exists and no pattern specified" {
    # Mock functions to succeed
    get_agent_session_name() { echo "test-agent"; return 0; }
    check_agent_session_exists() { return 0; }
    export -f get_agent_session_name check_agent_session_exists
    
    run check_command_status "rust"
    [ "$status" -eq 0 ]
}

@test "show_command_examples shows examples for specific agent" {
    run show_command_examples "rust"
    [[ "$output" == *"cargo --version"* ]]
    
    run show_command_examples "react"
    [[ "$output" == *"npm run test"* ]]
    
    run show_command_examples "devops"
    [[ "$output" == *"docker --version"* ]]
    
    run show_command_examples "other"
    [[ "$output" == *"echo"* ]]
}

@test "show_command_examples shows examples for first 3 agents when none specified" {
    # Mock get_agent_types and get_agent_config
    get_agent_types() { echo -e "rust\nreact\ndevops\nqa"; }
    get_agent_config() { return 0; }
    export -f get_agent_types get_agent_config
    
    # Use real head command for this test
    export HEAD_CMD="head"
    
    run show_command_examples ""
    [[ "$output" == *"rust"* ]]
    [[ "$output" == *"react"* ]]
    [[ "$output" == *"devops"* ]]
}

@test "show_available_agents returns comma-separated list" {
    # Mock get_agent_types
    get_agent_types() { echo -e "rust\nreact\ndevops"; }
    export -f get_agent_types
    
    run show_available_agents
    [ "$status" -eq 0 ]
}

@test "format_command_output handles empty output" {
    run format_command_output ""
    [[ "$output" == "No output available" ]]
}

@test "format_command_output truncates long output" {
    local long_output=""
    for i in {1..25}; do
        long_output+="line $i\n"
    done
    
    # Use real head and wc commands for this test
    export HEAD_CMD="head"
    export WC_CMD="wc"
    
    run bash -c "source \"$BATS_TEST_DIRNAME/../../lib/communication_lib.sh\" && export HEAD_CMD=\"head\" && export WC_CMD=\"wc\" && format_command_output \"\$(echo -e \"$long_output\")\" 10"
    [[ "$output" == *"output truncated"* ]]
}

@test "save_command_to_history returns 1 for missing parameters" {
    run save_command_to_history "" ""
    [ "$status" -eq 1 ]
    
    run save_command_to_history "rust" ""
    [ "$status" -eq 1 ]
}

@test "save_command_to_history creates history entry" {
    local temp_history="/tmp/test_history"
    
    run save_command_to_history "rust" "test command" "$temp_history"
    [ "$status" -eq 0 ]
    
    # Clean up
    rm -f "$temp_history"
}

@test "save_command_to_history trims history when too long" {
    local temp_history="/tmp/test_history"
    
    # Create a long history file
    for i in {1..105}; do
        echo "[$DATE_CMD] command $i" >> "$temp_history"
    done
    
    run save_command_to_history "rust" "new command" "$temp_history" 100
    [ "$status" -eq 0 ]
    
    # Check that file is trimmed
    local line_count
    line_count=$(wc -l < "$temp_history" 2>/dev/null || echo "0")
    [[ $line_count -le 100 ]]
    
    # Clean up
    rm -f "$temp_history"
}