# Agent Conductor

A reusable, configuration-driven orchestration framework for managing multiple AI agents working on complex software projects. Agent Conductor provides session isolation, file-based communication, and technology-agnostic coordination for AI agents.

> **⚠️ Platform Support**: Currently optimized for **macOS** due to bash command implementations. Linux and Windows (WSL) support is planned for future releases as part of our platform-agnostic roadmap.

## Features

- **Reusable Framework**: Drop the orchestration folder into any project
- **Session Isolation**: Each AI agent runs in its own tmux session
- **Configuration-Driven**: YAML configuration defines project-specific settings
- **File-Based Communication**: Agents coordinate through shared memory files
- **Technology Agnostic**: Works with any programming language/framework
- **Comprehensive Testing**: Unit and integration tests with BATS framework

## Quick Start

1. **Copy the orchestration framework to your project:**
   ```bash
   cp -r orchestration/ /path/to/your/project/
   ```

2. **Configure for your project:**
   ```bash
   cd /path/to/your/project/orchestration
   cp templates/project.example.yml config/project.yml
   cp templates/agents.example.yml config/agents.yml
   # Edit config files with your project details
   ```

3. **Install dependencies:**
   ```bash
   brew install tmux yq  # macOS (recommended)
   # Linux support coming soon
   ```

4. **Initialize and deploy agents:**
   ```bash
   ./scripts/core/orchestrator.sh init
   ./scripts/core/orchestrator.sh deploy rust 123  # Deploy rust agent for issue #123
   ./scripts/core/orchestrator.sh status
   ```

## Project Structure

```
agent-conductor/
├── orchestration/          # Distributable framework
│   ├── README.md          # Framework documentation
│   ├── config/            # Configuration files
│   ├── scripts/           # Core orchestration scripts
│   ├── prompts/           # Agent prompt templates
│   ├── templates/         # Configuration templates
│   └── tests/             # Framework tests
└── README.md              # This file - project overview
```

## Use Cases

- **Web Applications**: Frontend, backend, and database agents
- **Mobile Development**: iOS, Android, and React Native agents
- **Data Projects**: ETL, ML, and analytics agents
- **DevOps/Infrastructure**: Infrastructure, monitoring, and security agents

## Documentation

See the [orchestration README](orchestration/README.md) for detailed setup instructions, configuration options, and usage examples.

## Platform Compatibility

### Current Support
- ✅ **macOS**: Full support with all features tested
- ⏳ **Linux**: Planned support
- ⏳ **Windows (WSL)**: Planned support

### Roadmap to Platform Agnostic
We're actively working toward full cross-platform compatibility:

1. **Command Standardization**: Replace macOS-specific commands with portable alternatives
2. **Path Handling**: Implement cross-platform path resolution
3. **Shell Compatibility**: Ensure compatibility across bash versions and shells
4. **Package Management**: Support multiple package managers (brew, apt, yum, chocolatey)
5. **Testing Matrix**: Comprehensive testing across all target platforms

See our [Distribution Strategy](docs/distribution-strategy.md) for detailed implementation plans.

## Contributing

Agent Conductor is designed to be modular, configurable, and extensible. Contributions are welcome to enhance the framework for broader use cases.

**Priority Contributions Needed**:
- Cross-platform compatibility improvements
- Linux/Windows testing and validation
- Package manager integrations
- Documentation for additional platforms