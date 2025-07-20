#!/usr/bin/env bats

# Unit tests for orchestrator_lib.sh functionality

setup() {
    # Load the library
    source "$BATS_TEST_DIRNAME/../../lib/orchestrator_lib.sh"
    
    # Set up mocks
    export DATE_CMD="echo 2024-01-15_10:30:00"
    export MKDIR_CMD="echo mkdir"
    export CAT_CMD="echo cat"
    export ECHO_CMD="echo echo"
    export AWK_CMD="echo awk"
    export GREP_CMD="echo grep"
    export HEAD_CMD="echo head"
    export TAIL_CMD="echo tail"
    export SED_CMD="echo sed"
    export TR_CMD="echo tr"
    export CD_CMD="echo cd"
    
    # Create temporary test directories and files
    export TEST_WORKSPACE="/tmp/test_workspace_$$"
    export TEST_MEMORY_DIR="/tmp/test_memory_$$"
    export TEST_LOGS_DIR="/tmp/test_logs_$$"
    export TEST_AGENT_LOGS_DIR="/tmp/test_agent_logs_$$"
    
    mkdir -p "$TEST_WORKSPACE" "$TEST_MEMORY_DIR" "$TEST_LOGS_DIR" "$TEST_AGENT_LOGS_DIR" 2>/dev/null
}

teardown() {
    # Clean up test directories
    rm -rf "$TEST_WORKSPACE" "$TEST_MEMORY_DIR" "$TEST_LOGS_DIR" "$TEST_AGENT_LOGS_DIR" 2>/dev/null
}

@test "get_orchestrator_error_message returns correct messages" {
    run get_orchestrator_error_message 1
    [[ "$output" == "Cannot access workspace directory" ]]
    
    run get_orchestrator_error_message 2
    [[ "$output" == "Failed to create directory structure" ]]
    
    run get_orchestrator_error_message 4
    [[ "$output" == "Configuration validation failed" ]]
    
    run get_orchestrator_error_message 99
    [[ "$output" == "Unknown orchestrator error" ]]
}

@test "validate_workspace_access returns 9 for missing workspace parameter" {
    run validate_workspace_access ""
    [ "$status" -eq 9 ]
}

@test "validate_workspace_access returns 1 for non-existent directory" {
    run validate_workspace_access "/nonexistent/directory"
    [ "$status" -eq 1 ]
}

@test "validate_workspace_access returns 1 for directory without write access" {
    # Create a directory without write permissions
    local readonly_dir="/tmp/readonly_$$"
    mkdir -p "$readonly_dir"
    chmod -w "$readonly_dir"
    
    run validate_workspace_access "$readonly_dir"
    [ "$status" -eq 1 ]
    
    # Clean up
    chmod +w "$readonly_dir"
    rmdir "$readonly_dir" 2>/dev/null
}

@test "validate_workspace_access returns 0 for valid writable directory" {
    run validate_workspace_access "$TEST_WORKSPACE"
    [ "$status" -eq 0 ]
}

@test "validate_orchestrator_environment returns 1 for invalid workspace" {
    run validate_orchestrator_environment "/nonexistent" "/tmp"
    [ "$status" -eq 1 ]
}

@test "validate_orchestrator_environment returns 1 for missing orchestration directory" {
    run validate_orchestrator_environment "$TEST_WORKSPACE" "/nonexistent"
    [ "$status" -eq 1 ]
}

@test "validate_orchestrator_environment returns 4 when config validation fails" {
    # Mock check_config_files_exist to fail
    check_config_files_exist() { return 1; }
    export -f check_config_files_exist
    
    # Create orchestration directory
    local orch_dir="/tmp/test_orch_$$"
    mkdir -p "$orch_dir"
    
    run validate_orchestrator_environment "$TEST_WORKSPACE" "$orch_dir"
    [ "$status" -eq 4 ]
    
    # Clean up
    rmdir "$orch_dir"
}

@test "validate_orchestrator_environment returns 0 when all validations pass" {
    # Mock check_config_files_exist to succeed
    check_config_files_exist() { return 0; }
    export -f check_config_files_exist
    
    # Create orchestration directory
    local orch_dir="/tmp/test_orch_$$"
    mkdir -p "$orch_dir"
    
    run validate_orchestrator_environment "$TEST_WORKSPACE" "$orch_dir"
    [ "$status" -eq 0 ]
    
    # Clean up
    rmdir "$orch_dir"
}

