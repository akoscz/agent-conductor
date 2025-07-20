#!/bin/bash

# Enhanced Communication Library - Race-condition-safe file-based communication
# Provides file locking, transactions, and enhanced queue management for Agent Conductor
# Compatible with bash 3.2 and macOS

# Dependency injection for external commands (allows mocking in tests)
MKDIR_CMD="${MKDIR_CMD:-mkdir}"
RMDIR_CMD="${RMDIR_CMD:-rmdir}"
DATE_CMD="${DATE_CMD:-date}"
STAT_CMD="${STAT_CMD:-stat}"
MKTEMP_CMD="${MKTEMP_CMD:-mktemp}"
FIND_CMD="${FIND_CMD:-find}"
RM_CMD="${RM_CMD:-rm}"
MV_CMD="${MV_CMD:-mv}"
CP_CMD="${CP_CMD:-cp}"
WC_CMD="${WC_CMD:-wc}"
TAIL_CMD="${TAIL_CMD:-tail}"
HEAD_CMD="${HEAD_CMD:-head}"
SORT_CMD="${SORT_CMD:-sort}"
CAT_CMD="${CAT_CMD:-cat}"
ECHO_CMD="${ECHO_CMD:-echo}"
SLEEP_CMD="${SLEEP_CMD:-sleep}"

# Configuration
LOCK_DIR="${AGENT_CONDUCTOR_LOCK_DIR:-/tmp/agent-conductor-locks}"
TRANSACTION_DIR="${AGENT_CONDUCTOR_TRANSACTION_DIR:-/tmp/agent-conductor-transactions}"
DEFAULT_LOCK_TIMEOUT="${DEFAULT_LOCK_TIMEOUT:-30}"
DEFAULT_LOCK_RETRY_DELAY="${DEFAULT_LOCK_RETRY_DELAY:-0.1}"

# Error codes for enhanced communication
EC_LOCK_TIMEOUT=20
EC_LOCK_EXISTS=21
EC_TRANSACTION_FAILED=22
EC_CONFLICT_DETECTED=23
EC_SEQUENCE_ERROR=24

# Initialize communication system
init_enhanced_communication() {
    local lock_dir="$LOCK_DIR"
    local tx_dir="$TRANSACTION_DIR"
    
    # Create directories if they don't exist
    if ! $MKDIR_CMD -p "$lock_dir" 2>/dev/null; then
        return 1
    fi
    if ! $MKDIR_CMD -p "$tx_dir" 2>/dev/null; then
        return 1
    fi
    
    # Cleanup stale locks (older than 1 hour)
    cleanup_stale_locks
    
    return 0
}

# Cleanup stale locks based on age
cleanup_stale_locks() {
    local lock_dir="$LOCK_DIR"
    local current_time
    current_time=$($DATE_CMD +%s)
    local cutoff_time=$((current_time - 3600))  # 1 hour ago
    
    if [[ -d "$lock_dir" ]]; then
        $FIND_CMD "$lock_dir" -name "*.lock.d" -type d 2>/dev/null | while read -r lock_path; do
            if [[ -f "$lock_path/info" ]]; then
                local lock_time
                lock_time=$(cut -d: -f2 "$lock_path/info" 2>/dev/null || echo "0")
                if [[ $lock_time -lt $cutoff_time ]]; then
                    $RM_CMD -rf "$lock_path" 2>/dev/null || true
                fi
            fi
        done
    fi
}

