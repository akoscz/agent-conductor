#!/usr/bin/env bash
#
# Agent Conductor Installation Script
# This script installs agent-conductor from GitHub releases
#

set -euo pipefail

# Default values
VERSION="latest"
PREFIX="${HOME}/.local/share/agent-conductor"
SKIP_DEPS=false
INTERACTIVE=true
LOCAL_INSTALL=false
# GitHub repository - this will be set automatically during release
# For manual use, set GITHUB_REPOSITORY environment variable
GITHUB_REPO="${GITHUB_REPOSITORY:-"akoscz/agent-conductor"}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored output
print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1" >&2
}

# Show usage information
show_help() {
    cat << EOF
Agent Conductor Installer

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --version VERSION    Install specific version (default: latest)
    --prefix PATH        Installation directory (default: ~/.local/share/agent-conductor)
    --skip-deps         Skip dependency checks
    --non-interactive   Skip interactive prompts, use defaults
    --local             Install from current directory instead of GitHub
    --help              Show this help message

EXAMPLES:
    $0                           # Install latest version from GitHub
    $0 --version v1.0.0         # Install specific version
    $0 --prefix ~/agent-conductor # Install to custom location
    $0 --local                  # Install from current directory

EOF
}

# Detect platform
detect_platform() {
    local platform=""
    local arch=""
    
    case "$(uname -s)" in
        Darwin*)
            platform="darwin"
            ;;
        Linux*)
            platform="linux"
            ;;
        *)
            print_error "Unsupported platform: $(uname -s)"
            print_error "Agent Conductor currently supports macOS and Linux only"
            exit 1
            ;;
    esac
    
    case "$(uname -m)" in
        x86_64)
            arch="amd64"
            ;;
        arm64|aarch64)
            arch="arm64"
            ;;
        *)
            print_error "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
    
    echo "${platform}-${arch}"
}

# Check for required dependencies
check_dependencies() {
    if [ "$SKIP_DEPS" = true ]; then
        print_info "Skipping dependency checks"
        return 0
    fi
    
    print_info "Checking dependencies..."
    
    local missing_deps=()
    
    # Check for tmux
    if ! command -v tmux &> /dev/null; then
        missing_deps+=("tmux")
    fi
    
    # Check for bash (should always be present, but let's be thorough)
    if ! command -v bash &> /dev/null; then
        missing_deps+=("bash")
    fi
    
    # Check bash version (require 3.2+)
    local bash_version=$(bash --version | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1)
    local major_version=$(echo "$bash_version" | cut -d. -f1)
    local minor_version=$(echo "$bash_version" | cut -d. -f2)
    
    if [ "$major_version" -lt 3 ] || ([ "$major_version" -eq 3 ] && [ "$minor_version" -lt 2 ]); then
        print_error "Bash version 3.2 or higher is required (found: $bash_version)"
        missing_deps+=("bash>=3.2")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_info "Please install the missing dependencies and try again"
        print_info "Or use --skip-deps to skip this check (not recommended)"
        exit 1
    fi
    
    print_success "All dependencies satisfied"
}

