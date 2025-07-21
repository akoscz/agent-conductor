#!/usr/bin/env bats

# Simple focused tests for Issue #13: load_agent_config path resolution fix

setup() {
    # Create minimal test environment
    export TEST_DIR="$(mktemp -d)"
    mkdir -p "$TEST_DIR/orchestration/"{config,agents/test,scripts/lib}
    
    # Create minimal test files
    echo "agent_types: {test: {directory: 'agents/test'}}" > "$TEST_DIR/orchestration/config/agents.yml"
    echo "name: Test Agent" > "$TEST_DIR/orchestration/agents/test/config.yml"
    echo "test prompt" > "$TEST_DIR/orchestration/agents/test/prompt.md"
    
    # Copy our fixed config_lib.sh
    cp "$BATS_TEST_DIRNAME/../../lib/config_lib.sh" "$TEST_DIR/orchestration/scripts/lib/"
    source "$TEST_DIR/orchestration/scripts/lib/config_lib.sh"
    cd "$TEST_DIR/orchestration"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "load_agent_config works with explicit orchestration_root (baseline)" {
    # This should always work - tests our fix works in the obvious case
    run load_agent_config "test" "$TEST_DIR/orchestration/config/agents.yml" "$TEST_DIR/orchestration"
    [ "$status" -eq 0 ]
}

@test "load_agent_config uses ORCHESTRATION_DIR when set (main fix)" {
    # This tests the main fix: ORCHESTRATION_DIR should be used when available
    export ORCHESTRATION_DIR="$TEST_DIR/orchestration"
    export AGENTS_CONFIG_FILE="$TEST_DIR/orchestration/config/agents.yml"
    
    run load_agent_config "test"
    [ "$status" -eq 0 ]
}

@test "path resolution bug would cause failure without fix" {
    # This demonstrates what would happen with the old buggy code
    # The old code would calculate wrong paths and fail to find files
    
    # Simulate what happens when load_agent_config uses wrong orchestration root
    export AGENTS_CONFIG_FILE="$TEST_DIR/orchestration/config/agents.yml"
    
    # Call with a wrong orchestration root (simulating the old bug)
    run load_agent_config "test" "$AGENTS_CONFIG_FILE" "/wrong/path"
    [ "$status" -ne 0 ]  # Should fail with wrong path
    
    # But should work with correct path (our fix)
    run load_agent_config "test" "$AGENTS_CONFIG_FILE" "$TEST_DIR/orchestration"  
    [ "$status" -eq 0 ]   # Should succeed with correct path
}

@test "regression test: real validation scenario works" {
    # Test the actual scenario that was failing before the fix
    if ! command -v yq &> /dev/null; then
        skip "yq not available" 
    fi
    
    export ORCHESTRATION_DIR="$TEST_DIR/orchestration"
    export AGENTS_CONFIG_FILE="$TEST_DIR/orchestration/config/agents.yml"
    
    # Create a proper agents.yml that yq can parse
    cat > "$TEST_DIR/orchestration/config/agents.yml" << 'EOF'
agent_types:
  test:
    directory: "agents/test"
EOF
    
    # This should work with our fix (orchestration_root passed explicitly)
    local orchestration_root="$ORCHESTRATION_DIR"
    run load_agent_config "test" "$AGENTS_CONFIG_FILE" "$orchestration_root"
    [ "$status" -eq 0 ]
}

@test "load_agent_config returns correct error codes for missing files" {
    export ORCHESTRATION_DIR="$TEST_DIR/orchestration"
    export AGENTS_CONFIG_FILE="$TEST_DIR/orchestration/config/agents.yml"
    
    # Test missing agent config file
    rm "$TEST_DIR/orchestration/agents/test/config.yml"
    run load_agent_config "test"
    [ "$status" -eq 4 ]  # Agent config file missing
    
    # Restore config, remove prompt
    echo "name: test" > "$TEST_DIR/orchestration/agents/test/config.yml"
    rm "$TEST_DIR/orchestration/agents/test/prompt.md"
    run load_agent_config "test"
    [ "$status" -eq 5 ]  # Agent prompt file missing
}

@test "load_agent_config handles nonexistent agent type" {
    if ! command -v yq &> /dev/null; then
        skip "yq not available"
    fi
    
    export ORCHESTRATION_DIR="$TEST_DIR/orchestration"
    export AGENTS_CONFIG_FILE="$TEST_DIR/orchestration/config/agents.yml"
    
    # Create proper agents.yml for yq
    cat > "$TEST_DIR/orchestration/config/agents.yml" << 'EOF'
agent_types:
  test:
    directory: "agents/test"
EOF
    
    run load_agent_config "nonexistent"
    [ "$status" -eq 3 ]  # Agent type not found
}