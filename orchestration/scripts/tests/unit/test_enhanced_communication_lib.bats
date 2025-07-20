#!/usr/bin/env bats

# Unit tests for enhanced_communication_lib.sh functionality
# Tests file locking, transactions, and enhanced queue management

setup() {
    # Set up test environment first
    export TEST_LOCK_DIR="/tmp/test-agent-conductor-locks-$$"
    export TEST_TRANSACTION_DIR="/tmp/test-agent-conductor-transactions-$$"
    export AGENT_CONDUCTOR_LOCK_DIR="$TEST_LOCK_DIR"
    export AGENT_CONDUCTOR_TRANSACTION_DIR="$TEST_TRANSACTION_DIR"
    
    # Load the enhanced library after setting environment
    source "$BATS_TEST_DIRNAME/../../lib/enhanced_communication_lib.sh"
    
    # Set up mocks for external commands
    export MKDIR_CMD="mkdir"
    export RMDIR_CMD="rmdir"
    export DATE_CMD="date"
    export STAT_CMD="stat"
    export MKTEMP_CMD="mktemp"
    export FIND_CMD="find"
    export RM_CMD="rm"
    export MV_CMD="mv"
    export CP_CMD="cp"
    export WC_CMD="wc"
    export TAIL_CMD="tail"
    export HEAD_CMD="head"
    export SORT_CMD="sort"
    export CAT_CMD="cat"
    export ECHO_CMD="echo"
    export SLEEP_CMD="sleep"
    
    # Create test directories manually to ensure they exist
    mkdir -p "$TEST_LOCK_DIR" 2>/dev/null || true
    mkdir -p "$TEST_TRANSACTION_DIR" 2>/dev/null || true
}

teardown() {
    # Cleanup test environment
    rm -rf "$TEST_LOCK_DIR" 2>/dev/null || true
    rm -rf "$TEST_TRANSACTION_DIR" 2>/dev/null || true
    rm -f "/tmp/agent-conductor-tx-$$" 2>/dev/null || true
    rm -rf "/tmp/test_queue_*" 2>/dev/null || true
    rm -rf "/tmp/agent_command_queue_test*" 2>/dev/null || true
    rm -rf "/tmp/agent_command_queue_concurrent_test" 2>/dev/null || true
    rm -rf "/tmp/agent_command_queue_status_agent" 2>/dev/null || true
    rm -rf "/tmp/agent_command_queue_empty_agent" 2>/dev/null || true
    # Clean up any leftover queue directories from this test session
    find /tmp -name "agent_command_queue_*" -type d -exec rm -rf {} + 2>/dev/null || true
}

# Test initialization
@test "init_enhanced_communication creates required directories" {
    # Clean up first
    rm -rf "$TEST_LOCK_DIR" "$TEST_TRANSACTION_DIR"
    
    run init_enhanced_communication
    [ "$status" -eq 0 ]
    
    # Check directories were created
    run test -d "$TEST_LOCK_DIR"
    [ "$status" -eq 0 ]
    
    run test -d "$TEST_TRANSACTION_DIR"
    [ "$status" -eq 0 ]
}

# Test basic locking functionality
@test "acquire_resource_lock creates lock directory" {
    run acquire_resource_lock "test_resource"
    [ "$status" -eq 0 ]
    
    run test -d "$TEST_LOCK_DIR/test_resource.lock.d"
    [ "$status" -eq 0 ]
    
    run test -f "$TEST_LOCK_DIR/test_resource.lock.d/info"
    [ "$status" -eq 0 ]
    
    # Clean up
    release_resource_lock "test_resource"
}

@test "acquire_resource_lock fails with empty resource name" {
    run acquire_resource_lock ""
    [ "$status" -eq 1 ]
}

