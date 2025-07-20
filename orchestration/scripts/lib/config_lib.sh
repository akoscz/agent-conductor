#!/bin/bash

# Configuration Library - Testable configuration management functions
# Provides core configuration loading and management functionality

# Dependency injection for external commands (allows mocking in tests)
YQ_CMD="${YQ_CMD:-yq}"
DATE_CMD="${DATE_CMD:-date}"
CP_CMD="${CP_CMD:-cp}"
MV_CMD="${MV_CMD:-mv}"

# Path resolution functions
get_orchestration_root() {
    local script_dir="$1"
    echo "$(dirname "$(dirname "$script_dir")")"
}

resolve_config_paths() {
    local orchestration_root="$1"
    export PROJECT_CONFIG_FILE="${PROJECT_CONFIG_FILE:-$orchestration_root/config/project.yml}"
    export AGENTS_CONFIG_FILE="${AGENTS_CONFIG_FILE:-$orchestration_root/config/agents.yml}"
}

# Validation functions
check_yq_available() {
    command -v "$YQ_CMD" &> /dev/null
    return $?
}

check_config_files_exist() {
    if [[ ! -f "$PROJECT_CONFIG_FILE" ]]; then
        return 1  # Project config missing
    fi
    
    if [[ ! -f "$AGENTS_CONFIG_FILE" ]]; then
        return 2  # Agents config missing
    fi
    
    return 0
}

check_workspace_directory() {
    local workspace_dir="$1"
    [[ -d "$workspace_dir" ]]
    return $?
}

check_required_tools() {
    local missing_tools=()
    
    if ! command -v tmux &> /dev/null; then
        missing_tools+=("tmux")
    fi
    
    if ! check_yq_available; then
        missing_tools+=("yq")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "${missing_tools[*]}"
        return 1
    fi
    
    return 0
}

# Core configuration loading
load_project_config() {
    local project_config_file="${1:-$PROJECT_CONFIG_FILE}"
    
    if [[ ! -f "$project_config_file" ]]; then
        return 1
    fi
    
    # Project configuration
    export PROJECT_NAME=$($YQ_CMD '.project.name' "$project_config_file")
    export PROJECT_DESCRIPTION=$($YQ_CMD '.project.description' "$project_config_file") 
    export PROJECT_VERSION=$($YQ_CMD '.project.version' "$project_config_file")
    export WORKSPACE_DIR=$($YQ_CMD '.project.workspace_dir' "$project_config_file")
    
    # GitHub configuration
    export GITHUB_OWNER=$($YQ_CMD '.project.github.owner' "$project_config_file")
    export GITHUB_REPO=$($YQ_CMD '.project.github.repo' "$project_config_file")
    export GITHUB_PROJECT_NUMBER=$($YQ_CMD '.project.github.project_number' "$project_config_file")
    
    return 0
}

load_directory_config() {
    local project_config_file="${1:-$PROJECT_CONFIG_FILE}"
    local orchestration_root="$2"
    
    if [[ ! -f "$project_config_file" ]]; then
        return 1
    fi
    
    # Directory paths (absolute)
    export CONFIG_DIR="$orchestration_root/$($YQ_CMD '.directories.config' "$project_config_file")"
    export SCRIPTS_DIR="$orchestration_root/$($YQ_CMD '.directories.scripts' "$project_config_file")"
    export PROMPTS_DIR="$orchestration_root/$($YQ_CMD '.directories.prompts' "$project_config_file")"
    export MEMORY_DIR="$orchestration_root/$($YQ_CMD '.directories.memory' "$project_config_file")"
    export LOGS_DIR="$orchestration_root/$($YQ_CMD '.directories.logs' "$project_config_file")"
    export TEMPLATES_DIR="$orchestration_root/$($YQ_CMD '.directories.templates' "$project_config_file")"
    
    return 0
}

load_memory_config() {
    local project_config_file="${1:-$PROJECT_CONFIG_FILE}"
    
    if [[ ! -f "$project_config_file" ]]; then
        return 1
    fi
    
    # Memory file paths
    export PROJECT_STATE_FILE="$MEMORY_DIR/$($YQ_CMD '.memory_files.project_state' "$project_config_file")"
    export TASK_ASSIGNMENTS_FILE="$MEMORY_DIR/$($YQ_CMD '.memory_files.task_assignments' "$project_config_file")"
    export BLOCKERS_FILE="$MEMORY_DIR/$($YQ_CMD '.memory_files.blockers' "$project_config_file")"
    export DECISIONS_FILE="$MEMORY_DIR/$($YQ_CMD '.memory_files.decisions' "$project_config_file")"
    
    return 0
}

