# 🤖 Agent Conductor User Guide

## Overview

Agent Conductor is a framework that lets you orchestrate multiple AI agents to work together on complex software projects. Each agent specializes in a different aspect of development (frontend, backend, DevOps, QA, etc.) and they collaborate through shared memory files while running in isolated tmux sessions.

**⚠️ Important**: Agent Conductor currently requires GitHub Issues for task management. All deployments must reference actual GitHub issue numbers.

## Quick Start

### 1. Install Agent Conductor

Download and run the installer:
```bash
curl -sSL https://raw.githubusercontent.com/akoscz/agent-conductor/main/install.sh | bash
```

The installer will:
- Install Agent Conductor to `~/.local/share/agent-conductor`
- Add `conductor` and `cond` aliases to your shell
- Make the conductor command available globally

Restart your shell or run:
```bash
source ~/.zshrc  # or ~/.bashrc
```

### 2. Initialize Your Project

Navigate to your project directory and initialize:
```bash
cd /path/to/your/project
conductor init
```

This creates a `.agent-conductor` directory with:
- Configuration files (`config/project.yml`, `config/agents.yml`)
- Agent-specific directories with prompts and settings
- Memory directory for inter-agent communication
- Log directory for session logs

### 3. Configure Your Project

Edit the generated configuration:
```bash
edit .agent-conductor/config/project.yml
```

Customize your project details:
```yaml
project:
  name: "YourProjectName"
  workspace_dir: "/absolute/path/to/your/project"
  github:
    owner: "your-github-username"
    repo: "your-repository-name"
    project_number: 1  # Optional: GitHub project board number
```

Validate your configuration:
```bash
conductor validate
```

## Core Commands

### Essential Commands

| Command | Description | Example |
|---------|-------------|---------|
| `init` | Set up the conductor environment | `conductor init` |
| `deploy <agent> <issue>` | Deploy an agent for a GitHub issue | `conductor deploy rust 123` |
| `list` | Show all active agent sessions | `conductor list` |
| `status` | Display project status and assignments | `conductor status` |
| `attach <agent>` | Connect to an agent's session | `conductor attach rust` |
| `stop-all` | Stop all running agents | `conductor stop-all` |

### Configuration Commands

| Command | Description |
|---------|-------------|
| `config` | Show current configuration details |
| `validate` | Check configuration and dependencies |
| `list-available` | Show all configured agent types |

### Communication Commands

| Command | Description | Example |
|---------|-------------|---------|
| `send <agent> '<cmd>'` | Send command to agent | `conductor send rust 'cargo --version'` |

## Working with Agents

### Deploying Agents

Deploy agents for specific GitHub issues:
```bash
# Deploy backend agent for issue #15
conductor deploy backend 15

# Deploy frontend agent for issue #16
conductor deploy frontend 16

# Deploy QA agent for issue #17
conductor deploy qa 17
```

**Important**: The issue number must correspond to an actual GitHub issue in your repository.

### Monitoring Agents

Check what agents are running:
```bash
conductor list
```

View project status and current assignments:
```bash
conductor status
```

### Interacting with Agents

Attach to an agent's session to see what it's doing:
```bash
conductor attach backend
# Press Ctrl+B then D to detach without stopping the agent
```

Send commands to agents without attaching:
```bash
conductor send backend 'npm test'
conductor send frontend 'npm run build'
```

### Stopping Agents

Stop all agents when you're done:
```bash
conductor stop-all
```

## Configuration Guide

### Available Agent Types

The system comes with these pre-configured agent types:
- **backend**: Server-side development, APIs, databases
- **frontend**: Client-side development, UI/UX
- **devops**: Infrastructure, deployment, monitoring
- **qa**: Testing, quality assurance
- **pm**: Project management, coordination
- **docs**: Documentation, technical writing

### Customizing Agent Types

Each agent type has its own directory in `.agent-conductor/agents/`:
```
.agent-conductor/agents/
├── backend/
│   ├── config.yml    # Agent configuration
│   └── prompt.md     # Detailed instructions for the AI
├── frontend/
│   ├── config.yml
│   └── prompt.md
...
```

To customize an agent:
1. Edit `.agent-conductor/agents/<type>/config.yml` for basic settings
2. Edit `.agent-conductor/agents/<type>/prompt.md` for detailed AI instructions
3. Update validation commands for your tech stack