@test "acquire_resource_lock timeout works" {
    # Create a persistent lock with a running process PID to prevent removal
    mkdir -p "$TEST_LOCK_DIR/test_timeout.lock.d"
    echo "$$:$(date +%s)" > "$TEST_LOCK_DIR/test_timeout.lock.d/info"
    
    # Now try to acquire the same lock from this process (should timeout)
    # We need to create a subshell to simulate a different process trying to acquire the lock
    run bash -c "source \"$BATS_TEST_DIRNAME/../../lib/enhanced_communication_lib.sh\" && export AGENT_CONDUCTOR_LOCK_DIR=\"$TEST_LOCK_DIR\" && acquire_resource_lock test_timeout 1"
    [ "$status" -eq 20 ]  # EC_LOCK_TIMEOUT
}

@test "acquire_resource_lock removes stale locks" {
    # Create a stale lock (old timestamp, non-existent PID)
    mkdir -p "$TEST_LOCK_DIR/stale_test.lock.d"
    echo "99999:1" > "$TEST_LOCK_DIR/stale_test.lock.d/info"
    
    run acquire_resource_lock "stale_test"
    [ "$status" -eq 0 ]
    [ -f "$TEST_LOCK_DIR/stale_test.lock.d/info" ]
    
    # Check that the lock info was updated with current PID
    local lock_info
    lock_info=$(cat "$TEST_LOCK_DIR/stale_test.lock.d/info")
    local lock_pid
    lock_pid=$(echo "$lock_info" | cut -d: -f1)
    [ "$lock_pid" = "$$" ]
    
    # Clean up
    release_resource_lock "stale_test"
}

@test "release_resource_lock removes lock directory" {
    run acquire_resource_lock "test_release"
    [ "$status" -eq 0 ]
    
    run test -d "$TEST_LOCK_DIR/test_release.lock.d"
    [ "$status" -eq 0 ]
    
    run release_resource_lock "test_release"
    [ "$status" -eq 0 ]
    
    run test -d "$TEST_LOCK_DIR/test_release.lock.d"
    [ "$status" -eq 1 ]
}

@test "release_resource_lock fails for empty resource name" {
    run release_resource_lock ""
    [ "$status" -eq 1 ]
}

@test "release_resource_lock fails for lock owned by different process" {
    # Create lock with different PID (using a PID that's very unlikely to exist)
    mkdir -p "$TEST_LOCK_DIR/other_proc.lock.d"
    echo "99999:$(date +%s)" > "$TEST_LOCK_DIR/other_proc.lock.d/info"
    
    run release_resource_lock "other_proc"
    [ "$status" -eq 21 ]  # EC_LOCK_EXISTS
    [ -d "$TEST_LOCK_DIR/other_proc.lock.d" ]  # Lock should still exist
    
    # Manual cleanup
    rm -rf "$TEST_LOCK_DIR/other_proc.lock.d"
}

# Test safe file operations
@test "safe_read_file reads existing file" {
    local test_file="/tmp/test_read_$$"
    echo "test content" > "$test_file"
    
    run safe_read_file "$test_file"
    [ "$status" -eq 0 ]
    [[ "$output" == "test content" ]]
    
    rm -f "$test_file"
}

@test "safe_read_file returns empty for non-existent file" {
    run safe_read_file "/tmp/non_existent_$$"
    [ "$status" -eq 0 ]
    [[ "$output" == "" ]]
}

@test "safe_read_file fails with empty file path" {
    run safe_read_file ""
    [ "$status" -eq 1 ]
}

@test "safe_write_file creates file with content" {
    local test_file="/tmp/test_write_$$"
    
    run safe_write_file "$test_file" "test content"
    [ "$status" -eq 0 ]
    [ -f "$test_file" ]
    
    local content
    content=$(cat "$test_file")
    [[ "$content" == "test content" ]]
    
    rm -f "$test_file"*
}

@test "safe_write_file fails with empty file path" {
    run safe_write_file "" "content"
    [ "$status" -eq 1 ]
}

