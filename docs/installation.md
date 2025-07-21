# Agent Conductor Installation Guide

Agent Conductor is a configuration-driven orchestration framework for managing multiple AI agents. This guide will help you install Agent Conductor on your system.

## Quick Start

### One-Line Install (Coming Soon)

Once we have our first release published, you'll be able to install with:

```bash
curl -sSL https://github.com/<YOUR_GITHUB_USER>/agent-conductor/releases/latest/download/install.sh | bash
```

### Manual Installation

1. **Download the latest release:**
   ```bash
   # Download the release archive
   curl -LO https://github.com/<YOUR_GITHUB_USER>/agent-conductor/releases/download/v0.0.1/agent-conductor-v0.0.1.tar.gz
   
   # Download the installer script
   curl -LO https://github.com/<YOUR_GITHUB_USER>/agent-conductor/releases/download/v0.0.1/install.sh
   chmod +x install.sh
   ```

2. **Run the installer:**
   ```bash
   ./install.sh
   ```

## Installation Options

The installer supports several command-line options:

```bash
./install.sh [OPTIONS]

Options:
  --version VERSION    Install specific version (default: latest)
  --prefix PATH        Installation directory (default: /usr/local/agent-conductor)
  --skip-deps          Skip dependency checks
  --help               Show this help message
```

### Examples

Install to a custom location:
```bash
./install.sh --prefix ~/my-tools/agent-conductor
```

Install a specific version:
```bash
./install.sh --version v0.0.1
```

## System Requirements

### Supported Platforms
- **macOS**: 10.15 (Catalina) or later
- **Linux**: Ubuntu 20.04+, CentOS 8+, Debian 11+ (coming soon)

### Dependencies
- **Required:**
  - Bash 4.0 or later
  - tmux 2.0 or later
- **Optional:**
  - yq (for YAML processing)

### Installing Dependencies

#### macOS
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required dependencies
brew install bash tmux

# Install optional dependencies
brew install yq
```

#### Linux (Ubuntu/Debian)
```bash
# Update package list
sudo apt update

# Install required dependencies
sudo apt install -y bash tmux

# Install optional dependencies
sudo apt install -y yq
```

## Post-Installation Setup

After installation, you need to add Agent Conductor to your PATH:

### Bash
Add to `~/.bashrc`:
```bash
export PATH="/usr/local/agent-conductor/bin:$PATH"
```

### Zsh
Add to `~/.zshrc`:
```bash
export PATH="/usr/local/agent-conductor/bin:$PATH"
```

### Fish
Add to `~/.config/fish/config.fish`:
```fish
set -gx PATH /usr/local/agent-conductor/bin $PATH
```

Then reload your shell configuration:
```bash
source ~/.bashrc  # or ~/.zshrc for Zsh
```

## Verify Installation

After installation, verify that Agent Conductor is working:

```bash
# Check installation
ls -la ~/.local/share/agent-conductor/

# Navigate to your project directory
cd /path/to/your/project

# Copy the orchestration framework
cp -r ~/.local/share/agent-conductor/orchestration .

# Initialize the orchestrator
./orchestration/scripts/core/orchestrator.sh init

# Check status
./orchestration/scripts/core/orchestrator.sh status
```

## Troubleshooting

### Permission Denied
If you get permission errors during installation:
```bash
# Install to a custom user directory
./install.sh --prefix ~/my-tools/agent-conductor

# Note: Default location (~/.local/share/agent-conductor) should not require sudo
```

### Command Not Found
If `orchestrator.sh` is not found:
1. Ensure the installation completed successfully
2. Check that the PATH is correctly set
3. Reload your shell configuration

### Dependency Issues
If dependencies are missing:
```bash
# Check bash version
bash --version

# Check tmux version
tmux -V

# Install missing dependencies using the commands above
```

## Uninstallation

To remove Agent Conductor:

```bash
# Remove the installation directory
rm -rf ~/.local/share/agent-conductor

# Remove symlink
rm -f ~/.local/bin/agent-conductor

# Remove from PATH (if you added it manually)
# Edit your shell configuration file and remove any agent-conductor PATH entries
```

## Next Steps

- [Quick Start Guide](../README.md#quick-start)
- [Configuration Guide](../orchestration/README.md#configuration)
- [Agent Management](../orchestration/README.md#commands-reference)

## Support

If you encounter issues:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review the [System Requirements](#system-requirements)
3. Open an issue on [GitHub](https://github.com/<YOUR_GITHUB_USER>/agent-conductor/issues)