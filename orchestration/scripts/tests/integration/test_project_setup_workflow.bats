#!/usr/bin/env bats

# Integration tests for project setup workflow

setup() {
    # Load required libraries
    source "$BATS_TEST_DIRNAME/../../lib/setup_lib.sh"
    source "$BATS_TEST_DIRNAME/../../lib/config_lib.sh"
    source "$BATS_TEST_DIRNAME/../../lib/orchestrator_lib.sh"
    
    # Set up test environment
    export TEST_SOURCE_ORCHESTRATION="/tmp/test_source_$$"
    export TEST_TARGET_PROJECT="/tmp/test_target_$$"
    export TEST_PROJECT_NAME="TestSetupProject"
    
    # Create source orchestration structure
    mkdir -p "$TEST_SOURCE_ORCHESTRATION"/{scripts,config,templates,prompts,lib}
    
    # Create essential source files
    cat > "$TEST_SOURCE_ORCHESTRATION/templates/project.example.yml" << EOF
project:
  name: "PROJECT_NAME_PLACEHOLDER"
  description: "A test project created with orchestration system"
  version: "1.0.0"
  workspace_dir: "/path/to/workspace"
  github:
    owner: "your-org"
    repo: "your-repo"
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
  session_prefix: "dev"
  default_shell: "/bin/bash"
  window_name: "agent"
phases:
  "1":
    name: "Foundation"
    description: "Basic setup and foundation"
    priority_tasks: ["Environment Setup", "Configuration"]
EOF

    cat > "$TEST_SOURCE_ORCHESTRATION/templates/agents.example.yml" << EOF
agent_types:
  rust:
    name: "Rust Agent"
    description: "Rust development agent"
    session_name: "rust-agent"
    prompt_file: "rust_agent.md"
    technologies: ["Rust", "Cargo"]
    capabilities: ["coding", "testing"]
    validation_profile: "rust"
  react:
    name: "React Agent"
    description: "React development agent"
    session_name: "react-agent"
    prompt_file: "react_agent.md"
    technologies: ["React", "TypeScript"]
    capabilities: ["frontend", "testing"]
    validation_profile: "react"
validation_profiles:
  rust:
    - "cargo check"
    - "cargo test"
  react:
    - "npm run type-check"
    - "npm test"
EOF

    # Create sample prompt files
    echo "# Rust Agent Prompt" > "$TEST_SOURCE_ORCHESTRATION/prompts/rust_agent.md"
    echo "# React Agent Prompt" > "$TEST_SOURCE_ORCHESTRATION/prompts/react_agent.md"
    
    # Create sample scripts
    echo "#!/bin/bash\necho 'orchestrator script'" > "$TEST_SOURCE_ORCHESTRATION/scripts/orchestrator.sh"
    chmod +x "$TEST_SOURCE_ORCHESTRATION/scripts/orchestrator.sh"
    
    # Create target project directory
    mkdir -p "$TEST_TARGET_PROJECT"
    
    # Set up real commands (not mocked) for integration testing
    export CP_CMD="cp"
    export RM_CMD="rm"
    export MKDIR_CMD="mkdir"
    export CD_CMD="cd"
    export DIRNAME_CMD="dirname"
    export BASENAME_CMD="basename"
    export PWD_CMD="pwd"
}

teardown() {
    # Clean up test directories
    rm -rf "$TEST_SOURCE_ORCHESTRATION" "$TEST_TARGET_PROJECT" 2>/dev/null
}

@test "project setup workflow - validate source orchestration structure" {
    # Test that the source orchestration structure is valid
    run validate_source_orchestration "$TEST_SOURCE_ORCHESTRATION"
    [ "$status" -eq 0 ]
    
    # Verify all essential components exist
    [[ -d "$TEST_SOURCE_ORCHESTRATION/scripts" ]]
    [[ -d "$TEST_SOURCE_ORCHESTRATION/config" ]]
    [[ -d "$TEST_SOURCE_ORCHESTRATION/templates" ]]
    [[ -f "$TEST_SOURCE_ORCHESTRATION/templates/project.example.yml" ]]
    [[ -f "$TEST_SOURCE_ORCHESTRATION/templates/agents.example.yml" ]]
}