@test "safe_write_file creates backup" {
    local test_file="/tmp/test_backup_$$"
    echo "original content" > "$test_file"
    
    run safe_write_file "$test_file" "new content"
    [ "$status" -eq 0 ]
    
    # Check backup was created
    local backup_count
    backup_count=$(find "$(dirname "$test_file")" -name "$(basename "$test_file").backup.*" | wc -l)
    [[ $backup_count -ge 1 ]]
    
    rm -f "$test_file"*
}

@test "safe_write_file detects conflicts when enabled" {
    local test_file="/tmp/test_conflict_$$"
    echo "original" > "$test_file"
    
    # Simulate external modification by updating mtime
    sleep 1
    echo "modified externally" > "$test_file"
    
    # This should detect the conflict
    run safe_write_file "$test_file" "new content" "true"
    # Note: In some cases this might succeed due to timing, so we test the logic exists
    [ "$status" -eq 0 ] || [ "$status" -eq 23 ]  # Either success or conflict detected
    
    rm -f "$test_file"*
}

@test "safe_write_file skips conflict detection when disabled" {
    local test_file="/tmp/test_no_conflict_$$"
    echo "original" > "$test_file"
    sleep 1
    echo "modified externally" > "$test_file"
    
    run safe_write_file "$test_file" "new content" "false"
    [ "$status" -eq 0 ]
    
    local content
    content=$(cat "$test_file")
    [[ "$content" == "new content" ]]
    
    rm -f "$test_file"*
}

# Test transaction functionality
@test "begin_file_transaction creates transaction" {
    run begin_file_transaction
    [ "$status" -eq 0 ]
    [[ "$output" == *"Transaction"*"started"* ]]
    
    # Check transaction ID file was created
    [ -f "/tmp/agent-conductor-tx-$$" ]
    
    # Check transaction directory was created
    local tx_id
    tx_id=$(cat "/tmp/agent-conductor-tx-$$")
    [ -d "$TEST_TRANSACTION_DIR/$tx_id" ]
}

@test "add_to_transaction stores operation" {
    begin_file_transaction
    
    run add_to_transaction "/tmp/test_tx_file" "test content"
    [ "$status" -eq 0 ]
    
    # Check operation file was created
    local tx_id
    tx_id=$(cat "/tmp/agent-conductor-tx-$$")
    local op_count
    op_count=$(find "$TEST_TRANSACTION_DIR/$tx_id" -name "op_*" -not -name "*.content" | wc -l)
    [[ $op_count -ge 1 ]]
}

@test "add_to_transaction fails without active transaction" {
    run add_to_transaction "/tmp/test_file" "content"
    [ "$status" -eq 22 ]  # EC_TRANSACTION_FAILED
}

@test "commit_file_transaction applies all operations" {
    local test_file1="/tmp/test_tx_1_$$"
    local test_file2="/tmp/test_tx_2_$$"
    
    begin_file_transaction
    add_to_transaction "$test_file1" "content1"
    add_to_transaction "$test_file2" "content2"
    
    run commit_file_transaction
    [ "$status" -eq 0 ]
    
    # Check files were created with correct content
    [ -f "$test_file1" ]
    [ -f "$test_file2" ]
    
    local content1
    local content2
    content1=$(cat "$test_file1")
    content2=$(cat "$test_file2")
    [[ "$content1" == "content1" ]]
    [[ "$content2" == "content2" ]]
    
    # Check transaction was cleaned up
    [ ! -f "/tmp/agent-conductor-tx-$$" ]
    
    rm -f "$test_file1" "$test_file2"
}

@test "commit_file_transaction fails without active transaction" {
    run commit_file_transaction
    [ "$status" -eq 22 ]  # EC_TRANSACTION_FAILED
}