@test "create_directory_structure returns 9 for missing parameters" {
    run create_directory_structure "" "" ""
    [ "$status" -eq 9 ]
    
    run create_directory_structure "$TEST_MEMORY_DIR" "" "$TEST_AGENT_LOGS_DIR"
    [ "$status" -eq 9 ]
}

@test "create_directory_structure creates all required directories" {
    run create_directory_structure "$TEST_MEMORY_DIR/new" "$TEST_LOGS_DIR/new" "$TEST_AGENT_LOGS_DIR/new"
    [ "$status" -eq 0 ]
    [[ "$output" == *"mkdir -p $TEST_MEMORY_DIR/new"* ]]
    [[ "$output" == *"mkdir -p $TEST_LOGS_DIR/new"* ]]
    [[ "$output" == *"mkdir -p $TEST_AGENT_LOGS_DIR/new"* ]]
}

@test "create_directory_structure returns 2 when mkdir fails" {
    # Mock mkdir to fail
    export MKDIR_CMD="false"
    
    run create_directory_structure "$TEST_MEMORY_DIR" "$TEST_LOGS_DIR" "$TEST_AGENT_LOGS_DIR"
    [ "$status" -eq 2 ]
}

@test "create_initial_memory_files returns 9 for missing parameters" {
    run create_initial_memory_files "" "" "" "" ""
    [ "$status" -eq 9 ]
    
    run create_initial_memory_files "/tmp/state" "" "/tmp/blockers" "/tmp/decisions" "Test"
    [ "$status" -eq 9 ]
}

@test "create_initial_memory_files calls individual file creation functions" {
    # Mock individual file creation functions
    create_project_state_file() { return 0; }
    create_task_assignments_file() { return 0; }
    create_blockers_file() { return 0; }
    create_decisions_file() { return 0; }
    export -f create_project_state_file create_task_assignments_file create_blockers_file create_decisions_file
    
    run create_initial_memory_files "/tmp/state" "/tmp/assignments" "/tmp/blockers" "/tmp/decisions" "TestProject"
    [ "$status" -eq 0 ]
}

@test "create_initial_memory_files returns 3 when file creation fails" {
    # Mock one function to fail
    create_project_state_file() { return 1; }
    export -f create_project_state_file
    
    run create_initial_memory_files "/tmp/state" "/tmp/assignments" "/tmp/blockers" "/tmp/decisions" "TestProject"
    [ "$status" -eq 3 ]
}

@test "create_project_state_file creates file with project content" {
    local temp_file="/tmp/test_state_$$"
    
    # Override CAT to actually create file
    export CAT_CMD="cat"
    
    run create_project_state_file "$temp_file" "TestProject"
    [ "$status" -eq 0 ]
    
    # Check file was created and contains expected content
    [[ -f "$temp_file" ]]
    grep -q "TestProject Project State" "$temp_file"
    
    # Clean up
    rm -f "$temp_file"
}

@test "create_task_assignments_file creates file with agent assignments" {
    local temp_file="/tmp/test_assignments_$$"
    
    # Mock get_agent_types and get_agent_config
    get_agent_types() { echo -e "rust\nreact"; }
    get_agent_config() { return 0; }
    export -f get_agent_types get_agent_config
    
    # Override CAT to actually create file
    export CAT_CMD="cat"
    
    run create_task_assignments_file "$temp_file"
    [ "$status" -eq 0 ]
    
    # Check file was created and contains expected content
    [[ -f "$temp_file" ]]
    grep -q "Task Assignments" "$temp_file"
    
    # Clean up
    rm -f "$temp_file"
}

@test "create_blockers_file creates file with blockers template" {
    local temp_file="/tmp/test_blockers_$$"
    
    # Override CAT to actually create file
    export CAT_CMD="cat"
    
    run create_blockers_file "$temp_file"
    [ "$status" -eq 0 ]
    
    # Check file was created and contains expected content
    [[ -f "$temp_file" ]]
    grep -q "Project Blockers" "$temp_file"
    
    # Clean up
    rm -f "$temp_file"
}

