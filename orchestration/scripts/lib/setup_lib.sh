#!/bin/bash

# Setup Library - Testable project setup functions
# Provides new project initialization and configuration functionality

# Dependency injection for external commands (allows mocking in tests)
CP_CMD="${CP_CMD:-cp}"
RM_CMD="${RM_CMD:-rm}"
MKDIR_CMD="${MKDIR_CMD:-mkdir}"
ECHO_CMD="${ECHO_CMD:-echo}"
READ_CMD="${READ}"
DIRNAME_CMD="${DIRNAME_CMD:-dirname}"
BASENAME_CMD="${BASENAME_CMD:-basename}"
PWD_CMD="${PWD_CMD:-pwd}"
CD_CMD="${CD_CMD:-cd}"

# Error message functions
get_setup_error_message() {
    local error_code="$1"
    case "$error_code" in
        1) echo "Missing project directory parameter" ;;
        2) echo "Project directory does not exist" ;;
        3) echo "Failed to copy orchestration system" ;;
        4) echo "Failed to setup configuration templates" ;;
        5) echo "Failed to create project structure" ;;
        6) echo "Failed to cleanup source project data" ;;
        7) echo "Orchestration system already exists" ;;
        8) echo "Cannot access source orchestration directory" ;;
        9) echo "Invalid project directory path" ;;
        10) echo "Permission denied accessing project directory" ;;
        *) echo "Unknown setup error" ;;
    esac
}

# Validation functions
validate_project_directory() {
    local project_dir="$1"
    
    if [[ -z "$project_dir" ]]; then
        return 1  # Missing project directory parameter
    fi
    
    # Check if the path is valid (not just empty or whitespace)
    if [[ ! "$project_dir" =~ ^[[:space:]]*$ ]] && [[ "$project_dir" != "." ]]; then
        # Path seems valid, check if it exists
        if [[ ! -d "$project_dir" ]]; then
            return 2  # Project directory does not exist
        fi
        
        # Test write access
        if ! touch "$project_dir/.setup_test" 2>/dev/null; then
            return 10  # Permission denied accessing project directory
        fi
        
        # Clean up test file
        $RM_CMD -f "$project_dir/.setup_test" 2>/dev/null
        
        return 0  # Valid directory
    else
        return 9  # Invalid project directory path
    fi
}

validate_source_orchestration() {
    local source_dir="$1"
    
    if [[ -z "$source_dir" ]]; then
        return 1  # Missing source directory
    fi
    
    if [[ ! -d "$source_dir" ]]; then
        return 8  # Cannot access source orchestration directory
    fi
    
    # Check if essential directories exist
    if [[ ! -d "$source_dir/scripts" ]] || [[ ! -d "$source_dir/config" ]] || [[ ! -d "$source_dir/templates" ]]; then
        return 8  # Source directory missing essential components
    fi
    
    return 0
}

check_orchestration_exists() {
    local project_dir="$1"
    
    if [[ -d "$project_dir/orchestration" ]]; then
        return 7  # Orchestration system already exists
    fi
    
    return 0  # No existing orchestration
}

# Core setup functions
copy_orchestration_system() {
    local source_dir="$1"
    local target_dir="$2"
    local overwrite="${3:-false}"
    
    # Validate source
    validate_source_orchestration "$source_dir"
    local error_code=$?
    if [[ $error_code -ne 0 ]]; then
        return $error_code
    fi
    
    # Validate target
    validate_project_directory "$target_dir"
    error_code=$?
    if [[ $error_code -ne 0 ]]; then
        return $error_code
    fi
    
    # Check if orchestration already exists
    if ! check_orchestration_exists "$target_dir"; then
        if [[ "$overwrite" != "true" ]]; then
            return 7  # Orchestration system already exists
        fi
        # Remove existing orchestration if overwrite is true
        $RM_CMD -rf "$target_dir/orchestration" 2>/dev/null
    fi
    
    # Copy the orchestration system
    if ! $CP_CMD -r "$source_dir" "$target_dir/orchestration" 2>/dev/null; then
        return 3  # Failed to copy orchestration system
    fi
    
    return 0
}

