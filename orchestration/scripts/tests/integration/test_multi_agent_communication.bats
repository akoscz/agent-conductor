#!/usr/bin/env bats

# Integration tests for multi-agent communication workflows

setup() {
    # Load required libraries
    source "$BATS_TEST_DIRNAME/../../lib/config_lib.sh"
    source "$BATS_TEST_DIRNAME/../../lib/session_lib.sh"
    source "$BATS_TEST_DIRNAME/../../lib/communication_lib.sh"
    source "$BATS_TEST_DIRNAME/../../lib/monitoring_lib.sh"
    
    # Set up test environment
    export ORCHESTRATION_ROOT="/tmp/test_comm_$$"
    export TEST_WORKSPACE="$ORCHESTRATION_ROOT/workspace"
    export PROJECT_CONFIG_FILE="$ORCHESTRATION_ROOT/config/project.yml"
    export AGENTS_CONFIG_FILE="$ORCHESTRATION_ROOT/config/agents.yml"
    
    # Create test directory structure
    mkdir -p "$ORCHESTRATION_ROOT/config"
    mkdir -p "$ORCHESTRATION_ROOT/memory"
    mkdir -p "$ORCHESTRATION_ROOT/logs/agents"
    mkdir -p "$TEST_WORKSPACE"
    
    # Create multi-agent configuration
    cat > "$PROJECT_CONFIG_FILE" << EOF
project:
  name: "MultiAgentTest"
  workspace_dir: "$TEST_WORKSPACE"
  github:
    owner: "testorg"
    repo: "testrepo"
directories:
  memory: "memory"
  logs: "logs"
memory_files:
  task_assignments: "task_assignments.md"
logging:
  orchestrator_log: "orchestrator.log"
  agent_logs_dir: "agents"
tmux:
  session_prefix: "test"
EOF

    cat > "$AGENTS_CONFIG_FILE" << EOF
agent_types:
  rust:
    name: "Rust Backend Agent"
    description: "Handles Rust backend development"
    session_name: "rust-agent"
    prompt_file: "rust_agent.md"
    technologies: ["Rust", "Cargo", "Tauri"]
    capabilities: ["backend", "api", "testing"]
    validation_profile: "rust"
  react:
    name: "React Frontend Agent"
    description: "Handles React frontend development"
    session_name: "react-agent"
    prompt_file: "react_agent.md"
    technologies: ["React", "TypeScript", "npm"]
    capabilities: ["frontend", "ui", "testing"]
    validation_profile: "react"
  devops:
    name: "DevOps Agent"
    description: "Handles deployment and infrastructure"
    session_name: "devops-agent"
    prompt_file: "devops_agent.md"
    technologies: ["Docker", "GitHub Actions", "CI/CD"]
    capabilities: ["deployment", "infrastructure", "automation"]
    validation_profile: "devops"
validation_profiles:
  rust:
    - "cargo check"
    - "cargo test"
  react:
    - "npm run type-check"
    - "npm test"
  devops:
    - "docker --version"
    - "gh --version"
EOF

    # Set up mocks
    export TMUX_CMD="mock_tmux"
    export YQ_CMD="mock_yq"
    export DATE_CMD="echo 2024-01-15_10:30:00"
    export GREP_CMD="grep"
    export WC_CMD="wc"
    
    # Mock tmux command with session tracking (using string-based approach for Bash 3.2 compatibility)
    export MOCK_SESSIONS=""
    
    mock_tmux() {
        case "$1" in
            "has-session")
                local session="$3"
                if [[ "$MOCK_SESSIONS" == *"$session"* ]]; then
                    return 0
                else
                    return 1
                fi
                ;;
            "new-session")
                local session_flag=false
                for arg in "$@"; do
                    if [[ "$session_flag" == "true" ]]; then
                        MOCK_SESSIONS="$MOCK_SESSIONS $arg"
                        echo "tmux new-session -d -s $arg -c $TEST_WORKSPACE"
                        return 0
                    fi
                    if [[ "$arg" == "-s" ]]; then
                        session_flag=true
                    fi
                done
                ;;
            "send-keys")
                local session=""
                local command=""
                local capture_next=false
                local command_parts=()
                
                for arg in "$@"; do
                    if [[ "$capture_next" == "session" ]]; then
                        session="$arg"
                        capture_next=false
                    elif [[ "$capture_next" == "command" ]]; then
                        command_parts+=("$arg")
                    elif [[ "$arg" == "-t" ]]; then
                        capture_next="session"
                    elif [[ "$arg" == "send-keys" ]]; then
                        capture_next="command"
                    fi
                done
                
                if [[ "$MOCK_SESSIONS" == *"$session"* ]]; then
                    echo "tmux send-keys -t $session ${command_parts[*]}"
                    return 0
                else
                    return 1
                fi
                ;;
            "list-sessions")
                if [[ -n "$MOCK_SESSIONS" ]]; then
                    for session in $MOCK_SESSIONS; do
                        echo "$session"
                    done
                fi
                ;;
            "capture-pane")
                echo "Mock session output for communication test"
                ;;
            *)
                echo "tmux $*"
                ;;
        esac
    }
    export -f mock_tmux
    
    # Mock yq with multi-agent responses
    mock_yq() {
        case "$1" in
            ".project.name") echo "MultiAgentTest" ;;
            ".project.workspace_dir") echo "$TEST_WORKSPACE" ;;
            ".agent_types | keys | .[]") echo -e "rust\nreact\ndevops" ;;
            ".agent_types.rust.name") echo "Rust Backend Agent" ;;
            ".agent_types.rust.session_name") echo "rust-agent" ;;
            ".agent_types.react.name") echo "React Frontend Agent" ;;
            ".agent_types.react.session_name") echo "react-agent" ;;
            ".agent_types.devops.name") echo "DevOps Agent" ;;
            ".agent_types.devops.session_name") echo "devops-agent" ;;
            ".agent_types | has(\"rust\")") echo "true" ;;
            ".agent_types | has(\"react\")") echo "true" ;;
            ".agent_types | has(\"devops\")") echo "true" ;;
            *) echo "null" ;;
        esac
    }
    export -f mock_yq
    
    # Create task assignments file
    export TASK_ASSIGNMENTS_FILE="$ORCHESTRATION_ROOT/memory/task_assignments.md"
    cat > "$TASK_ASSIGNMENTS_FILE" << EOF
