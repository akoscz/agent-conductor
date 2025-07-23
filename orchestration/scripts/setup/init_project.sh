#!/usr/bin/env bash
#
# Agent Conductor Project Initialization Script
# This script initializes a new Agent Conductor project
#

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONDUCTOR_HOME="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Show usage
show_help() {
    cat << EOF
Agent Conductor Project Initialization

USAGE:
    conductor init [PROJECT_PATH]

ARGUMENTS:
    PROJECT_PATH    Path to initialize project (default: current directory)

DESCRIPTION:
    Initializes a new Agent Conductor project by creating the necessary
    directory structure and configuration files.

EXAMPLES:
    conductor init                    # Initialize current directory
    conductor init /path/to/project   # Initialize specific directory

EOF
}

# Initialize project directory structure
init_project_structure() {
    local project_dir="$1"
    local orchestrator_dir="$project_dir/.agent-conductor"
    
    print_step "Creating project structure in $project_dir"
    
    # Create main orchestrator directory
    mkdir -p "$orchestrator_dir"
    
    # Create subdirectories
    mkdir -p "$orchestrator_dir/config"
    mkdir -p "$orchestrator_dir/agents"
    mkdir -p "$orchestrator_dir/logs/agents"
    mkdir -p "$orchestrator_dir/memory"
    
    # Create .gitignore for logs and memory
    cat > "$orchestrator_dir/.gitignore" << 'EOF'
# Agent logs
logs/

# Agent memory (can contain sensitive data)
memory/

# Local configuration overrides
config/local.yml

# Session state files
*.state
*.session
EOF
    
    print_success "Project structure created"
}

# Copy and customize configuration files
setup_config_files() {
    local project_dir="$1"
    local orchestrator_dir="$project_dir/.agent-conductor"
    local project_name=""
    
    print_step "Setting up configuration files"
    
    # Try to detect project name
    if [ -f "$project_dir/package.json" ]; then
        project_name=$(grep -Po '"name"\s*:\s*"\K[^"]+' "$project_dir/package.json" 2>/dev/null || echo "")
    elif [ -f "$project_dir/Cargo.toml" ]; then
        project_name=$(grep -Po '^name\s*=\s*"\K[^"]+' "$project_dir/Cargo.toml" 2>/dev/null || echo "")
    elif [ -d "$project_dir/.git" ]; then
        project_name=$(basename "$(git -C "$project_dir" rev-parse --show-toplevel 2>/dev/null || echo "$project_dir")")
    else
        project_name=$(basename "$project_dir")
    fi
    
    # Copy project configuration
    if [ -f "$CONDUCTOR_HOME/orchestration/config/project.simple.yml" ]; then
        cp "$CONDUCTOR_HOME/orchestration/config/project.simple.yml" "$orchestrator_dir/config/project.yml"
        
        # Update project name if detected
        if [ -n "$project_name" ]; then
            sed -i.bak "s/name: \"AI Agent Orchestration Demo\"/name: \"$project_name\"/" "$orchestrator_dir/config/project.yml"
            rm "$orchestrator_dir/config/project.yml.bak"
        fi
    fi
    
    # Copy agents configuration
    if [ -f "$CONDUCTOR_HOME/orchestration/config/agents.example.yml" ]; then
        cp "$CONDUCTOR_HOME/orchestration/config/agents.example.yml" "$orchestrator_dir/config/agents.yml"
    fi
    
    print_success "Configuration files created"
}

# Setup default agent types
setup_default_agents() {
    local orchestrator_dir="$1/.agent-conductor"
    
    print_step "Setting up default agent types"
    
    # Create directories for default agent types
    local agent_types=("backend" "frontend" "devops" "qa" "docs" "pm")
    
    for agent_type in "${agent_types[@]}"; do
        local agent_dir="$orchestrator_dir/agents/$agent_type"
        mkdir -p "$agent_dir"
        
        # Copy agent config if exists
        if [ -f "$CONDUCTOR_HOME/orchestration/agents/$agent_type/config.yml" ]; then
            cp "$CONDUCTOR_HOME/orchestration/agents/$agent_type/config.yml" "$agent_dir/"
        fi
        
        # Copy agent prompt if exists
        if [ -f "$CONDUCTOR_HOME/orchestration/agents/$agent_type/prompt.md" ]; then
            cp "$CONDUCTOR_HOME/orchestration/agents/$agent_type/prompt.md" "$agent_dir/"
        fi
    done
    
    print_success "Default agent types configured"
}

