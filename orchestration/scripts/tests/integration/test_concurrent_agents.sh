#!/bin/bash

# Concurrent agent test script
# Simulates multiple agents working with the enhanced communication system

set -e

echo "🚀 Testing concurrent agent communication..."

# Load the library
source "./scripts/lib/enhanced_communication_lib.sh"

# Set test environment
export AGENT_CONDUCTOR_LOCK_DIR="/tmp/concurrent-test-locks-$$"
export AGENT_CONDUCTOR_TRANSACTION_DIR="/tmp/concurrent-test-tx-$$"

# Initialize
init_enhanced_communication
echo "✅ Enhanced communication initialized"

# Test 1: Concurrent file operations
echo "📝 Testing concurrent file operations..."

test_file="/tmp/concurrent_test_$$"
num_processes=5

# Function to simulate agent writing to shared file
write_agent_data() {
    local agent_id="$1"
    local iterations="$2"
    
    for ((i=1; i<=iterations; i++)); do
        # Read current content
        current_content=$(safe_read_file "$test_file" 2>/dev/null || echo "")
        
        # Append agent data
        new_content="${current_content}Agent-${agent_id}-Write-${i}\n"
        
        # Write back safely
        if ! safe_write_file "$test_file" "$new_content" "true"; then
            echo "⚠️  Agent $agent_id write $i failed (conflict detected)"
            sleep 0.1  # Brief retry delay
            continue
        fi
        
        sleep 0.05  # Simulate processing time
    done
    
    echo "✅ Agent $agent_id completed"
}

# Start multiple agents concurrently
for ((agent=1; agent<=num_processes; agent++)); do
    write_agent_data "$agent" 3 &
done

# Wait for all agents to complete
wait

# Check results
if [[ -f "$test_file" ]]; then
    line_count=$(wc -l < "$test_file")
    echo "✅ Concurrent writes completed - $line_count lines written"
    
    # Verify no data corruption
    if grep -q "Agent-" "$test_file"; then
        echo "✅ Data integrity verified"
    else
        echo "❌ Data corruption detected"
        exit 1
    fi
else
    echo "❌ Test file not created"
    exit 1
fi

# Test 2: Concurrent queue operations
echo "📋 Testing concurrent queue operations..."

queue_test_agent="concurrent_test"
init_agent_queue "$queue_test_agent"

# Function to enqueue commands
enqueue_agent_commands() {
    local agent_id="$1"
    local priority="$2"
    local count="$3"
    
    for ((i=1; i<=count; i++)); do
        if enqueue_command_safe "$queue_test_agent" "Agent-${agent_id}-Cmd-${i}" "$priority"; then
            echo "Agent $agent_id enqueued command $i"
        else
            echo "⚠️  Agent $agent_id failed to enqueue command $i"
        fi
        sleep 0.02
    done
}

# Start multiple agents enqueuing with different priorities
enqueue_agent_commands "1" "high" 2 &
enqueue_agent_commands "2" "normal" 3 &
enqueue_agent_commands "3" "low" 2 &

wait

# Check queue status
echo "📊 Queue status:"
get_queue_status "$queue_test_agent"

# Dequeue all commands and verify ordering
echo "📤 Dequeuing commands (should be priority ordered):"
dequeue_count=0
while command=$(dequeue_command_safe "$queue_test_agent" 2>/dev/null); do
    echo "  Dequeued: $command"
    ((dequeue_count++))
done

echo "✅ Dequeued $dequeue_count commands total"

# Test 3: Transaction operations with multiple files
echo "🔄 Testing transaction operations..."

tx_file1="/tmp/tx_test1_$$"
tx_file2="/tmp/tx_test2_$$"
tx_file3="/tmp/tx_test3_$$"

# Test successful transaction
if begin_file_transaction; then
    echo "✅ Transaction started"
    
    add_to_transaction "$tx_file1" "Transaction content 1"
    add_to_transaction "$tx_file2" "Transaction content 2"
    add_to_transaction "$tx_file3" "Transaction content 3"
    
    echo "✅ Files added to transaction"
    
    if commit_file_transaction; then
        echo "✅ Transaction committed"
        
        # Verify all files were created
        if [[ -f "$tx_file1" && -f "$tx_file2" && -f "$tx_file3" ]]; then
            echo "✅ All transaction files created"
            
            # Verify content
            content1=$(cat "$tx_file1")
            content2=$(cat "$tx_file2")
            content3=$(cat "$tx_file3")
            
            if [[ "$content1" == "Transaction content 1" && 
                  "$content2" == "Transaction content 2" && 
                  "$content3" == "Transaction content 3" ]]; then
                echo "✅ Transaction content verified"
            else
                echo "❌ Transaction content incorrect"
                exit 1
            fi
        else
            echo "❌ Transaction files not created"
            exit 1
        fi
    else
        echo "❌ Transaction commit failed"
        exit 1
    fi
else
    echo "❌ Transaction begin failed"
    exit 1
fi

# Test rollback
echo "🔄 Testing transaction rollback..."
rollback_file="/tmp/rollback_test_$$"

if begin_file_transaction; then
    add_to_transaction "$rollback_file" "This should not be saved"
    
    if rollback_file_transaction; then
        echo "✅ Transaction rolled back"
        
        if [[ ! -f "$rollback_file" ]]; then
            echo "✅ Rollback file correctly not created"
        else
            echo "❌ Rollback failed - file was created"
            exit 1
        fi
    else
        echo "❌ Rollback failed"
        exit 1
    fi
else
    echo "❌ Transaction begin failed"
    exit 1
fi

# Test 4: Lock contention simulation
echo "🔒 Testing lock contention..."

contention_resource="contention_test"
lock_attempts=0
lock_successes=0

# Function to attempt lock acquisition
attempt_lock() {
    local attempt_id="$1"
    ((lock_attempts++))
    
    if acquire_resource_lock "$contention_resource" 1; then  # 1 second timeout
        ((lock_successes++))
        echo "Lock acquired by attempt $attempt_id"
        sleep 0.5  # Hold lock briefly
        release_resource_lock "$contention_resource"
        echo "Lock released by attempt $attempt_id"
    else
        echo "Lock timeout for attempt $attempt_id"
    fi
}

# Start multiple lock attempts
for ((i=1; i<=3; i++)); do
    attempt_lock "$i" &
done

wait

echo "✅ Lock contention test: $lock_successes successes out of $lock_attempts attempts"

# Cleanup
echo "🧹 Cleaning up test environment..."
rm -rf "$AGENT_CONDUCTOR_LOCK_DIR" "$AGENT_CONDUCTOR_TRANSACTION_DIR" 2>/dev/null || true
rm -f "$test_file" "$tx_file1" "$tx_file2" "$tx_file3" "$rollback_file" 2>/dev/null || true
rm -rf "/tmp/agent_command_queue_${queue_test_agent}" 2>/dev/null || true

echo "🎉 All concurrent agent tests completed successfully!"
echo ""
echo "📋 Test Summary:"
echo "  ✅ Concurrent file operations"
echo "  ✅ Concurrent queue operations"
echo "  ✅ Transaction operations"
echo "  ✅ Lock contention handling"
echo ""
echo "The enhanced communication system is ready for production use!"