# Task Assignments - Updated: 2024-01-15 10:30:00

## Rust Agent
- **Current**: Not assigned
- **Status**: Idle
- **Session**: None

## React Agent
- **Current**: Not assigned  
- **Status**: Idle
- **Session**: None

## Devops Agent
- **Current**: Not assigned
- **Status**: Idle
- **Session**: None
EOF
}

teardown() {
    # Clean up test environment
    rm -rf "$ORCHESTRATION_ROOT" 2>/dev/null
    unset MOCK_SESSIONS
}

@test "multi-agent communication - configuration loading for multiple agents" {
    # Load configuration
    run load_full_configuration "$ORCHESTRATION_ROOT/lib"
    [ "$status" -eq 0 ]
    
    # Verify all agents are discoverable
    run get_agent_types
    [ "$status" -eq 0 ]
    [[ "$output" == *"rust"* ]]
    [[ "$output" == *"react"* ]]
    [[ "$output" == *"devops"* ]]
    
    # Verify individual agent configurations
    for agent in "rust" "react" "devops"; do
        run load_agent_config "$agent"
        [ "$status" -eq 0 ]
    done
}

@test "multi-agent communication - session creation for multiple agents" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Create sessions for all agents
    local agents=("rust" "react" "devops")
    local sessions=("rust-agent" "react-agent" "devops-agent")
    
    for i in "${!agents[@]}"; do
        local agent="${agents[$i]}"
        local session="${sessions[$i]}"
        
        # Load agent config
        load_agent_config "$agent"
        
        # Create session
        run create_agent_session "$session" "$TEST_WORKSPACE"
        [ "$status" -eq 0 ]
        [[ "$output" == *"tmux new-session -d -s $session -c $TEST_WORKSPACE"* ]]
        
        # Verify session exists
        run session_exists "$session"
        [ "$status" -eq 0 ]
    done
}

@test "multi-agent communication - individual command sending" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Create mock sessions
    MOCK_SESSIONS["rust-agent"]="true"
    MOCK_SESSIONS["react-agent"]="true"
    MOCK_SESSIONS["devops-agent"]="true"
    
    # Test sending commands to individual agents
    run send_command_to_agent "rust" "cargo --version"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux send-keys -t rust-agent cargo --version Enter"* ]]
    
    run send_command_to_agent "react" "npm --version"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux send-keys -t react-agent npm --version Enter"* ]]
    
    run send_command_to_agent "devops" "docker --version"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux send-keys -t devops-agent docker --version Enter"* ]]
}

@test "multi-agent communication - broadcast messaging" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Create mock sessions
    MOCK_SESSIONS["rust-agent"]="true"
    MOCK_SESSIONS["react-agent"]="true"
    MOCK_SESSIONS["devops-agent"]="true"
    
    # Test broadcasting to all agents
    run broadcast_message_to_agents "echo 'Project status: Phase 1 complete'" "rust react devops"
    [ "$status" -eq 0 ]
}