load_logging_config() {
    local project_config_file="${1:-$PROJECT_CONFIG_FILE}"
    
    if [[ ! -f "$project_config_file" ]]; then
        return 1
    fi
    
    # Logging
    export ORCHESTRATOR_LOG="$LOGS_DIR/$($YQ_CMD '.logging.orchestrator_log' "$project_config_file")"
    export AGENT_LOGS_DIR="$LOGS_DIR/$($YQ_CMD '.logging.agent_logs_dir' "$project_config_file")"
    
    return 0
}

load_tmux_config() {
    local project_config_file="${1:-$PROJECT_CONFIG_FILE}"
    
    if [[ ! -f "$project_config_file" ]]; then
        return 1
    fi
    
    # tmux configuration
    export TMUX_SESSION_PREFIX=$($YQ_CMD '.tmux.session_prefix' "$project_config_file")
    export TMUX_DEFAULT_SHELL=$($YQ_CMD '.tmux.default_shell' "$project_config_file")
    export TMUX_WINDOW_NAME=$($YQ_CMD '.tmux.window_name' "$project_config_file")
    
    return 0
}

# Agent configuration functions
get_agent_types() {
    local agents_config_file="${1:-$AGENTS_CONFIG_FILE}"
    
    if [[ ! -f "$agents_config_file" ]]; then
        return 1
    fi
    
    $YQ_CMD '.agent_types | keys | .[]' "$agents_config_file" | tr -d '"'
    return $?
}

agent_type_exists() {
    local agent_type="$1"
    local agents_config_file="${2:-$AGENTS_CONFIG_FILE}"
    
    if [[ -z "$agent_type" ]] || [[ ! -f "$agents_config_file" ]]; then
        return 1
    fi
    
    $YQ_CMD ".agent_types | has(\"$agent_type\")" "$agents_config_file" | grep -q "true"
    return $?
}

load_agent_config() {
    local agent_type="$1"
    local agents_config_file="${2:-$AGENTS_CONFIG_FILE}"
    local orchestration_root="${3:-$(get_orchestration_root "$(dirname "${BASH_SOURCE[0]}")")}"
    
    if [[ -z "$agent_type" ]]; then
        return 1  # Missing agent type
    fi
    
    if [[ ! -f "$agents_config_file" ]]; then
        return 2  # Config file missing
    fi
    
    # Check if agent exists in config
    if ! agent_type_exists "$agent_type" "$agents_config_file"; then
        return 3  # Agent type not found
    fi
    
    # Get agent directory from main config
    local agent_directory=$($YQ_CMD ".agent_types.$agent_type.directory" "$agents_config_file")
    
    if [[ "$agent_directory" = "null" || -z "$agent_directory" ]]; then
        # Fallback to old structure if no directory specified
        export AGENT_TYPE="$agent_type"
        export AGENT_NAME=$($YQ_CMD ".agent_types.$agent_type.name" "$agents_config_file")
        export AGENT_DESCRIPTION=$($YQ_CMD ".agent_types.$agent_type.description" "$agents_config_file")
        export AGENT_SESSION_NAME=$($YQ_CMD ".agent_types.$agent_type.session_name" "$agents_config_file")
        export AGENT_PROMPT_FILE="$PROMPTS_DIR/$($YQ_CMD ".agent_types.$agent_type.prompt_file" "$agents_config_file")"
        export AGENT_VALIDATION_PROFILE=$($YQ_CMD ".agent_types.$agent_type.validation_profile" "$agents_config_file")
        export AGENT_TECHNOLOGIES=$($YQ_CMD ".agent_types.$agent_type.technologies | join(\" \")" "$agents_config_file")
        export AGENT_CAPABILITIES=$($YQ_CMD ".agent_types.$agent_type.capabilities | join(\" \")" "$agents_config_file")
    else
        # New directory-based structure
        local agent_config_file="$orchestration_root/$agent_directory/config.yml"
        local agent_prompt_file="$orchestration_root/$agent_directory/prompt.md"
        
        if [[ ! -f "$agent_config_file" ]]; then
            return 4  # Agent config file missing
        fi
        
        if [[ ! -f "$agent_prompt_file" ]]; then
            return 5  # Agent prompt file missing
        fi
        
        # Export agent-specific variables from agent's config.yml
        export AGENT_TYPE="$agent_type"
        export AGENT_NAME=$($YQ_CMD ".name" "$agent_config_file")
        export AGENT_DESCRIPTION=$($YQ_CMD ".description" "$agent_config_file")
        export AGENT_SESSION_NAME=$($YQ_CMD ".session_name" "$agent_config_file")
        export AGENT_PROMPT_FILE="$agent_prompt_file"
        export AGENT_VALIDATION_PROFILE=$($YQ_CMD ".validation_profile" "$agent_config_file")
        export AGENT_TECHNOLOGIES=$($YQ_CMD ".technologies | join(\" \")" "$agent_config_file")
        export AGENT_CAPABILITIES=$($YQ_CMD ".capabilities | join(\" \")" "$agent_config_file")
    fi
    
    return 0
}

