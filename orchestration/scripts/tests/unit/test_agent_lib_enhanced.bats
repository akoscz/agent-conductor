#!/usr/bin/env bats

# Unit tests for enhanced agent_lib.sh functionality

setup() {
    # Load the library
    source "$BATS_TEST_DIRNAME/../../lib/agent_lib.sh"
    
    # Set up mocks
    export TMUX_CMD="echo tmux"
    export DATE_CMD="echo 2024-01-15_10:30:00"
    export AWK_CMD="echo awk"
    export MV_CMD="echo mv"
    export GREP_CMD="echo grep"
    export WC_CMD="echo wc"
    export HEAD_CMD="echo head"
    export CAT_CMD="echo cat"
    
    # Mock configuration variables
    export AGENT_SESSION_NAME="test-agent"
    export AGENT_NAME="Test Agent"
    export WORKSPACE_DIR="/tmp/test"
    export MEMORY_DIR="/tmp/memory"
    export LOGS_DIR="/tmp/logs"
    export AGENT_PROMPT_FILE="/tmp/prompt.md"
    export GITHUB_OWNER="testorg"
    export GITHUB_REPO="testrepo"
    export TASK_ASSIGNMENTS_FILE="/tmp/assignments.md"
    export ORCHESTRATOR_LOG="/tmp/orchestrator.log"
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

@test "validate_agent_type calls get_agent_types" {
    # Mock get_agent_types function
    get_agent_types() { echo -e "rust\nreact\ndevops"; }
    export -f get_agent_types
    
    run validate_agent_type "rust"
    [ "$status" -eq 0 ]
}

@test "validate_agent_type rejects invalid agent type" {
    # Mock get_agent_types function
    get_agent_types() { echo -e "rust\nreact\ndevops"; }
    export -f get_agent_types
    
    run validate_agent_type "invalid"
    [ "$status" -eq 1 ]
}

@test "check_session_exists calls tmux has-session" {
    run check_session_exists "test-session"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux has-session -t test-session"* ]]
}

@test "kill_existing_session calls tmux kill-session" {
    run kill_existing_session "test-session"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux kill-session -t test-session"* ]]
}

@test "create_agent_session calls tmux new-session with correct arguments" {
    run create_agent_session "test-session" "/tmp/workspace"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux new-session -d -s test-session -c /tmp/workspace"* ]]
}

@test "create_agent_session uses PWD when no workspace provided" {
    run create_agent_session "test-session"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux new-session -d -s test-session -c"* ]]
}

@test "send_session_command calls tmux send-keys with correct arguments" {
    run send_session_command "test-session" "echo hello"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux send-keys -t test-session echo hello Enter"* ]]
}

@test "setup_agent_environment sends multiple commands to session" {
    run setup_agent_environment "test-session" "Test Agent" "123" "/tmp/prompt.md" "/tmp/memory" "owner" "repo"
    [ "$status" -eq 0 ]
    [[ "$output" == *"clear"* ]]
    [[ "$output" == *"Agent: Test Agent"* ]]
    [[ "$output" == *"Task: #123"* ]]
}

@test "update_task_assignment returns 1 for missing file" {
    run update_task_assignment "rust" "123" "test-session" "/nonexistent/file"
    [ "$status" -eq 1 ]
}

@test "update_task_assignment calls awk when file exists" {
    # Create temporary file
    local temp_file="/tmp/test_assignments.md"
    echo "# Task Assignments" > "$temp_file"
    
    # Mock AWK to echo its usage
    export AWK_CMD="echo awk"
    
    run update_task_assignment "rust" "123" "test-session" "$temp_file"
    [ "$status" -eq 0 ]
    [[ "$output" == *"awk"* ]]
    
    # Clean up
    rm -f "$temp_file"
}

@test "log_deployment creates log entry with timestamp" {
    local temp_log="/tmp/test.log"
    
    run log_deployment "Test Agent" "123" "$temp_log"
    [ "$status" -eq 0 ]
    
    # Clean up
    rm -f "$temp_log"
}

@test "deploy_agent validates arguments first" {
    # Mock validate_agent_deployment_args to fail
    validate_agent_deployment_args() { return 2; }
    export -f validate_agent_deployment_args
    
    run deploy_agent "rust" ""
    [ "$status" -eq 2 ]
}

@test "deploy_agent validates agent type" {
    # Mock functions
    validate_agent_deployment_args() { return 0; }
    validate_agent_type() { return 1; }
    export -f validate_agent_deployment_args validate_agent_type
    
    run deploy_agent "invalid" "123"
    [ "$status" -eq 10 ]
}

@test "deploy_agent loads agent configuration" {
    # Mock functions
    validate_agent_deployment_args() { return 0; }
    validate_agent_type() { return 0; }
    get_agent_config() { return 1; }
    export -f validate_agent_deployment_args validate_agent_type get_agent_config
    
    run deploy_agent "rust" "123"
    [ "$status" -eq 11 ]
}

@test "deploy_agent creates session when all validations pass" {
    # Mock all dependencies
    validate_agent_deployment_args() { return 0; }
    validate_agent_type() { return 0; }
    get_agent_config() { return 0; }
    check_session_exists() { return 1; }  # Session doesn't exist
    create_agent_session() { return 0; }
    setup_agent_environment() { return 0; }
    update_task_assignment() { return 0; }
    log_deployment() { return 0; }
    export -f validate_agent_deployment_args validate_agent_type get_agent_config
    export -f check_session_exists create_agent_session setup_agent_environment
    export -f update_task_assignment log_deployment
    
    run deploy_agent "rust" "123"
    [ "$status" -eq 0 ]
}

@test "get_deployment_error_message returns correct message for error code 1" {
    run get_deployment_error_message 1
    [[ "$output" == *"Missing agent type"* ]]
}

@test "get_deployment_error_message returns correct message for error code 2" {
    run get_deployment_error_message 2
    [[ "$output" == *"Missing task number"* ]]
}

@test "get_deployment_error_message returns correct message for error code 3" {
    run get_deployment_error_message 3
    [[ "$output" == *"Invalid task number format"* ]]
}

@test "get_deployment_error_message returns correct message for error code 10" {
    run get_deployment_error_message 10
    [[ "$output" == *"Invalid agent type"* ]]
}

@test "get_deployment_success_info includes session name and task number" {
    run get_deployment_success_info "rust-agent" "123" "owner" "repo" "/tmp/prompt.md" "rust"
    [[ "$output" == *"rust-agent"* ]]
    [[ "$output" == *"#123"* ]]
    [[ "$output" == *"owner/repo"* ]]
}

@test "validate_deployment_prerequisites returns 1 for missing workspace" {
    run validate_deployment_prerequisites "/nonexistent" "/tmp/prompt.md" "/tmp/memory"
    [ "$status" -eq 1 ]
}

@test "validate_deployment_prerequisites returns 2 for missing prompt file" {
    mkdir -p "/tmp/test_workspace" 2>/dev/null
    run validate_deployment_prerequisites "/tmp/test_workspace" "/nonexistent/prompt.md" "/tmp/memory"
    [ "$status" -eq 2 ]
    rmdir "/tmp/test_workspace" 2>/dev/null
}

@test "validate_deployment_prerequisites returns 3 for memory directory creation failure" {
    mkdir -p "/tmp/test_workspace" 2>/dev/null
    touch "/tmp/test_prompt.md" 2>/dev/null
    
    # Mock mkdir to fail
    mkdir() { return 1; }
    export -f mkdir
    
    run validate_deployment_prerequisites "/tmp/test_workspace" "/tmp/test_prompt.md" "/dev/null/impossible"
    [ "$status" -eq 3 ]
    
    # Clean up
    rm -f "/tmp/test_prompt.md" 2>/dev/null
    rmdir "/tmp/test_workspace" 2>/dev/null
}

@test "validate_deployment_prerequisites returns 4 when tmux not available" {
    mkdir -p "/tmp/test_workspace" "/tmp/test_memory" 2>/dev/null
    touch "/tmp/test_prompt.md" 2>/dev/null
    
    # Mock command to fail for tmux
    command() { 
        if [[ "$2" == "$TMUX_CMD" ]]; then
            return 1
        fi
        return 0
    }
    export -f command
    
    run validate_deployment_prerequisites "/tmp/test_workspace" "/tmp/test_prompt.md" "/tmp/test_memory"
    [ "$status" -eq 4 ]
    
    # Clean up
    rm -f "/tmp/test_prompt.md" 2>/dev/null
    rmdir "/tmp/test_workspace" "/tmp/test_memory" 2>/dev/null
}

@test "check_deployment_conflicts returns 1 when session exists" {
    # Mock check_session_exists to return true
    check_session_exists() { return 0; }
    export -f check_session_exists
    
    run check_deployment_conflicts "existing-session" "123"
    [ "$status" -eq 1 ]
}

@test "check_deployment_conflicts returns 2 when task already assigned" {
    # Mock check_session_exists to return false
    check_session_exists() { return 1; }
    export -f check_session_exists
    
    # Create temporary assignments file with existing task
    local temp_file="/tmp/test_assignments.md"
    echo "Task #123" > "$temp_file"
    
    run check_deployment_conflicts "new-session" "123" "$temp_file"
    [ "$status" -eq 2 ]
    
    # Clean up
    rm -f "$temp_file"
}

@test "prepare_deployment_environment creates required directories" {
    run prepare_deployment_environment "/tmp/workspace" "/tmp/memory" "/tmp/logs"
    [ "$status" -eq 0 ]
}

@test "create_deployment_backup returns 0 for non-existent file" {
    run create_deployment_backup "/nonexistent/file"
    [ "$status" -eq 0 ]
}

@test "create_deployment_backup creates backup for existing file" {
    local temp_file="/tmp/test_assignments.md"
    echo "test content" > "$temp_file"
    
    run create_deployment_backup "$temp_file"
    [ "$status" -eq 0 ]
    
    # Clean up
    rm -f "$temp_file" "$temp_file.backup."* 2>/dev/null
}

@test "validate_agent_deployment_complete returns 1 for non-existent session" {
    # Mock check_session_exists to return false
    check_session_exists() { return 1; }
    export -f check_session_exists
    
    run validate_agent_deployment_complete "nonexistent-session" "/tmp"
    [ "$status" -eq 1 ]
}

@test "deploy_agent_with_validation performs comprehensive validation" {
    # Mock all dependencies to succeed
    validate_agent_deployment_args() { return 0; }
    validate_agent_type() { return 0; }
    get_agent_config() { return 0; }
    validate_deployment_prerequisites() { return 0; }
    check_deployment_conflicts() { return 0; }
    prepare_deployment_environment() { return 0; }
    create_deployment_backup() { return 0; }
    check_session_exists() { return 1; }  # Session doesn't exist
    create_agent_session() { return 0; }
    setup_agent_environment() { return 0; }
    validate_agent_deployment_complete() { return 0; }
    update_task_assignment() { return 0; }
    log_deployment() { return 0; }
    export -f validate_agent_deployment_args validate_agent_type get_agent_config
    export -f validate_deployment_prerequisites check_deployment_conflicts
    export -f prepare_deployment_environment create_deployment_backup
    export -f check_session_exists create_agent_session setup_agent_environment
    export -f validate_agent_deployment_complete update_task_assignment log_deployment
    
    run deploy_agent_with_validation "rust" "123"
    [ "$status" -eq 0 ]
}

@test "get_enhanced_deployment_error_message returns correct message for prerequisite errors" {
    run get_enhanced_deployment_error_message 21
    [[ "$output" == *"Workspace directory missing"* ]]
    
    run get_enhanced_deployment_error_message 22
    [[ "$output" == *"Agent prompt file not found"* ]]
    
    run get_enhanced_deployment_error_message 25
    [[ "$output" == *"Session already exists"* ]]
    
    run get_enhanced_deployment_error_message 31
    [[ "$output" == *"Session was created but is not accessible"* ]]
}