@test "multi-agent communication - broadcast to specific agent subset" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Create mock sessions
    MOCK_SESSIONS["rust-agent"]="true"
    MOCK_SESSIONS["react-agent"]="true"
    MOCK_SESSIONS["devops-agent"]="true"
    
    # Test broadcasting to development agents only (excluding devops)
    run broadcast_message_to_agents "echo 'Development checkpoint reached'" "rust react"
    [ "$status" -eq 0 ]
}

@test "multi-agent communication - command validation across agents" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Test safe commands for different agent types
    run validate_command_syntax "cargo test"
    [ "$status" -eq 0 ]
    
    run validate_command_syntax "npm run test"
    [ "$status" -eq 0 ]
    
    run validate_command_syntax "docker build ."
    [ "$status" -eq 0 ]
    
    # Test dangerous commands are blocked for all agents
    run validate_command_syntax "rm -rf /"
    [ "$status" -eq 5 ]
    
    run validate_command_syntax "sudo dangerous-command"
    [ "$status" -eq 5 ]
}

@test "multi-agent communication - session monitoring across agents" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Create mock sessions with different states
    MOCK_SESSIONS["rust-agent"]="true"
    MOCK_SESSIONS["react-agent"]="true"
    # devops-agent intentionally not created to test missing session
    
    # Test individual agent health checks
    run check_agent_health "rust-agent"
    [ "$status" -eq 0 ]
    
    run check_agent_health "react-agent"
    [ "$status" -eq 0 ]
    
    run check_agent_health "devops-agent"
    [ "$status" -eq 2 ]  # Session doesn't exist
    
    # Test agent status retrieval
    run get_agent_status "rust-agent"
    [ "$status" -eq 0 ]
    [[ "$output" == "Healthy" ]]
    
    run get_agent_status "devops-agent"
    [ "$status" -eq 2 ]
    [[ "$output" == "Not Found" ]]
}

@test "multi-agent communication - agent discovery and listing" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Create some mock sessions
    MOCK_SESSIONS["rust-agent"]="true"
    MOCK_SESSIONS["react-agent"]="true"
    
    # Test listing active agent sessions
    run list_active_agent_sessions "agent"
    [ "$status" -eq 0 ]
    [[ "$output" == *"rust-agent"* ]]
    [[ "$output" == *"react-agent"* ]]
    
    # Test agent session pattern building
    run build_agent_session_pattern "rust react devops"
    [ "$status" -eq 0 ]
    [[ "$output" == "(rust|react|devops)" ]]
    
    # Test getting sessions by pattern
    run get_agent_sessions_by_pattern "rust react"
    [ "$status" -eq 0 ]
}

@test "multi-agent communication - command queueing system" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Test command queueing for different agents
    local rust_queue="/tmp/rust_queue_$$"
    local react_queue="/tmp/react_queue_$$"
    
    run queue_command_for_agent "rust" "cargo build" "$rust_queue"
    [ "$status" -eq 0 ]
    
    run queue_command_for_agent "rust" "cargo test" "$rust_queue"
    [ "$status" -eq 0 ]
    
    run queue_command_for_agent "react" "npm run build" "$react_queue"
    [ "$status" -eq 0 ]
    
    # Verify queue contents
    [[ -f "$rust_queue" ]]
    [[ -f "$react_queue" ]]
    
    grep -q "cargo build" "$rust_queue"
    grep -q "cargo test" "$rust_queue"
    grep -q "npm run build" "$react_queue"
    
    # Clean up
    rm -f "$rust_queue" "$react_queue"
}

@test "multi-agent communication - command history tracking" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Test command history for multiple agents
    local rust_history="/tmp/rust_history_$$"
    local react_history="/tmp/react_history_$$"
    
    run save_command_to_history "rust" "cargo check" "$rust_history"
    [ "$status" -eq 0 ]
    
    run save_command_to_history "rust" "cargo build" "$rust_history"
    [ "$status" -eq 0 ]
    
    run save_command_to_history "react" "npm install" "$react_history"
    [ "$status" -eq 0 ]
    
    # Verify history contents
    [[ -f "$rust_history" ]]
    [[ -f "$react_history" ]]
    
    grep -q "cargo check" "$rust_history"
    grep -q "cargo build" "$rust_history"
    grep -q "npm install" "$react_history"
    
    # Clean up
    rm -f "$rust_history" "$react_history"
}

