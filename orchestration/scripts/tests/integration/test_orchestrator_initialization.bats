#!/usr/bin/env bats

# Integration tests for orchestrator initialization workflow

setup() {
    # Load test setup utilities
    source "$BATS_TEST_DIRNAME/../test_setup_common.sh"
    
    # Load required libraries
    source "$BATS_TEST_DIRNAME/../../lib/config_lib.sh"
    source "$BATS_TEST_DIRNAME/../../lib/orchestrator_lib.sh"
    
    # Set up integration test environment
    setup_integration_test_environment "orchestrator_init"
    export TEST_WORKSPACE="$TEST_ORCHESTRATION_ROOT/workspace"
    
    # Create workspace directory
    mkdir -p "$TEST_WORKSPACE"
    
    # Test configs are already set up by setup_integration_test_environment
    cat > "$PROJECT_CONFIG_FILE" << EOF
project:
  name: "TestProject"
  description: "Test project for orchestrator"
  version: "1.0.0"
  workspace_dir: "$TEST_WORKSPACE"
  github:
    owner: "testorg"
    repo: "testrepo"
    project_number: 1
directories:
  config: "config"
  scripts: "scripts"
  agents: "agents"
  memory: "memory"
  logs: "logs"
  templates: "templates"
memory_files:
  project_state: "project_state.md"
  task_assignments: "task_assignments.md"
  blockers: "blockers.md"
  decisions: "decisions.md"
logging:
  orchestrator_log: "orchestrator.log"
  agent_logs_dir: "agents"
tmux:
  session_prefix: "test"
  default_shell: "/bin/bash"
  window_name: "agent"
phases:
  "1":
    name: "Foundation"
    description: "Basic setup and foundation"
    priority_tasks: ["Setup", "Configuration"]
EOF

    cat > "$AGENTS_CONFIG_FILE" << EOF
agent_types:
  rust:
    name: "Rust Agent"
    description: "Rust development agent"
    session_name: "rust-agent"
    prompt_file: "rust_agent.md"
    technologies: ["Rust", "Cargo", "Tauri"]
    capabilities: ["coding", "testing", "building"]
    validation_profile: "rust"
  react:
    name: "React Agent"
    description: "React frontend agent"
    session_name: "react-agent"
    prompt_file: "react_agent.md"
    technologies: ["React", "TypeScript", "npm"]
    capabilities: ["frontend", "testing", "styling"]
    validation_profile: "react"
validation_profiles:
  rust:
    - "cargo check"
    - "cargo test --lib"
    - "cargo clippy"
  react:
    - "npm run type-check"
    - "npm run lint"
    - "npm test"
EOF

    # Set up mocks
    export YQ_CMD="mock_yq"
    export DATE_CMD="echo 2024-01-15_10:30:00"
    export MKDIR_CMD="mkdir"
    export CAT_CMD="cat"
    export CD_CMD="cd"
    
    # Create comprehensive mock yq function
    mock_yq() {
        case "$1" in
            ".project.name") echo "TestProject" ;;
            ".project.description") echo "Test project for orchestrator" ;;
            ".project.version") echo "1.0.0" ;;
            ".project.workspace_dir") echo "$TEST_WORKSPACE" ;;
            ".project.github.owner") echo "testorg" ;;
            ".project.github.repo") echo "testrepo" ;;
            ".project.github.project_number") echo "1" ;;
            ".directories.config") echo "config" ;;
            ".directories.scripts") echo "scripts" ;;
            ".directories.prompts") echo "prompts" ;;
            ".directories.memory") echo "memory" ;;
            ".directories.logs") echo "logs" ;;
            ".directories.templates") echo "templates" ;;
            ".memory_files.project_state") echo "project_state.md" ;;
            ".memory_files.task_assignments") echo "task_assignments.md" ;;
            ".memory_files.blockers") echo "blockers.md" ;;
            ".memory_files.decisions") echo "decisions.md" ;;
            ".logging.orchestrator_log") echo "orchestrator.log" ;;
            ".logging.agent_logs_dir") echo "agents" ;;
            ".tmux.session_prefix") echo "test" ;;
            ".tmux.default_shell") echo "/bin/bash" ;;
            ".tmux.window_name") echo "agent" ;;
            ".phases | has(\"1\")") echo "true" ;;
            ".phases.1.name") echo "Foundation" ;;
            ".phases.1.description") echo "Basic setup and foundation" ;;
            ".phases.1.priority_tasks | join(\", \")") echo "Setup, Configuration" ;;
            ".agent_types | keys | .[]") echo -e "rust\nreact" ;;
            ".agent_types.rust.name") echo "Rust Agent" ;;
            ".agent_types.rust.description") echo "Rust development agent" ;;
            ".agent_types.rust.session_name") echo "rust-agent" ;;
            ".agent_types.rust.prompt_file") echo "rust_agent.md" ;;
            ".agent_types.rust.technologies | join(\" \")") echo "Rust Cargo Tauri" ;;
            ".agent_types.rust.capabilities | join(\" \")") echo "coding testing building" ;;
            ".agent_types.rust.validation_profile") echo "rust" ;;
            ".agent_types.react.name") echo "React Agent" ;;
            ".agent_types.react.session_name") echo "react-agent" ;;
            ".agent_types | has(\"rust\")") echo "true" ;;
            ".agent_types | has(\"react\")") echo "true" ;;
            ".validation_profiles | keys | .[]") echo -e "rust\nreact" ;;
            ".validation_profiles | has(\"rust\")") echo "true" ;;
            ".validation_profiles.rust") echo "- cargo check\n- cargo test --lib\n- cargo clippy" ;;
            *) echo "null" ;;
        esac
    }
    export -f mock_yq
}

