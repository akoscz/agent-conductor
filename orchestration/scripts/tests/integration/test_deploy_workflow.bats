#!/usr/bin/env bats

# Integration tests for deploy agent workflow

setup() {
    # Load the library
    source "$BATS_TEST_DIRNAME/../../lib/agent_lib.sh"
    
    # Create test directories
    export TEST_WORKSPACE="$BATS_TMPDIR/workspace"
    export TEST_MEMORY="$BATS_TMPDIR/memory"
    export TEST_LOGS="$BATS_TMPDIR/logs"
    
    mkdir -p "$TEST_WORKSPACE" "$TEST_MEMORY" "$TEST_LOGS"
    
    # Mock external commands
    export TMUX_CMD="echo tmux"
    # Mock date command to handle different format requests
    mock_date() {
        if [[ "$1" == "+%Y-%m-%d %H:%M:%S" ]]; then
            echo "2024-01-15 10:30:00"
        else
            echo "2024-01-15 10:30:00"
        fi
    }
    export -f mock_date
    export DATE_CMD="mock_date"
    export AWK_CMD="awk"
    export MV_CMD="cp"  # Use cp instead of mv for testing
    
    # Create test assignment file
    cat > "$TEST_MEMORY/task_assignments.md" << 'EOF'
# Task Assignments - Updated: 2024-01-01 00:00:00

## Rust Agent
- **Current**: Not assigned
- **Status**: Idle
- **Session**: None
- **Next**: Available for assignment
EOF
}

@test "update_task_assignment updates file correctly" {
    local test_file="$TEST_MEMORY/task_assignments.md"
    
    run update_task_assignment "rust" "123" "rust-agent" "$test_file"
    [ "$status" -eq 0 ]
    
    # Verify file was updated (cp creates .tmp file)
    [ -f "$test_file.tmp" ]
    grep -q "Task #123" "$test_file.tmp"
    grep -q "rust-agent" "$test_file.tmp"
    grep -q "Active" "$test_file.tmp"
}

@test "log_deployment creates log entry" {
    local test_log="$TEST_LOGS/test.log"
    
    run log_deployment "Test Agent" "123" "$test_log"
    [ "$status" -eq 0 ]
    
    # Check log file was created and contains expected content
    [ -f "$test_log" ]
    grep -q "2024-01-15 10:30:00 - Deployed Test Agent for task #123" "$test_log"
}

@test "setup_agent_environment sends all required commands" {
    run setup_agent_environment "test-session" "Test Agent" "123" "test.md" "/tmp/memory" "user" "repo"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux send-keys -t test-session clear Enter"* ]]
    [[ "$output" == *"tmux send-keys -t test-session echo '🤖 Agent: Test Agent | Task: #123 | Session: test-session' Enter"* ]]
    [[ "$output" == *"tmux send-keys -t test-session echo '🔗 GitHub: https://github.com/user/repo/issues/123' Enter"* ]]
}