# Atomic directory-based locking (compatible with NFS)
acquire_resource_lock() {
    local resource_name="$1"
    local timeout="${2:-$DEFAULT_LOCK_TIMEOUT}"
    local retry_delay="${3:-$DEFAULT_LOCK_RETRY_DELAY}"
    
    if [[ -z "$resource_name" ]]; then
        return 1
    fi
    
    local lock_dir="$LOCK_DIR"
    local lock_path="$lock_dir/${resource_name}.lock.d"
    local start_time
    start_time=$($DATE_CMD +%s)
    local current_time
    
    # Ensure lock directory exists
    $MKDIR_CMD -p "$lock_dir" 2>/dev/null || true
    
    while true; do
        # Attempt atomic lock creation
        if $MKDIR_CMD "$lock_path" 2>/dev/null; then
            # Successfully acquired lock - store info
            local pid=$$
            local timestamp
            timestamp=$($DATE_CMD +%s)
            $ECHO_CMD "$pid:$timestamp" > "$lock_path/info" 2>/dev/null || true
            return 0
        fi
        
        # Check timeout
        current_time=$($DATE_CMD +%s)
        if [[ $((current_time - start_time)) -ge $timeout ]]; then
            return $EC_LOCK_TIMEOUT
        fi
        
        # Check if lock is stale and remove it
        if [[ -f "$lock_path/info" ]]; then
            local lock_info
            lock_info=$($CAT_CMD "$lock_path/info" 2>/dev/null || echo "")
            if [[ -n "$lock_info" ]]; then
                local lock_pid
                local lock_time
                lock_pid=$(echo "$lock_info" | cut -d: -f1)
                lock_time=$(echo "$lock_info" | cut -d: -f2)
                
                # Check if process is still running and lock is recent
                if ! kill -0 "$lock_pid" 2>/dev/null || [[ $((current_time - lock_time)) -gt 300 ]]; then
                    # Process dead or lock too old - remove stale lock
                    $RM_CMD -rf "$lock_path" 2>/dev/null || true
                    continue  # Try again immediately
                fi
            fi
        fi
        
        $SLEEP_CMD "$retry_delay"
    done
}

# Release resource lock
release_resource_lock() {
    local resource_name="$1"
    
    if [[ -z "$resource_name" ]]; then
        return 1
    fi
    
    local lock_dir="$LOCK_DIR"
    local lock_path="$lock_dir/${resource_name}.lock.d"
    
    # Verify we own this lock
    if [[ -f "$lock_path/info" ]]; then
        local lock_info
        lock_info=$($CAT_CMD "$lock_path/info" 2>/dev/null || echo "")
        local lock_pid
        lock_pid=$(echo "$lock_info" | cut -d: -f1 2>/dev/null || echo "")
        
        if [[ "$lock_pid" != "$$" ]]; then
            return $EC_LOCK_EXISTS  # Not our lock
        fi
    fi
    
    $RM_CMD -rf "$lock_path" 2>/dev/null || true
    return 0
}

# Safe file read with locking
safe_read_file() {
    local file_path="$1"
    local lock_timeout="${2:-10}"
    local resource_name
    
    if [[ -z "$file_path" ]]; then
        return 1
    fi
    
    resource_name=$(basename "$file_path")
    
    if acquire_resource_lock "read_$resource_name" "$lock_timeout"; then
        local content=""
        if [[ -f "$file_path" ]]; then
            content=$($CAT_CMD "$file_path" 2>/dev/null || echo "")
        fi
        release_resource_lock "read_$resource_name"
        $ECHO_CMD "$content"
        return 0
    else
        return $EC_LOCK_TIMEOUT
    fi
}