teardown() {
    # Clean up test environment using common cleanup
    cleanup_test_environment
}

@test "orchestrator initialization - load full configuration" {
    # Test loading the complete configuration
    run load_full_configuration "$ORCHESTRATION_ROOT/lib"
    [ "$status" -eq 0 ]
    
    # Verify all configuration sections were loaded
    [[ "$PROJECT_NAME" == "TestProject" ]]
    [[ "$PROJECT_DESCRIPTION" == "Test project for orchestrator" ]]
    [[ "$PROJECT_VERSION" == "1.0.0" ]]
    [[ "$WORKSPACE_DIR" == "$TEST_WORKSPACE" ]]
    [[ "$GITHUB_OWNER" == "testorg" ]]
    [[ "$GITHUB_REPO" == "testrepo" ]]
    [[ "$GITHUB_PROJECT_NUMBER" == "1" ]]
}

@test "orchestrator initialization - directory configuration loading" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Verify directory paths are set correctly
    [[ "$CONFIG_DIR" == "$ORCHESTRATION_ROOT/config" ]]
    [[ "$SCRIPTS_DIR" == "$ORCHESTRATION_ROOT/scripts" ]]
    [[ "$PROMPTS_DIR" == "$ORCHESTRATION_ROOT/prompts" ]]
    [[ "$MEMORY_DIR" == "$ORCHESTRATION_ROOT/memory" ]]
    [[ "$LOGS_DIR" == "$ORCHESTRATION_ROOT/logs" ]]
    [[ "$TEMPLATES_DIR" == "$ORCHESTRATION_ROOT/templates" ]]
}

@test "orchestrator initialization - memory file configuration" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Verify memory file paths are set correctly
    [[ "$PROJECT_STATE_FILE" == "$MEMORY_DIR/project_state.md" ]]
    [[ "$TASK_ASSIGNMENTS_FILE" == "$MEMORY_DIR/task_assignments.md" ]]
    [[ "$BLOCKERS_FILE" == "$MEMORY_DIR/blockers.md" ]]
    [[ "$DECISIONS_FILE" == "$MEMORY_DIR/decisions.md" ]]
}

@test "orchestrator initialization - logging configuration" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Verify logging paths are set correctly
    [[ "$ORCHESTRATOR_LOG" == "$LOGS_DIR/orchestrator.log" ]]
    [[ "$AGENT_LOGS_DIR" == "$LOGS_DIR/agents" ]]
}

@test "orchestrator initialization - tmux configuration" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Verify tmux settings are loaded
    [[ "$TMUX_SESSION_PREFIX" == "test" ]]
    [[ "$TMUX_DEFAULT_SHELL" == "/bin/bash" ]]
    [[ "$TMUX_WINDOW_NAME" == "agent" ]]
}

