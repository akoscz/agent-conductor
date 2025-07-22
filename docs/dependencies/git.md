# Git 2.33.0 Essential Documentation

## Overview

Git is a fast, scalable, distributed revision control system with an unusually rich command set that provides both high-level operations and full access to internal mechanisms. This documentation covers the essential Git commands and concepts needed for effective version control and scripting.

## Table of Contents

1. [Core Git Commands](#core-git-commands)
2. [Branch Management](#branch-management)
3. [Remote Repository Operations](#remote-repository-operations)
4. [Configuration and Setup](#configuration-and-setup)
5. [Scripting with Git: Porcelain vs Plumbing](#scripting-with-git-porcelain-vs-plumbing)
6. [GitHub Integration](#github-integration)

## Core Git Commands

### git status

Shows the working tree status, displaying paths that have differences between the index file and the current HEAD commit, paths that have differences between the working tree and the index file, and paths in the working tree that are not tracked by Git.

**Basic Syntax:**
```bash
git status [<options>] [--] [<pathspec>…]
```

**Key Options:**
- `-s` or `--short`: Compact status output
- `--porcelain[=<version>]`: Machine-parsable format
- `--long`: Verbose default format (default)
- `-u[<mode>]`: Control display of untracked files
  - `no`: Hide untracked files
  - `normal`: Show untracked files/directories
  - `all`: Show individual files in untracked directories
- `-b` or `--branch`: Show branch and tracking info
- `-v`: Show staged changes
- `-vv`: Show both staged and unstaged changes

**Short Format Status Codes:**
- `' '` = unmodified
- `'M'` = modified
- `'A'` = added
- `'D'` = deleted
- `'R'` = renamed
- `'??'` = untracked
- `'!!'` = ignored

**Examples:**
```bash
# Basic status
git status

# Compact status
git status -s

# Show branch info
git status -b

# Ignore untracked files
git status -uno
```

### git add

Stages file contents to the index for the next commit.

**Basic Syntax:**
```bash
git add [<options>] [--] <pathspec>…
```

**Common Usage:**
```bash
# Stage a specific file
git add filename.txt

# Stage all changes
git add .

# Stage all tracked files
git add -u

# Interactive staging
git add -i
```

### git commit

Records changes to the repository by creating a new commit with staged changes.

**Basic Syntax:**
```bash
git commit [<options>] [--] <pathspec>…
```

**Common Options:**
- `-m <message>`: Use the given message as the commit message
- `-a`: Automatically stage all modified files
- `--amend`: Modify the last commit

**Examples:**
```bash
# Commit with message
git commit -m "Fix bug in user authentication"

# Commit all changes with message
git commit -am "Update documentation"

# Amend last commit
git commit --amend
```

### git diff

Shows changes between commits, commit and working tree, etc.

**Basic Syntax:**
```bash
git diff [<options>] [<commit>] [--] [<path>…]
```

**Common Usage:**
```bash
# Show unstaged changes
git diff

# Show staged changes
git diff --cached

# Compare two commits
git diff commit1..commit2

# Compare branches
git diff main feature-branch
```

### git log

Shows commit logs with various filtering and formatting options.

**Basic Syntax:**
```bash
git log [<options>] [<revision range>] [[--] <path>…]
```

**Key Options:**
- `-p` or `--patch`: Show changes introduced by each commit
- `--graph`: Draw a text-based graphical representation of commit history
- `--since=<date>`: Show commits more recent than a specific date
- `--author=<pattern>`: Limit commits by author name
- `--grep=<pattern>`: Search commit messages
- `--pretty=format:`: Customize output format

**Format Placeholders:**
- `%h`: Abbreviated commit hash
- `%an`: Author name
- `%s`: Commit subject line
- `%ad`: Author date

**Examples:**
```bash
# Basic log
git log

# Compact one-line format
git log --oneline

# Show graph with custom format
git log --pretty=format:"%h - %an, %ar : %s" --graph

# Filter by author
git log --author="John Doe"

# Filter by date
git log --since="2 weeks ago"
```

## Branch Management

### git branch

Lists, creates, or deletes branches.

**Basic Syntax:**
```bash
git branch [<options>] [<branch-name>]
```

**Common Operations:**
```bash
# List all branches
git branch

# List all branches including remote
git branch -a

# Create new branch
git branch feature-branch

# Delete branch
git branch -d feature-branch

# Force delete branch
git branch -D feature-branch
```

### git checkout / git switch

Switches branches or restores working tree files. Note: `git switch` is the newer, more focused command for branch switching.

**Basic Syntax:**
```bash
git checkout [<options>] <branch>
git switch [<options>] <branch>
```

**Examples:**
```bash
# Switch to existing branch
git checkout main
git switch main

# Create and switch to new branch
git checkout -b feature-branch
git switch -c feature-branch

# Switch to previous branch
git checkout -
git switch -
```

### git merge

Joins two or more development histories together.

**Basic Syntax:**
```bash
git merge [<options>] <commit>…
```

**Common Options:**
- `--no-ff`: Create a merge commit even if fast-forward is possible
- `--ff-only`: Only merge if fast-forward is possible
- `--squash`: Squash all commits into a single commit

**Examples:**
```bash
# Merge feature branch into current branch
git merge feature-branch

# Merge with no fast-forward
git merge --no-ff feature-branch
```

## Remote Repository Operations

### git clone

Creates a copy of a remote repository.

**Basic Syntax:**
```bash
git clone [<options>] <repository> [<directory>]
```

**Examples:**
```bash
# Clone repository
git clone https://github.com/user/repo.git

# Clone to specific directory
git clone https://github.com/user/repo.git my-project

# Clone specific branch
git clone -b feature-branch https://github.com/user/repo.git
```

### git fetch

Downloads objects and refs from another repository.

**Basic Syntax:**
```bash
git fetch [<options>] [<repository> [<refspec>…]]
```

**Examples:**
```bash
# Fetch from origin
git fetch origin

# Fetch all remotes
git fetch --all

# Fetch specific branch
git fetch origin main
```

### git pull

Fetches from and integrates with another repository or a local branch.

**Basic Syntax:**
```bash
git pull [<options>] [<repository> [<refspec>…]]
```

**Examples:**
```bash
# Pull from origin main
git pull origin main

# Pull with rebase
git pull --rebase origin main
```

### git push

Updates remote refs along with associated objects.

**Basic Syntax:**
```bash
git push [<options>] [<repository> [<refspec>…]]
```

**Examples:**
```bash
# Push to origin main
git push origin main

# Push new branch and set upstream
git push -u origin feature-branch

# Force push (use with caution)
git push --force origin main
```

## Configuration and Setup

### git config

Gets and sets repository or global options.

**Configuration Levels:**
- `--system`: System-wide configuration
- `--global`: User-specific configuration
- `--local`: Repository-specific configuration (default)

**Common Configuration:**
```bash
# Set user identity
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Set default editor
git config --global core.editor "vim"

# Set default branch name
git config --global init.defaultBranch main

# Create aliases
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit

# View configuration
git config --list
git config user.name
```

**Configuration File Locations:**
- System: `/etc/gitconfig`
- Global: `~/.gitconfig` or `~/.config/git/config`
- Local: `.git/config` (in repository)

### Common Configuration Options

**Core Settings:**
```ini
[core]
    editor = vim
    autocrlf = input
    filemode = false
    ignorecase = false

[init]
    defaultBranch = main

[pull]
    rebase = false

[push]
    default = simple

[color]
    ui = auto
```

**Useful Aliases:**
```ini
[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = !gitk
```

## Scripting with Git: Porcelain vs Plumbing

Git commands are divided into two categories:

### Porcelain Commands

High-level, user-friendly commands designed for interactive use:
- `git add`, `git commit`, `git push`, `git pull`
- `git branch`, `git merge`, `git log`
- `git status`, `git diff`

**Characteristics:**
- User-friendly interface
- May change behavior between versions
- Designed for human interaction
- Provide helpful output messages

### Plumbing Commands

Low-level commands designed for scripting and building tools:
- `git hash-object`: Store objects in Git database
- `git cat-file`: Display Git objects
- `git update-index`: Manipulate the index
- `git write-tree`: Create tree objects
- `git commit-tree`: Create commit objects
- `git update-ref`: Update references

**Characteristics:**
- Stable interface across Git versions
- Minimal, predictable output
- Designed for automation and scripting
- Direct access to Git's internal mechanisms

### Git Directory Structure

The `.git` directory contains:
- `objects/`: Git's content database
- `refs/`: Pointers to commit objects (branches, tags)
- `HEAD`: Pointer to current branch
- `index`: Staging area information
- `config`: Repository configuration

### Scripting Best Practices

**For Scripts:**
```bash
# Use plumbing commands for reliability
git rev-parse HEAD  # Get current commit hash
git symbolic-ref HEAD  # Get current branch name

# Use porcelain with --porcelain flag for stable output
git status --porcelain

# Check exit codes
if git diff-index --quiet HEAD --; then
    echo "No changes"
else
    echo "Changes detected"
fi
```

**Environment Variables:**
- `GIT_DIR`: Location of .git directory
- `GIT_WORK_TREE`: Location of working directory
- `GIT_INDEX_FILE`: Location of index file

## GitHub Integration

### Authentication

**HTTPS with Personal Access Token:**
```bash
git clone https://github.com/username/repo.git
# Use token as password when prompted
```

**SSH:**
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add to SSH agent
ssh-add ~/.ssh/id_ed25519

# Clone with SSH
git clone git@github.com:username/repo.git
```

### GitHub-Specific Workflows

**Fork and Pull Request Workflow:**
1. Fork repository on GitHub
2. Clone your fork locally
3. Create feature branch
4. Make changes and commit
5. Push to your fork
6. Create pull request

```bash
# Clone your fork
git clone https://github.com/yourusername/repo.git
cd repo

# Add upstream remote
git remote add upstream https://github.com/originaluser/repo.git

# Create feature branch
git checkout -b feature-branch

# Make changes and commit
git add .
git commit -m "Add new feature"

# Push to your fork
git push origin feature-branch

# Create pull request on GitHub web interface
```

**Keeping Fork Updated:**
```bash
# Fetch upstream changes
git fetch upstream

# Merge upstream main into local main
git checkout main
git merge upstream/main

# Push updated main to your fork
git push origin main
```

### GitHub Flow

1. Create a branch from main
2. Add commits
3. Open a pull request
4. Discuss and review code
5. Deploy and test
6. Merge to main

### Common GitHub Commands

```bash
# Check remote URLs
git remote -v

# Add remote
git remote add origin https://github.com/username/repo.git

# Change remote URL
git remote set-url origin https://github.com/username/new-repo.git

# Push and set upstream
git push -u origin main

# Delete remote branch
git push origin --delete feature-branch
```

### GitHub CLI Integration

If using GitHub CLI (`gh`):
```bash
# Create repository
gh repo create

# Create pull request
gh pr create

# List pull requests
gh pr list

# Check out pull request
gh pr checkout 123
```

---

This documentation provides a comprehensive reference for Git 2.33.0, covering essential commands, configuration, scripting considerations, and GitHub integration patterns commonly used in development workflows.