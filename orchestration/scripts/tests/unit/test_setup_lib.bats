#!/usr/bin/env bats

# Unit tests for setup_lib.sh functionality

setup() {
    # Load the library
    source "$BATS_TEST_DIRNAME/../../lib/setup_lib.sh"
    
    # Set up mocks
    export CP_CMD="echo cp"
    export RM_CMD="echo rm"
    export MKDIR_CMD="echo mkdir"
    export ECHO_CMD="echo echo"
    export DIRNAME_CMD="echo dirname"
    export BASENAME_CMD="echo basename"
    export PWD_CMD="echo pwd"
    export CD_CMD="echo cd"
    
    # Create temporary test directories
    export TEST_PROJECT_DIR="/tmp/test_project_$$"
    export TEST_SOURCE_DIR="/tmp/test_source_$$"
    
    mkdir -p "$TEST_PROJECT_DIR" "$TEST_SOURCE_DIR" 2>/dev/null
    mkdir -p "$TEST_SOURCE_DIR/scripts" "$TEST_SOURCE_DIR/config" "$TEST_SOURCE_DIR/templates" 2>/dev/null
}

teardown() {
    # Clean up test directories
    rm -rf "$TEST_PROJECT_DIR" "$TEST_SOURCE_DIR" 2>/dev/null
}

@test "get_setup_error_message returns correct messages" {
    run get_setup_error_message 1
    [[ "$output" == "Missing project directory parameter" ]]
    
    run get_setup_error_message 2
    [[ "$output" == "Project directory does not exist" ]]
    
    run get_setup_error_message 7
    [[ "$output" == "Orchestration system already exists" ]]
    
    run get_setup_error_message 99
    [[ "$output" == "Unknown setup error" ]]
}

@test "validate_project_directory returns 1 for missing directory parameter" {
    run validate_project_directory ""
    [ "$status" -eq 1 ]
}

@test "validate_project_directory returns 2 for non-existent directory" {
    run validate_project_directory "/nonexistent/directory"
    [ "$status" -eq 2 ]
}

@test "validate_project_directory returns 9 for invalid path" {
    run validate_project_directory "   "
    [ "$status" -eq 9 ]
    
    run validate_project_directory "."
    [ "$status" -eq 9 ]
}

@test "validate_project_directory returns 10 for directory without write access" {
    # Create a directory without write permissions
    local readonly_dir="/tmp/readonly_$$"
    mkdir -p "$readonly_dir"
    chmod -w "$readonly_dir"
    
    run validate_project_directory "$readonly_dir"
    [ "$status" -eq 10 ]
    
    # Clean up
    chmod +w "$readonly_dir"
    rmdir "$readonly_dir" 2>/dev/null
}

@test "validate_project_directory returns 0 for valid writable directory" {
    run validate_project_directory "$TEST_PROJECT_DIR"
    [ "$status" -eq 0 ]
}

@test "validate_source_orchestration returns 1 for missing source directory" {
    run validate_source_orchestration ""
    [ "$status" -eq 1 ]
}

@test "validate_source_orchestration returns 8 for non-existent source directory" {
    run validate_source_orchestration "/nonexistent/source"
    [ "$status" -eq 8 ]
}

@test "validate_source_orchestration returns 8 for source missing essential components" {
    # Create source without required subdirectories
    local incomplete_source="/tmp/incomplete_source_$$"
    mkdir -p "$incomplete_source"
    
    run validate_source_orchestration "$incomplete_source"
    [ "$status" -eq 8 ]
    
    # Clean up
    rmdir "$incomplete_source"
}

@test "validate_source_orchestration returns 0 for valid source directory" {
    run validate_source_orchestration "$TEST_SOURCE_DIR"
    [ "$status" -eq 0 ]
}

@test "check_orchestration_exists returns 7 when orchestration directory exists" {
    # Create orchestration subdirectory
    mkdir -p "$TEST_PROJECT_DIR/orchestration"
    
    run check_orchestration_exists "$TEST_PROJECT_DIR"
    [ "$status" -eq 7 ]
    
    # Clean up
    rmdir "$TEST_PROJECT_DIR/orchestration"
}

@test "check_orchestration_exists returns 0 when no orchestration directory" {
    run check_orchestration_exists "$TEST_PROJECT_DIR"
    [ "$status" -eq 0 ]
}

@test "copy_orchestration_system validates source first" {
    run copy_orchestration_system "/nonexistent/source" "$TEST_PROJECT_DIR"
    [ "$status" -eq 8 ]  # Source validation failure
}

@test "copy_orchestration_system validates target" {
    run copy_orchestration_system "$TEST_SOURCE_DIR" "/nonexistent/target"
    [ "$status" -eq 2 ]  # Target validation failure
}