@test "orchestrator initialization - agent types discovery" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Test agent types discovery
    run get_agent_types
    [ "$status" -eq 0 ]
    [[ "$output" == *"rust"* ]]
    [[ "$output" == *"react"* ]]
    
    # Test individual agent configurations
    run load_agent_config "rust"
    [ "$status" -eq 0 ]
    [[ "$AGENT_NAME" == "Rust Agent" ]]
    [[ "$AGENT_SESSION_NAME" == "rust-agent" ]]
    [[ "$AGENT_TECHNOLOGIES" == "Rust Cargo Tauri" ]]
    [[ "$AGENT_CAPABILITIES" == "coding testing building" ]]
}

@test "orchestrator initialization - validation profiles" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Test validation profile discovery
    run get_validation_profiles
    [ "$status" -eq 0 ]
    [[ "$output" == *"rust"* ]]
    [[ "$output" == *"react"* ]]
    
    # Test specific validation commands
    run get_validation_commands "rust"
    [ "$status" -eq 0 ]
    [[ "$output" == *"cargo check"* ]]
    [[ "$output" == *"cargo test"* ]]
    [[ "$output" == *"cargo clippy"* ]]
}

@test "orchestrator initialization - phase information" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Test phase information retrieval
    run get_phase_info "1"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Name: Foundation"* ]]
    [[ "$output" == *"Description: Basic setup and foundation"* ]]
    [[ "$output" == *"Priority Tasks: Setup, Configuration"* ]]
}

@test "orchestrator initialization - agent capability queries" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Test finding agents by capability
    run get_agents_by_capability "coding"
    [ "$status" -eq 0 ]
    [[ "$output" == *"rust"* ]]
    
    run get_agents_by_capability "frontend"
    [ "$status" -eq 0 ]
    [[ "$output" == *"react"* ]]
    
    run get_agents_by_capability "testing"
    [ "$status" -eq 0 ]
    # Both agents should have testing capability
}

@test "orchestrator initialization - comprehensive environment validation" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Mock tool checks to succeed
    check_required_tools() { return 0; }
    export -f check_required_tools
    
    # Test comprehensive validation
    run validate_configuration "$PROJECT_CONFIG_FILE" "$AGENTS_CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "orchestrator initialization - directory structure creation" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Test directory structure creation
    run create_directory_structure "$MEMORY_DIR" "$LOGS_DIR" "$AGENT_LOGS_DIR"
    [ "$status" -eq 0 ]
    
    # Verify directories were created
    [[ -d "$MEMORY_DIR" ]]
    [[ -d "$LOGS_DIR" ]]
    [[ -d "$AGENT_LOGS_DIR" ]]
}

@test "orchestrator initialization - memory files creation" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Create directories first
    mkdir -p "$MEMORY_DIR" "$LOGS_DIR" "$AGENT_LOGS_DIR"
    
    # Test memory files creation
    run create_initial_memory_files "$PROJECT_STATE_FILE" "$TASK_ASSIGNMENTS_FILE" "$BLOCKERS_FILE" "$DECISIONS_FILE" "$PROJECT_NAME"
    [ "$status" -eq 0 ]
    
    # Verify files were created with correct content
    [[ -f "$PROJECT_STATE_FILE" ]]
    [[ -f "$TASK_ASSIGNMENTS_FILE" ]]
    [[ -f "$BLOCKERS_FILE" ]]
    [[ -f "$DECISIONS_FILE" ]]
    
    grep -q "TestProject Project State" "$PROJECT_STATE_FILE"
    grep -q "Task Assignments" "$TASK_ASSIGNMENTS_FILE"
    grep -q "Project Blockers" "$BLOCKERS_FILE"
    grep -q "Technical Decisions Log" "$DECISIONS_FILE"
}

@test "orchestrator initialization - logging setup" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Create logs directory
    mkdir -p "$LOGS_DIR"
    
    # Test logging setup
    run setup_logging "$ORCHESTRATOR_LOG" "$PROJECT_NAME"
    [ "$status" -eq 0 ]
    
    # Verify log file was created
    [[ -f "$ORCHESTRATOR_LOG" ]]
    grep -q "Orchestrator initialized for TestProject" "$ORCHESTRATOR_LOG"
}

