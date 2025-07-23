# 🤖 AI Agent Orchestration System

A reusable, configuration-driven orchestration framework for managing multiple AI agents working on complex software projects using tmux session isolation and file-based communication.

## ⚠️ GitHub Integration Requirement

**This orchestration system requires GitHub Issues for task management and project coordination.**

### GitHub Dependencies:
- **Task Deployment**: All agent deployments require GitHub issue numbers
- **PM Agent**: Uses `gh` CLI commands for GitHub project integration
- **Project Configuration**: Must specify GitHub owner, repository, and project number
- **Agent Coordination**: Agents reference GitHub issues in shared memory files
- **Workflow Integration**: Agent prompts are designed around GitHub workflows

### Prerequisites:
- GitHub repository with Issues enabled
- GitHub CLI (`gh`) installed and authenticated
- GitHub project board (optional but recommended)

**Note**: This system cannot currently work with other task management platforms (Jira, Linear, Azure DevOps, etc.). See the main project's decoupling plan for future architecture options.

## 🏗️ Architecture

- **Session Isolation**: Each AI agent runs in its own tmux session
- **Configuration-Driven**: YAML configuration file defines project-specific settings
- **File-Based Communication**: Agents coordinate through shared memory files
- **Technology Agnostic**: Works with any programming language/framework
- **Reusable**: Can be adapted for different projects by changing configuration

## 📁 Directory Structure

```
.agent-conductor/                # Created by 'conductor init'
├── agents/                      # Agent type definitions
│   ├── backend/                 # Backend agent
│   │   ├── config.yml          # Agent-specific configuration
│   │   └── prompt.md           # Agent instructions
│   ├── frontend/               # Frontend agent
│   │   ├── config.yml
│   │   └── prompt.md
│   ├── devops/                 # DevOps agent
│   │   ├── config.yml
│   │   └── prompt.md
│   ├── qa/                     # QA agent
│   │   ├── config.yml
│   │   └── prompt.md
│   ├── pm/                     # Project Manager agent
│   │   ├── config.yml
│   │   └── prompt.md
│   └── docs/                   # Documentation agent
│       ├── config.yml
│       └── prompt.md
├── config/                     # Project configuration
│   ├── agents.yml              # Agent definitions and validation profiles
│   └── project.yml             # Project settings and GitHub integration
├── scripts/
│   ├── core/                   # Primary orchestration scripts
│   │   ├── orchestrator.sh     # Main CLI interface
│   │   ├── config_loader.sh    # Configuration loading
│   │   └── init_orchestrator.sh # System initialization
│   ├── lib/                    # Core libraries (testable functions)
│   │   ├── orchestrator_lib.sh # Core orchestration logic
│   │   ├── agent_lib.sh        # Agent lifecycle management
│   │   ├── config_lib.sh       # Configuration utilities
│   │   ├── session_lib.sh      # tmux session management
│   │   ├── communication_lib.sh # Basic inter-agent communication
│   │   ├── enhanced_communication_lib.sh # Advanced communication
│   │   ├── monitoring_lib.sh   # Health monitoring
│   │   └── setup_lib.sh        # Project setup utilities
│   ├── agent-management/       # Agent control scripts
│   │   ├── deploy_agent.sh     # Deploy agents
│   │   ├── deploy_agent_new.sh # Enhanced deployment
│   │   ├── attach_agent.sh     # Attach to sessions
│   │   ├── list_agents.sh      # List active agents
│   │   ├── check_agents.sh     # Health checks
│   │   └── stop_all_agents.sh  # Stop all agents
│   ├── communication/          # Communication utilities
│   │   └── send_command.sh     # Send commands to agents
│   ├── session-management/     # Session management
│   │   └── start_daily_session.sh # Daily session setup
│   ├── setup/                  # Setup utilities
│   │   └── setup_new_project.sh # New project setup
│   └── tests/                  # Test suite
│       ├── unit/               # Unit tests
│       │   └── *.bats         # BATS unit test files
│       ├── integration/        # Integration tests
│       │   └── *.bats         # BATS integration test files
│       ├── run_tests.sh        # Test runner
│       └── test_setup_common.sh # Common test setup
├── memory/                     # Shared memory files (runtime)
├── logs/                       # Log files (runtime)
└── test-config/                # Test configurations
    ├── agents.yml              # Test agent definitions
    ├── project.yml             # Test project config
    └── agents/                 # Test agent configs
        ├── rust/
        └── react/
```

