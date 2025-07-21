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
    --help              Show this help message

EXAMPLES:
    $0                           # Install latest version to default location
    $0 --version v1.0.0         # Install specific version
    $0 --prefix ~/agent-conductor # Install to custom location

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
    
    # Copy documentation
    if [ -d "${extracted_dir}/docs" ]; then
        cp -r "${extracted_dir}/docs" "$install_dir/" || {
            print_error "Failed to copy docs directory"
            exit 1
        }
    fi
    
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
# Agent Conductor wrapper script
CONDUCTOR_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
    print_info "Version: ${VERSION}"
    print_info "Install prefix: ${PREFIX}"
    echo ""
    
    # Detect platform
    PLATFORM=$(detect_platform)
    print_info "Detected platform: ${PLATFORM}"
    
    # Check dependencies
    check_dependencies
    
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
    
    # Validate installation
    if validate_installation "$PREFIX"; then
        echo ""
        print_success "Agent Conductor has been installed successfully!"
        echo ""
        print_info "Installation directory: ${PREFIX}"
        print_info "To use agent-conductor, add the following to your PATH:"
        echo "    export PATH=\"${PREFIX}/bin:\$PATH\""
        echo ""
        print_info "You can add this line to your shell configuration file:"
        case "$SHELL" in
            */bash)
                echo "    echo 'export PATH=\"${PREFIX}/bin:\$PATH\"' >> ~/.bashrc"
                ;;
            */zsh)
                echo "    echo 'export PATH=\"${PREFIX}/bin:\$PATH\"' >> ~/.zshrc"
                ;;
            *)
                echo "    Add to your shell's configuration file"
                ;;
        esac
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_info "🚀 NEXT STEPS:"
        echo ""
        echo "1. Copy the orchestration framework to your project:"
        echo "   cp -r ${PREFIX}/orchestration /path/to/your/project/"
        echo ""
        echo "2. Navigate to your project and configure:"
        echo "   cd /path/to/your/project/orchestration"
        echo "   cp config/project.example.yml config/project.yml"
        echo "   cp config/agents.example.yml config/agents.yml"
        echo "   # Edit these files with your project details"
        echo ""
        echo "3. Initialize and deploy agents:"
        echo "   ./scripts/core/orchestrator.sh init      # Initialize the system"
        echo "   ./scripts/core/orchestrator.sh validate  # Validate configuration"
        echo "   ./scripts/core/orchestrator.sh deploy backend 123  # Deploy an agent"
        echo ""
        echo "4. Or use the conductor command (after adding to PATH):"
        echo "   conductor init"
        echo "   conductor validate"
        echo "   conductor deploy backend 123"
        echo ""
        print_info "📚 For detailed documentation, see:"
        echo "   ${PREFIX}/docs/"
        echo "   ${PREFIX}/orchestration/README.md"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    else
        print_error "Installation validation failed"
        print_info "Please check the error messages above and try again"
        exit 1
    fi
}

# Run main function
main "$@"