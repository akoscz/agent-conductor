#!/usr/bin/env bats

# Unit tests for shell alias installation logic

setup() {
    # Create a temporary directory for test files
    TEST_TEMP_DIR="$(mktemp -d)"
    TEST_SHELL_RC="$TEST_TEMP_DIR/test_zshrc"
    TEST_INSTALL_DIR="/test/install/dir"
}

teardown() {
    # Clean up temporary files
    rm -rf "$TEST_TEMP_DIR"
}

# Extract the shell alias setup function for testing
setup_shell_alias() {
    local install_dir="$1"
    local shell_rc="$2"
    
    # Remove any existing Agent Conductor aliases (including old names)
    if grep -q "# Agent Conductor aliases\|alias conductor=\|alias cond=\|alias orchestrator=\|alias ac=\|alias orch=" "$shell_rc" 2>/dev/null; then
        # Remove all Agent Conductor related content
        sed -i.bak '/^# Agent Conductor aliases[[:space:]]*$/d; /^alias conductor=/d; /^alias cond=/d; /^alias orchestrator=/d; /^alias ac=/d; /^alias orch=/d' "$shell_rc"
        rm -f "$shell_rc.bak"
    fi
    
    # Add aliases with proper spacing (only add blank line if file doesn't end with one)
    if [[ -s "$shell_rc" ]] && [[ $(tail -c1 "$shell_rc" 2>/dev/null | wc -l) -eq 0 ]]; then
        echo "" >> "$shell_rc"
    fi
    echo "# Agent Conductor aliases" >> "$shell_rc"
    echo "alias conductor='${install_dir}/bin/conductor'" >> "$shell_rc"
    echo "alias cond='${install_dir}/bin/conductor'  # Short alias" >> "$shell_rc"
}

@test "fresh install adds aliases correctly" {
    # Setup: Create a shell config with existing content
    cat > "$TEST_SHELL_RC" << 'EOF'
# Some existing content
export PATH=/usr/local/bin:$PATH
EOF

    # Run: Install aliases
    setup_shell_alias "$TEST_INSTALL_DIR" "$TEST_SHELL_RC"
    
    # Assert: Check that aliases were added correctly
    grep -q "# Agent Conductor aliases" "$TEST_SHELL_RC"
    grep -q "alias conductor='/test/install/dir/bin/conductor'" "$TEST_SHELL_RC"
    grep -q "alias cond='/test/install/dir/bin/conductor'  # Short alias" "$TEST_SHELL_RC"
    
    # Assert: Original content is preserved
    grep -q "export PATH=/usr/local/bin:\$PATH" "$TEST_SHELL_RC"
}

@test "reinstall replaces existing aliases" {
    # Setup: Create shell config with old aliases
    cat > "$TEST_SHELL_RC" << 'EOF'
# Some existing content

# Agent Conductor aliases
alias conductor='/old/install/dir/bin/conductor'
alias cond='/old/install/dir/bin/conductor'  # Short alias
EOF

    # Run: Install new aliases
    setup_shell_alias "/new/install/dir" "$TEST_SHELL_RC"
    
    # Assert: Only one set of aliases exists with new path
    [ $(grep -c "alias conductor=" "$TEST_SHELL_RC") -eq 1 ]
    [ $(grep -c "# Agent Conductor aliases" "$TEST_SHELL_RC") -eq 1 ]
    grep -q "alias conductor='/new/install/dir/bin/conductor'" "$TEST_SHELL_RC"
    
    # Assert: Old path is completely removed
    ! grep -q "/old/install/dir" "$TEST_SHELL_RC"
}

@test "removes old orchestrator aliases" {
    # Setup: Config with old alias names
    cat > "$TEST_SHELL_RC" << 'EOF'
# Some existing content
alias orchestrator='/old/install/dir/bin/conductor'
alias ac='/old/install/dir/bin/conductor'
alias orch='/old/install/dir/bin/conductor'
export PATH=/usr/local/bin:$PATH
EOF

    # Run: Install new aliases
    setup_shell_alias "$TEST_INSTALL_DIR" "$TEST_SHELL_RC"
    
    # Assert: Old aliases are removed
    ! grep -q "alias orchestrator=" "$TEST_SHELL_RC"
    ! grep -q "alias ac=" "$TEST_SHELL_RC"
    ! grep -q "alias orch=" "$TEST_SHELL_RC"
    
    # Assert: New aliases are added
    grep -q "alias conductor='/test/install/dir/bin/conductor'" "$TEST_SHELL_RC"
    grep -q "alias cond='/test/install/dir/bin/conductor'" "$TEST_SHELL_RC"
    
    # Assert: Other content preserved
    grep -q "export PATH=/usr/local/bin:\$PATH" "$TEST_SHELL_RC"
}

