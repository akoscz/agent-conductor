# Agent Conductor Installation Guide

Agent Conductor is a configuration-driven orchestration framework for managing multiple AI agents. This guide will help you install Agent Conductor on your system.

## Quick Start

### One-Line Install

```bash
curl -sSL https://raw.githubusercontent.com/akoscz/agent-conductor/main/install.sh | bash
```

The installer will:
1. Ask where you want to install Agent Conductor (default: `~/.local/share/agent-conductor`)
2. Install the core scripts and tools
3. Set up shell aliases (`conductor` and `cond`) for easy access
4. Guide you through initializing your first project

**Alternative - Install specific version:**
```bash
# Download installer from specific release
curl -LO https://github.com/akoscz/agent-conductor/releases/download/v0.0.1/install.sh
chmod +x install.sh
./install.sh --version v0.0.1
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
  --prefix PATH        Installation directory (default: ~/.local/share/agent-conductor)
  --skip-deps          Skip dependency checks
  --non-interactive    Skip interactive prompts, use defaults
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

The installer automatically adds shell aliases for you. To start using Agent Conductor:

1. **Reload your shell configuration:**
   ```bash
   source ~/.bashrc  # or ~/.zshrc for Zsh
   ```

2. **Verify the aliases are working:**
   ```bash
   conductor help    # Long form
   cond help        # Short form
   ```

If the aliases weren't added automatically, you can add them manually:

### Bash (~/.bashrc)
```bash
alias conductor='~/.local/share/agent-conductor/bin/conductor'
alias cond='~/.local/share/agent-conductor/bin/conductor'
```

### Zsh (~/.zshrc)
```bash
alias conductor='~/.local/share/agent-conductor/bin/conductor'
alias cond='~/.local/share/agent-conductor/bin/conductor'
```

## Getting Started

### 1. Initialize a New Project

Agent Conductor no longer requires copying files into your project. Simply initialize your project:

```bash
# Navigate to your project directory
cd /path/to/your/project

# Initialize Agent Conductor for this project
conductor init

# Or initialize a specific directory
conductor init /path/to/project
```

This creates a `.agent-conductor` directory with:
- Configuration files (`project.yml`, `agents.yml`)
- Agent-specific prompts and settings
- Logs and memory directories

### 2. Configure Your Project

Edit the configuration files:
```bash
# Project settings
edit .agent-conductor/config/project.yml

# Agent definitions
edit .agent-conductor/config/agents.yml
```

### 3. Validate and Deploy

```bash
# Validate configuration
conductor validate

# Deploy your first agent
conductor deploy backend 123

# List active agents
conductor list
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
If `conductor` or `cond` commands are not found:
1. Ensure the installation completed successfully
2. Reload your shell: `source ~/.bashrc` (or `~/.zshrc`)
3. Check if aliases were added: `grep conductor ~/.bashrc`
4. If not, add them manually as shown in [Post-Installation Setup](#post-installation-setup)

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

# Remove aliases from your shell configuration
# For bash:
sed -i.bak '/# Agent Conductor aliases/,+2d' ~/.bashrc

# For zsh:
sed -i.bak '/# Agent Conductor aliases/,+2d' ~/.zshrc

# Remove any project-specific .agent-conductor directories
# (in each project where you initialized Agent Conductor)
rm -rf /path/to/project/.agent-conductor
```

## Next Steps

- [Quick Start Guide](../README.md#quick-start)
- [Configuration Guide](../orchestration/README.md#configuration)
- [Agent Management](../orchestration/README.md#commands-reference)
- [User Guide](../orchestration/USER_GUIDE.md)

## Support

If you encounter issues:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review the [System Requirements](#system-requirements)
3. Open an issue on [GitHub](https://github.com/<YOUR_GITHUB_USER>/agent-conductor/issues)