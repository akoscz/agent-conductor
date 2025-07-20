#!/usr/bin/env bats

# Integration tests for full deployment workflow

setup() {
    # Load all required libraries
    source "$BATS_TEST_DIRNAME/../../lib/config_lib.sh"
    source "$BATS_TEST_DIRNAME/../../lib/session_lib.sh"
    source "$BATS_TEST_DIRNAME/../../lib/agent_lib.sh"
    source "$BATS_TEST_DIRNAME/../../lib/monitoring_lib.sh"
    source "$BATS_TEST_DIRNAME/../../lib/communication_lib.sh"
    
    # Set up test environment
    export ORCHESTRATION_ROOT="/tmp/test_orchestration_$$"
    export TEST_WORKSPACE="$ORCHESTRATION_ROOT/workspace"
    export PROJECT_CONFIG_FILE="$ORCHESTRATION_ROOT/config/project.yml"
    export AGENTS_CONFIG_FILE="$ORCHESTRATION_ROOT/config/agents.yml"
    
    # Create test directory structure
    mkdir -p "$ORCHESTRATION_ROOT/config"
    mkdir -p "$ORCHESTRATION_ROOT/memory"
    mkdir -p "$ORCHESTRATION_ROOT/logs"
    mkdir -p "$ORCHESTRATION_ROOT/prompts"
    mkdir -p "$TEST_WORKSPACE"
    
    # Create minimal test config files
    cat > "$PROJECT_CONFIG_FILE" << EOF
project:
  name: "TestProject"
  workspace_dir: "$TEST_WORKSPACE"
  github:
    owner: "testorg"
    repo: "testrepo"
directories:
  memory: "memory"
  logs: "logs"
  prompts: "prompts"
memory_files:
  task_assignments: "task_assignments.md"
  project_state: "project_state.md"
  blockers: "blockers.md"
  decisions: "decisions.md"
logging:
  orchestrator_log: "orchestrator.log"
  agent_logs_dir: "agents"
tmux:
  session_prefix: "test"
  default_shell: "/bin/bash"
  window_name: "agent"
EOF

    cat > "$AGENTS_CONFIG_FILE" << EOF
agent_types:
  rust:
    name: "Rust Agent"
    description: "Rust development agent"
    session_name: "rust-agent"
    prompt_file: "rust_agent.md"
    technologies: ["Rust", "Cargo"]
    capabilities: ["coding", "testing"]
    validation_profile: "rust"
validation_profiles:
  rust:
    - "cargo check"
    - "cargo test"
EOF

    # Set up mocks for external commands
    export TMUX_CMD="echo tmux"
    export YQ_CMD="mock_yq"
    export DATE_CMD="echo 2024-01-15_10:30:00"
    
    # Create mock yq function
    mock_yq() {
        case "$1" in
            ".project.name") echo "TestProject" ;;
            ".project.workspace_dir") echo "$TEST_WORKSPACE" ;;
            ".project.github.owner") echo "testorg" ;;
            ".project.github.repo") echo "testrepo" ;;
            ".agent_types | keys | .[]") echo "rust" ;;
            ".agent_types.rust.name") echo "Rust Agent" ;;
            ".agent_types.rust.session_name") echo "rust-agent" ;;
            ".agent_types.rust.prompt_file") echo "rust_agent.md" ;;
            ".agent_types | has(\"rust\")") echo "true" ;;
            *) echo "null" ;;
        esac
    }
    export -f mock_yq
}

teardown() {
    # Clean up test environment
    rm -rf "$ORCHESTRATION_ROOT" 2>/dev/null
}

@test "full deployment workflow - load configuration and deploy agent" {
    # Step 1: Load full configuration
    run load_full_configuration "$ORCHESTRATION_ROOT/lib"
    [ "$status" -eq 0 ]
    
    # Verify environment variables are set
    [[ "$PROJECT_NAME" == "TestProject" ]]
    [[ "$WORKSPACE_DIR" == "$TEST_WORKSPACE" ]]
    [[ "$GITHUB_OWNER" == "testorg" ]]
    [[ "$GITHUB_REPO" == "testrepo" ]]
}

@test "full deployment workflow - validate agent configuration" {
    # Load configuration first
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Step 2: Validate agent exists
    run agent_type_exists "rust"
    [ "$status" -eq 0 ]
    
    # Step 3: Load agent configuration
    run load_agent_config "rust"
    [ "$status" -eq 0 ]
    
    # Verify agent variables are set
    [[ "$AGENT_NAME" == "Rust Agent" ]]
    [[ "$AGENT_SESSION_NAME" == "rust-agent" ]]
}

