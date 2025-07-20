#!/bin/bash

# Configuration loader for AI Agent Orchestrator
# Sources configuration from separate project.yml and agents.yml files
# Fully dynamic agent type support

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the config library
source "$SCRIPT_DIR/../lib/config_lib.sh" || {
    echo "❌ Failed to load configuration library"
    exit 1
}

# Load configuration into environment variables
load_config() {
    if ! load_full_configuration "$SCRIPT_DIR"; then
        local exit_code=$?
        echo "$(get_config_error_message $exit_code)"
        echo "💡 Install with: brew install yq tmux"
        exit $exit_code
    fi
}

# Thin wrapper functions that call library functions and handle CLI concerns

# Get all available agent types dynamically
get_agent_types() {
    # Call the library function directly using YQ_CMD
    $YQ_CMD '.agent_types | keys | .[]' "$AGENTS_CONFIG_FILE" 2>/dev/null | tr -d '"' || echo ""
}

# Get agent configuration by type
get_agent_config() {
    local agent_type="$1"
    local result
    result=$(load_agent_config "$agent_type")
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo "$(get_agent_config_error_message $exit_code "$agent_type")"
        if [[ $exit_code -eq 3 ]]; then
            echo "Available agents: $(get_agent_types | tr '\n' ', ' | sed 's/, $//')"
        fi
        return $exit_code
    fi
    
    return 0
}

# Get agent info for display
get_agent_info() {
    local agent_type="$1"
    local result
    result=$(get_agent_info "$agent_type" "$AGENTS_CONFIG_FILE")
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo "$(get_agent_config_error_message $exit_code "$agent_type")"
        return $exit_code
    fi
    
    echo "$result"
    return 0
}

# Get validation commands for agent's validation profile
get_agent_validation_commands() {
    local agent_type="$1"
    local result
    result=$(get_agent_validation_commands "$agent_type" "$AGENTS_CONFIG_FILE")
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        case $exit_code in
            1|2|3) echo "$(get_agent_config_error_message $exit_code "$agent_type")" ;;
            4|5) echo "$(get_validation_error_message $exit_code)" ;;
        esac
        return $exit_code
    fi
    
    echo "$result"
    return 0
}

# Get all validation profiles
get_validation_profiles() {
    # Call the library function directly using YQ_CMD
    $YQ_CMD '.validation_profiles | keys | .[]' "$AGENTS_CONFIG_FILE" 2>/dev/null | tr -d '"' || echo ""
}

# Get validation commands for specific profile
get_validation_commands() {
    local profile="$1"
    local result
    result=$(get_validation_commands "$profile" "$AGENTS_CONFIG_FILE")
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo "$(get_validation_error_message $exit_code "$profile")"
        if [[ $exit_code -eq 3 ]]; then
            echo "Available profiles: $(get_validation_profiles "$AGENTS_CONFIG_FILE" | tr '\n' ', ' | sed 's/, $//')"
        fi
        return $exit_code
    fi
    
    echo "$result"
    return 0
}

# Get phase information
get_phase_info() {
    local phase_number="$1"
    local result
    result=$(get_phase_info "$phase_number" "$PROJECT_CONFIG_FILE")
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        if [[ $exit_code -eq 1 ]]; then
            echo "❌ Phase number required"
        elif [[ $exit_code -eq 3 ]]; then
            echo "❌ Phase $phase_number not found"
        fi
        return $exit_code
    fi
    
    echo "$result"
    return 0
}

# Get agents capable of handling specific capability
get_agents_by_capability() {
    local capability="$1"
    local result
    result=$(get_agents_by_capability "$capability" "$AGENTS_CONFIG_FILE")
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        if [[ $exit_code -eq 1 ]]; then
            echo "❌ Capability required"
        fi
        return $exit_code
    fi
    
    echo "$result"
    return 0
}

# Validate configuration
validate_config() {
    echo "🔍 Validating configuration..."
    
    local result
    result=$(validate_configuration)
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo "$result"
        if [[ $exit_code -eq 1 ]]; then
            echo "💡 Install with: brew install tmux yq"
        fi
        return $exit_code
    fi
    
    echo "✅ Configuration validated successfully"
    return 0
}

