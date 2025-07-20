#!/bin/bash

# Common test setup functions for Agent Conductor tests
# This script provides utilities for setting up test environments

# Setup test configuration environment
setup_test_config() {
    local test_root="${1:-$(pwd)}"
    
    # Use test-config directory for tests
    export PROJECT_CONFIG_FILE="$test_root/test-config/project.yml"
    export AGENTS_CONFIG_FILE="$test_root/test-config/agents.yml"
    
    # Ensure test config files exist
    if [[ ! -f "$PROJECT_CONFIG_FILE" ]]; then
        echo "ERROR: Test project config not found at $PROJECT_CONFIG_FILE" >&2
        return 1
    fi
    
    if [[ ! -f "$AGENTS_CONFIG_FILE" ]]; then
        echo "ERROR: Test agents config not found at $AGENTS_CONFIG_FILE" >&2
        return 1
    fi
    
    return 0
}

# Setup test environment with temporary directories
setup_test_environment() {
    local test_name="$1"
    local base_dir="${2:-/tmp}"
    
    # Create unique test environment
    export TEST_ENV_ID="test_${test_name}_$$_$(date +%s)"
    export TEST_WORKSPACE="$base_dir/$TEST_ENV_ID"
    export TEST_ORCHESTRATION_ROOT="$TEST_WORKSPACE/orchestration"
    
    # Create test directories
    mkdir -p "$TEST_WORKSPACE"
    mkdir -p "$TEST_ORCHESTRATION_ROOT"
    
    # Setup test configs (need to get orchestration root, not scripts/tests root)
    setup_test_config "$(dirname "$(dirname "$(dirname "$BASH_SOURCE")")")"
    
    return 0
}

# Cleanup test environment
cleanup_test_environment() {
    if [[ -n "$TEST_WORKSPACE" && -d "$TEST_WORKSPACE" ]]; then
        rm -rf "$TEST_WORKSPACE"
    fi
    
    # Cleanup any test-specific temporary files
    rm -rf "/tmp/agent_command_queue_test*" 2>/dev/null || true
    rm -rf "/tmp/test-agent-conductor-*" 2>/dev/null || true
}

# Get orchestration root for tests
get_test_orchestration_root() {
    echo "$(dirname "$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")")"
}

# Setup minimal config for unit tests
setup_unit_test_config() {
    local orchestration_root
    orchestration_root=$(get_test_orchestration_root)
    
    export PROJECT_CONFIG_FILE="$orchestration_root/test-config/project.yml"
    export AGENTS_CONFIG_FILE="$orchestration_root/test-config/agents.yml"
    export ORCHESTRATION_ROOT="$orchestration_root"
}

# Setup integration test environment with full orchestration copy
setup_integration_test_environment() {
    local test_name="$1"
    local base_dir="${2:-/tmp}"
    
    # Create unique test environment (bypassing setup_test_environment to avoid config path issues)
    export TEST_ENV_ID="test_${test_name}_$$_$(date +%s)"
    export TEST_WORKSPACE="$base_dir/$TEST_ENV_ID"
    export TEST_ORCHESTRATION_ROOT="$TEST_WORKSPACE/orchestration"
    
    # Create test directories
    mkdir -p "$TEST_WORKSPACE"
    mkdir -p "$TEST_ORCHESTRATION_ROOT"
    
    # Copy full orchestration structure to test workspace
    local source_orch
    source_orch=$(get_test_orchestration_root)
    
    cp -r "$source_orch"/* "$TEST_ORCHESTRATION_ROOT/"
    
    # Use the copied test configs
    export PROJECT_CONFIG_FILE="$TEST_ORCHESTRATION_ROOT/test-config/project.yml"
    export AGENTS_CONFIG_FILE="$TEST_ORCHESTRATION_ROOT/test-config/agents.yml"
    
    return 0
}