get_agent_info() {
    local agent_type="$1"
    local agents_config_file="${2:-$AGENTS_CONFIG_FILE}"
    local orchestration_root="${3:-$(get_orchestration_root "$(dirname "${BASH_SOURCE[0]}")")}"
    
    if [[ -z "$agent_type" ]]; then
        return 1  # Missing agent type
    fi
    
    if [[ ! -f "$agents_config_file" ]]; then
        return 2  # Config file missing
    fi
    
    if ! agent_type_exists "$agent_type" "$agents_config_file"; then
        return 3  # Agent type not found
    fi
    
    # Get agent directory from main config
    local agent_directory=$($YQ_CMD ".agent_types.$agent_type.directory" "$agents_config_file")
    
    local name description session technologies capabilities
    
    if [[ "$agent_directory" = "null" || -z "$agent_directory" ]]; then
        # Fallback to old structure
        name=$($YQ_CMD ".agent_types.$agent_type.name" "$agents_config_file")
        description=$($YQ_CMD ".agent_types.$agent_type.description" "$agents_config_file")
        session=$($YQ_CMD ".agent_types.$agent_type.session_name" "$agents_config_file")
        technologies=$($YQ_CMD ".agent_types.$agent_type.technologies | join(\", \")" "$agents_config_file")
        capabilities=$($YQ_CMD ".agent_types.$agent_type.capabilities | join(\", \")" "$agents_config_file")
    else
        # New directory-based structure
        local agent_config_file="$orchestration_root/$agent_directory/config.yml"
        
        if [[ ! -f "$agent_config_file" ]]; then
            return 4  # Agent config file missing
        fi
        
        name=$($YQ_CMD ".name" "$agent_config_file")
        description=$($YQ_CMD ".description" "$agent_config_file")
        session=$($YQ_CMD ".session_name" "$agent_config_file")
        technologies=$($YQ_CMD ".technologies | join(\", \")" "$agent_config_file")
        capabilities=$($YQ_CMD ".capabilities | join(\", \")" "$agent_config_file")
    fi
    
    echo "Agent Type: $agent_type"
    echo "Name: $name"
    echo "Description: $description"
    echo "Session: $session"
    echo "Technologies: $technologies"
    echo "Capabilities: $capabilities"
    
    return 0
}

# Validation profile functions
get_validation_profiles() {
    local agents_config_file="${1:-$AGENTS_CONFIG_FILE}"
    
    if [[ ! -f "$agents_config_file" ]]; then
        return 1
    fi
    
    $YQ_CMD '.validation_profiles | keys | .[]' "$agents_config_file" | tr -d '"'
    return $?
}

validation_profile_exists() {
    local profile="$1"
    local agents_config_file="${2:-$AGENTS_CONFIG_FILE}"
    
    if [[ -z "$profile" ]] || [[ ! -f "$agents_config_file" ]]; then
        return 1
    fi
    
    $YQ_CMD ".validation_profiles | has(\"$profile\")" "$agents_config_file" | grep -q "true"
    return $?
}

get_validation_commands() {
    local profile="$1"
    local agents_config_file="${2:-$AGENTS_CONFIG_FILE}"
    
    if [[ -z "$profile" ]]; then
        return 1  # Missing profile
    fi
    
    if [[ ! -f "$agents_config_file" ]]; then
        return 2  # Config file missing
    fi
    
    if ! validation_profile_exists "$profile" "$agents_config_file"; then
        return 3  # Profile not found
    fi
    
    $YQ_CMD ".validation_profiles.$profile" "$agents_config_file"
    return $?
}