@test "project setup workflow - validate target project directory" {
    # Test target directory validation
    run validate_project_directory "$TEST_TARGET_PROJECT"
    [ "$status" -eq 0 ]
    
    # Test non-existent directory
    run validate_project_directory "/nonexistent/directory"
    [ "$status" -eq 2 ]
    
    # Test invalid directory paths
    run validate_project_directory ""
    [ "$status" -eq 1 ]
    
    run validate_project_directory "   "
    [ "$status" -eq 9 ]
}

@test "project setup workflow - copy orchestration system" {
    # Test copying orchestration system to target
    run copy_orchestration_system "$TEST_SOURCE_ORCHESTRATION" "$TEST_TARGET_PROJECT"
    [ "$status" -eq 0 ]
    
    # Verify orchestration directory was created
    [[ -d "$TEST_TARGET_PROJECT/orchestration" ]]
    [[ -d "$TEST_TARGET_PROJECT/orchestration/scripts" ]]
    [[ -d "$TEST_TARGET_PROJECT/orchestration/config" ]]
    [[ -d "$TEST_TARGET_PROJECT/orchestration/templates" ]]
    [[ -d "$TEST_TARGET_PROJECT/orchestration/prompts" ]]
    
    # Verify files were copied
    [[ -f "$TEST_TARGET_PROJECT/orchestration/templates/project.example.yml" ]]
    [[ -f "$TEST_TARGET_PROJECT/orchestration/templates/agents.example.yml" ]]
    [[ -f "$TEST_TARGET_PROJECT/orchestration/scripts/orchestrator.sh" ]]
    [[ -x "$TEST_TARGET_PROJECT/orchestration/scripts/orchestrator.sh" ]]
}

@test "project setup workflow - setup configuration templates" {
    # First copy the orchestration system
    copy_orchestration_system "$TEST_SOURCE_ORCHESTRATION" "$TEST_TARGET_PROJECT"
    
    # Test setting up configuration templates
    run setup_configuration_templates "$TEST_TARGET_PROJECT" "$TEST_PROJECT_NAME"
    [ "$status" -eq 0 ]
    
    # Verify configuration files were created from templates
    [[ -f "$TEST_TARGET_PROJECT/orchestration/config/project.yml" ]]
    [[ -f "$TEST_TARGET_PROJECT/orchestration/config/agents.yml" ]]
    
    # Verify project name was substituted
    grep -q "$TEST_PROJECT_NAME" "$TEST_TARGET_PROJECT/orchestration/config/project.yml"
    
    # Verify original templates still exist
    [[ -f "$TEST_TARGET_PROJECT/orchestration/templates/project.example.yml" ]]
    [[ -f "$TEST_TARGET_PROJECT/orchestration/templates/agents.example.yml" ]]
}

@test "project setup workflow - create project structure" {
    # First copy the orchestration system
    copy_orchestration_system "$TEST_SOURCE_ORCHESTRATION" "$TEST_TARGET_PROJECT"
    
    # Test creating project directory structure
    run create_project_structure "$TEST_TARGET_PROJECT"
    [ "$status" -eq 0 ]
    
    # Verify required directories were created
    [[ -d "$TEST_TARGET_PROJECT/orchestration/memory" ]]
    [[ -d "$TEST_TARGET_PROJECT/orchestration/logs" ]]
    [[ -d "$TEST_TARGET_PROJECT/orchestration/logs/agents" ]]
}

@test "project setup workflow - cleanup source project data" {
    # First copy the orchestration system and create structure
    copy_orchestration_system "$TEST_SOURCE_ORCHESTRATION" "$TEST_TARGET_PROJECT"
    create_project_structure "$TEST_TARGET_PROJECT"
    
    # Create some test files in memory and logs directories
    echo "test memory data" > "$TEST_TARGET_PROJECT/orchestration/memory/test.md"
    echo "test log data" > "$TEST_TARGET_PROJECT/orchestration/logs/test.log"
    
    # Test cleanup
    run cleanup_source_project_data "$TEST_TARGET_PROJECT"
    [ "$status" -eq 0 ]
    
    # Verify files were removed but directories preserved
    [[ -d "$TEST_TARGET_PROJECT/orchestration/memory" ]]
    [[ -d "$TEST_TARGET_PROJECT/orchestration/logs" ]]
    [[ ! -f "$TEST_TARGET_PROJECT/orchestration/memory/test.md" ]]
    [[ ! -f "$TEST_TARGET_PROJECT/orchestration/logs/test.log" ]]
    
    # Verify .gitkeep files were created
    [[ -f "$TEST_TARGET_PROJECT/orchestration/memory/.gitkeep" ]]
    [[ -f "$TEST_TARGET_PROJECT/orchestration/logs/.gitkeep" ]]
    [[ -f "$TEST_TARGET_PROJECT/orchestration/logs/agents/.gitkeep" ]]
}