@test "orchestrator initialization - complete initialization workflow" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Mock validation to succeed
    validate_orchestrator_environment() { return 0; }
    export -f validate_orchestrator_environment
    
    # Test complete initialization
    run initialize_orchestrator "$WORKSPACE_DIR" "$ORCHESTRATION_ROOT" "$PROJECT_NAME" "$MEMORY_DIR" "$LOGS_DIR" "$AGENT_LOGS_DIR" "$PROJECT_STATE_FILE" "$TASK_ASSIGNMENTS_FILE" "$BLOCKERS_FILE" "$DECISIONS_FILE" "$ORCHESTRATOR_LOG"
    [ "$status" -eq 0 ]
    
    # Verify all components were initialized
    [[ -d "$MEMORY_DIR" ]]
    [[ -d "$LOGS_DIR" ]]
    [[ -d "$AGENT_LOGS_DIR" ]]
    [[ -f "$PROJECT_STATE_FILE" ]]
    [[ -f "$TASK_ASSIGNMENTS_FILE" ]]
    [[ -f "$BLOCKERS_FILE" ]]
    [[ -f "$DECISIONS_FILE" ]]
    [[ -f "$ORCHESTRATOR_LOG" ]]
}

@test "orchestrator initialization - agent management integration" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Test agent information retrieval
    run get_agent_info "rust"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Agent Type: rust"* ]]
    [[ "$output" == *"Name: Rust Agent"* ]]
    [[ "$output" == *"Description: Rust development agent"* ]]
    [[ "$output" == *"Session: rust-agent"* ]]
    [[ "$output" == *"Technologies: Rust, Cargo, Tauri"* ]]
    [[ "$output" == *"Capabilities: coding, testing, building"* ]]
}

@test "orchestrator initialization - validation commands integration" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Test agent validation commands retrieval
    run get_agent_validation_commands "rust"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Validation commands for rust"* ]]
    [[ "$output" == *"cargo check"* ]]
    [[ "$output" == *"cargo test"* ]]
    [[ "$output" == *"cargo clippy"* ]]
}

@test "orchestrator initialization - error handling" {
    # Test various error conditions
    
    # Missing yq
    export YQ_CMD="false"
    run load_full_configuration "$ORCHESTRATION_ROOT/lib"
    [ "$status" -eq 1 ]
    
    # Reset yq
    export YQ_CMD="mock_yq"
    
    # Missing config files
    rm "$PROJECT_CONFIG_FILE"
    run load_full_configuration "$ORCHESTRATION_ROOT/lib"
    [ "$status" -eq 2 ]
    
    # Restore config file
    cat > "$PROJECT_CONFIG_FILE" << EOF
project:
  name: "TestProject"
  workspace_dir: "$TEST_WORKSPACE"
EOF
}

@test "orchestrator initialization - configuration display" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Test configuration display
    run show_orchestrator_configuration "$WORKSPACE_DIR" "$ORCHESTRATION_ROOT" "$PROJECT_CONFIG_FILE" "$AGENTS_CONFIG_FILE" "$MEMORY_DIR" "$PROMPTS_DIR" "$LOGS_DIR" "$SCRIPTS_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Orchestrator Configuration"* ]]
    [[ "$output" == *"Directory Structure:"* ]]
    [[ "$output" == *"Configuration Files:"* ]]
    [[ "$output" == *"Available Agents:"* ]]
    [[ "$output" == *"rust"* ]]
    [[ "$output" == *"react"* ]]
}

@test "orchestrator initialization - status display integration" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Create memory files for status display
    mkdir -p "$MEMORY_DIR" "$LOGS_DIR"
    
    cat > "$PROJECT_STATE_FILE" << EOF
# TestProject Project State
## Current Phase: Phase 1 - Foundation
## Active Tasks
- [ ] Task #1: Setup environment
## Completed Tasks
None yet
## Blockers
None
EOF

    cat > "$TASK_ASSIGNMENTS_FILE" << EOF
# Task Assignments
## Rust Agent
- **Current**: Not assigned
- **Status**: Idle
- **Session**: None
## React Agent
- **Current**: Not assigned
- **Status**: Idle
- **Session**: None
EOF

    cat > "$BLOCKERS_FILE" << EOF
# Project Blockers
## Current Blockers
None
EOF

    # Test status display
    run show_orchestrator_status "$PROJECT_NAME" "$PROJECT_STATE_FILE" "$TASK_ASSIGNMENTS_FILE" "$BLOCKERS_FILE" "$SCRIPTS_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"TestProject Project Status"* ]]
    [[ "$output" == *"Project State:"* ]]
    [[ "$output" == *"Agent Assignments:"* ]]
    [[ "$output" == *"Active Sessions:"* ]]
    [[ "$output" == *"Current Blockers:"* ]]
}