@test "multi-agent communication - coordination workflows" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Create mock sessions for coordination test
    MOCK_SESSIONS["rust-agent"]="true"
    MOCK_SESSIONS["react-agent"]="true"
    MOCK_SESSIONS["devops-agent"]="true"
    
    # Simulate a coordinated workflow
    
    # 1. Backend agent starts API development
    run send_command_to_agent "rust" "echo 'Starting API development'"
    [ "$status" -eq 0 ]
    
    # 2. Frontend agent waits for API specification
    run send_command_to_agent "react" "echo 'Waiting for API spec'"
    [ "$status" -eq 0 ]
    
    # 3. DevOps agent prepares deployment environment
    run send_command_to_agent "devops" "echo 'Setting up deployment pipeline'"
    [ "$status" -eq 0 ]
    
    # 4. Broadcast status update to all agents
    run broadcast_message_to_agents "echo 'Phase 1 coordination checkpoint'" "rust react devops"
    [ "$status" -eq 0 ]
}

@test "multi-agent communication - error handling and resilience" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Test communication with non-existent agent
    run send_command_to_agent "nonexistent" "test command"
    [ "$status" -eq 3 ]  # Invalid agent type
    
    # Test communication with non-existent session
    run send_command_to_agent "rust" "test command"
    [ "$status" -eq 4 ]  # Session not found
    
    # Test broadcasting when some agents are unavailable
    MOCK_SESSIONS["rust-agent"]="true"
    # react-agent and devops-agent not available
    
    # Should succeed for available agents, handle failures gracefully
    run broadcast_message_to_agents "test message" "rust react devops"
    # May return non-zero status but should not crash
}

@test "multi-agent communication - capability-based agent selection" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Test finding agents by specific capabilities
    run get_agents_by_capability "backend"
    [[ "$output" == *"rust"* ]]
    
    run get_agents_by_capability "frontend"
    [[ "$output" == *"react"* ]]
    
    run get_agents_by_capability "deployment"
    [[ "$output" == *"devops"* ]]
    
    run get_agents_by_capability "testing"
    # Should return multiple agents as many have testing capability
}

@test "multi-agent communication - session cleanup coordination" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Create mock sessions
    MOCK_SESSIONS["rust-agent"]="true"
    MOCK_SESSIONS["react-agent"]="true"
    MOCK_SESSIONS["devops-agent"]="true"
    
    # Test coordinated session cleanup
    run kill_agent_sessions "rust react devops" "/tmp/cleanup.log"
    [ "$status" -eq 0 ]
    [[ "$output" == "3" ]]  # Should report 3 sessions stopped
}

@test "multi-agent communication - comprehensive monitoring report" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Create mock sessions and monitoring data
    MOCK_SESSIONS["rust-agent"]="true"
    MOCK_SESSIONS["react-agent"]="true"
    
    # Create comprehensive memory files
    mkdir -p "$ORCHESTRATION_ROOT/memory"
    cat > "$TASK_ASSIGNMENTS_FILE" << EOF
# Task Assignments
## Rust Agent
- **Current**: Task #101 (Backend API)
- **Status**: Active
- **Session**: rust-agent

## React Agent
- **Current**: Task #102 (Frontend UI)
- **Status**: Active
- **Session**: react-agent

## Devops Agent
- **Current**: Not assigned
- **Status**: Idle
- **Session**: None
EOF

    local project_state="$ORCHESTRATION_ROOT/memory/project_state.md"
    cat > "$project_state" << EOF
# Project State
## Current Phase: Phase 2 - Development
## Active Tasks
- [x] #100: Project setup
- [ ] #101: Backend API development (Rust)
- [ ] #102: Frontend UI development (React)
- [ ] #103: Deployment pipeline (DevOps)
EOF

    local blockers_file="$ORCHESTRATION_ROOT/memory/blockers.md"
    cat > "$blockers_file" << EOF
# Blockers
## Current Blockers
- API specification review pending
EOF

    # Generate comprehensive monitoring report
    run generate_monitoring_report "rust react devops" "$ORCHESTRATION_ROOT/memory" "$TASK_ASSIGNMENTS_FILE" "$project_state" "$blockers_file"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Agent Monitoring Report"* ]]
    [[ "$output" == *"rust-agent"* ]]
    [[ "$output" == *"react-agent"* ]]
    [[ "$output" == *"Task #101"* ]]
    [[ "$output" == *"Task #102"* ]]
}

@test "multi-agent communication - agent examples and help" {
    load_full_configuration "$ORCHESTRATION_ROOT/lib"
    
    # Test command examples for different agent types
    run show_command_examples "rust"
    [[ "$output" == *"cargo --version"* ]]
    
    run show_command_examples "react"
    [[ "$output" == *"npm run test"* ]]
    
    run show_command_examples "devops"
    [[ "$output" == *"docker --version"* ]]
    
    # Test showing available agents
    run show_available_agents
    [ "$status" -eq 0 ]
}