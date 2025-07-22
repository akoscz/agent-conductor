# tmux 3.5a Documentation

## Overview

tmux is a terminal multiplexer that enables multiple terminals to be created, accessed, and controlled from a single screen. It allows you to detach and reattach sessions while programs continue running in the background.

**Supported Platforms**: OpenBSD, FreeBSD, NetBSD, Linux, macOS, and Solaris

## Installation

### Dependencies
- libevent 2.x
- ncurses
- C compiler, make, pkg-config, and yacc (bison)

### Installation Steps
```bash
# From release tarball
$ ./configure && make
$ sudo make install

# From version control
$ git clone https://github.com/tmux/tmux.git
$ cd tmux
$ sh autogen.sh
$ ./configure && make
```

## Core Concepts

### Sessions
- A session is a collection of pseudo terminals managed by tmux
- Sessions persist when you disconnect from the terminal
- Can contain multiple windows
- Identified by name or number

### Windows
- Each window occupies the entire screen
- Windows can be split into rectangular panes
- Similar to tabs in a web browser

### Panes
- Subdivisions within a window
- Each pane is a separate pseudo terminal
- Can be arranged in various layouts

## Session Management Commands

### Creating Sessions
```bash
tmux new-session                    # Create new session
tmux new-session -s mywork          # Create session named "mywork"
tmux new-session -d                 # Create detached session
```

### Attaching to Sessions
```bash
tmux attach                         # Attach to last session
tmux attach -t mywork               # Attach to session "mywork"
tmux a -t 0                        # Attach to session 0
```

### Listing and Managing Sessions
```bash
tmux list-sessions                  # List all sessions
tmux ls                            # Short form
tmux kill-session -t mywork        # Kill session "mywork"
tmux kill-server                   # Kill all sessions
```

### Session Navigation (within tmux)
- `prefix + s`: List sessions
- `prefix + $`: Rename current session
- `prefix + d`: Detach from session

## Window Management

### Creating and Managing Windows
```bash
tmux new-window                     # Create new window
tmux new-window -n editor           # Create window named "editor"
tmux select-window -t 2             # Select window 2
tmux rename-window newname          # Rename current window
```

### Window Navigation (within tmux)
- `prefix + c`: Create new window
- `prefix + n`: Next window
- `prefix + p`: Previous window
- `prefix + l`: Last window
- `prefix + 0-9`: Select window by number
- `prefix + ,`: Rename window
- `prefix + &`: Kill window
- `prefix + w`: List windows

## Pane Management

### Creating Panes
```bash
tmux split-window                   # Split horizontally
tmux split-window -h                # Split vertically
tmux split-window -v                # Split horizontally (explicit)
```

### Pane Navigation and Control (within tmux)
- `prefix + %`: Split pane vertically
- `prefix + "`: Split pane horizontally
- `prefix + arrow keys`: Navigate between panes
- `prefix + q`: Show pane numbers
- `prefix + o`: Go to next pane
- `prefix + z`: Toggle pane zoom
- `prefix + x`: Kill current pane
- `prefix + {`: Move pane left
- `prefix + }`: Move pane right

### Resizing Panes
```bash
tmux resize-pane -D 5               # Resize down by 5 lines
tmux resize-pane -U 5               # Resize up by 5 lines
tmux resize-pane -L 5               # Resize left by 5 columns
tmux resize-pane -R 5               # Resize right by 5 columns
```

### Pane Resizing (within tmux)
- `prefix + Ctrl + arrow keys`: Resize pane
- `prefix + Alt + arrow keys`: Resize pane in larger increments

## Key Bindings and Configuration

### Default Prefix Key
- Default: `Ctrl-b` (written as `prefix` in documentation)
- Can be changed in configuration

### Essential Key Bindings
- `prefix + ?`: List all key bindings
- `prefix + :`: Enter command mode
- `prefix + [`: Enter copy mode
- `prefix + ]`: Paste buffer
- `prefix + r`: Reload configuration file (if configured)

### Copy Mode
- `prefix + [`: Enter copy mode
- `Space`: Start selection
- `Enter`: Copy selection
- `prefix + ]`: Paste
- `q`: Exit copy mode

## Configuration

### Configuration Files
- User config: `~/.tmux.conf`
- System config: `/etc/tmux.conf`

### Essential Configuration Options