@test "multiple reinstalls don't create duplicates" {
    # Setup: Start with empty config
    echo "# Initial content" > "$TEST_SHELL_RC"
    
    # Run: Install multiple times
    setup_shell_alias "/install1" "$TEST_SHELL_RC"
    setup_shell_alias "/install2" "$TEST_SHELL_RC"
    setup_shell_alias "/install3" "$TEST_SHELL_RC"
    
    # Assert: Only one set of aliases exists
    [ $(grep -c "alias conductor=" "$TEST_SHELL_RC") -eq 1 ]
    [ $(grep -c "alias cond=" "$TEST_SHELL_RC") -eq 1 ]
    [ $(grep -c "# Agent Conductor aliases" "$TEST_SHELL_RC") -eq 1 ]
    
    # Assert: Latest install path is used
    grep -q "alias conductor='/install3/bin/conductor'" "$TEST_SHELL_RC"
}

@test "cleans up messy existing config" {
    # Setup: Create a messy config with duplicates and old names
    cat > "$TEST_SHELL_RC" << 'EOF'
# Some content
alias cond='/old1/bin/conductor'  # Short alias

# Agent Conductor aliases

# Agent Conductor aliases
alias conductor='/old2/bin/conductor'
alias cond='/old2/bin/conductor'  # Short alias
alias orchestrator='/old3/bin/conductor'
alias ac='/old4/bin/conductor'

# More content
export PATH=/usr/local/bin:$PATH
EOF

    # Run: Install clean aliases
    setup_shell_alias "/clean/install" "$TEST_SHELL_RC"
    
    # Assert: Only one clean set of aliases
    [ $(grep -c "alias conductor=" "$TEST_SHELL_RC") -eq 1 ]
    [ $(grep -c "alias cond=" "$TEST_SHELL_RC") -eq 1 ]
    [ $(grep -c "# Agent Conductor aliases" "$TEST_SHELL_RC") -eq 1 ]
    
    # Assert: All old aliases removed
    ! grep -q "orchestrator" "$TEST_SHELL_RC"
    ! grep -q "alias ac=" "$TEST_SHELL_RC"
    ! grep -q "/old1/" "$TEST_SHELL_RC"
    ! grep -q "/old2/" "$TEST_SHELL_RC"
    
    # Assert: Clean aliases added
    grep -q "alias conductor='/clean/install/bin/conductor'" "$TEST_SHELL_RC"
    
    # Assert: Other content preserved
    grep -q "export PATH=/usr/local/bin:\$PATH" "$TEST_SHELL_RC"
}

@test "handles empty shell config" {
    # Setup: Empty config
    touch "$TEST_SHELL_RC"
    
    # Run: Install aliases
    setup_shell_alias "$TEST_INSTALL_DIR" "$TEST_SHELL_RC"
    
    # Assert: Aliases added correctly
    grep -q "# Agent Conductor aliases" "$TEST_SHELL_RC"
    grep -q "alias conductor='/test/install/dir/bin/conductor'" "$TEST_SHELL_RC"
    grep -q "alias cond='/test/install/dir/bin/conductor'" "$TEST_SHELL_RC"
}

@test "preserves spacing and formatting" {
    # Setup: Config with specific formatting
    cat > "$TEST_SHELL_RC" << 'EOF'
# Important header

export IMPORTANT_VAR="value"

# Another section
alias important_alias='some_command'
EOF

    # Run: Install aliases
    setup_shell_alias "$TEST_INSTALL_DIR" "$TEST_SHELL_RC"
    
    # Assert: Original formatting preserved
    grep -q "# Important header" "$TEST_SHELL_RC"
    grep -q "export IMPORTANT_VAR=" "$TEST_SHELL_RC"
    grep -q "alias important_alias=" "$TEST_SHELL_RC"
    
    # Assert: Aliases added with proper spacing
    grep -q "^# Agent Conductor aliases$" "$TEST_SHELL_RC"
}

@test "handles special characters in install path" {
    local special_path="/path with spaces/and-dashes/install_dir"
    
    # Setup: Basic config
    echo "# Test config" > "$TEST_SHELL_RC"
    
    # Run: Install with special path
    setup_shell_alias "$special_path" "$TEST_SHELL_RC"
    
    # Assert: Path handled correctly
    grep -q "alias conductor='/path with spaces/and-dashes/install_dir/bin/conductor'" "$TEST_SHELL_RC"
}