@test "create_decisions_file creates file with decisions template" {
    local temp_file="/tmp/test_decisions_$$"
    
    # Override CAT to actually create file
    export CAT_CMD="cat"
    
    run create_decisions_file "$temp_file"
    [ "$status" -eq 0 ]
    
    # Check file was created and contains expected content
    [[ -f "$temp_file" ]]
    grep -q "Technical Decisions Log" "$temp_file"
    
    # Clean up
    rm -f "$temp_file"
}

@test "setup_logging returns 9 for missing parameters" {
    run setup_logging "" ""
    [ "$status" -eq 9 ]
    
    run setup_logging "/tmp/test.log" ""
    [ "$status" -eq 9 ]
}

@test "setup_logging creates initial log entry" {
    local temp_log="/tmp/test_orchestrator_$$"
    
    run setup_logging "$temp_log" "TestProject"
    [ "$status" -eq 0 ]
    
    # Check log file was created
    [[ -f "$temp_log" ]]
    grep -q "Orchestrator initialized for TestProject" "$temp_log"
    
    # Clean up
    rm -f "$temp_log"
}

@test "add_log_entry returns 9 for missing parameters" {
    run add_log_entry "" ""
    [ "$status" -eq 9 ]
    
    run add_log_entry "/tmp/test.log" ""
    [ "$status" -eq 9 ]
}

@test "add_log_entry appends message to log file" {
    local temp_log="/tmp/test_log_$$"
    
    run add_log_entry "$temp_log" "Test message"
    [ "$status" -eq 0 ]
    
    # Check log entry was added
    [[ -f "$temp_log" ]]
    grep -q "Test message" "$temp_log"
    
    # Clean up
    rm -f "$temp_log"
}

@test "get_project_state_summary returns 9 for missing parameter" {
    run get_project_state_summary ""
    [ "$status" -eq 9 ]
}

@test "get_project_state_summary returns 5 for missing file" {
    run get_project_state_summary "/nonexistent/state.md"
    [ "$status" -eq 5 ]
    [[ "$output" == "No project state file found" ]]
}

@test "get_project_state_summary extracts key sections from file" {
    local temp_file="/tmp/test_state_$$"
    cat > "$temp_file" << EOF
# Project State
## Current Phase: Phase 1
## Active Tasks
- Task 1
## Completed Tasks
- None
## Blockers
- None
EOF
    
    run get_project_state_summary "$temp_file"
    [ "$status" -eq 0 ]
    
    # Clean up
    rm -f "$temp_file"
}

@test "get_agent_assignments_summary returns 9 for missing parameter" {
    run get_agent_assignments_summary ""
    [ "$status" -eq 9 ]
}

@test "get_agent_assignments_summary returns 6 for missing file" {
    run get_agent_assignments_summary "/nonexistent/assignments.md"
    [ "$status" -eq 6 ]
    [[ "$output" == "No assignments found" ]]
}

@test "get_agent_assignments_summary parses agent assignments" {
    local temp_file="/tmp/test_assignments_$$"
    cat > "$temp_file" << EOF
## Rust Agent
- **Current**: Not assigned
- **Status**: Idle
## React Agent
- **Current**: Task #123
- **Status**: Active
EOF
    
    run get_agent_assignments_summary "$temp_file"
    [ "$status" -eq 0 ]
    
    # Clean up
    rm -f "$temp_file"
}

@test "get_current_blockers returns 9 for missing parameter" {
    run get_current_blockers ""
    [ "$status" -eq 9 ]
}

@test "get_current_blockers returns 10 for missing file" {
    run get_current_blockers "/nonexistent/blockers.md"
    [ "$status" -eq 10 ]
}

@test "get_current_blockers returns 0 when no blockers section" {
    local temp_file="/tmp/test_blockers_$$"
    echo "# Some other content" > "$temp_file"
    
    run get_current_blockers "$temp_file"
    [ "$status" -eq 0 ]
    
    # Clean up
    rm -f "$temp_file"
}

@test "handle_orchestrator_command returns 9 for missing parameters" {
    run handle_orchestrator_command "" ""
    [ "$status" -eq 9 ]
    
    run handle_orchestrator_command "init" ""
    [ "$status" -eq 9 ]
}