setup_configuration_templates() {
    local project_dir="$1"
    local project_name="${2:-}"
    
    if [[ -z "$project_dir" ]]; then
        return 1  # Missing project directory parameter
    fi
    
    local orchestration_dir="$project_dir/orchestration"
    
    if [[ ! -d "$orchestration_dir" ]]; then
        return 5  # Orchestration directory missing
    fi
    
    # Remove any existing config files
    $RM_CMD -f "$orchestration_dir/config/project.yml" 2>/dev/null
    $RM_CMD -f "$orchestration_dir/config/agents.yml" 2>/dev/null
    
    # Copy templates to config
    if [[ -f "$orchestration_dir/templates/project.example.yml" ]]; then
        if ! $CP_CMD "$orchestration_dir/templates/project.example.yml" "$orchestration_dir/config/project.yml" 2>/dev/null; then
            return 4  # Failed to setup configuration templates
        fi
    fi
    
    if [[ -f "$orchestration_dir/templates/agents.example.yml" ]]; then
        if ! $CP_CMD "$orchestration_dir/templates/agents.example.yml" "$orchestration_dir/config/agents.yml" 2>/dev/null; then
            return 4  # Failed to setup configuration templates
        fi
    fi
    
    # If project name is provided, try to update the project config
    if [[ -n "$project_name" ]] && [[ -f "$orchestration_dir/config/project.yml" ]]; then
        # Basic sed replacement for project name (if the config supports it)
        sed -i.bak "s/PROJECT_NAME_PLACEHOLDER/$project_name/g" "$orchestration_dir/config/project.yml" 2>/dev/null || true
        $RM_CMD -f "$orchestration_dir/config/project.yml.bak" 2>/dev/null
    fi
    
    return 0
}

create_project_structure() {
    local project_dir="$1"
    
    if [[ -z "$project_dir" ]]; then
        return 1  # Missing project directory parameter
    fi
    
    local orchestration_dir="$project_dir/orchestration"
    
    # Create essential directories if they don't exist
    local dirs_to_create=(
        "$orchestration_dir/memory"
        "$orchestration_dir/logs"
        "$orchestration_dir/logs/agents"
    )
    
    for dir in "${dirs_to_create[@]}"; do
        if ! $MKDIR_CMD -p "$dir" 2>/dev/null; then
            return 5  # Failed to create project structure
        fi
    done
    
    return 0
}

cleanup_source_project_data() {
    local project_dir="$1"
    
    if [[ -z "$project_dir" ]]; then
        return 1  # Missing project directory parameter
    fi
    
    local orchestration_dir="$project_dir/orchestration"
    
    # Remove memory files from source project
    $RM_CMD -rf "$orchestration_dir/memory/"* 2>/dev/null || true
    
    # Remove log files from source project
    $RM_CMD -rf "$orchestration_dir/logs/"* 2>/dev/null || true
    
    # Create empty .gitkeep files to preserve directory structure
    touch "$orchestration_dir/memory/.gitkeep" 2>/dev/null || true
    touch "$orchestration_dir/logs/.gitkeep" 2>/dev/null || true
    touch "$orchestration_dir/logs/agents/.gitkeep" 2>/dev/null || true
    
    return 0
}

# User interaction functions
prompt_for_overwrite() {
    local project_dir="$1"
    
    echo "⚠️  Orchestration system already exists in $project_dir"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0  # User confirmed overwrite
    else
        return 7  # User declined overwrite
    fi
}

# Complete setup workflow
setup_new_project() {
    local project_dir="$1"
    local source_dir="$2"
    local project_name="${3:-}"
    local interactive="${4:-true}"
    
    # Validate project directory
    validate_project_directory "$project_dir"
    local error_code=$?
    if [[ $error_code -ne 0 ]]; then
        return $error_code
    fi
    
    # Check if orchestration already exists
    if ! check_orchestration_exists "$project_dir"; then
        if [[ "$interactive" == "true" ]]; then
            if ! prompt_for_overwrite "$project_dir"; then
                return 7  # User declined overwrite
            fi
        else
            return 7  # Orchestration already exists, no overwrite in non-interactive mode
        fi
    fi
    
    # Copy orchestration system
    local overwrite="false"
    if [[ "$interactive" == "true" ]] || ! check_orchestration_exists "$project_dir"; then
        overwrite="true"
    fi
    
    if ! copy_orchestration_system "$source_dir" "$project_dir" "$overwrite"; then
        local error_code=$?
        return $error_code
    fi
    
    # Setup configuration templates
    if ! setup_configuration_templates "$project_dir" "$project_name"; then
        local error_code=$?
        return $error_code
    fi
    
    # Create project structure
    if ! create_project_structure "$project_dir"; then
        local error_code=$?
        return $error_code
    fi
    
    # Cleanup source project data
    if ! cleanup_source_project_data "$project_dir"; then
        local error_code=$?
        return $error_code
    fi
    
    return 0
}