### Specializing Agent Configurations

The default agents are generic templates that you should customize for your specific project. Here's how to transform them from generic to specialized:

#### Example: Specializing the Backend Agent

**Generic Configuration (default):**
```yaml
# .agent-conductor/agents/backend/config.yml
name: "Backend Development Agent"
description: "Implements server-side logic and APIs"
technologies: ["YourBackendLang", "YourFramework", "YourDatabase"]
capabilities: ["backend", "api-development", "database-design"]
```

**Specialized Configuration (SurveyForge example):**
```yaml
# .agent-conductor/agents/backend/config.yml
name: "Rust Backend Agent"
description: "Implements Rust/Tauri backend features and data processing"
session_name: "backend-agent"
technologies: ["Rust", "Tokio", "Polars", "Tauri", "CSV Processing", "Serde", "Geospatial"]
capabilities: ["backend", "data-processing", "performance-optimization", "csv-parsing", "gps-calculations"]
validation_profile: "rust"
```

#### Example: Specializing the Frontend Agent

**Generic Configuration (default):**
```yaml
# .agent-conductor/agents/frontend/config.yml
name: "Frontend Development Agent"
description: "Develops user interfaces and client-side functionality"
technologies: ["YourFrontendTech", "YourStateLib", "YourUILib"]
capabilities: ["frontend", "ui-components", "user-experience"]
```

**Specialized Configuration (SurveyForge example):**
```yaml
# .agent-conductor/agents/frontend/config.yml
name: "React Frontend Agent"
description: "Develops React/TypeScript UI components and user interfaces"
session_name: "frontend-agent"
technologies: ["React", "TypeScript", "Zustand", "Ant Design", "ECharts", "TanStack Table", "React Hook Form"]
capabilities: ["frontend", "ui-components", "user-experience", "data-visualization", "file-upload"]
validation_profile: "react"
```

#### Specialization Steps

1. **Update Technology Stack**: Replace placeholder technologies with your actual stack
2. **Define Specific Capabilities**: Add domain-specific capabilities your agent will handle
3. **Customize Session Names**: Use consistent naming (e.g., `backend-agent` vs `rust-agent`)
4. **Update Validation Profiles**: Match your build/test commands

#### Prompt Specialization

Beyond configuration, customize the agent prompts with project-specific details:

**Generic Prompt Section:**
```markdown
## Technology Stack
- **Language**: Your backend language
- **Framework**: Your web framework
- **Database**: Your database choice
```

**Specialized Prompt Section:**
```markdown
## Technology Stack
- **Language**: Rust with Tokio async runtime
- **Data Processing**: Polars (10x faster than pandas)
- **CSV Parsing**: csv crate with serde for type safety
- **Desktop Framework**: Tauri v2
- **Testing**: cargo test, tokio-test, criterion for benchmarks
```

### Adding New Agent Types

To add a completely new agent type (e.g., "mobile"):
1. Create directory: `mkdir .agent-conductor/agents/mobile`
2. Create config: `.agent-conductor/agents/mobile/config.yml`
3. Create prompt: `.agent-conductor/agents/mobile/prompt.md`
4. Add to `.agent-conductor/config/agents.yml`:
```yaml
agent_types:
  mobile:
    directory: "agents/mobile"
```

### Validation Profiles

Validation profiles define the commands agents use to verify their work. Customize these for your tech stack:

#### Generic Validation Profiles (default):
```yaml
# .agent-conductor/config/agents.yml
validation_profiles:
  generic:
    lint: "echo 'Add your lint command'"
    test: "echo 'Add your test command'"
    build: "echo 'Add your build command'"
```

#### Specialized Validation Profiles (examples):

**Rust/Cargo Profile:**
```yaml
validation_profiles:
  rust:
    clippy: "cargo clippy --all-targets --all-features -- -D warnings"
    format: "cargo fmt --all -- --check"
    test: "cargo test --all-features"
    benchmark: "cargo run --release -- --benchmark"
    integration: "cargo run -- --test-mode test-data/sample.csv"
```