@test "handle_orchestrator_command returns 8 for invalid command" {
    run handle_orchestrator_command "invalid" "/tmp/scripts"
    [ "$status" -eq 8 ]
}

@test "handle_orchestrator_command returns 9 for deploy without enough args" {
    run handle_orchestrator_command "deploy" "/tmp/scripts" "rust"
    [ "$status" -eq 9 ]
}

@test "handle_orchestrator_command returns 9 for attach without enough args" {
    run handle_orchestrator_command "attach" "/tmp/scripts"
    [ "$status" -eq 9 ]
}

@test "handle_orchestrator_command returns 9 for send without enough args" {
    run handle_orchestrator_command "send" "/tmp/scripts" "rust"
    [ "$status" -eq 9 ]
}

@test "handle_orchestrator_command returns 0 for status, config, validate commands" {
    run handle_orchestrator_command "status" "/tmp/scripts"
    [ "$status" -eq 0 ]
    
    run handle_orchestrator_command "config" "/tmp/scripts"
    [ "$status" -eq 0 ]
    
    run handle_orchestrator_command "validate" "/tmp/scripts"
    [ "$status" -eq 0 ]
}

@test "initialize_orchestrator validates environment first" {
    # Mock validate_orchestrator_environment to fail
    validate_orchestrator_environment() { return 1; }
    export -f validate_orchestrator_environment
    
    run initialize_orchestrator "/nonexistent" "/tmp" "Test" "/tmp/mem" "/tmp/logs" "/tmp/agent" "/tmp/state" "/tmp/assign" "/tmp/block" "/tmp/dec" "/tmp/orch.log"
    [ "$status" -eq 1 ]
}

@test "initialize_orchestrator returns 1 when cd fails" {
    # Mock all validations to pass but cd to fail
    validate_orchestrator_environment() { return 0; }
    export -f validate_orchestrator_environment
    export CD_CMD="false"
    
    run initialize_orchestrator "$TEST_WORKSPACE" "/tmp" "Test" "/tmp/mem" "/tmp/logs" "/tmp/agent" "/tmp/state" "/tmp/assign" "/tmp/block" "/tmp/dec" "/tmp/orch.log"
    [ "$status" -eq 1 ]
}

@test "initialize_orchestrator calls all setup functions when validations pass" {
    # Mock all functions to succeed
    validate_orchestrator_environment() { return 0; }
    create_directory_structure() { return 0; }
    create_initial_memory_files() { return 0; }
    setup_logging() { return 0; }
    export -f validate_orchestrator_environment create_directory_structure create_initial_memory_files setup_logging
    
    run initialize_orchestrator "$TEST_WORKSPACE" "/tmp" "Test" "/tmp/mem" "/tmp/logs" "/tmp/agent" "/tmp/state" "/tmp/assign" "/tmp/block" "/tmp/dec" "/tmp/orch.log"
    [ "$status" -eq 0 ]
}

@test "show_orchestrator_status displays all sections" {
    # Mock all summary functions
    get_project_state_summary() { echo "  • Phase 1"; }
    get_agent_assignments_summary() { echo "  • Rust: Idle"; }
    get_current_blockers() { echo ""; }
    export -f get_project_state_summary get_agent_assignments_summary get_current_blockers
    
    run show_orchestrator_status "TestProject" "/tmp/state" "/tmp/assign" "/tmp/block" "/tmp/scripts"
    [ "$status" -eq 0 ]
    [[ "$output" == *"TestProject Project Status"* ]]
    [[ "$output" == *"Project State:"* ]]
    [[ "$output" == *"Agent Assignments:"* ]]
    [[ "$output" == *"Active Sessions:"* ]]
    [[ "$output" == *"Current Blockers:"* ]]
}

@test "show_orchestrator_configuration displays configuration information" {
    # Mock get_agent_types
    get_agent_types() { echo -e "rust\nreact"; }
    export -f get_agent_types
    
    run show_orchestrator_configuration "/workspace" "/orch" "/config/project.yml" "/config/agents.yml" "/memory" "/prompts" "/logs" "/scripts"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Orchestrator Configuration"* ]]
    [[ "$output" == *"Directory Structure:"* ]]
    [[ "$output" == *"Configuration Files:"* ]]
    [[ "$output" == *"Available Agents:"* ]]
}