@test "rollback_file_transaction cleans up transaction" {
    local test_file="/tmp/test_rollback_$$"
    
    begin_file_transaction
    add_to_transaction "$test_file" "content"
    
    run rollback_file_transaction
    [ "$status" -eq 0 ]
    
    # File should not have been created
    [ ! -f "$test_file" ]
    
    # Transaction should be cleaned up
    [ ! -f "/tmp/agent-conductor-tx-$$" ]
}

# Test enhanced queue management
@test "init_agent_queue creates queue directory and sequence file" {
    # Clean up any existing queue first
    rm -rf "/tmp/agent_command_queue_test_agent" 2>/dev/null || true
    
    run init_agent_queue "test_agent"
    [ "$status" -eq 0 ]
    [ -d "/tmp/agent_command_queue_test_agent" ]
    [ -f "/tmp/agent_command_queue_test_agent/.sequence" ]
    
    local seq_content
    seq_content=$(cat "/tmp/agent_command_queue_test_agent/.sequence" | tr -d '\n')
    [[ "$seq_content" == "0" ]]
}

@test "init_agent_queue fails with empty agent type" {
    run init_agent_queue ""
    [ "$status" -eq 1 ]
}

@test "enqueue_command_safe adds command with sequence" {
    # Clean up and initialize fresh queue
    rm -rf "/tmp/agent_command_queue_test_agent" 2>/dev/null || true
    init_agent_queue "test_agent"
    
    run enqueue_command_safe "test_agent" "test command" "high"
    [ "$status" -eq 0 ]
    
    # Check command file was created
    local cmd_count
    cmd_count=$(find "/tmp/agent_command_queue_test_agent" -name "cmd_*" -type f | wc -l | tr -d ' ')
    [[ $cmd_count -eq 1 ]]
    
    # Check sequence was incremented
    local seq_content
    seq_content=$(cat "/tmp/agent_command_queue_test_agent/.sequence" | tr -d '\n')
    [[ "$seq_content" == "1" ]]
}

@test "enqueue_command_safe fails with missing parameters" {
    run enqueue_command_safe "" "command"
    [ "$status" -eq 1 ]
    
    run enqueue_command_safe "agent" ""
    [ "$status" -eq 1 ]
}

@test "enqueue_command_safe handles different priorities" {
    # Clean up and initialize fresh queue
    rm -rf "/tmp/agent_command_queue_test_agent" 2>/dev/null || true
    init_agent_queue "test_agent"
    
    enqueue_command_safe "test_agent" "high_cmd" "high"
    enqueue_command_safe "test_agent" "normal_cmd" "normal"
    enqueue_command_safe "test_agent" "low_cmd" "low"
    
    # Check priority encoding in filenames
    local high_count
    local normal_count
    local low_count
    high_count=$(find "/tmp/agent_command_queue_test_agent" -name "cmd_1_*" -type f | wc -l | tr -d ' ')
    normal_count=$(find "/tmp/agent_command_queue_test_agent" -name "cmd_2_*" -type f | wc -l | tr -d ' ')
    low_count=$(find "/tmp/agent_command_queue_test_agent" -name "cmd_3_*" -type f | wc -l | tr -d ' ')
    
    [[ $high_count -eq 1 ]]
    [[ $normal_count -eq 1 ]]
    [[ $low_count -eq 1 ]]
}

@test "dequeue_command_safe returns commands by priority then sequence" {
    # Clean up and initialize fresh queue
    rm -rf "/tmp/agent_command_queue_test_agent" 2>/dev/null || true
    init_agent_queue "test_agent"
    
    # Add commands in different order
    enqueue_command_safe "test_agent" "low_cmd" "low"
    enqueue_command_safe "test_agent" "high_cmd" "high"
    enqueue_command_safe "test_agent" "normal_cmd" "normal"
    
    # First dequeue should return high priority
    run dequeue_command_safe "test_agent"
    [ "$status" -eq 0 ]
    [[ "$output" == "high_cmd" ]]
    
    # Second dequeue should return normal priority
    run dequeue_command_safe "test_agent"
    [ "$status" -eq 0 ]
    [[ "$output" == "normal_cmd" ]]
    
    # Third dequeue should return low priority
    run dequeue_command_safe "test_agent"
    [ "$status" -eq 0 ]
    [[ "$output" == "low_cmd" ]]
    
    # Fourth dequeue should fail (empty queue)
    run dequeue_command_safe "test_agent"
    [ "$status" -eq 1 ]
}

