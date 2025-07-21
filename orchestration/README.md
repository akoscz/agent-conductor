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
├── agents/                       # Agent type definitions
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
├── config/                     # Configuration templates
│   ├── agents.example.yml      # Agent definitions template
│   └── project.example.yml     # Project configuration template
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

**Project Configuration** (`config/project.yml`):
```yaml
project:
  name: "YourProject"
  workspace_dir: "/path/to/project"
  github:
    owner: "username"
    repo: "repository"

directories:
  memory: "memory"
  logs: "logs"
  agents: "agents"

memory_files:
  project_state: "project_state.md"
  task_assignments: "task_assignments.md"
  blockers: "blockers.md"
  decisions: "decisions.md"

phases:
  1:
    name: "Foundation"
    priority_tasks: [1, 2, 3, 4]
```

**Agent Type Definitions** (`config/agents.yml`):
```yaml
agent_types:
  backend:
    name: "Backend Development Agent"
    session_name: "backend-agent"
    prompt_file: "agents/backend/prompt.md"
    technologies: ["Node.js", "Python", "Go", "PostgreSQL"]
    validation_profile: "backend"
    capabilities: ["api", "database", "backend-logic"]

  frontend:
    name: "Frontend Development Agent"
    session_name: "frontend-agent"
    prompt_file: "agents/frontend/prompt.md"
    technologies: ["React", "Vue", "TypeScript", "CSS"]
    validation_profile: "frontend"
    capabilities: ["ui", "components", "styling"]

validation_profiles:
  backend:
    test: "npm test"
    lint: "npm run lint"
    build: "npm run build"
  
  frontend:
    test: "npm test"
    lint: "npm run lint"
    build: "npm run build"
    typecheck: "npm run typecheck"
```

**Individual Agent Configuration** (`agents/backend/config.yml`):
```yaml
agent:
  type: "backend"
  specialization: "API Development"
  additional_tools:
    - "Postman"
    - "Database GUI"
  
environment:
  node_version: "18"
  python_version: "3.11"
  
validation:
  pre_commit:
    - "npm run lint"
    - "npm test"
  deployment:
    - "npm run build"
    - "npm run test:integration"
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