# Show configuration summary
show_config() {
    echo "📊 $PROJECT_NAME Orchestrator Configuration"
    echo "==========================================="
    echo "Project: $PROJECT_NAME v$PROJECT_VERSION"
    echo "Description: $PROJECT_DESCRIPTION"
    echo "Workspace: $WORKSPACE_DIR"
    echo "Orchestration: $ORCHESTRATION_DIR"
    echo ""
    echo "📁 Configuration Files:"
    echo "  • Project: $PROJECT_CONFIG_FILE"
    echo "  • Agents: $AGENTS_CONFIG_FILE"
    echo ""
    echo "🤖 Configured Agent Types:"
    get_agent_types "$AGENTS_CONFIG_FILE" | while read -r agent; do
        if load_agent_config "$agent" &>/dev/null; then
            echo "  • $agent: $AGENT_NAME"
            echo "    Technologies: $AGENT_TECHNOLOGIES"
            echo "    Capabilities: $AGENT_CAPABILITIES"
            echo ""
        fi
    done
    echo "📁 Key Directories:"
    echo "  • Config: $CONFIG_DIR"
    echo "  • Scripts: $SCRIPTS_DIR"  
    echo "  • Prompts: $PROMPTS_DIR"
    echo "  • Memory: $MEMORY_DIR"
    echo "  • Logs: $LOGS_DIR"
    echo ""
    echo "🔗 GitHub: https://github.com/$GITHUB_OWNER/$GITHUB_REPO"
}

# Add new agent type to configuration
add_agent_type() {
    local agent_type="$1"
    local agent_name="$2"
    local description="$3"
    local technologies="$4"
    local capabilities="$5"
    local validation_profile="$6"
    
    if [[ -z "$agent_type" ]] || [[ -z "$agent_name" ]]; then
        echo "❌ Usage: add_agent_type <type> <name> [description] [technologies] [capabilities] [validation_profile]"
        return 1
    fi
    
    echo "🤖 Adding new agent type: $agent_type"
    
    local result
    add_agent_type "$agent_type" "$agent_name" "$description" "$technologies" "$capabilities" "$validation_profile" "$AGENTS_CONFIG_FILE"
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        case $exit_code in
            3) echo "❌ Agent type '$agent_type' already exists" ;;
            *) echo "❌ Failed to add agent type (error code: $exit_code)" ;;
        esac
        return $exit_code
    fi
    
    echo "✅ Agent type '$agent_type' added successfully"
    echo "💡 Don't forget to create: $PROMPTS_DIR/${agent_type}_agent.md"
    return 0
}

# Remove agent type from configuration
remove_agent_type() {
    local agent_type="$1"
    
    if [[ -z "$agent_type" ]]; then
        echo "❌ Usage: remove_agent_type <type>"
        return 1
    fi
    
    echo "🗑️ Removing agent type: $agent_type"
    
    local result
    remove_agent_type "$agent_type" "$AGENTS_CONFIG_FILE"
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        case $exit_code in
            3) echo "❌ Agent type '$agent_type' does not exist" ;;
            *) echo "❌ Failed to remove agent type (error code: $exit_code)" ;;
        esac
        return $exit_code
    fi
    
    echo "✅ Agent type '$agent_type' removed successfully"
    return 0
}

# Main function for direct script execution
main() {
    load_config
    
    case "${1:-show}" in
        "load")
            echo "✅ Configuration loaded"
            ;;
        "validate")
            validate_config
            ;;
        "show"|"")
            show_config
            ;;
        "agents")
            echo "Available agent types:"
            get_agent_types | sed 's/^/  • /'
            ;;
        "agent")
            get_agent_info "$2"
            ;;
        "validation")
            get_agent_validation_commands "$2"
            ;;
        "profiles")
            echo "Available validation profiles:"
            get_validation_profiles | sed 's/^/  • /'
            ;;
        "profile")
            get_validation_commands "$2"
            ;;
        "phase")
            get_phase_info "$2"
            ;;
        "capability")
            echo "Agents with capability '$2':"
            get_agents_by_capability "$2" | sed 's/^/  • /'
            ;;
        "add-agent")
            add_agent_type "$2" "$3" "$4" "$5" "$6" "$7"
            ;;
        "remove-agent")
            remove_agent_type "$2"
            ;;
        *)
            echo "Usage: $0 [load|validate|show|agents|agent <type>|validation <type>|profiles|profile <name>|phase <number>|capability <name>|add-agent <type> <name> [desc] [tech] [cap] [validation]|remove-agent <type>]"
            exit 1
            ;;
    esac
}

# Allow script to be sourced or executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
else
    load_config
fi