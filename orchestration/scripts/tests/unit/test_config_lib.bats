#!/usr/bin/env bats

# Unit tests for config_lib.sh functionality

setup() {
    # Load the library
    source "$BATS_TEST_DIRNAME/../../lib/config_lib.sh"
    
    # Set up mocks
    export YQ_CMD="echo yq"
    export DATE_CMD="echo 2024-01-15_10:30:00"
    export CP_CMD="echo cp"
    export MV_CMD="echo mv"
    
    # Create temporary test files
    export TEST_PROJECT_CONFIG="/tmp/test_project.yml"
    export TEST_AGENTS_CONFIG="/tmp/test_agents.yml"
    export PROJECT_CONFIG_FILE="$TEST_PROJECT_CONFIG"
    export AGENTS_CONFIG_FILE="$TEST_AGENTS_CONFIG"
}

teardown() {
    # Clean up test files
    rm -f "$TEST_PROJECT_CONFIG" "$TEST_AGENTS_CONFIG" 2>/dev/null || true
}

@test "get_orchestration_root returns correct parent directory" {
    run get_orchestration_root "/path/to/scripts"
    [ "$status" -eq 0 ]
    [[ "$output" == "/path" ]]  # Two levels up: scripts -> to -> path
}

@test "resolve_config_paths sets correct environment variables" {
    # Clear existing variables to test defaults
    unset PROJECT_CONFIG_FILE
    unset AGENTS_CONFIG_FILE
    
    resolve_config_paths "/test/root"
    [ "$?" -eq 0 ]
    [[ "$PROJECT_CONFIG_FILE" == "/test/root/config/project.yml" ]]
    [[ "$AGENTS_CONFIG_FILE" == "/test/root/config/agents.yml" ]]
}

@test "check_yq_available returns success when yq command exists" {
    export YQ_CMD="true"
    run check_yq_available
    [ "$status" -eq 0 ]
}

@test "check_yq_available returns failure when yq command missing" {
    export YQ_CMD="nonexistent_command_12345"
    run check_yq_available
    [ "$status" -eq 1 ]
}

@test "check_config_files_exist returns 1 when project config missing" {
    export PROJECT_CONFIG_FILE="/nonexistent/project.yml"
    export AGENTS_CONFIG_FILE="$TEST_AGENTS_CONFIG"
    touch "$TEST_AGENTS_CONFIG"
    
    run check_config_files_exist
    [ "$status" -eq 1 ]
}

@test "check_config_files_exist returns 2 when agents config missing" {
    export PROJECT_CONFIG_FILE="$TEST_PROJECT_CONFIG"
    export AGENTS_CONFIG_FILE="/nonexistent/agents.yml"
    touch "$TEST_PROJECT_CONFIG"
    
    run check_config_files_exist
    [ "$status" -eq 2 ]
}

@test "check_config_files_exist returns 0 when both configs exist" {
    touch "$TEST_PROJECT_CONFIG" "$TEST_AGENTS_CONFIG"
    
    run check_config_files_exist
    [ "$status" -eq 0 ]
}

@test "check_workspace_directory returns 0 for existing directory" {
    run check_workspace_directory "/tmp"
    [ "$status" -eq 0 ]
}

@test "check_workspace_directory returns 1 for non-existing directory" {
    run check_workspace_directory "/nonexistent/directory"
    [ "$status" -eq 1 ]
}

@test "check_required_tools returns success when all tools available" {
    # Mock tmux and yq as available
    export YQ_CMD="true"
    # Override function to always return true for tmux
    tmux() { return 0; }
    export -f tmux
    
    run check_required_tools
    [ "$status" -eq 0 ]
}

@test "check_required_tools returns failure and lists missing tools" {
    export YQ_CMD="nonexistent_command_12345"
    # Override function to return false for tmux
    tmux() { return 1; }
    export -f tmux
    
    run check_required_tools
    [ "$status" -eq 1 ]
    [[ "$output" == *"tmux"* ]]
    [[ "$output" == *"yq"* ]]
}

@test "load_project_config returns 1 when config file missing" {
    export PROJECT_CONFIG_FILE="/nonexistent/project.yml"
    
    run load_project_config
    [ "$status" -eq 1 ]
}