# Safe file write with conflict detection
safe_write_file() {
    local file_path="$1"
    local content="$2"
    local check_conflicts="${3:-true}"
    local lock_timeout="${4:-15}"
    local resource_name
    
    if [[ -z "$file_path" ]]; then
        return 1
    fi
    
    resource_name=$(basename "$file_path")
    
    if acquire_resource_lock "write_$resource_name" "$lock_timeout"; then
        local original_mtime=0
        local current_mtime=0
        
        # Conflict detection via modification time
        if [[ "$check_conflicts" == "true" && -f "$file_path" ]]; then
            original_mtime=$($STAT_CMD -f %m "$file_path" 2>/dev/null || echo "0")
        fi
        
        # Create backup before writing
        local backup_file="${file_path}.backup.$($DATE_CMD +%Y%m%d_%H%M%S).$$"
        if [[ -f "$file_path" ]]; then
            $CP_CMD "$file_path" "$backup_file" 2>/dev/null || true
        fi
        
        # Atomic write using temp file
        local temp_file
        temp_file=$($MKTEMP_CMD) || {
            release_resource_lock "write_$resource_name"
            return 1
        }
        
        $ECHO_CMD "$content" > "$temp_file"
        
        # Check for conflicts again before final write
        if [[ "$check_conflicts" == "true" && -f "$file_path" ]]; then
            current_mtime=$($STAT_CMD -f %m "$file_path" 2>/dev/null || echo "0")
            if [[ $current_mtime -gt $original_mtime ]]; then
                $RM_CMD -f "$temp_file" 2>/dev/null || true
                release_resource_lock "write_$resource_name"
                return $EC_CONFLICT_DETECTED
            fi
        fi
        
        # Perform atomic move
        $MV_CMD "$temp_file" "$file_path"
        local write_result=$?
        
        release_resource_lock "write_$resource_name"
        
        # Cleanup old backups (keep last 5)
        cleanup_old_backups "$file_path" 5
        
        return $write_result
    else
        return $EC_LOCK_TIMEOUT
    fi
}

# Cleanup old backup files
cleanup_old_backups() {
    local file_path="$1"
    local keep_count="${2:-5}"
    local file_dir
    local file_name
    
    file_dir=$(dirname "$file_path")
    file_name=$(basename "$file_path")
    
    $FIND_CMD "$file_dir" -name "${file_name}.backup.*" -type f 2>/dev/null | \
        $SORT_CMD -r | $TAIL_CMD -n +$((keep_count + 1)) | \
        while read -r backup_file; do
            $RM_CMD -f "$backup_file" 2>/dev/null || true
        done
}

# Transaction support for multi-file operations
begin_file_transaction() {
    local timestamp=$($DATE_CMD +%s)
    local random_suffix=$(($RANDOM * $RANDOM))
    local transaction_id="tx_$$_${timestamp}_${random_suffix}"
    local tx_dir="$TRANSACTION_DIR/$transaction_id"
    
    if ! $MKDIR_CMD -p "$tx_dir" 2>/dev/null; then
        return 1
    fi
    
    # Store transaction ID for this shell
    $ECHO_CMD "$transaction_id" > "/tmp/agent-conductor-tx-$$"
    $ECHO_CMD "Transaction $transaction_id started" >&2
    return 0
}

# Add file operation to current transaction
add_to_transaction() {
    local file_path="$1"
    local new_content="$2"
    local tx_id
    
    if [[ ! -f "/tmp/agent-conductor-tx-$$" ]]; then
        return $EC_TRANSACTION_FAILED
    fi
    
    tx_id=$($CAT_CMD "/tmp/agent-conductor-tx-$$" 2>/dev/null)
    local tx_dir="$TRANSACTION_DIR/$tx_id"
    
    if [[ ! -d "$tx_dir" ]]; then
        return $EC_TRANSACTION_FAILED
    fi
    
    # Store the operation
    local timestamp=$($DATE_CMD +%s)
    local random_suffix=$(($RANDOM * $RANDOM))
    local op_file="$tx_dir/op_${timestamp}_${random_suffix}"
    $ECHO_CMD "WRITE|$file_path" > "$op_file"
    $ECHO_CMD "$new_content" > "${op_file}.content"
    
    return 0
}

