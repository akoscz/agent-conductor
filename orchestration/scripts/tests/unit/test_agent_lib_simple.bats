#!/usr/bin/env bats

# Simple tests for agent_lib.sh functionality

setup() {
    # Load the library
    source "$BATS_TEST_DIRNAME/../../lib/agent_lib.sh"
    
    # Set up mocks
    export TMUX_CMD="echo tmux"
    export DATE_CMD="echo 2024-01-15 10:30:00"
}

@test "validate_agent_deployment_args accepts valid arguments" {
    run validate_agent_deployment_args "rust" "123"
    [ "$status" -eq 0 ]
}

@test "validate_agent_deployment_args rejects empty agent type" {
    run validate_agent_deployment_args "" "123"
    [ "$status" -eq 1 ]
}

@test "validate_agent_deployment_args rejects empty task number" {
    run validate_agent_deployment_args "rust" ""
    [ "$status" -eq 2 ]
}

@test "validate_agent_deployment_args rejects non-numeric task number" {
    run validate_agent_deployment_args "rust" "abc"
    [ "$status" -eq 3 ]
}

@test "create_agent_session calls tmux with correct arguments" {
    run create_agent_session "test-session" "/tmp/workspace"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux new-session -d -s test-session -c /tmp/workspace"* ]]
}

@test "get_deployment_error_message returns correct message for missing agent type" {
    run get_deployment_error_message 1
    [[ "$output" == *"Missing agent type"* ]]
}

@test "send_session_command formats tmux command correctly" {
    run send_session_command "test-session" "echo hello"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux send-keys -t test-session echo hello Enter"* ]]
}