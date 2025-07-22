# GitHub CLI (gh) Documentation - Version 2.76.0

**Platform**: macOS (Darwin Kernel Version 24.5.0)  
**Version**: gh version 2.76.0 (2025-07-17)  
**Release**: https://github.com/cli/cli/releases/tag/v2.76.0

## Overview

GitHub CLI (gh) is an open source command-line tool for interacting with GitHub from the terminal. It allows users to perform GitHub operations without leaving the command line.

## Installation and Authentication

### Authentication Commands (gh auth)

- `gh auth login`: Authenticate with GitHub
- `gh auth logout`: Remove GitHub authentication  
- `gh auth refresh`: Refresh authentication credentials
- `gh auth setup-git`: Configure git to use GitHub CLI authentication
- `gh auth status`: Check current authentication status
- `gh auth switch`: Switch between GitHub accounts
- `gh auth token`: Manage authentication tokens

## Core Commands Reference

### Repository Operations
- `gh browse`: Open GitHub resources in browser
- `gh repo`: Repository operations (create, clone, fork, etc.)
- `gh release`: Release management

### Issue Management (gh issue)

**Available Commands:**
- `gh issue create`: Create a new issue
- `gh issue list` (alias: `gh issue ls`): List repository issues
- `gh issue view`: Display issue details
- `gh issue edit`: Modify issue details
- `gh issue close`: Close an existing issue
- `gh issue reopen`: Reopen a closed issue
- `gh issue comment`: Add a comment to an issue
- `gh issue delete`: Remove an issue
- `gh issue develop`: Link development to an issue
- `gh issue lock`: Lock issue discussions
- `gh issue unlock`: Unlock issue discussions
- `gh issue pin`: Pin an issue
- `gh issue unpin`: Unpin a previously pinned issue
- `gh issue transfer`: Move issue to another repository
- `gh issue status`: Check current issue status

**Key Options for gh issue list:**
```bash
# Basic usage
gh issue list

# Filtering options
-a, --assignee string    # Filter by assignee
-A, --author string      # Filter by author
-l, --label strings      # Filter by label
-m, --milestone string   # Filter by milestone
-s, --state string       # Filter by state: {open|closed|all} (default "open")
-S, --search query       # Search issues with query
-L, --limit int          # Maximum number of issues to fetch (default 30)

# JSON output options
--json fields            # Output JSON with specified fields
-q, --jq expression      # Filter JSON output using jq expression
-t, --template string    # Format JSON output using Go template

# Other options
-R, --repo               # Select specific repository
-w, --web                # List issues in web browser
```

### Project Management (gh project)

**Available Commands:**
- `gh project create`: Create a new project
- `gh project list` (alias: `gh project ls`): List projects
- `gh project view`: View specific project details
- `gh project edit`: Modify project settings
- `gh project close`: Close a project
- `gh project delete`: Remove a project
- `gh project copy`: Duplicate a project
- `gh project link`: Connect project to repositories
- `gh project unlink`: Remove project connections

**Field Management:**
- `gh project field-create`: Add new project fields
- `gh project field-delete`: Remove project fields
- `gh project field-list`: Display project fields

**Item Management:**
- `gh project item-add`: Add items to project
- `gh project item-create`: Create new project items
- `gh project item-edit`: Modify project items
- `gh project item-delete`: Remove project items
- `gh project item-list`: List project items
- `gh project item-archive`: Archive project items

**Key Options for gh project list:**
```bash
# Basic usage
gh project list

# Options
--closed              # Include closed projects
--owner string        # Login of the owner
-L, --limit int       # Maximum number of projects to fetch (default 30)

# JSON output options
--format string       # Output format: {json}
-q, --jq expression   # Filter JSON output using jq expression
-t, --template string # Format JSON output using Go template

# Other options
-w, --web             # Open projects list in web browser
```

**Authentication Note:** The minimum required scope for project commands is `project`. Verify with `gh auth status` and refresh with `gh auth refresh -s project` if needed.

### Pull Request Management
- `gh pr`: Pull request management and interactions

### Additional Core Commands
- `gh gist`: Create, list, and manage GitHub Gists
- `gh codespace`: Manage GitHub Codespaces
- `gh org`: Organization-related operations

## GitHub Actions Commands

- `gh cache`: GitHub Actions cache management
- `gh run`: Workflow run management and viewing
- `gh workflow`: GitHub Actions workflow control

## Additional Commands

- `gh alias`: Create command aliases
- `gh api`: Direct GitHub API interactions
- `gh attestation`: Software artifact verification
- `gh completion`: Shell completion setup
- `gh config`: CLI configuration management
- `gh extension`: Extend CLI functionality
- `gh gpg-key`: GPG key management
- `gh label`: Repository label management
- `gh search`: Search GitHub resources
- `gh secret`: Repository secret management
- `gh ssh-key`: SSH key management
- `gh variable`: Repository variable management

## JSON Output Options

GitHub CLI supports JSON output for most commands through several mechanisms:

### Common JSON Flags
- `--json fields`: Output JSON with specified fields
- `-q, --jq expression`: Filter JSON output using jq expressions
- `-t, --template string`: Format JSON output using Go templates
- `--format string`: For some commands, specify output format as `json`

### Example JSON Usage
```bash
# List issues in JSON format
gh issue list --json number,title,state,author

# Filter JSON output with jq
gh issue list --json number,title --jq '.[] | select(.title | contains("bug"))'

# Use Go template formatting
gh issue list --json number,title --template '{{range .}}{{.number}}: {{.title}}{{"\n"}}{{end}}'
```

## Global Options

- `--version`: Display CLI version
- `-R, --repo`: Select a specific repository (available for most commands)
- `-w, --web`: Open resource in web browser (available for many commands)

## Configuration and Setup

Use `gh config` commands to manage CLI configuration:
- Set default editor, protocol, browser
- Configure authentication preferences
- Manage aliases and extensions

For detailed help on any command, use:
```bash
gh help [command]
gh [command] --help
```

## Version 2.76.0 Release Notes (July 17, 2025)

### New Features
- **GitHub Copilot Assignment**: Ability to assign GitHub Copilot during issue creation
  - Command line: `gh issue create --assignee @copilot`
  - Web browser: `gh issue create --assignee @copilot --web`
  - Interactive selection of "Copilot (AI)" as assignee
- **Release View Enhancement**: Display immutable field in `release view` command

### Bug Fixes
- Do not fetch logs for skipped jobs
- Transform `extension` and `filename` qualifiers into `path` qualifier for web code search

### Platform Support
- Supports Free, Pro, Team versions
- Enterprise Cloud and Enterprise Server (versions 3.14-3.17)
- Multiple operating systems including macOS, Linux, and Windows

## Additional Resources

- **Official Manual**: https://cli.github.com/manual/
- **GitHub Repository**: https://github.com/cli/cli
- **Release Notes**: https://github.com/cli/cli/releases
- **Feedback**: Submit issues in the cli/cli repository