@test "project setup workflow - complete setup workflow non-interactive" {
    # Test the complete setup workflow in non-interactive mode
    run setup_new_project "$TEST_TARGET_PROJECT" "$TEST_SOURCE_ORCHESTRATION" "$TEST_PROJECT_NAME" "false"
    [ "$status" -eq 0 ]
    
    # Verify complete setup
    [[ -d "$TEST_TARGET_PROJECT/orchestration" ]]
    [[ -f "$TEST_TARGET_PROJECT/orchestration/config/project.yml" ]]
    [[ -f "$TEST_TARGET_PROJECT/orchestration/config/agents.yml" ]]
    [[ -d "$TEST_TARGET_PROJECT/orchestration/memory" ]]
    [[ -d "$TEST_TARGET_PROJECT/orchestration/logs" ]]
    [[ -f "$TEST_TARGET_PROJECT/orchestration/memory/.gitkeep" ]]
    
    # Verify project name substitution
    grep -q "$TEST_PROJECT_NAME" "$TEST_TARGET_PROJECT/orchestration/config/project.yml"
}

@test "project setup workflow - overwrite handling" {
    # First setup
    setup_new_project "$TEST_TARGET_PROJECT" "$TEST_SOURCE_ORCHESTRATION" "$TEST_PROJECT_NAME" "false"
    
    # Modify a file to test overwrite
    echo "modified content" > "$TEST_TARGET_PROJECT/orchestration/config/project.yml"
    
    # Attempt setup again without overwrite (should fail)
    run setup_new_project "$TEST_TARGET_PROJECT" "$TEST_SOURCE_ORCHESTRATION" "$TEST_PROJECT_NAME" "false"
    [ "$status" -eq 7 ]  # Orchestration already exists
    
    # Verify file wasn't overwritten
    grep -q "modified content" "$TEST_TARGET_PROJECT/orchestration/config/project.yml"
}

@test "project setup workflow - configuration validation after setup" {
    # Complete the setup
    setup_new_project "$TEST_TARGET_PROJECT" "$TEST_SOURCE_ORCHESTRATION" "$TEST_PROJECT_NAME" "false"
    
    # Set up environment for configuration testing
    export PROJECT_CONFIG_FILE="$TEST_TARGET_PROJECT/orchestration/config/project.yml"
    export AGENTS_CONFIG_FILE="$TEST_TARGET_PROJECT/orchestration/config/agents.yml"
    export YQ_CMD="mock_yq"
    
    # Mock yq to return valid responses for the created configuration
    mock_yq() {
        case "$1" in
            ".project.name") echo "$TEST_PROJECT_NAME" ;;
            ".project.workspace_dir") echo "/path/to/workspace" ;;
            ".agent_types | keys | .[]") echo -e "rust\nreact" ;;
            ".agent_types.rust.name") echo "Rust Agent" ;;
            ".agent_types.react.name") echo "React Agent" ;;
            ".agent_types | has(\"rust\")") echo "true" ;;
            ".agent_types | has(\"react\")") echo "true" ;;
            *) echo "null" ;;
        esac
    }
    export -f mock_yq
    
    # Test configuration loading
    run load_full_configuration "$TEST_TARGET_PROJECT/orchestration/lib"
    [ "$status" -eq 0 ]
    
    # Verify configuration values
    [[ "$PROJECT_NAME" == "$TEST_PROJECT_NAME" ]]
    
    # Test agent types discovery
    run get_agent_types
    [ "$status" -eq 0 ]
    [[ "$output" == *"rust"* ]]
    [[ "$output" == *"react"* ]]
}