@test "load_project_config calls yq with correct parameters" {
    touch "$TEST_PROJECT_CONFIG"
    
    # Create a mock yq that echoes its parameters
    cat > /tmp/mock_yq << 'EOF'
#!/bin/bash
echo "yq called with: $*"
EOF
    chmod +x /tmp/mock_yq
    export YQ_CMD="/tmp/mock_yq"
    
    run load_project_config "$TEST_PROJECT_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == *".project.name"* ]]
    
    # Clean up
    rm -f /tmp/mock_yq
}

@test "agent_type_exists returns 1 for empty agent type" {
    touch "$TEST_AGENTS_CONFIG"
    
    run agent_type_exists ""
    [ "$status" -eq 1 ]
}

@test "agent_type_exists returns 1 for missing config file" {
    run agent_type_exists "rust" "/nonexistent/agents.yml"
    [ "$status" -eq 1 ]
}

@test "load_agent_config returns 1 for missing agent type" {
    run load_agent_config ""
    [ "$status" -eq 1 ]
}

@test "load_agent_config returns 2 for missing config file" {
    run load_agent_config "rust" "/nonexistent/agents.yml"
    [ "$status" -eq 2 ]
}

@test "get_agent_info returns 1 for missing agent type" {
    run get_agent_info ""
    [ "$status" -eq 1 ]
}

@test "get_agent_info returns 2 for missing config file" {
    run get_agent_info "rust" "/nonexistent/agents.yml"
    [ "$status" -eq 2 ]
}

@test "validation_profile_exists returns 1 for empty profile" {
    touch "$TEST_AGENTS_CONFIG"
    
    run validation_profile_exists ""
    [ "$status" -eq 1 ]
}

@test "get_validation_commands returns 1 for missing profile" {
    run get_validation_commands ""
    [ "$status" -eq 1 ]
}

@test "get_validation_commands returns 2 for missing config file" {
    run get_validation_commands "rust" "/nonexistent/agents.yml"
    [ "$status" -eq 2 ]
}

@test "get_phase_info returns 1 for missing phase number" {
    run get_phase_info ""
    [ "$status" -eq 1 ]
}

@test "get_phase_info returns 2 for missing config file" {
    run get_phase_info "1" "/nonexistent/project.yml"
    [ "$status" -eq 2 ]
}

@test "get_agents_by_capability returns 1 for missing capability" {
    run get_agents_by_capability ""
    [ "$status" -eq 1 ]
}

@test "get_agents_by_capability returns 2 for missing config file" {
    run get_agents_by_capability "coding" "/nonexistent/agents.yml"
    [ "$status" -eq 2 ]
}

@test "add_agent_type returns 1 for missing required parameters" {
    run add_agent_type "" ""
    [ "$status" -eq 1 ]
}

@test "add_agent_type returns 2 for missing config file" {
    run add_agent_type "test" "Test Agent" "Test description" "" "" "" "/nonexistent/agents.yml"
    [ "$status" -eq 2 ]
}

@test "remove_agent_type returns 1 for missing agent type" {
    run remove_agent_type ""
    [ "$status" -eq 1 ]
}

@test "remove_agent_type returns 2 for missing config file" {
    run remove_agent_type "rust" "/nonexistent/agents.yml"
    [ "$status" -eq 2 ]
}

@test "load_full_configuration returns 1 when yq not available" {
    export YQ_CMD="nonexistent_command_12345"
    
    run load_full_configuration
    [ "$status" -eq 1 ]
}

@test "get_config_error_message returns correct message for error code 1" {
    run get_config_error_message 1
    [[ "$output" == *"yq is required"* ]]
}

@test "get_config_error_message returns correct message for error code 2" {
    run get_config_error_message 2
    [[ "$output" == *"Project configuration file not found"* ]]
}

@test "get_agent_config_error_message returns correct message for error code 1" {
    run get_agent_config_error_message 1
    [[ "$output" == *"Missing agent type"* ]]
}

@test "get_agent_config_error_message returns correct message for error code 3" {
    run get_agent_config_error_message 3 "rust"
    [[ "$output" == *"Unknown agent type: rust"* ]]
}

@test "get_validation_error_message returns correct message for error code 1" {
    run get_validation_error_message 1
    [[ "$output" == *"Missing validation profile"* ]]
}

@test "get_validation_error_message returns correct message for error code 3" {
    run get_validation_error_message 3 "rust"
    [[ "$output" == *"Validation profile not found: rust"* ]]
}