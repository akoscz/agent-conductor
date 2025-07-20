#!/bin/bash

# Simple test script for enhanced communication library

set -e

echo "Testing enhanced communication library..."

# Load the library
source "./scripts/lib/enhanced_communication_lib.sh"

# Set test environment
export AGENT_CONDUCTOR_LOCK_DIR="/tmp/test-lock-$$"
export AGENT_CONDUCTOR_TRANSACTION_DIR="/tmp/test-tx-$$"

echo "Initializing enhanced communication..."
if init_enhanced_communication; then
    echo "✅ Init successful"
else
    echo "❌ Init failed"
    exit 1
fi

echo "Testing basic locking..."
if acquire_resource_lock "test_resource" 5; then
    echo "✅ Lock acquired"
    if release_resource_lock "test_resource"; then
        echo "✅ Lock released"
    else
        echo "❌ Lock release failed"
        exit 1
    fi
else
    echo "❌ Lock acquisition failed"
    exit 1
fi

echo "Testing safe file operations..."
test_file="/tmp/test_safe_file_$$"
if safe_write_file "$test_file" "test content"; then
    echo "✅ Safe write successful"
    content=$(safe_read_file "$test_file")
    if [[ "$content" == "test content" ]]; then
        echo "✅ Safe read successful"
    else
        echo "❌ Safe read failed - got: '$content'"
        exit 1
    fi
else
    echo "❌ Safe write failed"
    exit 1
fi

echo "Testing queue operations..."
if init_agent_queue "test_agent"; then
    echo "✅ Queue init successful"
    if enqueue_command_safe "test_agent" "test command" "normal"; then
        echo "✅ Enqueue successful"
        command=$(dequeue_command_safe "test_agent")
        if [[ "$command" == "test command" ]]; then
            echo "✅ Dequeue successful"
        else
            echo "❌ Dequeue failed - got: '$command'"
            exit 1
        fi
    else
        echo "❌ Enqueue failed"
        exit 1
    fi
else
    echo "❌ Queue init failed"
    exit 1
fi

echo "Testing transactions..."
test_file1="/tmp/test_tx1_$$"
test_file2="/tmp/test_tx2_$$"

if begin_file_transaction; then
    echo "✅ Transaction begin successful"
    if add_to_transaction "$test_file1" "content1" && add_to_transaction "$test_file2" "content2"; then
        echo "✅ Add to transaction successful"
        if commit_file_transaction; then
            echo "✅ Transaction commit successful"
            if [[ -f "$test_file1" && -f "$test_file2" ]]; then
                content1=$(cat "$test_file1")
                content2=$(cat "$test_file2")
                if [[ "$content1" == "content1" && "$content2" == "content2" ]]; then
                    echo "✅ Transaction files created correctly"
                else
                    echo "❌ Transaction files have wrong content"
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
        echo "❌ Add to transaction failed"
        exit 1
    fi
else
    echo "❌ Transaction begin failed"
    exit 1
fi

# Cleanup
rm -rf "/tmp/test-lock-$$" "/tmp/test-tx-$$" 2>/dev/null || true
rm -f "$test_file"* "$test_file1" "$test_file2" 2>/dev/null || true
rm -rf "/tmp/agent_command_queue_test_agent" 2>/dev/null || true

echo "🎉 All tests passed!"