# Get installation directory from user
get_install_directory() {
    if [ "$INTERACTIVE" = false ]; then
        return 0
    fi
    
    echo ""
    print_info "Where would you like to install Agent Conductor?"
    print_info "Default: ${HOME}/.local/share/agent-conductor"
    read -p "Installation directory (press Enter for default): " user_dir
    
    if [[ -n "$user_dir" ]]; then
        # Expand ~ to home directory
        PREFIX="${user_dir/#\~/$HOME}"
        # Make path absolute
        if [[ ! "$PREFIX" = /* ]]; then
            PREFIX="$PWD/$PREFIX"
        fi
    fi
    
    # Confirm with user
    print_info "Installing to: ${PREFIX}"
    read -p "Continue? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
        print_error "Installation cancelled"
        exit 1
    fi
}

# Get the download URL for the release
get_download_url() {
    local version="$1"
    local platform="$2"
    
    # If version is "latest", fetch the actual version tag
    if [ "$version" = "latest" ]; then
        local api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
        local actual_version=$(curl -s "$api_url" | grep '"tag_name":' | cut -d'"' -f4)
        if [ -z "$actual_version" ]; then
            print_error "Failed to fetch latest version from GitHub"
            return 1
        fi
        version="$actual_version"
    fi
    
    # Construct asset name based on platform
    # For now, we use universal archives
    # TODO: Switch to platform-specific archives in future releases
    local asset_name="agent-conductor-${version}.tar.gz"
    
    echo "https://github.com/${GITHUB_REPO}/releases/download/${version}/${asset_name}"
}

# Download release from GitHub
download_release() {
    local version="$1"
    local platform="$2"
    local temp_dir="$3"
    
    print_info "Downloading agent-conductor ${version} for ${platform}..."
    
    local download_url=$(get_download_url "$version" "$platform")
    local archive_path="${temp_dir}/agent-conductor.tar.gz"
    
    # Download the release
    if command -v curl &> /dev/null; then
        curl -L -o "$archive_path" "$download_url" || {
            print_error "Failed to download release from: $download_url"
            exit 1
        }
    elif command -v wget &> /dev/null; then
        wget -O "$archive_path" "$download_url" || {
            print_error "Failed to download release from: $download_url"
            exit 1
        }
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    print_success "Download complete"
    echo "$archive_path"
}

# Install from local directory
install_from_local() {
    local source_dir="$1"
    local install_dir="$2"
    
    print_info "Installing from local directory: $source_dir"
    
    # Verify we're in an agent-conductor repository
    if [ ! -f "$source_dir/orchestration/scripts/core/orchestrator.sh" ]; then
        print_error "Current directory doesn't appear to be an agent-conductor repository"
        print_error "Missing: orchestration/scripts/core/orchestrator.sh"
        exit 1
    fi
    
    # Create installation directory
    if [ ! -d "$install_dir" ]; then
        mkdir -p "$install_dir" || {
            print_error "Failed to create installation directory: $install_dir"
            exit 1
        }
    fi
    
    # Copy orchestration framework
    print_info "Copying orchestration framework..."
    cp -r "$source_dir/orchestration" "$install_dir/" || {
        print_error "Failed to copy orchestration directory"
        exit 1
    }
    
    # Don't copy docs folder - only orchestration docs are distributed
    
    # Copy other files
    for file in README.md LICENSE VERSION; do
        if [ -f "$source_dir/$file" ]; then
            cp "$source_dir/$file" "$install_dir/" || true
        fi
    done
    
    
    # Create bin directory and wrapper script
    mkdir -p "${install_dir}/bin"
    cat > "${install_dir}/bin/conductor" << 'EOF'
#!/usr/bin/env bash
# Agent Conductor - Global command wrapper

CONDUCTOR_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Find project root by looking for .agent-conductor directory
find_project_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.agent-conductor" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# Handle init command specially
if [[ "$1" == "init" ]]; then
    # Use provided path or current directory
    init_path="${2:-$PWD}"
    exec "$CONDUCTOR_HOME/orchestration/scripts/setup/init_project.sh" "$init_path"
    exit $?
fi

# Handle help command
if [[ "$1" == "help" ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]] || [[ -z "$1" ]]; then
    # Show help from orchestrator
    exec "$CONDUCTOR_HOME/orchestration/scripts/core/orchestrator.sh" help
    exit $?
fi

# For all other commands, we need to be in a project
if ! project_root=$(find_project_root); then
    echo "Error: Not in an Agent Conductor project"
    echo "Run 'conductor init' to initialize a new project in the current directory"
    echo "Or 'conductor init /path/to/project' to initialize a specific directory"
    exit 1
fi

# Set project context and run orchestrator
export WORKSPACE_DIR="$project_root"
export ORCHESTRATION_DIR="$project_root/.agent-conductor"
exec "$CONDUCTOR_HOME/orchestration/scripts/core/orchestrator.sh" "$@"
EOF
    chmod +x "${install_dir}/bin/conductor"
    
    print_success "Local installation complete"
}

# Extract and install files
install_files() {
    local archive_path="$1"
    local install_dir="$2"
    local temp_dir="$3"
    
    print_info "Installing agent-conductor to ${install_dir}..."
    
    # Create installation directory
    if [ ! -d "$install_dir" ]; then
        mkdir -p "$install_dir" || {
            print_error "Failed to create installation directory: $install_dir"
            print_info "You may need to run this script with sudo"
            exit 1
        }
    fi
    
    # Extract archive
    tar -xzf "$archive_path" -C "$temp_dir" || {
        print_error "Failed to extract archive"
        exit 1
    }
    
    # Find the extracted directory (handles versioned directory names)
    local extracted_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "agent-conductor*" | head -1)
    
    if [ -z "$extracted_dir" ]; then
        # No versioned directory, files might be in temp_dir directly
        extracted_dir="$temp_dir"
    fi
    
    # Copy orchestration framework
    if [ -d "${extracted_dir}/orchestration" ]; then
        cp -r "${extracted_dir}/orchestration" "$install_dir/" || {
            print_error "Failed to copy orchestration directory"
            exit 1
        }
    fi
    
    # Don't copy docs folder - only orchestration docs are distributed
    
    # Copy other files
    for file in README.md LICENSE VERSION; do
        if [ -f "${extracted_dir}/${file}" ]; then
            cp "${extracted_dir}/${file}" "$install_dir/" || true
        fi
    done
    
    
    # Create bin directory and wrapper script
    mkdir -p "${install_dir}/bin"
    cat > "${install_dir}/bin/conductor" << 'EOF'
#!/usr/bin/env bash
# Agent Conductor - Global command wrapper

CONDUCTOR_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Find project root by looking for .agent-conductor directory
find_project_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.agent-conductor" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# Handle init command specially
if [[ "$1" == "init" ]]; then
    # Use provided path or current directory
    init_path="${2:-$PWD}"
    exec "$CONDUCTOR_HOME/orchestration/scripts/setup/init_project.sh" "$init_path"
    exit $?
fi

# Handle help command
if [[ "$1" == "help" ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]] || [[ -z "$1" ]]; then
    # Show help from orchestrator
    exec "$CONDUCTOR_HOME/orchestration/scripts/core/orchestrator.sh" help
    exit $?
fi

# For all other commands, we need to be in a project
if ! project_root=$(find_project_root); then
    echo "Error: Not in an Agent Conductor project"
    echo "Run 'conductor init' to initialize a new project in the current directory"
    echo "Or 'conductor init /path/to/project' to initialize a specific directory"
    exit 1
fi

# Set project context and run orchestrator
export WORKSPACE_DIR="$project_root"
export ORCHESTRATION_DIR="$project_root/.agent-conductor"
exec "$CONDUCTOR_HOME/orchestration/scripts/core/orchestrator.sh" "$@"
EOF
    chmod +x "${install_dir}/bin/conductor"
    
    print_success "Files installed successfully"
}

# Validate installation
validate_installation() {
    local install_dir="$1"
    
    print_info "Validating installation..."
    
    # Check if main executable exists
    if [ ! -f "${install_dir}/bin/conductor" ]; then
        print_error "Main executable not found at ${install_dir}/bin/conductor"
        return 1
    fi
    
    # Check if executable permissions are set
    if [ ! -x "${install_dir}/bin/conductor" ]; then
        print_error "Main executable is not executable"
        return 1
    fi
    
    # Try to run version command (if implemented)
    # "${install_dir}/bin/conductor" --version &>/dev/null || {
    #     print_error "Failed to run conductor executable"
    #     return 1
    # }
    
    print_success "Installation validated successfully"
    return 0
}

# Setup shell aliases
setup_shell_alias() {
    local install_dir="$1"
    
    if [ "$INTERACTIVE" = false ]; then
        return 0
    fi
    
    local shell_rc=""
    case "$SHELL" in
        */bash) shell_rc="$HOME/.bashrc" ;;
        */zsh) shell_rc="$HOME/.zshrc" ;;
        *) 
            print_info "Unknown shell: $SHELL"
            return 1
            ;;
    esac
    
    # Remove any existing Agent Conductor aliases (including old names)
    if grep -q "# Agent Conductor aliases\|alias conductor=\|alias cond=\|alias orchestrator=\|alias ac=\|alias orch=" "$shell_rc" 2>/dev/null; then
        print_info "Removing existing Agent Conductor aliases from $shell_rc"
        
        # Remove all Agent Conductor related content
        sed -i.bak '/^# Agent Conductor aliases[[:space:]]*$/d; /^alias conductor=/d; /^alias cond=/d; /^alias orchestrator=/d; /^alias ac=/d; /^alias orch=/d' "$shell_rc"
        rm -f "$shell_rc.bak"
    fi
    
    # Add aliases with proper spacing (only add blank line if file doesn't end with one)
    if [[ -s "$shell_rc" ]] && [[ $(tail -c1 "$shell_rc" 2>/dev/null | wc -l) -eq 0 ]]; then
        echo "" >> "$shell_rc"
    fi
    echo "# Agent Conductor aliases" >> "$shell_rc"
    echo "alias conductor='${install_dir}/bin/conductor'" >> "$shell_rc"
    echo "alias cond='${install_dir}/bin/conductor'  # Short alias" >> "$shell_rc"
    
    print_success "Added shell aliases: 'conductor' and 'cond'"
    return 0
}