# Copy user documentation
copy_user_docs() {
    local orchestrator_dir="$1/.agent-conductor"
    
    print_step "Copying user documentation"
    
    # Copy USER_GUIDE.md if it exists
    if [ -f "$CONDUCTOR_HOME/USER_GUIDE.md" ]; then
        cp "$CONDUCTOR_HOME/USER_GUIDE.md" "$orchestrator_dir/USER_GUIDE.md"
    elif [ -f "$CONDUCTOR_HOME/orchestration/USER_GUIDE.md" ]; then
        cp "$CONDUCTOR_HOME/orchestration/USER_GUIDE.md" "$orchestrator_dir/USER_GUIDE.md"
    fi
    
    # Create a project-specific README
    cat > "$orchestrator_dir/README.md" << EOF
# Agent Conductor Project

This directory contains the Agent Conductor configuration and data for this project.

## Structure

- \`config/\` - Project and agent configuration files
- \`agents/\` - Agent-specific prompts and settings
- \`logs/\` - Agent session logs (gitignored)
- \`memory/\` - Shared context between agents (gitignored)

## Quick Start

1. Review and customize your configuration:
   - \`config/project.yml\` - Project settings
   - \`config/agents.yml\` - Agent definitions

2. Validate your configuration:
   \`\`\`bash
   conductor validate
   \`\`\`

3. Deploy an agent:
   \`\`\`bash
   conductor deploy backend 123
   \`\`\`

## Documentation

- See \`USER_GUIDE.md\` for detailed usage instructions
- Run \`conductor help\` for command reference

EOF
    
    print_success "Documentation copied"
}

# Create initialization marker
create_init_marker() {
    local orchestrator_dir="$1/.agent-conductor"
    
    # Create initialization marker with metadata
    cat > "$orchestrator_dir/.initialized" << EOF
# Agent Conductor Project
# Initialized: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
# Version: $(cat "$CONDUCTOR_HOME/VERSION" 2>/dev/null || echo "unknown")
# Installation: $CONDUCTOR_HOME
EOF
}

# Main initialization process
main() {
    # Parse arguments
    local project_path="${1:-$PWD}"
    
    # Handle help
    if [[ "$project_path" == "--help" ]] || [[ "$project_path" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    # Make path absolute
    if [[ ! "$project_path" = /* ]]; then
        project_path="$PWD/$project_path"
    fi
    
    # Normalize path
    project_path=$(cd "$project_path" 2>/dev/null && pwd) || {
        print_error "Invalid project path: $project_path"
        exit 1
    }
    
    echo "======================================"
    echo "  Agent Conductor Project Initialization"
    echo "======================================"
    echo ""
    print_info "Project path: $project_path"
    echo ""
    
    # Check if already initialized
    if [ -d "$project_path/.agent-conductor" ]; then
        print_error "Project already initialized!"
        echo ""
        print_info "⚠️  WARNING: Reinitializing will DELETE all existing configuration and data:"
        echo "   • Project and agent configurations"
        echo "   • Agent-specific prompts and settings"
        echo "   • Session logs and memory files"
        echo "   • Any customizations you've made"
        echo ""
        print_info "🔄 To reinitialize (DESTRUCTIVE):"
        echo "    rm -rf $project_path/.agent-conductor"
        echo "    conductor init"
        echo ""
        print_info "💾 To preserve existing configuration:"
        echo "    # Backup your current configuration"
        echo "    cp -r $project_path/.agent-conductor $project_path/.agent-conductor.backup"
        echo "    # Then reinitialize if needed"
        echo "    rm -rf $project_path/.agent-conductor"
        echo "    conductor init"
        echo "    # Manually merge desired settings from backup"
        exit 1
    fi
    
    # Initialize project
    init_project_structure "$project_path"
    setup_config_files "$project_path"
    setup_default_agents "$project_path"
    copy_user_docs "$project_path"
    create_init_marker "$project_path"
    
    echo ""
    print_success "Project initialized successfully!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "🚀 NEXT STEPS:"
    echo ""
    echo "1. Review and customize configuration:"
    echo "   cd $project_path"
    echo "   edit .agent-conductor/config/project.yml"
    echo "   edit .agent-conductor/config/agents.yml"
    echo ""
    echo "2. Validate your configuration:"
    echo "   conductor validate"
    echo ""
    echo "3. Deploy your first agent:"
    echo "   conductor deploy backend 123"
    echo ""
    echo "4. View available commands:"
    echo "   conductor help"
    echo ""
    print_info "📚 Configuration files:"
    echo "   .agent-conductor/config/project.yml  - Project settings"
    echo "   .agent-conductor/config/agents.yml   - Agent definitions"
    echo "   .agent-conductor/agents/*/           - Agent-specific configs"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Run main function
main "$@"