**React/TypeScript Profile:**
```yaml
validation_profiles:
  react:
    lint: "npm run lint"
    typecheck: "npm run type-check"
    test: "npm run test"
    coverage: "npm run test:coverage"
    accessibility: "npm run test:a11y"
    e2e: "npm run test:e2e"
    build: "npm run build"
```

**Python/Django Profile:**
```yaml
validation_profiles:
  python:
    lint: "flake8 ."
    format: "black --check ."
    typecheck: "mypy ."
    test: "python manage.py test"
    coverage: "coverage run --source='.' manage.py test"
    security: "bandit -r ."
```

#### Assigning Validation Profiles

In your agent configurations, reference the appropriate profile:
```yaml
# .agent-conductor/agents/backend/config.yml
validation_profile: "rust"  # References the rust profile above
```

Agents will automatically run these validation commands before completing tasks.

## Agent Communication

Agents communicate through shared memory files in the `.agent-conductor/memory/` directory:

- **`project_state.md`**: Overall project status and progress
- **`task_assignments.md`**: Current agent assignments and status  
- **`blockers.md`**: Issues and blockers across agents
- **`decisions.md`**: Technical decisions and rationale

Agents automatically read these files to understand context and update them to share progress.

## Best Practices

### 1. Start Small
Begin with core agents (backend, frontend) and add specialists (QA, DevOps) as needed.

### 2. Clear Issue Descriptions
Write detailed GitHub issues since agents will reference them throughout their work.

### 3. Monitor Regularly
Check agent status frequently to ensure they're making progress:
```bash
conductor status
```

### 4. Use Phases (Optional)
Organize work into phases in `.agent-conductor/config/project.yml`:
```yaml
phases:
  1:
    name: "Foundation"
    priority_tasks: [1, 2, 3, 4]  # GitHub issue numbers
  2:
    name: "Core Features"
    priority_tasks: [5, 6, 7, 8]
```

### 5. Customize Prompts
Invest time in detailed agent prompts that reflect your:
- Coding standards
- Technology stack
- Project conventions
- Quality requirements

### 6. Validation Gates
Define comprehensive validation commands so agents can verify their work.

## Troubleshooting

### Common Issues

**Configuration errors:**
```bash
conductor validate
```

**Stuck sessions:**
```bash
tmux list-sessions
conductor stop-all
```

**Agent not responding:**
```bash
conductor attach <agent-name>
# Check what the agent is doing
```

**Missing dependencies:**
Ensure you have:
- `tmux` (session management)
- `yq` (YAML processing) 
- `gh` (GitHub CLI)
- `git` (version control)

### Logs

Check logs for detailed information:
```bash
tail -f .agent-conductor/logs/orchestrator.log
tail -f .agent-conductor/logs/agents/<agent-name>.log
```

## GitHub Integration

### Requirements
- GitHub repository with Issues enabled
- GitHub CLI (`gh`) installed and authenticated
- Issues created for tasks you want agents to work on

### Workflow
1. Create GitHub issues for your tasks
2. Deploy agents with issue numbers: `conductor deploy backend 15`
3. Agents will reference the issue throughout their work
4. PM agent can coordinate using GitHub project boards

### Limitations
- Currently only works with GitHub (not Jira, Linear, etc.)
- Requires manual task-to-agent assignment
- All deployments need GitHub issue numbers

## Platform Support

**Currently Supported:**
- ✅ macOS (full support)

**Planned:**
- ⏳ Linux
- ⏳ Windows (WSL)

## Getting Help

- Run `conductor help` for command help
- Check the `.agent-conductor/README.md` for detailed technical information
- Review agent prompt files to understand what each agent does
- Look at example configurations in the `.agent-conductor/config/` directory

## Example Workflow

Here's a typical workflow for a web application:

```bash
# 1. Set up the system
conductor init
conductor validate

# 2. Deploy agents for your GitHub issues
conductor deploy backend 10   # API development
conductor deploy frontend 11  # UI development  
conductor deploy qa 12        # Testing

# 3. Monitor progress
conductor status
conductor list

# 4. Check on specific agents
conductor attach backend

# 5. Deploy additional agents as needed
conductor deploy devops 13    # Deployment setup

# 6. Clean up when done
conductor stop-all
```

This workflow creates a collaborative environment where multiple AI agents work together on different aspects of your project, coordinating through shared memory files while maintaining isolation in their own tmux sessions.