# Commit all transaction operations atomically
commit_file_transaction() {
    local tx_id
    
    if [[ ! -f "/tmp/agent-conductor-tx-$$" ]]; then
        return $EC_TRANSACTION_FAILED
    fi
    
    tx_id=$($CAT_CMD "/tmp/agent-conductor-tx-$$" 2>/dev/null)
    local tx_dir="$TRANSACTION_DIR/$tx_id"
    
    if [[ ! -d "$tx_dir" ]]; then
        return $EC_TRANSACTION_FAILED
    fi
    
    # Acquire locks for all files first
    local lock_resources=()
    local failed_locks=0
    
    $FIND_CMD "$tx_dir" -name "op_*" -not -name "*.content" -type f 2>/dev/null | while read -r op_file; do
        local operation
        operation=$($CAT_CMD "$op_file" 2>/dev/null)
        local file_path
        file_path=$(echo "$operation" | cut -d'|' -f2)
        local resource_name
        resource_name=$(basename "$file_path")
        
        if ! acquire_resource_lock "tx_write_$resource_name" 30; then
            failed_locks=1
            break
        fi
        lock_resources+=("tx_write_$resource_name")
    done
    
    if [[ $failed_locks -eq 1 ]]; then
        # Release any acquired locks
        for resource in "${lock_resources[@]}"; do
            release_resource_lock "$resource"
        done
        return $EC_LOCK_TIMEOUT
    fi
    
    # Execute all operations
    local commit_failed=0
    $FIND_CMD "$tx_dir" -name "op_*" -not -name "*.content" -type f 2>/dev/null | $SORT_CMD | while read -r op_file; do
        local operation
        operation=$($CAT_CMD "$op_file" 2>/dev/null)
        local op_type
        local file_path
        op_type=$(echo "$operation" | cut -d'|' -f1)
        file_path=$(echo "$operation" | cut -d'|' -f2)
        
        if [[ "$op_type" == "WRITE" ]]; then
            local content
            content=$($CAT_CMD "${op_file}.content" 2>/dev/null || echo "")
            local temp_file
            temp_file=$($MKTEMP_CMD) || {
                commit_failed=1
                break
            }
            
            $ECHO_CMD "$content" > "$temp_file"
            if ! $MV_CMD "$temp_file" "$file_path"; then
                commit_failed=1
                break
            fi
        fi
    done
    
    # Release all locks
    for resource in "${lock_resources[@]}"; do
        release_resource_lock "$resource"
    done
    
    # Cleanup transaction
    $RM_CMD -rf "$tx_dir" 2>/dev/null || true
    $RM_CMD -f "/tmp/agent-conductor-tx-$$" 2>/dev/null || true
    
    if [[ $commit_failed -eq 1 ]]; then
        return $EC_TRANSACTION_FAILED
    fi
    
    return 0
}

# Rollback current transaction
rollback_file_transaction() {
    local tx_id
    
    if [[ ! -f "/tmp/agent-conductor-tx-$$" ]]; then
        return 0  # No active transaction
    fi
    
    tx_id=$($CAT_CMD "/tmp/agent-conductor-tx-$$" 2>/dev/null)
    local tx_dir="$TRANSACTION_DIR/$tx_id"
    
    # Simply remove transaction directory
    $RM_CMD -rf "$tx_dir" 2>/dev/null || true
    $RM_CMD -f "/tmp/agent-conductor-tx-$$" 2>/dev/null || true
    
    return 0
}

# Enhanced queue management with sequence numbers
init_agent_queue() {
    local agent_type="$1"
    local queue_dir="/tmp/agent_command_queue_${agent_type}"
    
    if [[ -z "$agent_type" ]]; then
        return 1
    fi
    
    if ! $MKDIR_CMD -p "$queue_dir" 2>/dev/null; then
        return 1
    fi
    
    # Initialize sequence file if it doesn't exist
    local seq_file="$queue_dir/.sequence"
    if [[ ! -f "$seq_file" ]]; then
        if ! $ECHO_CMD "0" > "$seq_file"; then
            return 1
        fi
    fi
    
    return 0
}