## 🚀 Quick Start

### 1. Install Agent Conductor

```bash
# Install Agent Conductor globally
curl -sSL https://raw.githubusercontent.com/akoscz/agent-conductor/main/install.sh | bash

# Restart your shell or source your profile
source ~/.zshrc  # or ~/.bashrc
```

### 2. Initialize Your Project

```bash
# Navigate to your project directory
cd /path/to/your/project

# Initialize Agent Conductor
conductor init
```

This creates a `.agent-conductor` directory with:
- Configuration templates (`config/project.yml`, `config/agents.yml`)
- Agent-specific directories with prompts and settings
- Memory directory for inter-agent communication
- Log directory for session tracking

### 3. Configure Your Project

```bash
# Edit the generated configuration
edit .agent-conductor/config/project.yml

# Customize with your details:
# - Project name, description, version
# - Workspace directory path (auto-detected)
# - GitHub repository details
# - Project phases and tasks (optional)
```

### 4. Deploy and Monitor

```bash
# Validate configuration
conductor validate

# Deploy agents for specific GitHub issues
conductor deploy rust 123   # Deploy rust agent for GitHub issue #123
conductor deploy react 124  # Deploy react agent for GitHub issue #124

# Monitor progress
conductor status
conductor list
```

**Important**: The task number parameter (123, 124) must correspond to actual GitHub issue numbers in your configured repository. The system will reference these issues throughout the agent's work.

## 📋 Commands Reference

| Command | Description | Example |
|---------|-------------|---------|
| `init` | Initialize conductor environment | `conductor init` |
| `config` | Show configuration details | `conductor config` |
| `validate` | Validate configuration and tools | `conductor validate` |
| `deploy <agent> <task>` | Deploy agent for specific GitHub issue | `conductor deploy rust 21` |
| `list` | List all active agent sessions | `conductor list` |
| `status` | Show project status and assignments | `conductor status` |
| `attach <agent>` | Attach to specific agent session | `conductor attach rust` |
| `send <agent> '<cmd>'` | Send command to agent session | `conductor send rust 'cargo --version'` |
| `stop-all` | Stop all agent sessions | `conductor stop-all` |

## ⚙️ Configuration

The configuration has been redesigned for better modularity:

### Configuration Architecture

1. **Template Configuration Files** (`config/`):
   - `agents.example.yml` - Template for agent type definitions
   - `project.example.yml` - Template for project-specific settings

2. **Agent-Specific Configurations** (`agents/<type>/`):
   - Each agent type has its own directory
   - `config.yml` - Agent-specific configuration
   - `prompt.md` - Detailed agent instructions

### Key Configuration Sections

**Project Configuration** (`.agent-conductor/config/project.yml`):
```yaml
project:
  name: "YourProject"
  workspace_dir: "/path/to/project"
  github:                    # REQUIRED: GitHub integration
    owner: "username"        # GitHub username or organization
    repo: "repository"       # Repository name
    project_number: 1        # GitHub project board number (optional)

directories:
  memory: "memory"
  logs: "logs"
  agents: "agents"

memory_files:
  project_state: "project_state.md"
  task_assignments: "task_assignments.md"
  blockers: "blockers.md"
  decisions: "decisions.md"

# Phases map to GitHub issue numbers - optional but useful for PM coordination
# Use project.simple.yml template if you don't need phases
phases:
  1:
    name: "Foundation"
    priority_tasks: [1, 2, 3, 4]  # Must be actual GitHub issue numbers
```

