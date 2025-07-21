#!/usr/bin/env bats

# Test path resolution fixes for load_agent_config function
# Tests for Issue #13: Fix load_agent_config path resolution bug

setup() {
    # Create temporary test environment
    export TEST_DIR="$(mktemp -d)"
    export ORIGINAL_PWD="$(pwd)"
    
    # Set up test orchestration structure
    mkdir -p "$TEST_DIR/orchestration/"{config,agents/backend,scripts/lib}
    
    # Create test config files
    cat > "$TEST_DIR/orchestration/config/agents.yml" << 'EOF'
agent_types:
  backend:
    directory: "agents/backend"
  frontend:
    directory: "agents/frontend"
EOF

    cat > "$TEST_DIR/orchestration/config/project.yml" << 'EOF'
project:
  name: "Test Project"
  workspace_dir: "$TEST_DIR"
directories:
  agents: "agents"
EOF

    # Create backend agent files
    cat > "$TEST_DIR/orchestration/agents/backend/config.yml" << 'EOF'
name: "Backend Agent"
description: "Test backend agent"
session_name: "backend-test"
prompt_file: "prompt.md"
technologies: ["Node.js"]
capabilities: ["backend"]
validation_profile: "backend"
EOF

    echo "# Backend agent prompt" > "$TEST_DIR/orchestration/agents/backend/prompt.md"
    
    # Copy config_lib.sh to test environment (with our fixes)
    cp "$BATS_TEST_DIRNAME/../../lib/config_lib.sh" "$TEST_DIR/orchestration/scripts/lib/"
    
    # Source the library
    source "$TEST_DIR/orchestration/scripts/lib/config_lib.sh"
    
    # Change to orchestration directory
    cd "$TEST_DIR/orchestration"
}

teardown() {
    cd "$ORIGINAL_PWD"
    rm -rf "$TEST_DIR"
}

@test "load_agent_config works with explicit orchestration_root parameter" {
    # This should work regardless of the bug fix
    run load_agent_config "backend" "$TEST_DIR/orchestration/config/agents.yml" "$TEST_DIR/orchestration"
    [ "$status" -eq 0 ]
}

@test "load_agent_config works when ORCHESTRATION_DIR is set (fix part 1)" {
    # Test that the fixed default parameter logic works
    export ORCHESTRATION_DIR="$TEST_DIR/orchestration"
    export AGENTS_CONFIG_FILE="$TEST_DIR/orchestration/config/agents.yml"
    
    # Call without explicit orchestration_root - should use ORCHESTRATION_DIR
    run load_agent_config "backend"
    [ "$status" -eq 0 ]
}

@test "load_agent_config works from current directory when ORCHESTRATION_DIR unset (fix part 2)" {
    # Test fallback to $(pwd) when ORCHESTRATION_DIR is not set
    unset ORCHESTRATION_DIR
    export AGENTS_CONFIG_FILE="$TEST_DIR/orchestration/config/agents.yml"
    
    # Should use $(pwd) which is $TEST_DIR/orchestration
    run load_agent_config "backend"
    [ "$status" -eq 0 ]
}

@test "validate_configuration passes orchestration_root explicitly" {
    # Set up environment as load_full_configuration would
    export ORCHESTRATION_DIR="$TEST_DIR/orchestration"
    export PROJECT_CONFIG_FILE="$TEST_DIR/orchestration/config/project.yml"
    export AGENTS_CONFIG_FILE="$TEST_DIR/orchestration/config/agents.yml"
    export WORKSPACE_DIR="$TEST_DIR"
    
    # Mock yq command for this test
    export YQ_CMD="echo"
    
    # This should now work without the path resolution bug
    run validate_configuration
    [ "$status" -eq 0 ]
}

@test "load_agent_config returns correct error codes for missing files" {
    export ORCHESTRATION_DIR="$TEST_DIR/orchestration"
    export AGENTS_CONFIG_FILE="$TEST_DIR/orchestration/config/agents.yml"
    
    # Test missing agent config file
    rm "$TEST_DIR/orchestration/agents/backend/config.yml"
    run load_agent_config "backend"
    [ "$status" -eq 4 ]  # Agent config file missing
    
    # Restore config, remove prompt
    echo "name: test" > "$TEST_DIR/orchestration/agents/backend/config.yml"
    rm "$TEST_DIR/orchestration/agents/backend/prompt.md"
    run load_agent_config "backend"
    [ "$status" -eq 5 ]  # Agent prompt file missing
}

@test "load_agent_config handles nonexistent agent type" {
    export ORCHESTRATION_DIR="$TEST_DIR/orchestration"
    export AGENTS_CONFIG_FILE="$TEST_DIR/orchestration/config/agents.yml"
    
    run load_agent_config "nonexistent"
    [ "$status" -eq 3 ]  # Agent type not found
}

@test "integration test: validation works end-to-end with fix" {
    # Set up complete environment
    export ORCHESTRATION_DIR="$TEST_DIR/orchestration"
    export PROJECT_CONFIG_FILE="$TEST_DIR/orchestration/config/project.yml"
    export AGENTS_CONFIG_FILE="$TEST_DIR/orchestration/config/agents.yml"
    export WORKSPACE_DIR="$TEST_DIR"
    
    # Create frontend agent to match agents.yml
    mkdir -p "$TEST_DIR/orchestration/agents/frontend"
    cat > "$TEST_DIR/orchestration/agents/frontend/config.yml" << 'EOF'
name: "Frontend Agent"
description: "Test frontend agent"
session_name: "frontend-test"
prompt_file: "prompt.md"
technologies: ["React"]
capabilities: ["frontend"]
validation_profile: "frontend"
EOF
    echo "# Frontend prompt" > "$TEST_DIR/orchestration/agents/frontend/prompt.md"
    
    # This should now pass validation
    run validate_configuration
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "Invalid agent configurations" ]]
}

@test "regression test: validation fails correctly for actually missing files" {
    # Set up environment
    export ORCHESTRATION_DIR="$TEST_DIR/orchestration"
    export PROJECT_CONFIG_FILE="$TEST_DIR/orchestration/config/project.yml"
    export AGENTS_CONFIG_FILE="$TEST_DIR/orchestration/config/agents.yml"
    export WORKSPACE_DIR="$TEST_DIR"
    
    # Remove backend config to trigger actual failure
    rm "$TEST_DIR/orchestration/agents/backend/config.yml"
    
    run validate_configuration
    [ "$status" -eq 6 ]
    [[ "$output" =~ "Invalid agent configurations: backend" ]]
}