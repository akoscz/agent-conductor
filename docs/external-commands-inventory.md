# External Commands Inventory - Agent Conductor

This document provides a comprehensive list of all external shell commands used throughout the agent-conductor codebase, organized by where they are used.

## Commands by Category

### Session Management
- **tmux** - Terminal multiplexer for managing agent sessions
  - `tmux new-session`
  - `tmux has-session`
  - `tmux list-sessions`
  - `tmux attach`
  - `tmux send-keys`
  - `tmux kill-session`
  - `tmux capture-pane`
  - `tmux list-panes`

### Version Control & GitHub
- **git** - Version control operations
  - `git status`
  - `git diff`
  - `git log`
  - `git add`
  - `git commit`
- **gh** - GitHub CLI for issue management
  - `gh issue list`
  - `gh issue view`
  - `gh project item-list`
  - `gh pr create`
  - `gh api`

### Text Processing
- **grep** - Pattern searching
- **sed** - Stream editor for text manipulation
- **awk** - Text processing and data extraction
- **cut** - Extract columns from text
- **tr** - Translate or delete characters
- **sort** - Sort lines of text
- **uniq** - Report or omit repeated lines
- **head** - Output first part of files
- **tail** - Output last part of files
- **wc** - Word, line, character count

### File Operations
- **cat** - Concatenate and display files
- **echo** - Display text
- **cp** - Copy files and directories
- **mv** - Move/rename files and directories
- **rm** - Remove files and directories
- **mkdir** - Create directories
- **touch** - Create empty files or update timestamps
- **chmod** - Change file permissions
- **ls** - List directory contents
- **find** - Search for files and directories

### Path & Directory Utilities
- **dirname** - Extract directory path from file path
- **basename** - Extract filename from path
- **pwd** - Print working directory
- **cd** - Change directory
- **realpath** - Resolve absolute path

### Date & Time
- **date** - Display or set system date and time

### Process Management
- **pgrep** - Find process IDs by name
- **ps** - Display running processes
- **kill** - Terminate processes
- **pkill** - Kill processes by name

### Network Tools
- **curl** - Transfer data from/to servers
- **wget** - Download files from the web

### Package Managers & Build Tools
- **npm** - Node.js package manager
  - `npm run`
  - `npm install`
- **node** - JavaScript runtime
- **cargo** - Rust package manager
  - `cargo test`
  - `cargo build`
  - `cargo doc`

### Data Processing
- **jq** - JSON processor
- **yq** - YAML processor

### Shell Utilities
- **command** - Execute commands
- **which** - Locate command
- **type** - Display command type
- **source** - Execute commands from file
- **export** - Set environment variables
- **xargs** - Build and execute commands from input

## Commands by File Type

### In Bash Scripts (*.sh)

#### Core Scripts
- **conductor**: tmux, date, echo, source
- **init_conductor**: source, echo, mkdir, cat
- **config_loader.sh**: yq, dirname, basename

#### Library Scripts (lib/*.sh)
- **session_lib.sh**: tmux, date, pgrep, awk, mv
- **agent_lib.sh**: tmux, date, echo, awk, grep, sed
- **communication_lib.sh**: tmux, echo, grep
- **config_lib.sh**: yq, dirname, cp, mv, date
- **orchestrator_lib.sh**: date, mkdir, cat, echo, awk, grep, head, tail, sed, tr
- **setup_lib.sh**: cp, rm, mkdir, echo, dirname, basename, pwd
- **monitoring_lib.sh**: tmux, ps, awk, date

#### Agent Management Scripts
- **deploy_agent.sh**: tmux, date, echo, source
- **attach_agent.sh**: tmux, echo
- **list_agents.sh**: tmux, awk, echo
- **check_agents.sh**: tmux, grep, echo
- **stop_all_agents.sh**: tmux, grep, awk

#### Setup Scripts
- **install.sh**: curl, wget, tar, mkdir, cp, rm, chmod, find, echo, cat
- **setup_new_project.sh**: source, echo, dirname

### In Test Files (*.bats)
- grep, sed, awk, cat, echo
- mkdir, touch, rm, cp, mv
- date (mocked)
- tmux (mocked)
- yq (mocked)

### In Agent Prompts (*.md)
- **pm agent**: gh, tmux, echo
- **backend agent**: cargo
- **frontend agent**: npm
- **qa agent**: cargo, npm
- **docs agent**: cargo, npm
- **devops agent**: cargo, npm, docker

### In Documentation (*.md)
- curl, wget, chmod
- brew (macOS)
- apt (Ubuntu/Debian)
- tmux, yq (as requirements)
- git, gh (for examples)

## Command Dependencies

### Required for Installation
- bash (3.2+)
- tmux (2.0+)
- curl or wget

### Required for Operation
- tmux
- yq (for YAML processing)
- Standard Unix utilities: grep, sed, awk, cat, echo, etc.

### Optional (Agent-Specific)
- gh (GitHub CLI) - for GitHub integration
- npm/node - for frontend agents
- cargo - for Rust backend agents
- docker - for DevOps agents

## Environment Variables for Command Injection

The codebase uses dependency injection for testing, allowing commands to be mocked:

```bash
# Session Library
TMUX_CMD="${TMUX_CMD:-tmux}"
DATE_CMD="${DATE_CMD:-date}"
PGREP_CMD="${PGREP_CMD:-pgrep}"
AWK_CMD="${AWK_CMD:-awk}"
MV_CMD="${MV_CMD:-mv}"

# Config Library
YQ_CMD="${YQ_CMD:-yq}"
CP_CMD="${CP_CMD:-cp}"

# Orchestrator Library
MKDIR_CMD="${MKDIR_CMD:-mkdir}"
CAT_CMD="${CAT_CMD:-cat}"
ECHO_CMD="${ECHO_CMD:-echo}"
GREP_CMD="${GREP_CMD:-grep}"
HEAD_CMD="${HEAD_CMD:-head}"
TAIL_CMD="${TAIL_CMD:-tail}"
SED_CMD="${SED_CMD:-sed}"
TR_CMD="${TR_CMD:-tr}"

# Setup Library
RM_CMD="${RM_CMD:-rm}"
DIRNAME_CMD="${DIRNAME_CMD:-dirname}"
BASENAME_CMD="${BASENAME_CMD:-basename}"
PWD_CMD="${PWD_CMD:-pwd}"

# Agent Library
SORT_CMD="${SORT_CMD:-sort}"
UNIQ_CMD="${UNIQ_CMD:-uniq}"
TEE_CMD="${TEE_CMD:-tee}"
```

## Platform Considerations

### macOS
- Uses BSD versions of commands (grep, sed, etc.)
- Requires Homebrew for installing dependencies
- Native tmux support

### Linux
- Uses GNU versions of commands
- Package managers: apt, yum, dnf
- Native support for all required commands

### Cross-Platform Compatibility
- Scripts avoid platform-specific flags where possible
- Uses POSIX-compliant command options
- Platform detection in install.sh for appropriate behavior