**Agent Type Registry** (`.agent-conductor/config/agents.yml`):
```yaml
# Registry points to individual agent directories
agent_types:
  backend:
    directory: "agents/backend"
  frontend:
    directory: "agents/frontend"
  devops:
    directory: "agents/devops"

# Shared validation profiles
validation_profiles:
  backend:
    syntax: "your-backend-lint-command"
    test: "your-backend-test-command"
    build: "your-backend-build-command"
  frontend:
    lint: "your-frontend-lint-command"
    test: "your-frontend-test-command"
    build: "npm run build"
    typecheck: "npm run typecheck"
```

**Individual Agent Configuration** (`.agent-conductor/agents/backend/config.yml`):
```yaml
name: "Backend Development Agent"
description: "Implements server-side logic and APIs"
session_name: "backend-agent"
prompt_file: "prompt.md"  # Local to this directory
technologies: ["YourBackendLang", "YourFramework", "YourDatabase"]
capabilities: ["backend", "api-development", "database-design"]
validation_profile: "backend"  # References validation_profiles in main agents.yml
```

## 🤖 Agent Communication

Agents communicate through shared memory files in `.agent-conductor/memory/`:

- **`project_state.md`**: Overall project status and progress
- **`task_assignments.md`**: Current agent assignments and status
- **`blockers.md`**: Current blockers and issues
- **`decisions.md`**: Technical decisions and rationale

Each agent reads these files to understand context and updates them to communicate progress.

## 🔧 Customization for Different Projects

### Web Applications
- **Frontend Agent**: React, Vue, Angular development
- **Backend Agent**: Node.js, Python, Java API development
- **Database Agent**: Schema design, migrations, optimization

### Mobile Applications
- **iOS Agent**: Swift/SwiftUI development
- **Android Agent**: Kotlin/Java development
- **React Native Agent**: Cross-platform mobile development

### Data Projects
- **Data Agent**: ETL pipelines, data processing
- **ML Agent**: Model training, feature engineering
- **Analytics Agent**: Reporting, visualization

### DevOps/Infrastructure
- **Infrastructure Agent**: Terraform, CloudFormation
- **Monitoring Agent**: Observability, alerting
- **Security Agent**: Security scanning, compliance

## 📝 Agent Prompt Templates

Each agent type has a detailed prompt file in `.agent-conductor/agents/<type>/prompt.md` containing:

- **Mission and responsibilities**
- **Technology stack and tools**
- **Communication protocols**
- **Validation requirements**
- **Quality standards**

Customize these prompts based on your project's specific needs and conventions.

## 🔍 Monitoring and Debugging

### View Agent Activity
```bash
# List all active sessions
conductor list

# Attach to specific agent
conductor attach rust

# View logs
tail -f .agent-conductor/logs/orchestrator.log
```

### Troubleshooting
```bash
# Validate configuration
conductor validate

# Check tmux sessions
tmux list-sessions

# Kill stuck sessions
conductor stop-all
```

## 🏷️ Best Practices

1. **Configuration First**: Always start by customizing the configuration file
2. **Agent Isolation**: Keep agents focused on specific domains/technologies
3. **Clear Communication**: Use structured memory files for agent coordination
4. **Regular Monitoring**: Check agent status and logs frequently
5. **Prompt Quality**: Invest time in detailed, context-rich agent prompts
6. **Validation Gates**: Define comprehensive validation commands for quality
7. **Progressive Deployment**: Start with core agents, add specialized ones as needed

## 🤝 Contributing

This orchestration system is designed to be:
- **Modular**: Easy to add new agent types
- **Configurable**: Adaptable to different project structures
- **Extensible**: Can be enhanced with additional features

Feel free to extend and customize for your specific use cases!

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](../LICENSE) file for details.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0