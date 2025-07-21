#!/bin/bash

# List Available AI Agents - Shows all configured agent types
# Displays agent configuration details including status and capabilities

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Only load dependencies if running directly (not in test mode)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Source libraries
    source "$SCRIPT_DIR/../lib/config_lib.sh" || {
        echo "❌ Failed to load configuration library"
        exit 1
    }

    source "$SCRIPT_DIR/../lib/session_lib.sh" || {
        echo "❌ Failed to load session library"
        exit 1
    }

    # Load configuration
    if ! load_full_configuration "$SCRIPT_DIR"; then
        echo "❌ Failed to load configuration"
        exit 1
    fi
fi

# Function to get agent emoji based on type
get_agent_emoji() {
    local agent_type="$1"
    case "$agent_type" in
        backend) echo "🦀" ;;
        frontend) echo "📱" ;;
        devops) echo "🚀" ;;
        qa) echo "🧪" ;;
        pm) echo "📋" ;;
        docs) echo "📚" ;;
        mobile) echo "📱" ;;
        data) echo "📊" ;;
        security) echo "🔒" ;;
        *) echo "🤖" ;;
    esac
}

# Function to get agent purpose based on type
get_agent_purpose() {
    local agent_type="$1"
    case "$agent_type" in
        backend) echo "Backend API and business logic" ;;
        frontend) echo "Frontend development and UI components" ;;
        devops) echo "Infrastructure and deployment" ;;
        qa) echo "Testing and quality assurance" ;;
        pm) echo "Project coordination and planning" ;;
        docs) echo "Documentation and guides" ;;
        mobile) echo "Mobile app development" ;;
        data) echo "Data processing and analytics" ;;
        security) echo "Security and compliance" ;;
        *) echo "Specialized development tasks" ;;
    esac
}

# Function to get suggested next tasks based on type
get_next_tasks() {
    local agent_type="$1"
    case "$agent_type" in
        backend) echo "Core service implementations" ;;
        frontend) echo "UI component implementations" ;;
        devops) echo "CI/CD pipeline setup" ;;
        qa) echo "Test suite development" ;;
        pm) echo "Sprint planning" ;;
        docs) echo "API documentation" ;;
        mobile) echo "Mobile UI development" ;;
        data) echo "Data pipeline setup" ;;
        security) echo "Security audit" ;;
        *) echo "Available for assignment" ;;
    esac
}

# Function to check if agent is currently deployed or needs configuration
get_agent_status() {
    local agent_type="$1"
    local project_name="$2"
    
    # Check if agent needs customization
    local agent_info
    agent_info=$(get_agent_info "$agent_type" 2>/dev/null)
    
    if echo "$agent_info" | grep -q "YourBackendLang\|YourFrontendTech\|YourCloudProvider"; then
        echo "Template (needs customization)"
        return 2
    fi
    
    # Check if tmux server is running
    if ! check_tmux_server_running >/dev/null 2>&1; then
        echo "Configured, Idle"
        return 1
    fi
    
    # Check if agent session exists
    local session_name="${project_name}-${agent_type}"
    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Deployed"
        return 0
    else
        echo "Configured, Idle" 
        return 1
    fi
}

# Main function to display available agents
display_available_agents() {
    local project_name="$1"
    
    echo "🤖 Available Agent Types"
    echo "========================"
    echo ""
    
    # Get all configured agent types
    local agent_types
    agent_types=$(get_agent_types "$AGENTS_CONFIG_FILE")
    
    if [[ -z "$agent_types" ]]; then
        echo "❌ No agent types configured"
        return 1
    fi
    
    # Display each agent type
    while IFS= read -r agent_type; do
        [[ -z "$agent_type" ]] && continue
        
        local emoji
        local name
        local status
        local purpose
        local next_tasks
        
        emoji=$(get_agent_emoji "$agent_type")
        # Extract name and description directly from config files
        local agent_config_file="$ORCHESTRATION_DIR/agents/$agent_type/config.yml"
        if [[ -f "$agent_config_file" ]]; then
            name=$(yq '.name' "$agent_config_file" 2>/dev/null | sed 's/^"//;s/"$//' || echo "${agent_type^} Agent")
            purpose=$(yq '.description' "$agent_config_file" 2>/dev/null | sed 's/^"//;s/"$//' || get_agent_purpose "$agent_type")
        else
            name="${agent_type^} Agent"
            purpose=$(get_agent_purpose "$agent_type")
        fi
        status=$(get_agent_status "$agent_type" "$project_name")
        next_tasks=$(get_next_tasks "$agent_type")
        
        # Display agent information
        echo "$emoji $agent_type ($name)"
        echo "   Status: $status"
        echo "   Purpose: $purpose"
        echo "   Next: $next_tasks"
        echo ""
        
    done <<< "$agent_types"
    
    echo "⚙️  Configuration:"
    echo "   To customize templates: edit orchestration/agents/<agent-type>/config.yml"
    echo "   To customize prompts: edit orchestration/agents/<agent-type>/prompt.md"
    echo ""
    echo "💡 Usage:"
    echo "   ./orchestration/scripts/core/orchestrator.sh deploy <agent-type> <task-id>"
    echo "   ./orchestration/scripts/core/orchestrator.sh list"
    echo ""
}

# Only execute main function if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    display_available_agents "$PROJECT_NAME"
fi