@test "copy_orchestration_system returns 7 when orchestration exists without overwrite" {
    # Create orchestration subdirectory
    mkdir -p "$TEST_PROJECT_DIR/orchestration"
    
    run copy_orchestration_system "$TEST_SOURCE_DIR" "$TEST_PROJECT_DIR" "false"
    [ "$status" -eq 7 ]
    
    # Clean up
    rmdir "$TEST_PROJECT_DIR/orchestration"
}

@test "copy_orchestration_system copies when overwrite is true" {
    # Create orchestration subdirectory
    mkdir -p "$TEST_PROJECT_DIR/orchestration"
    
    run copy_orchestration_system "$TEST_SOURCE_DIR" "$TEST_PROJECT_DIR" "true"
    [ "$status" -eq 0 ]
    [[ "$output" == *"rm -rf $TEST_PROJECT_DIR/orchestration"* ]]
    [[ "$output" == *"cp -r $TEST_SOURCE_DIR $TEST_PROJECT_DIR/orchestration"* ]]
}

@test "copy_orchestration_system copies when no existing orchestration" {
    run copy_orchestration_system "$TEST_SOURCE_DIR" "$TEST_PROJECT_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"cp -r $TEST_SOURCE_DIR $TEST_PROJECT_DIR/orchestration"* ]]
}

@test "copy_orchestration_system returns 3 when copy fails" {
    # Mock cp to fail
    export CP_CMD="false"
    
    run copy_orchestration_system "$TEST_SOURCE_DIR" "$TEST_PROJECT_DIR"
    [ "$status" -eq 3 ]
}

@test "setup_configuration_templates returns 1 for missing project directory" {
    run setup_configuration_templates ""
    [ "$status" -eq 1 ]
}

@test "setup_configuration_templates returns 5 for missing orchestration directory" {
    run setup_configuration_templates "$TEST_PROJECT_DIR"
    [ "$status" -eq 5 ]
}

@test "setup_configuration_templates copies template files when they exist" {
    # Create orchestration directory and templates
    local orch_dir="$TEST_PROJECT_DIR/orchestration"
    mkdir -p "$orch_dir/config" "$orch_dir/templates"
    touch "$orch_dir/templates/project.example.yml"
    touch "$orch_dir/templates/agents.example.yml"
    
    run setup_configuration_templates "$TEST_PROJECT_DIR" "TestProject"
    [ "$status" -eq 0 ]
    [[ "$output" == *"cp $orch_dir/templates/project.example.yml $orch_dir/config/project.yml"* ]]
    [[ "$output" == *"cp $orch_dir/templates/agents.example.yml $orch_dir/config/agents.yml"* ]]
}

@test "setup_configuration_templates returns 4 when copy fails" {
    # Create orchestration directory and templates
    local orch_dir="$TEST_PROJECT_DIR/orchestration"
    mkdir -p "$orch_dir/config" "$orch_dir/templates"
    touch "$orch_dir/templates/project.example.yml"
    
    # Mock cp to fail
    export CP_CMD="false"
    
    run setup_configuration_templates "$TEST_PROJECT_DIR"
    [ "$status" -eq 4 ]
}

@test "create_project_structure returns 1 for missing project directory" {
    run create_project_structure ""
    [ "$status" -eq 1 ]
}

@test "create_project_structure creates required directories" {
    # Create orchestration directory first
    mkdir -p "$TEST_PROJECT_DIR/orchestration"
    
    run create_project_structure "$TEST_PROJECT_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"mkdir -p $TEST_PROJECT_DIR/orchestration/memory"* ]]
    [[ "$output" == *"mkdir -p $TEST_PROJECT_DIR/orchestration/logs"* ]]
    [[ "$output" == *"mkdir -p $TEST_PROJECT_DIR/orchestration/logs/agents"* ]]
}

@test "create_project_structure returns 5 when mkdir fails" {
    # Create orchestration directory first
    mkdir -p "$TEST_PROJECT_DIR/orchestration"
    
    # Mock mkdir to fail
    export MKDIR_CMD="false"
    
    run create_project_structure "$TEST_PROJECT_DIR"
    [ "$status" -eq 5 ]
}

@test "cleanup_source_project_data returns 1 for missing project directory" {
    run cleanup_source_project_data ""
    [ "$status" -eq 1 ]
}

@test "cleanup_source_project_data removes memory and log files" {
    # Create orchestration directory structure
    local orch_dir="$TEST_PROJECT_DIR/orchestration"
    mkdir -p "$orch_dir/memory" "$orch_dir/logs"
    touch "$orch_dir/memory/test.md" "$orch_dir/logs/test.log"
    
    run cleanup_source_project_data "$TEST_PROJECT_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"rm -rf $orch_dir/memory/"* ]]
    [[ "$output" == *"rm -rf $orch_dir/logs/"* ]]
}

