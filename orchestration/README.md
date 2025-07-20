# 🤖 AI Agent Orchestration System

A reusable, configuration-driven orchestration framework for managing multiple AI agents working on complex software projects using tmux session isolation and file-based communication.

## 🏗️ Architecture

- **Session Isolation**: Each AI agent runs in its own tmux session
- **Configuration-Driven**: YAML configuration file defines project-specific settings
- **File-Based Communication**: Agents coordinate through shared memory files
- **Technology Agnostic**: Works with any programming language/framework
- **Reusable**: Can be adapted for different projects by changing configuration

## 📁 Directory Structure

```
orchestration/
├── config/
│   ├── project.yml               # Project configuration
│   └── agents.yml                # Agent definitions
├── scripts/
│   ├── core/
│   │   ├── orchestrator.sh       # Main orchestrator command
│   │   ├── config_loader.sh      # Configuration management
│   │   └── init_orchestrator.sh  # System initialization
│   ├── agent-management/
│   │   ├── deploy_agent.sh       # Agent deployment
│   │   ├── deploy_agent_new.sh   # New agent deployment
│   │   ├── list_agents.sh        # Show active agents
│   │   ├── attach_agent.sh       # Connect to agent session
│   │   ├── check_agents.sh       # Check agent status
│   │   └── stop_all_agents.sh    # Stop all agents
│   ├── communication/
│   │   └── send_command.sh       # Send commands to agents
│   ├── session-management/
│   │   └── start_daily_session.sh # Daily session management
│   ├── setup/
│   │   └── setup_new_project.sh  # New project setup
│   ├── lib/
│   │   ├── orchestrator_lib.sh   # Core orchestrator functions
│   │   ├── agent_lib.sh          # Agent management functions
│   │   ├── config_lib.sh         # Configuration utilities
│   │   ├── session_lib.sh        # Session management
│   │   ├── communication_lib.sh  # Communication utilities
│   │   ├── monitoring_lib.sh     # Monitoring functions
│   │   └── setup_lib.sh          # Setup utilities
│   └── tests/
│       ├── run_tests.sh          # Test runner
│       ├── unit/                 # Unit tests (*.bats)
│       └── integration/          # Integration tests (*.bats)
├── prompts/
│   ├── rust_agent.md             # Rust agent instructions
│   ├── react_agent.md            # React agent instructions
│   ├── devops_agent.md           # DevOps agent instructions
│   ├── qa_agent.md               # QA agent instructions
│   ├── pm_agent.md               # Project manager instructions
│   └── docs_agent.md             # Documentation agent instructions
├── memory/                       # Shared memory files (created at runtime)
├── logs/                         # Log files (created at runtime)
└── templates/
    ├── project.example.yml       # Project configuration template
    └── agents.example.yml        # Agent configuration template
```

## 🚀 Quick Start

### 1. Setup for New Project

```bash
# Copy orchestration system to your project
cp -r orchestration/ /path/to/your/project/

# Copy and customize configuration
cd /path/to/your/project/orchestration
cp templates/project.example.yml config/project.yml
cp templates/agents.example.yml config/agents.yml

# Edit config/project.yml and config/agents.yml with your project details:
# - Project name, description, version
# - Workspace directory path
# - GitHub repository details
# - Agent types and technologies
# - Validation commands for your stack
# - Project phases and tasks
```

### 2. Install Dependencies

```bash
# Install required tools
brew install tmux yq  # macOS
# or
apt-get install tmux yq  # Ubuntu/Debian
```

### 3. Initialize and Deploy

```bash
# Initialize the orchestration system
./scripts/core/orchestrator.sh init

# Check configuration
./scripts/core/orchestrator.sh config
./scripts/core/orchestrator.sh validate

# Deploy agents for specific tasks
./scripts/core/orchestrator.sh deploy rust 123   # Deploy rust agent for GitHub issue #123
./scripts/core/orchestrator.sh deploy react 124  # Deploy react agent for GitHub issue #124

# Monitor progress
./scripts/core/orchestrator.sh status
./scripts/core/orchestrator.sh list
```

## 📋 Commands Reference

| Command | Description | Example |
|---------|-------------|---------|
| `init` | Initialize orchestrator environment | `./scripts/core/orchestrator.sh init` |
| `config` | Show configuration details | `./scripts/core/orchestrator.sh config` |
| `validate` | Validate configuration and tools | `./scripts/core/orchestrator.sh validate` |
| `deploy <agent> <task>` | Deploy agent for specific task | `./scripts/core/orchestrator.sh deploy rust 21` |
| `list` | List all active agent sessions | `./scripts/core/orchestrator.sh list` |
| `status` | Show project status and assignments | `./scripts/core/orchestrator.sh status` |
| `attach <agent>` | Attach to specific agent session | `./scripts/core/orchestrator.sh attach rust` |
| `send <agent> '<cmd>'` | Send command to agent session | `./scripts/core/orchestrator.sh send rust 'cargo --version'` |
| `stop-all` | Stop all agent sessions | `./scripts/core/orchestrator.sh stop-all` |

## ⚙️ Configuration

The configuration is split between two files:
- `config/project.yml` - Project-specific settings
- `config/agents.yml` - Agent definitions and configurations

### Key Configuration Sections

**Project Information**
```yaml
project:
  name: "YourProject"
  workspace_dir: "/path/to/project"
  github:
    owner: "username"
    repo: "repository"
```

**Agent Definitions**
```yaml
agents:
  rust:
    name: "Rust Agent"
    session_name: "rust-agent"
    prompt_file: "rust_agent.md"
    technologies: ["Rust", "Tauri", "Tokio"]
  react:
    name: "React Agent"
    session_name: "react-agent"
    prompt_file: "react_agent.md"
    technologies: ["React", "TypeScript", "Zustand"]
```

**Validation Commands**
```yaml
validation:
  rust:
    test: "cargo test"
    lint: "cargo clippy"
    build: "cargo build"
  react:
    test: "npm test"
    lint: "npm run lint"
    build: "npm run build"
```

**Project Phases**
```yaml
phases:
  1:
    name: "Foundation"
    priority_tasks: [1, 2, 3, 4]
```

## 🤖 Agent Communication

Agents communicate through shared memory files:

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

Each agent type has a detailed prompt file in `prompts/` directory containing:

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
./scripts/core/orchestrator.sh list

# Attach to specific agent
./scripts/core/orchestrator.sh attach rust

# View logs
tail -f logs/orchestrator.log
```

### Troubleshooting
```bash
# Validate configuration
./scripts/core/orchestrator.sh validate

# Check tmux sessions
tmux list-sessions

# Kill stuck sessions
./scripts/core/orchestrator.sh stop-all
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

This orchestration framework can be freely used and adapted for any project.