# Enqueue command with sequence number and priority
enqueue_command_safe() {
    local agent_type="$1"
    local command="$2"
    local priority="${3:-normal}"
    local queue_dir="/tmp/agent_command_queue_${agent_type}"
    
    if [[ -z "$agent_type" || -z "$command" ]]; then
        return 1
    fi
    
    # Initialize queue if needed
    init_agent_queue "$agent_type"
    
    local seq_file="$queue_dir/.sequence"
    local sequence
    
    # Get next sequence number atomically
    if acquire_resource_lock "queue_${agent_type}_seq" 10; then
        sequence=$($CAT_CMD "$seq_file" 2>/dev/null || echo "0")
        sequence=$((sequence + 1))
        $ECHO_CMD "$sequence" > "$seq_file"
        release_resource_lock "queue_${agent_type}_seq"
    else
        return $EC_LOCK_TIMEOUT
    fi
    
    # Create command file with sequence and priority
    local priority_num
    case "$priority" in
        "high") priority_num="1" ;;
        "normal") priority_num="2" ;;
        "low") priority_num="3" ;;
        *) priority_num="2" ;;
    esac
    
    local cmd_file="$queue_dir/cmd_${priority_num}_$(printf "%010d" "$sequence")"
    local timestamp
    timestamp=$($DATE_CMD '+%Y-%m-%d %H:%M:%S')
    
    # Write command file atomically
    local temp_file
    temp_file=$($MKTEMP_CMD) || return 1
    
    $CAT_CMD > "$temp_file" << EOF
TIMESTAMP=$timestamp
SEQUENCE=$sequence
PRIORITY=$priority
COMMAND=$command
STATUS=pending
EOF
    
    $MV_CMD "$temp_file" "$cmd_file"
    return $?
}

# Dequeue next command safely
dequeue_command_safe() {
    local agent_type="$1"
    local queue_dir="/tmp/agent_command_queue_${agent_type}"
    
    if [[ -z "$agent_type" ]]; then
        return 1
    fi
    
    if ! acquire_resource_lock "queue_${agent_type}" 15; then
        return $EC_LOCK_TIMEOUT
    fi
    
    # Find highest priority, lowest sequence command
    local cmd_file
    cmd_file=$($FIND_CMD "$queue_dir" -name "cmd_*" -type f 2>/dev/null | $SORT_CMD | $HEAD_CMD -n1)
    
    if [[ -n "$cmd_file" && -f "$cmd_file" ]]; then
        local command
        command=$($CAT_CMD "$cmd_file" | grep "^COMMAND=" | cut -d= -f2- 2>/dev/null || echo "")
        $RM_CMD -f "$cmd_file" 2>/dev/null || true
        release_resource_lock "queue_${agent_type}"
        
        if [[ -n "$command" ]]; then
            $ECHO_CMD "$command"
            return 0
        fi
    fi
    
    release_resource_lock "queue_${agent_type}"
    return 1  # No commands available
}

# Get queue status
get_queue_status() {
    local agent_type="$1"
    local queue_dir="/tmp/agent_command_queue_${agent_type}"
    
    if [[ -z "$agent_type" || ! -d "$queue_dir" ]]; then
        return 1
    fi
    
    local total_commands
    local high_priority
    local normal_priority
    local low_priority
    
    total_commands=$($FIND_CMD "$queue_dir" -name "cmd_*" -type f 2>/dev/null | $WC_CMD -l)
    high_priority=$($FIND_CMD "$queue_dir" -name "cmd_1_*" -type f 2>/dev/null | $WC_CMD -l)
    normal_priority=$($FIND_CMD "$queue_dir" -name "cmd_2_*" -type f 2>/dev/null | $WC_CMD -l)
    low_priority=$($FIND_CMD "$queue_dir" -name "cmd_3_*" -type f 2>/dev/null | $WC_CMD -l)
    
    $ECHO_CMD "Queue: $agent_type, Total: $total_commands, High: $high_priority, Normal: $normal_priority, Low: $low_priority"
    return 0
}

# Initialize enhanced communication system on load
init_enhanced_communication