get_agent_validation_commands() {
    local agent_type="$1"
    local agents_config_file="${2:-$AGENTS_CONFIG_FILE}"
    
    if [[ -z "$agent_type" ]]; then
        return 1  # Missing agent type
    fi
    
    if [[ ! -f "$agents_config_file" ]]; then
        return 2  # Config file missing
    fi
    
    if ! agent_type_exists "$agent_type" "$agents_config_file"; then
        return 3  # Agent type not found
    fi
    
    local profile=$($YQ_CMD ".agent_types.$agent_type.validation_profile" "$agents_config_file")
    
    if [[ "$profile" = "null" ]]; then
        return 4  # No validation profile defined
    fi
    
    if ! validation_profile_exists "$profile" "$agents_config_file"; then
        return 5  # Validation profile not found
    fi
    
    echo "Validation commands for $agent_type (profile: $profile):"
    get_validation_commands "$profile" "$agents_config_file" | sed 's/^/  /'
    
    return 0
}

# Phase functions
get_phase_info() {
    local phase_number="$1"
    local project_config_file="${2:-$PROJECT_CONFIG_FILE}"
    
    if [[ -z "$phase_number" ]]; then
        return 1  # Missing phase number
    fi
    
    if [[ ! -f "$project_config_file" ]]; then
        return 2  # Config file missing
    fi
    
    if ! $YQ_CMD ".phases | has(\"$phase_number\")" "$project_config_file" | grep -q "true"; then
        return 3  # Phase not found
    fi
    
    echo "Name: $($YQ_CMD ".phases.$phase_number.name" "$project_config_file")"
    echo "Description: $($YQ_CMD ".phases.$phase_number.description" "$project_config_file")"
    echo "Priority Tasks: $($YQ_CMD ".phases.$phase_number.priority_tasks | join(\", \")" "$project_config_file")"
    
    return 0
}

# Capability functions
get_agents_by_capability() {
    local capability="$1"
    local agents_config_file="${2:-$AGENTS_CONFIG_FILE}"
    
    if [[ -z "$capability" ]]; then
        return 1  # Missing capability
    fi
    
    if [[ ! -f "$agents_config_file" ]]; then
        return 2  # Config file missing
    fi
    
    get_agent_types "$agents_config_file" | while read -r agent; do
        if $YQ_CMD ".agent_types.$agent.capabilities | contains([\"$capability\"])" "$agents_config_file" | grep -q "true"; then
            echo "$agent"
        fi
    done
    
    return 0
}

# Agent management functions
add_agent_type() {
    local agent_type="$1"
    local agent_name="$2"
    local description="$3"
    local technologies="$4"
    local capabilities="$5"
    local validation_profile="$6"
    local agents_config_file="${7:-$AGENTS_CONFIG_FILE}"
    
    if [[ -z "$agent_type" ]] || [[ -z "$agent_name" ]]; then
        return 1  # Missing required parameters
    fi
    
    if [[ ! -f "$agents_config_file" ]]; then
        return 2  # Config file missing
    fi
    
    # Check if agent already exists
    if agent_type_exists "$agent_type" "$agents_config_file"; then
        return 3  # Agent already exists
    fi
    
    # Create backup
    if ! $CP_CMD "$agents_config_file" "$agents_config_file.backup"; then
        return 4  # Backup failed
    fi
    
    # Build yq command for adding agent
    local yq_command=".agent_types.\"$agent_type\" = {
        \"name\": \"$agent_name\",
        \"description\": \"${description:-Agent for $agent_type development}\",
        \"session_name\": \"$agent_type-agent\",
        \"prompt_file\": \"${agent_type}_agent.md\",
        \"technologies\": [${technologies:-\"Generic\"}],
        \"capabilities\": [${capabilities:-\"general\"}],
        \"validation_profile\": \"${validation_profile:-generic}\"
    }"
    
    # Add the agent type
    if ! $YQ_CMD "$yq_command" "$agents_config_file" > "$agents_config_file.tmp"; then
        return 5  # yq command failed
    fi
    
    if ! $MV_CMD "$agents_config_file.tmp" "$agents_config_file"; then
        return 6  # Move failed
    fi
    
    return 0
}

remove_agent_type() {
    local agent_type="$1"
    local agents_config_file="${2:-$AGENTS_CONFIG_FILE}"
    
    if [[ -z "$agent_type" ]]; then
        return 1  # Missing agent type
    fi
    
    if [[ ! -f "$agents_config_file" ]]; then
        return 2  # Config file missing
    fi
    
    # Check if agent exists
    if ! agent_type_exists "$agent_type" "$agents_config_file"; then
        return 3  # Agent doesn't exist
    fi
    
    # Create backup
    if ! $CP_CMD "$agents_config_file" "$agents_config_file.backup"; then
        return 4  # Backup failed
    fi
    
    # Remove the agent type
    if ! $YQ_CMD "del(.agent_types.\"$agent_type\")" "$agents_config_file" > "$agents_config_file.tmp"; then
        return 5  # yq command failed
    fi
    
    if ! $MV_CMD "$agents_config_file.tmp" "$agents_config_file"; then
        return 6  # Move failed
    fi
    
    return 0
}