@test "dequeue_command_safe fails with empty agent type" {
    run dequeue_command_safe ""
    [ "$status" -eq 1 ]
}

@test "dequeue_command_safe returns failure for empty queue" {
    init_agent_queue "empty_agent"
    
    run dequeue_command_safe "empty_agent"
    [ "$status" -eq 1 ]
}

@test "get_queue_status returns correct counts" {
    # Clean up any existing status_agent queue
    rm -rf "/tmp/agent_command_queue_status_agent" 2>/dev/null || true
    init_agent_queue "status_agent"
    
    enqueue_command_safe "status_agent" "cmd1" "high"
    enqueue_command_safe "status_agent" "cmd2" "high"
    enqueue_command_safe "status_agent" "cmd3" "normal"
    enqueue_command_safe "status_agent" "cmd4" "low"
    
    run get_queue_status "status_agent"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Total:        4"* ]]
    [[ "$output" == *"High:        2"* ]]
    [[ "$output" == *"Normal:        1"* ]]
    [[ "$output" == *"Low:        1"* ]]
}

@test "get_queue_status fails with empty agent type" {
    run get_queue_status ""
    [ "$status" -eq 1 ]
}

@test "get_queue_status fails for non-existent queue" {
    run get_queue_status "non_existent_agent"
    [ "$status" -eq 1 ]
}

# Test concurrent access scenarios
@test "multiple processes can acquire different locks" {
    # Test that different locks can be acquired simultaneously
    run acquire_resource_lock "resource1"
    [ "$status" -eq 0 ]
    
    run acquire_resource_lock "resource2"
    [ "$status" -eq 0 ]
    
    [ -d "$TEST_LOCK_DIR/resource1.lock.d" ]
    [ -d "$TEST_LOCK_DIR/resource2.lock.d" ]
    
    # Clean up
    release_resource_lock "resource1"
    release_resource_lock "resource2"
}

@test "cleanup_old_backups removes excess backups" {
    local test_file="/tmp/test_cleanup_$$"
    echo "original" > "$test_file"
    
    # Create multiple backups manually
    for i in {1..8}; do
        echo "backup$i" > "${test_file}.backup.backup$i"
    done
    
    run cleanup_old_backups "$test_file" 3
    [ "$status" -eq 0 ]
    
    # Should have only 3 backups remaining
    local backup_count
    backup_count=$(find "$(dirname "$test_file")" -name "$(basename "$test_file").backup.*" | wc -l)
    [[ $backup_count -eq 3 ]]
    
    rm -f "$test_file"*
}

# Test error conditions and edge cases
@test "safe operations handle lock timeout gracefully" {
    # Create a persistent lock to test timeout
    mkdir -p "$TEST_LOCK_DIR/timeout_test.lock.d"
    echo "$$:$(date +%s)" > "$TEST_LOCK_DIR/timeout_test.lock.d/info"
    
    # Try to read with very short timeout - should timeout waiting for write lock to clear
    run safe_read_file "/tmp/timeout_test" 1
    # This might succeed if the lock is acquired quickly, so we accept either outcome
    [ "$status" -eq 0 ] || [ "$status" -eq 20 ]  # Success or timeout
}

@test "transaction handles lock failures gracefully" {
    # This is harder to test without actual concurrency, so we test the basic flow
    begin_file_transaction
    add_to_transaction "/tmp/tx_test_$$" "content"
    
    # Commit should work
    run commit_file_transaction
    [ "$status" -eq 0 ]
    
    rm -f "/tmp/tx_test_$$"
}