# Information and help functions
generate_setup_instructions() {
    local project_dir="$1"
    local project_name="${2:-your-project}"
    
    echo "📝 Next Steps:"
    echo ""
    echo "1. 🔧 Configure for your project:"
    echo "   cd $project_dir/orchestration"
    echo "   # Edit config/project.yml and config/agents.yml with your project details"
    echo ""
    echo "2. 🛠️  Install dependencies:"
    echo "   brew install tmux yq  # macOS"
    echo "   # or apt-get install tmux yq  # Ubuntu"
    echo ""
    echo "3. 🚀 Initialize and start:"
    echo "   ./scripts/orchestrator.sh validate"
    echo "   ./scripts/orchestrator.sh init"
    echo "   ./scripts/orchestrator.sh deploy <agent-type> <task-id>"
    echo ""
    echo "4. 📋 Key files to customize:"
    echo "   - config/project.yml (project-specific settings)"
    echo "   - config/agents.yml (agent types and validation)"
    echo "   - prompts/*.md (agent instructions)"
    echo ""
    echo "🔗 Documentation: orchestration/README.md"
    echo ""
    echo "Happy orchestrating! 🤖"
}

show_setup_help() {
    local script_name="$1"
    
    echo "🤖 AI Agent Orchestration - New Project Setup"
    echo "=============================================="
    echo ""
    echo "Usage: $script_name <project-directory> [project-name]"
    echo ""
    echo "Arguments:"
    echo "  project-directory    Path to the target project directory"
    echo "  project-name        Optional name for the project (used in config)"
    echo ""
    echo "Example: $script_name /path/to/my-new-project MyProject"
    echo ""
    echo "This script will:"
    echo "  1. Copy orchestration system to your project"
    echo "  2. Create configuration template"
    echo "  3. Set up directory structure"
    echo "  4. Provide setup instructions"
}

# Utility functions
get_current_orchestration_dir() {
    local script_path="$1"
    
    # Get the directory of the calling script, then go up to orchestration root
    local script_dir
    script_dir=$($DIRNAME_CMD "$script_path")
    local orchestration_dir
    orchestration_dir=$($DIRNAME_CMD "$script_dir")
    
    # Convert to absolute path
    $CD_CMD "$orchestration_dir" && $PWD_CMD
}

extract_project_name_from_path() {
    local project_dir="$1"
    
    # Extract the last component of the path as a default project name
    $BASENAME_CMD "$project_dir"
}

# Validation helper for setup process
validate_setup_requirements() {
    local missing_tools=()
    
    # Check for required commands
    if ! command -v cp &> /dev/null; then
        missing_tools+=("cp")
    fi
    
    if ! command -v rm &> /dev/null; then
        missing_tools+=("rm")
    fi
    
    if ! command -v mkdir &> /dev/null; then
        missing_tools+=("mkdir")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "Missing required tools: ${missing_tools[*]}"
        return 1
    fi
    
    return 0
}

# Status functions
show_setup_progress() {
    local step="$1"
    local total_steps="$2"
    local description="$3"
    
    echo "[$step/$total_steps] $description"
}

verify_setup_completion() {
    local project_dir="$1"
    
    local orchestration_dir="$project_dir/orchestration"
    
    # Check if essential components exist
    local required_items=(
        "$orchestration_dir/scripts"
        "$orchestration_dir/config/project.yml"
        "$orchestration_dir/config/agents.yml"
        "$orchestration_dir/memory"
        "$orchestration_dir/logs"
    )
    
    for item in "${required_items[@]}"; do
        if [[ ! -e "$item" ]]; then
            echo "Missing: $item"
            return 1
        fi
    done
    
    echo "✅ Setup verification passed"
    return 0
}