# Comprehensive validation function
validate_configuration() {
    local project_config_file="${1:-$PROJECT_CONFIG_FILE}"
    local agents_config_file="${2:-$AGENTS_CONFIG_FILE}"
    
    # Check required tools
    local missing_tools
    missing_tools=$(check_required_tools)
    if [[ $? -ne 0 ]]; then
        echo "Missing required tools: $missing_tools"
        return 1
    fi
    
    # Check config files
    check_config_files_exist
    local config_check=$?
    if [[ $config_check -eq 1 ]]; then
        echo "Project configuration file not found: $project_config_file"
        return 2
    elif [[ $config_check -eq 2 ]]; then
        echo "Agents configuration file not found: $agents_config_file"
        return 3
    fi
    
    # Load project config to get workspace dir
    if ! load_project_config "$project_config_file"; then
        echo "Failed to load project configuration"
        return 4
    fi
    
    # Check workspace directory
    if ! check_workspace_directory "$WORKSPACE_DIR"; then
        echo "Workspace directory does not exist: $WORKSPACE_DIR"
        return 5
    fi
    
    # Validate agent configurations
    local invalid_agents=()
    while read -r agent; do
        if ! load_agent_config "$agent" "$agents_config_file" &>/dev/null; then
            invalid_agents+=("$agent")
        fi
    done < <(get_agent_types "$agents_config_file")
    
    if [[ ${#invalid_agents[@]} -gt 0 ]]; then
        echo "Invalid agent configurations: ${invalid_agents[*]}"
        return 6
    fi
    
    return 0
}

# Main configuration loading function
load_full_configuration() {
    local script_dir="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
    
    # Resolve paths
    local orchestration_root
    orchestration_root=$(get_orchestration_root "$script_dir")
    export ORCHESTRATION_DIR="$orchestration_root"
    
    resolve_config_paths "$orchestration_root"
    
    # Check prerequisites
    if ! check_yq_available; then
        return 1  # yq not available
    fi
    
    check_config_files_exist
    local config_check=$?
    if [[ $config_check -ne 0 ]]; then
        return $((config_check + 1))  # Config files missing (2 or 3)
    fi
    
    # Load all configuration sections
    if ! load_project_config; then
        return 4  # Project config failed
    fi
    
    if ! load_directory_config "$PROJECT_CONFIG_FILE" "$orchestration_root"; then
        return 5  # Directory config failed
    fi
    
    if ! load_memory_config; then
        return 6  # Memory config failed
    fi
    
    if ! load_logging_config; then
        return 7  # Logging config failed
    fi
    
    if ! load_tmux_config; then
        return 8  # Tmux config failed
    fi
    
    return 0
}

# Error message helpers
get_config_error_message() {
    local error_code="$1"
    
    case $error_code in
        1) echo "❌ yq is required for configuration parsing but not installed" ;;
        2) echo "❌ Project configuration file not found: $PROJECT_CONFIG_FILE" ;;
        3) echo "❌ Agents configuration file not found: $AGENTS_CONFIG_FILE" ;;
        4) echo "❌ Failed to load project configuration" ;;
        5) echo "❌ Failed to load directory configuration" ;;
        6) echo "❌ Failed to load memory configuration" ;;
        7) echo "❌ Failed to load logging configuration" ;;
        8) echo "❌ Failed to load tmux configuration" ;;
        *) echo "❌ Unknown configuration error (code: $error_code)" ;;
    esac
}

get_agent_config_error_message() {
    local error_code="$1"
    local agent_type="$2"
    
    case $error_code in
        1) echo "❌ Missing agent type" ;;
        2) echo "❌ Agents configuration file not found" ;;
        3) echo "❌ Unknown agent type: $agent_type" ;;
        *) echo "❌ Unknown agent configuration error (code: $error_code)" ;;
    esac
}

get_validation_error_message() {
    local error_code="$1"
    local profile="$2"
    
    case $error_code in
        1) echo "❌ Missing validation profile" ;;
        2) echo "❌ Agents configuration file not found" ;;
        3) echo "❌ Validation profile not found: $profile" ;;
        4) echo "❌ No validation profile defined for agent" ;;
        5) echo "❌ Validation profile not found in configuration" ;;
        *) echo "❌ Unknown validation error (code: $error_code)" ;;
    esac
}