# Main installation process
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --version)
                VERSION="$2"
                shift 2
                ;;
            --prefix)
                PREFIX="$2"
                shift 2
                ;;
            --skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            --non-interactive)
                INTERACTIVE=false
                shift
                ;;
            --local)
                LOCAL_INSTALL=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Print installation banner
    echo "======================================"
    echo "  Agent Conductor Installation Script"
    echo "======================================"
    echo ""
    
    # Check if running from a cloned repo
    if [ -f "./orchestration/scripts/core/orchestrator.sh" ] && [ "$LOCAL_INSTALL" = false ]; then
        print_info "Detected: Running from agent-conductor repository"
        print_info "Tip: Use --local to install from current directory instead of downloading"
        echo ""
    fi
    
    # Get installation directory from user (if interactive)
    get_install_directory
    
    if [ "$LOCAL_INSTALL" = true ]; then
        print_info "Install mode: Local directory"
    else
        print_info "Install mode: GitHub release"
        print_info "Version: ${VERSION}"
    fi
    print_info "Install prefix: ${PREFIX}"
    echo ""
    
    # Check dependencies
    check_dependencies
    
    if [ "$LOCAL_INSTALL" = true ]; then
        # Install from current directory
        CURRENT_DIR="$(pwd)"
        install_from_local "$CURRENT_DIR" "$PREFIX"
    else
        # Detect platform for GitHub download
        PLATFORM=$(detect_platform)
        print_info "Detected platform: ${PLATFORM}"
        
        # Create temporary directory
        TEMP_DIR=$(mktemp -d) || {
            print_error "Failed to create temporary directory"
            exit 1
        }
        
        # Cleanup function
        cleanup() {
            rm -rf "$TEMP_DIR"
        }
        trap cleanup EXIT
        
        # Download release
        ARCHIVE_PATH=$(download_release "$VERSION" "$PLATFORM" "$TEMP_DIR")
        
        # Install files
        install_files "$ARCHIVE_PATH" "$PREFIX" "$TEMP_DIR"
    fi
    
    # Validate installation
    if validate_installation "$PREFIX"; then
        # Setup shell aliases
        setup_shell_alias "$PREFIX"
        
        local shell_rc=""
        case "$SHELL" in
            */bash) shell_rc="~/.bashrc" ;;
            */zsh) shell_rc="~/.zshrc" ;;
            *) shell_rc="your shell's configuration file" ;;
        esac
        
        echo ""
        print_success "Agent Conductor has been installed successfully!"
        echo ""
        print_info "Installation directory: ${PREFIX}"
        
        # Show PATH instructions if aliases weren't set up
        if [ "$INTERACTIVE" = false ] || ! grep -q "alias orchestrator=" "${shell_rc/#\~/$HOME}" 2>/dev/null; then
            print_info "To use agent-conductor, add the following to your PATH:"
            echo "    export PATH=\"${PREFIX}/bin:\$PATH\""
            echo ""
            print_info "Or add these aliases to $shell_rc:"
            echo "    alias conductor='${PREFIX}/bin/conductor'"
            echo "    alias cond='${PREFIX}/bin/conductor'"
        fi
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_info "🚀 QUICK START:"
        echo ""
        echo "1. Reload your shell or run:"
        echo "   source $shell_rc"
        echo ""
        echo "2. Initialize a project:"
        echo "   cd /path/to/your/project"
        echo "   conductor init"
        echo ""
        echo "   Or initialize a specific directory:"
        echo "   conductor init /path/to/project"
        echo ""
        echo "3. Start using Agent Conductor:"
        echo "   conductor validate          # Check configuration"
        echo "   conductor deploy rust 123   # Deploy an agent"
        echo "   conductor list              # List active sessions"
        echo ""
        echo "You can also use 'cond' as a shorter alias for 'conductor'"
        echo ""
        print_info "📚 For detailed documentation, see:"
        echo "   ${PREFIX}/orchestration/README.md"
        echo "   ${PREFIX}/orchestration/USER_GUIDE.md"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    else
        print_error "Installation validation failed"
        print_info "Please check the error messages above and try again"
        exit 1
    fi
}

# Run main function
main "$@"