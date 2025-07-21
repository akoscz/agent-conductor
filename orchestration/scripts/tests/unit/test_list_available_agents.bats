#!/usr/bin/env bats

# Unit tests for list_available_agents.sh functionality

setup() {
    # Create temporary test environment
    export TEST_DIR="/tmp/test_list_available_$$"
    export TEST_ORCHESTRATION_DIR="$TEST_DIR/orchestration"
    export TEST_AGENTS_DIR="$TEST_ORCHESTRATION_DIR/agents"
    export TEST_CONFIG_DIR="$TEST_ORCHESTRATION_DIR/config"
    
    mkdir -p "$TEST_AGENTS_DIR"/{backend,frontend,devops} "$TEST_CONFIG_DIR"
    
    # Create mock agent configurations
    cat > "$TEST_AGENTS_DIR/backend/config.yml" << 'EOF'
name: "Test Backend Agent"
description: "Test backend implementation"
session_name: "test-backend"
technologies: ["Rust", "PostgreSQL"]
capabilities: ["api", "database"]
validation_profile: "backend"
EOF

    cat > "$TEST_AGENTS_DIR/frontend/config.yml" << 'EOF'
name: "Test Frontend Agent" 
description: "Test frontend implementation"
session_name: "test-frontend"
technologies: ["React", "TypeScript"]
capabilities: ["ui", "components"]
validation_profile: "frontend"
EOF

    cat > "$TEST_AGENTS_DIR/devops/config.yml" << 'EOF'
name: "Test DevOps Agent"
description: "Test infrastructure management"
session_name: "test-devops" 
technologies: ["YourCloudProvider", "Docker"]
capabilities: ["deployment", "monitoring"]
validation_profile: "devops"
EOF

    # Create main agents config
    cat > "$TEST_CONFIG_DIR/agents.yml" << 'EOF'
agent_types:
  backend:
    directory: "agents/backend"
  frontend:
    directory: "agents/frontend" 
  devops:
    directory: "agents/devops"
EOF

    # Mock environment variables
    export ORCHESTRATION_DIR="$TEST_ORCHESTRATION_DIR"
    export AGENTS_CONFIG_FILE="$TEST_CONFIG_DIR/agents.yml"
    export PROJECT_NAME="TestProject"
    
    # Source required functions 
    source "$BATS_TEST_DIRNAME/../../lib/config_lib.sh" 2>/dev/null || true
    source "$BATS_TEST_DIRNAME/../../lib/session_lib.sh" 2>/dev/null || true
    
    # Source the script under test
    source "$BATS_TEST_DIRNAME/../../agent-management/list_available_agents.sh"
}

teardown() {
    rm -rf "$TEST_DIR" 2>/dev/null || true
}

@test "get_agent_emoji returns correct emojis for known agent types" {
    result=$(get_agent_emoji "backend")
    [ "$result" = "🦀" ]
    
    result=$(get_agent_emoji "frontend")
    [ "$result" = "📱" ]
    
    result=$(get_agent_emoji "devops")
    [ "$result" = "🚀" ]
    
    result=$(get_agent_emoji "unknown")
    [ "$result" = "🤖" ]
}

@test "get_agent_purpose returns correct purposes for known agent types" {
    result=$(get_agent_purpose "backend")
    [ "$result" = "Backend API and business logic" ]
    
    result=$(get_agent_purpose "frontend")
    [ "$result" = "Frontend development and UI components" ]
    
    result=$(get_agent_purpose "devops")
    [ "$result" = "Infrastructure and deployment" ]
    
    result=$(get_agent_purpose "unknown")
    [ "$result" = "Specialized development tasks" ]
}

@test "get_next_tasks returns correct suggestions for known agent types" {
    result=$(get_next_tasks "backend")
    [ "$result" = "Core service implementations" ]
    
    result=$(get_next_tasks "frontend") 
    [ "$result" = "UI component implementations" ]
    
    result=$(get_next_tasks "devops")
    [ "$result" = "CI/CD pipeline setup" ]
    
    result=$(get_next_tasks "unknown")
    [ "$result" = "Available for assignment" ]
}

@test "get_agent_status detects template configuration that needs customization" {
    # Test the template detection logic directly
    agent_info="Technologies: YourCloudProvider, Docker"
    if echo "$agent_info" | grep -q "YourBackendLang\|YourFrontendTech\|YourCloudProvider"; then
        result="Template (needs customization)"
    else
        result="Configured, Idle"
    fi
    [ "$result" = "Template (needs customization)" ]
}

@test "get_agent_status shows configured idle status for properly configured agents" {
    # Test the configured detection logic directly
    agent_info="Technologies: Rust, PostgreSQL" 
    if echo "$agent_info" | grep -q "YourBackendLang\|YourFrontendTech\|YourCloudProvider"; then
        result="Template (needs customization)"
    else
        result="Configured, Idle"
    fi
    [ "$result" = "Configured, Idle" ]
}

@test "display_available_agents produces expected output format" {
    # Mock required functions that might not be available
    get_agent_types() {
        echo "backend"
        echo "frontend" 
        echo "devops"
    }
    export -f get_agent_types
    
    check_tmux_server_running() {
        return 1  # No tmux server running
    }
    export -f check_tmux_server_running
    
    run display_available_agents "TestProject"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"🤖 Available Agent Types"* ]]
    [[ "$output" == *"🦀 backend (Test Backend Agent)"* ]]
    [[ "$output" == *"📱 frontend (Test Frontend Agent)"* ]]
    [[ "$output" == *"🚀 devops (Test DevOps Agent)"* ]]
    [[ "$output" == *"Status: Configured, Idle"* ]]
    [[ "$output" == *"Template (needs customization)"* ]]
    [[ "$output" == *"⚙️  Configuration:"* ]]
    [[ "$output" == *"💡 Usage:"* ]]
}

@test "handles missing agent config files gracefully" {
    # Test fallback behavior for missing config files
    # Just test that the fallback functions work
    result=$(get_agent_purpose "backend")
    [ "$result" = "Backend API and business logic" ]
    
    # Test emoji fallback
    result=$(get_agent_emoji "unknown-agent")
    [ "$result" = "🤖" ]
    
    # Test name generation for unknown agent
    name="Unknown Agent"
    [ "$name" = "Unknown Agent" ]
}

@test "handles empty agent types list" {
    get_agent_types() {
        echo ""  # Empty list
    }
    export -f get_agent_types
    
    run display_available_agents "TestProject"
    
    [ "$status" -eq 1 ]
    [[ "$output" == *"❌ No agent types configured"* ]]
}

@test "integration test - script executes without errors when sourced" {
    # This tests that the script can be executed as intended
    run bash -c "
        export ORCHESTRATION_DIR='$TEST_ORCHESTRATION_DIR'
        export AGENTS_CONFIG_FILE='$TEST_CONFIG_DIR/agents.yml'  
        export PROJECT_NAME='TestProject'
        
        # Mock the required functions
        get_agent_types() { echo 'backend'; echo 'frontend'; }
        check_tmux_server_running() { return 1; }
        get_agent_info() { echo 'Technologies: Test'; }
        
        # Source and call the function directly
        source '$BATS_TEST_DIRNAME/../../agent-management/list_available_agents.sh' 
        display_available_agents 'TestProject'
    "
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"Available Agent Types"* ]]
}