@test "full deployment workflow - session management integration" {
    # Load configuration
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    load_agent_config "rust"
    
    # Step 4: Check if session exists (should not initially)
    run session_exists "$AGENT_SESSION_NAME"
    # Note: This will call tmux which is mocked, so it should succeed
    [ "$status" -eq 0 ]
    
    # Step 5: Create agent session
    run create_agent_session "$AGENT_SESSION_NAME" "$WORKSPACE_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux new-session -d -s rust-agent -c $TEST_WORKSPACE"* ]]
}

@test "full deployment workflow - agent deployment with validation" {
    # Load configuration
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Create task assignments file for testing
    export TASK_ASSIGNMENTS_FILE="$ORCHESTRATION_ROOT/memory/task_assignments.md"
    echo "# Task Assignments" > "$TASK_ASSIGNMENTS_FILE"
    
    # Step 6: Deploy agent with full validation
    run deploy_agent "rust" "123"
    [ "$status" -eq 0 ]
}

@test "full deployment workflow - command sending integration" {
    # Load configuration
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Mock successful validations
    validate_command_parameters() { return 0; }
    validate_command_syntax() { return 0; }
    validate_agent_exists() { return 0; }
    get_agent_session_name() { echo "rust-agent"; return 0; }
    check_agent_session_exists() { return 0; }
    export -f validate_command_parameters validate_command_syntax validate_agent_exists
    export -f get_agent_session_name check_agent_session_exists
    
    # Step 7: Send command to agent
    run send_command_to_agent "rust" "cargo --version"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux send-keys -t rust-agent cargo --version Enter"* ]]
}

@test "full deployment workflow - monitoring integration" {
    # Load configuration
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Step 8: Check agent health
    run check_agent_health "rust-agent"
    [ "$status" -eq 0 ]
    
    # Step 9: Get agent status
    run get_agent_status "rust-agent"
    [ "$status" -eq 0 ]
    [[ "$output" == "Healthy" ]]
}

@test "full deployment workflow - error handling" {
    # Load configuration
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Test error scenarios
    
    # Invalid agent type
    run validate_agent_type "nonexistent"
    [ "$status" -eq 1 ]
    
    # Invalid task number
    run validate_agent_deployment_args "rust" "abc"
    [ "$status" -eq 3 ]
    
    # Dangerous command
    run validate_command_syntax "rm -rf /"
    [ "$status" -eq 5 ]
}

@test "full deployment workflow - comprehensive deployment with enhanced validation" {
    # Load configuration
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Create all required files
    export MEMORY_DIR="$ORCHESTRATION_ROOT/memory"
    export LOGS_DIR="$ORCHESTRATION_ROOT/logs"
    export AGENT_LOGS_DIR="$ORCHESTRATION_ROOT/logs/agents"
    export TASK_ASSIGNMENTS_FILE="$MEMORY_DIR/task_assignments.md"
    export ORCHESTRATOR_LOG="$LOGS_DIR/orchestrator.log"
    export AGENT_PROMPT_FILE="$ORCHESTRATION_ROOT/prompts/rust_agent.md"
    
    mkdir -p "$MEMORY_DIR" "$LOGS_DIR" "$AGENT_LOGS_DIR" "$ORCHESTRATION_ROOT/prompts"
    echo "# Task Assignments" > "$TASK_ASSIGNMENTS_FILE"
    touch "$AGENT_PROMPT_FILE"
    
    # Mock all validation functions to succeed
    validate_deployment_prerequisites() { return 0; }
    check_deployment_conflicts() { return 0; }
    prepare_deployment_environment() { return 0; }
    create_deployment_backup() { return 0; }
    validate_agent_deployment_complete() { return 0; }
    export -f validate_deployment_prerequisites check_deployment_conflicts
    export -f prepare_deployment_environment create_deployment_backup
    export -f validate_agent_deployment_complete
    
    # Step 10: Enhanced deployment with comprehensive validation
    run deploy_agent_with_validation "rust" "123" "false"
    [ "$status" -eq 0 ]
}

@test "full deployment workflow - multi-agent coordination" {
    # Load configuration
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Add multiple agents to config for testing
    cat >> "$AGENTS_CONFIG_FILE" << EOF
  react:
    name: "React Agent"
    description: "React development agent"
    session_name: "react-agent"
    prompt_file: "react_agent.md"
    technologies: ["React", "npm"]
    capabilities: ["frontend", "testing"]
    validation_profile: "react"
validation_profiles:
  react:
    - "npm test"
    - "npm run lint"
EOF

    # Update mock yq to handle multiple agents
    mock_yq() {
        case "$1" in
            ".agent_types | keys | .[]") echo -e "rust\nreact" ;;
            ".agent_types.react.name") echo "React Agent" ;;
            ".agent_types.react.session_name") echo "react-agent" ;;
            ".agent_types | has(\"react\")") echo "true" ;;
            *) 
                # Call original mock for other cases
                case "$1" in
                    ".project.name") echo "TestProject" ;;
                    ".project.workspace_dir") echo "$TEST_WORKSPACE" ;;
                    ".agent_types.rust.name") echo "Rust Agent" ;;
                    ".agent_types.rust.session_name") echo "rust-agent" ;;
                    ".agent_types | has(\"rust\")") echo "true" ;;
                    *) echo "null" ;;
                esac
                ;;
        esac
    }
    export -f mock_yq
    
    # Test multi-agent operations
    run get_agent_types
    [[ "$output" == *"rust"* ]]
    [[ "$output" == *"react"* ]]
    
    # Test broadcasting to multiple agents
    send_command_to_agent() { return 0; }
    export -f send_command_to_agent
    
    run broadcast_message_to_agents "status update" "rust react"
    [ "$status" -eq 0 ]
}