#### Changing Prefix Key
```bash
# Change prefix from C-b to C-a
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix
```

#### Mouse Support
```bash
# Enable mouse support
set -g mouse on
```

#### Status Line Configuration
```bash
# Status line settings
set -g status-right "%H:%M"
set -g window-status-current-style "underscore"
```

#### Terminal and Color Settings
```bash
# Enable RGB color support
set-option -sa terminal-features ",xterm*:RGB"
set -g default-terminal "tmux-256color"
```

#### Key Binding Examples
```bash
# Create custom key bindings
bind-key h select-pane -L
bind-key j select-pane -D
bind-key k select-pane -U
bind-key l select-pane -R

# Reload configuration
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"
```

## Scripting tmux

### Sending Commands
```bash
# Send commands to specific sessions/windows/panes
tmux send-keys -t mywork:0 'ls -la' Enter
tmux send-keys -t mywork:editor 'vim file.txt' Enter

# Send to specific pane
tmux send-keys -t mywork:0.1 'echo hello' Enter
```

### Creating Complex Setups
```bash
#!/bin/bash
# Script to create development environment

# Create new session
tmux new-session -d -s dev

# Split window
tmux split-window -h
tmux split-window -v

# Send commands to panes
tmux send-keys -t dev:0.0 'cd ~/project && vim .' Enter
tmux send-keys -t dev:0.1 'cd ~/project && npm run dev' Enter
tmux send-keys -t dev:0.2 'cd ~/project && git status' Enter

# Attach to session
tmux attach-session -t dev
```

### Environment Variables
```bash
# Check if running inside tmux
if [ -n "$TMUX" ]; then
    echo "Running inside tmux"
fi
```

## Advanced Features

### Layouts
- `prefix + space`: Cycle through preset layouts
- Available layouts: even-horizontal, even-vertical, main-horizontal, main-vertical, tiled

### Session Sharing
```bash
# Multiple users can attach to same session
tmux new-session -s shared
# Other user: tmux attach -t shared
```

### Capturing Pane Content
```bash
tmux capture-pane -t mywork:0        # Capture pane content
tmux save-buffer ~/pane-content.txt  # Save to file
```

### Window Monitoring
```bash
# Monitor window for activity
tmux set-window-option monitor-activity on
```

## Troubleshooting

### Common Issues
1. **Nested tmux sessions**: Avoid running tmux inside tmux
2. **Key conflicts**: Some key combinations might conflict with terminal or SSH
3. **Color issues**: Ensure terminal supports 256 colors

### Debugging
```bash
# Verbose logging
tmux -v new-session
tmux -vv new-session  # Very verbose
```

### Useful Commands for Debugging
```bash
tmux info                           # Show tmux info
tmux list-keys                      # List all key bindings
tmux show-options -g                # Show global options
tmux display-message '#{session_name}' # Display current session name
```

## Best Practices

1. **Use meaningful session names** for easy identification
2. **Configure mouse support** for easier navigation
3. **Create startup scripts** for common development environments
4. **Use copy mode** efficiently for text selection
5. **Customize key bindings** to match your workflow
6. **Use status line** to display useful information
7. **Keep sessions organized** - don't create too many at once

## Resources

- **Manual page**: `man tmux`
- **Wiki**: https://github.com/tmux/tmux/wiki
- **FAQ**: https://github.com/tmux/tmux/wiki/FAQ
- **Mailing list**: tmux-users@googlegroups.com
- **GitHub repository**: https://github.com/tmux/tmux

## Example Configuration File

```bash
# ~/.tmux.conf example configuration

# Change prefix key to C-a
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Enable mouse support
set -g mouse on

# Set default terminal
set -g default-terminal "tmux-256color"
set-option -sa terminal-features ",xterm*:RGB"

# Status line configuration
set -g status-right "%H:%M"
set -g window-status-current-style "underscore"

# Custom key bindings
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Reload configuration
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# Split panes using | and -
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Enable activity monitoring
setw -g monitor-activity on
set -g visual-activity on

# Start window numbers at 1
set -g base-index 1
setw -g pane-base-index 1

# Don't rename windows automatically
set-option -g allow-rename off
```

This documentation covers the essential aspects of tmux 3.5a including session management, window and pane operations, key bindings, configuration, and scripting capabilities.