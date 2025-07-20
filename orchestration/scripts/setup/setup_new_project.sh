#!/bin/bash

# AI Agent Orchestration - New Project Setup Script (Thin CLI wrapper)
# Sets up orchestration system for a new project using setup library

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source setup library
source "$SCRIPT_DIR/../lib/setup_lib.sh" || {
    echo "❌ Failed to load setup library"
    exit 1
}

PROJECT_DIR="$1"
PROJECT_NAME="${2:-$(extract_project_name_from_path "$PROJECT_DIR" 2>/dev/null)}"

# Show help if no project directory provided
if [ -z "$PROJECT_DIR" ]; then
    show_setup_help "$0"
    exit 1
fi

# Get the current orchestration directory
CURRENT_DIR="$(get_current_orchestration_dir "${BASH_SOURCE[0]}")"

echo "🚀 Setting up AI Agent Orchestration for new project..."
echo "Source: $CURRENT_DIR"
echo "Target: $PROJECT_DIR"
echo ""

# Validate setup requirements
if ! validate_setup_requirements; then
    echo "❌ Setup requirements not met"
    exit 1
fi

# Setup the new project
setup_new_project "$PROJECT_DIR" "$CURRENT_DIR" "$PROJECT_NAME" "true"
result=$?

case $result in
    0)
        echo "✅ Orchestration system copied successfully!"
        echo ""
        generate_setup_instructions "$PROJECT_DIR" "$PROJECT_NAME"
        
        # Verify setup completion
        if verify_setup_completion "$PROJECT_DIR"; then
            echo ""
            echo "🎉 Setup completed successfully!"
        else
            echo ""
            echo "⚠️  Setup completed with warnings - please verify manually"
        fi
        ;;
    7)
        echo "Setup cancelled."
        exit 0
        ;;
    *)
        echo "❌ $(get_setup_error_message $result)"
        exit 1
        ;;
esac