@test "full deployment workflow - monitoring report generation" {
    # Load configuration
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Create memory files for monitoring
    export MEMORY_DIR="$ORCHESTRATION_ROOT/memory"
    export TASK_ASSIGNMENTS_FILE="$MEMORY_DIR/task_assignments.md"
    export PROJECT_STATE_FILE="$MEMORY_DIR/project_state.md"
    export BLOCKERS_FILE="$MEMORY_DIR/blockers.md"
    
    cat > "$TASK_ASSIGNMENTS_FILE" << EOF
# Task Assignments
## Rust Agent
- **Current**: Task #123
- **Status**: Active
- **Session**: rust-agent
EOF

    cat > "$PROJECT_STATE_FILE" << EOF
# Project State
## Current Phase: Phase 1
## Active Tasks
- [ ] Task #123: Implement feature
EOF

    cat > "$BLOCKERS_FILE" << EOF
# Blockers
## Current Blockers
None
EOF

    # Mock monitoring functions
    list_active_agent_sessions() { echo "rust-agent"; }
    get_agent_status() { echo "Healthy"; }
    check_session_activity() { return 0; }
    get_resource_usage() { echo "CPU: 10% | Memory: 5% | Processes: 2"; }
    export -f list_active_agent_sessions get_agent_status check_session_activity get_resource_usage
    
    # Generate comprehensive monitoring report
    run generate_monitoring_report "rust" "$MEMORY_DIR" "$TASK_ASSIGNMENTS_FILE" "$PROJECT_STATE_FILE" "$BLOCKERS_FILE"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Agent Monitoring Report"* ]]
    [[ "$output" == *"rust-agent: Healthy"* ]]
    [[ "$output" == *"Task #123"* ]]
}

@test "full deployment workflow - cleanup and session management" {
    # Load configuration
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Mock session operations
    get_agent_sessions_by_pattern() { echo "rust-agent"; }
    kill_session() { return 0; }
    export -f get_agent_sessions_by_pattern kill_session
    
    # Test session cleanup
    run kill_agent_sessions "rust" "/tmp/test.log"
    [ "$status" -eq 0 ]
    [[ "$output" == "1" ]]  # Should report 1 session stopped
}

@test "full deployment workflow - configuration validation" {
    # Test comprehensive configuration validation
    
    # Mock required tools check
    check_required_tools() { return 0; }
    export -f check_required_tools
    
    run validate_configuration "$PROJECT_CONFIG_FILE" "$AGENTS_CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "full deployment workflow - end-to-end agent lifecycle" {
    # This test demonstrates the complete agent lifecycle
    
    # 1. Initialize
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # 2. Validate and deploy
    export MEMORY_DIR="$ORCHESTRATION_ROOT/memory"
    export LOGS_DIR="$ORCHESTRATION_ROOT/logs"
    export AGENT_PROMPT_FILE="$ORCHESTRATION_ROOT/prompts/rust_agent.md"
    export TASK_ASSIGNMENTS_FILE="$MEMORY_DIR/task_assignments.md"
    
    mkdir -p "$MEMORY_DIR" "$LOGS_DIR" "$ORCHESTRATION_ROOT/prompts"
    echo "# Task Assignments" > "$TASK_ASSIGNMENTS_FILE"
    touch "$AGENT_PROMPT_FILE"
    
    run deploy_agent "rust" "123"
    [ "$status" -eq 0 ]
    
    # 3. Send commands
    validate_command_parameters() { return 0; }
    validate_command_syntax() { return 0; }
    validate_agent_exists() { return 0; }
    get_agent_session_name() { echo "rust-agent"; return 0; }
    check_agent_session_exists() { return 0; }
    export -f validate_command_parameters validate_command_syntax validate_agent_exists
    export -f get_agent_session_name check_agent_session_exists
    
    run send_command_to_agent "rust" "cargo test"
    [ "$status" -eq 0 ]
    
    # 4. Monitor
    run check_agent_health "rust-agent"
    [ "$status" -eq 0 ]
    
    # 5. Cleanup (mock)
    kill_session() { return 0; }
    export -f kill_session
    
    run kill_session "rust-agent"
    [ "$status" -eq 0 ]
}