@test "project setup workflow - orchestrator initialization after setup" {
    # Complete the setup
    setup_new_project "$TEST_TARGET_PROJECT" "$TEST_SOURCE_ORCHESTRATION" "$TEST_PROJECT_NAME" "false"
    
    # Set up configuration environment
    export PROJECT_CONFIG_FILE="$TEST_TARGET_PROJECT/orchestration/config/project.yml"
    export AGENTS_CONFIG_FILE="$TEST_TARGET_PROJECT/orchestration/config/agents.yml"
    export YQ_CMD="mock_yq"
    export DATE_CMD="echo 2024-01-15_10:30:00"
    export CAT_CMD="cat"
    
    # Mock yq
    mock_yq() {
        case "$1" in
            ".project.name") echo "$TEST_PROJECT_NAME" ;;
            ".project.workspace_dir") echo "$TEST_TARGET_PROJECT/workspace" ;;
            ".directories.memory") echo "memory" ;;
            ".directories.logs") echo "logs" ;;
            ".memory_files.project_state") echo "project_state.md" ;;
            ".memory_files.task_assignments") echo "task_assignments.md" ;;
            ".memory_files.blockers") echo "blockers.md" ;;
            ".memory_files.decisions") echo "decisions.md" ;;
            ".logging.orchestrator_log") echo "orchestrator.log" ;;
            ".agent_types | keys | .[]") echo -e "rust\nreact" ;;
            ".agent_types.rust.name") echo "Rust Agent" ;;
            ".agent_types.react.name") echo "React Agent" ;;
            *) echo "null" ;;
        esac
    }
    export -f mock_yq
    
    # Load configuration
    load_full_configuration "$TEST_TARGET_PROJECT/orchestration/lib"
    
    # Create workspace directory
    mkdir -p "$TEST_TARGET_PROJECT/workspace"
    
    # Mock validation to succeed
    validate_orchestrator_environment() { return 0; }
    export -f validate_orchestrator_environment
    
    # Test orchestrator initialization
    run initialize_orchestrator "$TEST_TARGET_PROJECT/workspace" "$TEST_TARGET_PROJECT/orchestration" "$PROJECT_NAME" "$MEMORY_DIR" "$LOGS_DIR" "$AGENT_LOGS_DIR" "$PROJECT_STATE_FILE" "$TASK_ASSIGNMENTS_FILE" "$BLOCKERS_FILE" "$DECISIONS_FILE" "$ORCHESTRATOR_LOG"
    [ "$status" -eq 0 ]
    
    # Verify initialization files were created
    [[ -f "$PROJECT_STATE_FILE" ]]
    [[ -f "$TASK_ASSIGNMENTS_FILE" ]]
    [[ -f "$BLOCKERS_FILE" ]]
    [[ -f "$DECISIONS_FILE" ]]
    [[ -f "$ORCHESTRATOR_LOG" ]]
    
    # Verify content
    grep -q "$TEST_PROJECT_NAME Project State" "$PROJECT_STATE_FILE"
    grep -q "Task Assignments" "$TASK_ASSIGNMENTS_FILE"
    grep -q "Project Blockers" "$BLOCKERS_FILE"
    grep -q "Technical Decisions Log" "$DECISIONS_FILE"
    grep -q "Orchestrator initialized for $TEST_PROJECT_NAME" "$ORCHESTRATOR_LOG"
}

@test "project setup workflow - setup verification" {
    # Complete the setup
    setup_new_project "$TEST_TARGET_PROJECT" "$TEST_SOURCE_ORCHESTRATION" "$TEST_PROJECT_NAME" "false"
    
    # Test setup verification
    run verify_setup_completion "$TEST_TARGET_PROJECT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Setup verification passed"* ]]
}

@test "project setup workflow - setup requirements validation" {
    # Test setup requirements validation
    run validate_setup_requirements
    [ "$status" -eq 0 ]
    
    # Mock missing tools
    command() { 
        case "$2" in
            "cp"|"rm"|"mkdir") return 1 ;;
            *) return 0 ;;
        esac
    }
    export -f command
    
    run validate_setup_requirements
    [ "$status" -eq 1 ]
    [[ "$output" == *"Missing required tools:"* ]]
}

@test "project setup workflow - current orchestration directory resolution" {
    # Create a mock script path
    local script_path="$TEST_SOURCE_ORCHESTRATION/scripts/setup.sh"
    touch "$script_path"
    
    # Test orchestration directory resolution
    run get_current_orchestration_dir "$script_path"
    [ "$status" -eq 0 ]
    # Should return the parent directory of scripts
    [[ "$output" == "$TEST_SOURCE_ORCHESTRATION" ]]
}