@test "prompt_for_overwrite returns 0 for yes response" {
    # Mock read to return 'y'
    read() { REPLY="y"; }
    export -f read
    
    run prompt_for_overwrite "$TEST_PROJECT_DIR"
    [ "$status" -eq 0 ]
}

@test "prompt_for_overwrite returns 7 for no response" {
    # Mock read to return 'n'
    read() { REPLY="n"; }
    export -f read
    
    run prompt_for_overwrite "$TEST_PROJECT_DIR"
    [ "$status" -eq 7 ]
}

@test "setup_new_project validates project directory first" {
    run setup_new_project "/nonexistent" "$TEST_SOURCE_DIR"
    [ "$status" -eq 2 ]  # Project directory validation failure
}

@test "setup_new_project returns 7 when orchestration exists in non-interactive mode" {
    # Create orchestration subdirectory
    mkdir -p "$TEST_PROJECT_DIR/orchestration"
    
    run setup_new_project "$TEST_PROJECT_DIR" "$TEST_SOURCE_DIR" "TestProject" "false"
    [ "$status" -eq 7 ]
    
    # Clean up
    rmdir "$TEST_PROJECT_DIR/orchestration"
}

@test "setup_new_project calls all setup functions when successful" {
    # Mock all functions to succeed
    copy_orchestration_system() { return 0; }
    setup_configuration_templates() { return 0; }
    create_project_structure() { return 0; }
    cleanup_source_project_data() { return 0; }
    export -f copy_orchestration_system setup_configuration_templates create_project_structure cleanup_source_project_data
    
    run setup_new_project "$TEST_PROJECT_DIR" "$TEST_SOURCE_DIR" "TestProject" "false"
    [ "$status" -eq 0 ]
}

@test "generate_setup_instructions includes all key information" {
    run generate_setup_instructions "$TEST_PROJECT_DIR" "TestProject"
    [[ "$output" == *"Next Steps:"* ]]
    [[ "$output" == *"Configure for your project:"* ]]
    [[ "$output" == *"Install dependencies:"* ]]
    [[ "$output" == *"Initialize and start:"* ]]
    [[ "$output" == *"Key files to customize:"* ]]
}

@test "show_setup_help displays usage information" {
    run show_setup_help "setup_script.sh"
    [[ "$output" == *"AI Agent Orchestration - New Project Setup"* ]]
    [[ "$output" == *"Usage: setup_script.sh"* ]]
    [[ "$output" == *"Arguments:"* ]]
    [[ "$output" == *"Example:"* ]]
}

@test "get_current_orchestration_dir resolves path from script" {
    # Mock dirname and cd/pwd
    dirname() { echo "/test/scripts"; }
    cd() { return 0; }
    pwd() { echo "/test"; }
    export -f dirname cd pwd
    
    run get_current_orchestration_dir "/test/scripts/setup.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"pwd"* ]]
}

@test "extract_project_name_from_path returns last path component" {
    # Use real basename command for this test
    export BASENAME_CMD="basename"
    
    run extract_project_name_from_path "/path/to/my-project"
    [[ "$output" == "my-project" ]]
}

@test "validate_setup_requirements returns 1 for missing tools" {
    # Mock command to fail for all tools
    command() { return 1; }
    export -f command
    
    run validate_setup_requirements
    [ "$status" -eq 1 ]
    [[ "$output" == *"Missing required tools:"* ]]
}

@test "validate_setup_requirements returns 0 when all tools available" {
    # Mock command to succeed for all tools
    command() { return 0; }
    export -f command
    
    run validate_setup_requirements
    [ "$status" -eq 0 ]
}

@test "show_setup_progress displays step information" {
    run show_setup_progress 3 5 "Creating directories"
    [[ "$output" == "[3/5] Creating directories" ]]
}

@test "verify_setup_completion returns 1 for missing components" {
    run verify_setup_completion "$TEST_PROJECT_DIR"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Missing:"* ]]
}

@test "verify_setup_completion returns 0 when all components exist" {
    # Create all required components
    local orch_dir="$TEST_PROJECT_DIR/orchestration"
    mkdir -p "$orch_dir/scripts" "$orch_dir/config" "$orch_dir/memory" "$orch_dir/logs"
    touch "$orch_dir/config/project.yml" "$orch_dir/config/agents.yml"
    
    run verify_setup_completion "$TEST_PROJECT_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Setup verification passed"* ]]
}