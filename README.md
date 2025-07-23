# Agent Conductor

A reusable, configuration-driven orchestration framework for managing multiple AI agents working on complex software projects. Agent Conductor provides session isolation, file-based communication, and technology-agnostic coordination for AI agents.

> **⚠️ Platform Support**: Currently optimized for **macOS** due to bash command implementations. Linux and Windows (WSL) support is planned for future releases as part of our platform-agnostic roadmap.

## Features

- **Reusable Framework**: Initialize any project with `conductor init`
- **Session Isolation**: Each AI agent runs in its own tmux session
- **Configuration-Driven**: YAML configuration defines project-specific settings
- **File-Based Communication**: Agents coordinate through shared memory files
- **Race Condition Safe**: Enhanced communication library with atomic file locking and transactions
- **Technology Agnostic**: Works with any programming language/framework
- **Comprehensive Testing**: Unit and integration tests with BATS framework

## ⚠️ GitHub Integration Dependency

**Agent Conductor is currently tightly coupled to GitHub Issues for task management.**

### Current GitHub Dependencies:
- **Task Assignment**: All deployments require GitHub issue numbers (`conductor deploy rust 123`)
- **PM Agent Integration**: PM agent uses GitHub CLI (`gh`) commands for project coordination
- **Configuration Requirements**: GitHub owner/repo/project_number must be configured
- **Agent Prompts**: All agent prompts reference GitHub workflows and issue tracking
- **Memory Files**: Task assignments and project state files contain GitHub issue references
- **Project Phases**: Project phases map directly to GitHub issue numbers

### Limitations:
- Cannot be used with other task management systems (Jira, Linear, Azure DevOps, etc.)
- Manual task-to-agent assignment required
- PM agent has limited coordination capabilities beyond GitHub integration

### Future Architecture:
See [docs/task-source-decoupling-plan.md](docs/task-source-decoupling-plan.md) for comprehensive plans to decouple from GitHub and create a universal task management abstraction layer. **Note:** This would require rewriting the system in a language other than bash.

## Quick Start

```bash
# Install Agent Conductor
curl -sSL https://raw.githubusercontent.com/akoscz/agent-conductor/main/install.sh | bash

# Initialize your project
cd /path/to/your/project
conductor init

# Configure and deploy
conductor validate
conductor deploy backend 123  # Deploy backend agent for GitHub issue #123
```

📖 **See the [Installation Guide](docs/installation.md) for detailed setup instructions**

## Documentation

| Document | Description |
|----------|-------------|
| 📖 [Installation Guide](docs/installation.md) | Complete installation and setup instructions |
| 🎯 [User Guide](orchestration/USER_GUIDE.md) | Comprehensive usage guide with examples |
| 🏗️ [System Architecture](docs/system-architecture.md) | Technical architecture and design details |
| ⚙️ [Framework Guide](orchestration/README.md) | Framework configuration and customization |
| 🔮 [Future Plans](docs/task-source-decoupling-plan.md) | GitHub decoupling and platform roadmap |

## Use Cases

- **Web Applications**: Frontend, backend, and database agents
- **Mobile Development**: iOS, Android, and React Native agents
- **Data Projects**: ETL, ML, and analytics agents
- **DevOps/Infrastructure**: Infrastructure, monitoring, and security agents


## Platform Support

- ✅ **macOS**: Full support with all features tested
- ⏳ **Linux**: Planned support  
- ⏳ **Windows (WSL)**: Planned support

See the [Distribution Strategy](docs/distribution-strategy.md) for cross-platform roadmap details.

## Contributing

Agent Conductor is designed to be modular, configurable, and extensible. Contributions are welcome to enhance the framework for broader use cases.

**Priority Contributions Needed**:
- Cross-platform compatibility improvements
- Linux/Windows testing and validation
- Package manager integrations
- Documentation for additional platforms

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

Copyright 2025 Agent Conductor Contributors

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0