@test "project setup workflow - project name extraction" {
    # Test project name extraction from path
    run extract_project_name_from_path "/path/to/my-awesome-project"
    [ "$status" -eq 0 ]
    [[ "$output" == "my-awesome-project" ]]
    
    run extract_project_name_from_path "$TEST_TARGET_PROJECT"
    [ "$status" -eq 0 ]
    # Should extract the last component
}

@test "project setup workflow - error scenarios" {
    # Test various error scenarios
    
    # Invalid source directory
    run setup_new_project "$TEST_TARGET_PROJECT" "/nonexistent/source" "$TEST_PROJECT_NAME" "false"
    [ "$status" -eq 8 ]  # Source validation error
    
    # Invalid target directory  
    run setup_new_project "/nonexistent/target" "$TEST_SOURCE_ORCHESTRATION" "$TEST_PROJECT_NAME" "false"
    [ "$status" -eq 2 ]  # Target validation error
    
    # Source missing essential components
    local incomplete_source="/tmp/incomplete_$$"
    mkdir -p "$incomplete_source"
    run setup_new_project "$TEST_TARGET_PROJECT" "$incomplete_source" "$TEST_PROJECT_NAME" "false"
    [ "$status" -eq 8 ]  # Source validation error
    rmdir "$incomplete_source"
}

@test "project setup workflow - end-to-end with agent deployment" {
    # Complete setup workflow
    setup_new_project "$TEST_TARGET_PROJECT" "$TEST_SOURCE_ORCHESTRATION" "$TEST_PROJECT_NAME" "false"
    
    # Initialize orchestrator environment
    export PROJECT_CONFIG_FILE="$TEST_TARGET_PROJECT/orchestration/config/project.yml"
    export AGENTS_CONFIG_FILE="$TEST_TARGET_PROJECT/orchestration/config/agents.yml"
    export YQ_CMD="mock_yq"
    export TMUX_CMD="echo tmux"
    export DATE_CMD="echo 2024-01-15_10:30:00"
    
    # Mock yq for agent testing
    mock_yq() {
        case "$1" in
            ".project.name") echo "$TEST_PROJECT_NAME" ;;
            ".project.workspace_dir") echo "$TEST_TARGET_PROJECT/workspace" ;;
            ".agent_types | keys | .[]") echo -e "rust\nreact" ;;
            ".agent_types.rust.name") echo "Rust Agent" ;;
            ".agent_types.rust.session_name") echo "rust-agent" ;;
            ".agent_types | has(\"rust\")") echo "true" ;;
            *) echo "null" ;;
        esac
    }
    export -f mock_yq
    
    # Load configuration and test agent operations
    source "$BATS_TEST_DIRNAME/../../lib/agent_lib.sh"
    load_full_configuration "$TEST_TARGET_PROJECT/orchestration/lib"
    
    # Create workspace
    mkdir -p "$TEST_TARGET_PROJECT/workspace"
    
    # Test agent validation
    run validate_agent_type "rust"
    [ "$status" -eq 0 ]
    
    # Test agent configuration loading
    run load_agent_config "rust"
    [ "$status" -eq 0 ]
    [[ "$AGENT_NAME" == "Rust Agent" ]]
    [[ "$AGENT_SESSION_NAME" == "rust-agent" ]]
    
    # This demonstrates that the setup workflow produces a fully functional orchestration environment
}

@test "project setup workflow - generate setup instructions" {
    # Test setup instructions generation
    run generate_setup_instructions "$TEST_TARGET_PROJECT" "$TEST_PROJECT_NAME"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Next Steps:"* ]]
    [[ "$output" == *"Configure for your project:"* ]]
    [[ "$output" == *"Install dependencies:"* ]]
    [[ "$output" == *"Initialize and start:"* ]]
    [[ "$output" == *"Key files to customize:"* ]]
    [[ "$output" == *"$TEST_TARGET_PROJECT"* ]]
}

@test "project setup workflow - help display" {
    # Test help display
    run show_setup_help "setup_new_project.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"AI Agent Orchestration - New Project Setup"* ]]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"Arguments:"* ]]
    [[ "$output" == *"Example:"* ]]
}