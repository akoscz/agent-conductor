# BATS (Bash Automated Testing System) Documentation

## Overview

BATS (Bash Automated Testing System) is a TAP-compliant testing framework for Bash 3.2 and above, designed to help developers verify the behavior of UNIX programs and Bash scripts. It provides a simple syntax for writing tests and includes features for test organization, filtering, and parallel execution.

## Installation

BATS can be installed through various methods:

- **Linux package managers**: Available in most distributions
- **macOS Homebrew**: `brew install bats-core`
- **npm**: `npm install -g bats`
- **Git submodules**: Recommended for projects
- **Docker**: Official Docker images available

### Recommended Project Structure

```
src/
    project.sh
test/
    bats/
    test_helper/
        bats-support/
        bats-assert/
    test.bats
```

## BATS Test Syntax and Structure

### Basic Test Structure

A BATS test file is a Bash script with the `.bats` extension. Tests are defined using the `@test` directive followed by a description:

```bash
#!/usr/bin/env bats

@test "addition using bc" {
  result="$(echo 2+2 | bc)"
  [ "$result" -eq 4 ]
}

@test "addition using dc" {
  result="$(echo 2 2+p | dc)"
  [ "$result" -eq 4 ]
}
```

### Test Execution Principles

- Each test case is essentially a function with a description
- Tests use Bash's `errexit` (`set -e`) option
- A test passes if all commands exit with a `0` status code
- "Each line is an assertion of truth"
- Test files are evaluated multiple times during test discovery

### Test Tagging

Tests can be tagged for organization and filtering:

```bash
@test "database connection test" {
  # bats test_tags=database,integration
  run connect_to_database
  [ "$status" -eq 0 ]
}
```

### Minimum Version Requirements

Specify minimum BATS version for compatibility:

```bash
bats_require_minimum_version 1.5.0
```

## Test Assertions and Helpers

### Core Testing Functions

#### `run` Command

The `run` helper executes commands and captures their output and exit status:

```bash
@test "can run our script" {
    run project.sh
    [ "$status" -eq 0 ]
    [ "$output" = "Welcome to our project!" ]
}
```

#### Built-in Assertions

Basic assertions using standard shell commands:

```bash
@test "basic assertions" {
    run echo "hello world"
    [ "$status" -eq 0 ]                    # Exit status check
    [ "$output" = "hello world" ]          # Exact output match
    [[ "$output" =~ hello ]]               # Regex match
    [ "${lines[0]}" = "hello world" ]      # First line check
}
```

### Assertion Libraries

#### bats-assert Library

Provides enhanced assertion functions:

```bash
@test "enhanced assertions" {
    run project.sh
    assert_success                          # Assert exit code 0
    assert_failure                          # Assert non-zero exit code
    assert_output "expected output"         # Exact output match
    assert_output --partial "partial"      # Partial output match
    refute_output "unwanted text"          # Assert output doesn't contain text
    assert_line "specific line"            # Assert specific line exists
}
```

#### bats-support Library

Provides additional helper functions and improves error reporting.

### Special Variables

BATS provides several special variables accessible in tests:

- `$status`: Exit status of the last command run via `run`
- `$output`: Combined stdout and stderr of the last command
- `$lines`: Array containing each line of `$output`
- `$BATS_TEST_FILENAME`: Full path to the current test file
- `$BATS_TEST_NAME`: Name of the current test function
- `$BATS_TEST_DIRNAME`: Directory containing the current test file

## Setup and Teardown Functions

### Per-Test Hooks

Functions that run before and after each test:

```bash
setup() {
    # Runs before each test
    export TEST_TEMP_DIR="$(mktemp -d)"
    cd "$TEST_TEMP_DIR"
}

teardown() {
    # Runs after each test
    rm -rf "$TEST_TEMP_DIR"
}

@test "example test with setup/teardown" {
    echo "test data" > testfile.txt
    [ -f testfile.txt ]
}
```

### Per-File Hooks

Functions that run once per test file:

```bash
setup_file() {
    # Runs once before all tests in the file
    export SHARED_RESOURCE="$(setup_expensive_resource)"
}

teardown_file() {
    # Runs once after all tests in the file
    cleanup_expensive_resource "$SHARED_RESOURCE"
}
```

### Per-Suite Hooks

Functions that run once for the entire test suite:

```bash
setup_suite() {
    # Runs once before all test files
    start_test_database
}

teardown_suite() {
    # Runs once after all test files
    stop_test_database
}
```

## Running Tests and Filtering

### Basic Execution

```bash
# Run a single test file
bats test/example.bats

# Run all tests in a directory
bats test/

# Run tests recursively
bats -r test/
```

### Command Line Options

#### Test Filtering

```bash
# Filter tests by name using regex
bats -f "addition" test/

# Filter tests by tags
bats --filter-tags database test/

# Filter tests by previous run status
bats --filter-status failed test/
```

#### Output Formatting

```bash
# Pretty format (default, human-readable)
bats -p test/

# TAP format (machine-parsable)
bats -t test/

# JUnit format
bats -F junit test/

# Generate test reports
bats --report-formatter junit test/
```

#### Parallel Execution

```bash
# Run tests in parallel (number of jobs)
bats -j 4 test/

# Serialize file execution but parallelize within files
bats --no-parallelize-across-files test/

# Serialize test execution within files
bats --no-parallelize-within-files test/
```

#### Debugging Options

```bash
# Print executed test commands
bats -x test/

# Add timing information
bats -T test/

# Show output on test failures
bats --print-output-on-failure test/
```

### Exit Codes

- `0`: All tests pass
- `1`: Test failures detected

## Test Organization Best Practices

### File Organization

1. **Separate test files by functionality**:
   - `test/unit/` for unit tests
   - `test/integration/` for integration tests
   - `test/acceptance/` for acceptance tests

2. **Use descriptive file names**:
   - `test_user_management.bats`
   - `test_database_operations.bats`

3. **Share common code with `load`**:

```bash
# test/test_helper.bash
setup_test_environment() {
    export TEST_ENV="testing"
    export PATH="$BATS_TEST_DIRNAME/../src:$PATH"
}

# test/example.bats
load 'test_helper'

setup() {
    setup_test_environment
}
```

### Test Naming Conventions

Use descriptive test names that explain the expected behavior:

```bash
@test "user registration with valid email should succeed" { }
@test "user registration with invalid email should fail" { }
@test "user login with correct credentials should return success" { }
```

### Test Independence

Ensure tests don't depend on each other:

```bash
# Good: Each test sets up its own state
@test "create user" {
    run create_user "testuser"
    assert_success
}

@test "delete user" {
    run create_user "testuser"  # Set up state
    run delete_user "testuser"
    assert_success
}

# Bad: Second test depends on first test
@test "create user" {
    run create_user "testuser"
    assert_success
}

@test "delete user that was created" {
    run delete_user "testuser"  # Depends on previous test
    assert_success
}
```

## Integration with Shell Scripts

### Testing Shell Functions

Load and test individual shell functions:

```bash
# src/utils.sh
calculate_sum() {
    echo $(( $1 + $2 ))
}

# test/test_utils.bats
load '../src/utils.sh'

@test "calculate_sum adds two numbers" {
    result=$(calculate_sum 5 3)
    [ "$result" -eq 8 ]
}
```

### Testing Command Line Programs

Test complete programs with various inputs:

```bash
@test "program handles missing arguments" {
    run ./myprogram
    assert_failure
    assert_output --partial "Usage:"
}

@test "program processes valid input file" {
    echo "test data" > input.txt
    run ./myprogram input.txt
    assert_success
    assert_output "Processed 1 line"
}
```

### Testing Scripts with Dependencies

Mock external dependencies:

```bash
setup() {
    # Create mock commands
    export PATH="$BATS_TEST_DIRNAME/mocks:$PATH"
    
    # Create mock git command
    cat > "$BATS_TEST_DIRNAME/mocks/git" << 'EOF'
#!/bin/bash
echo "mocked git output"
exit 0
EOF
    chmod +x "$BATS_TEST_DIRNAME/mocks/git"
}

@test "script calls git correctly" {
    run ./deploy.sh
    assert_success
    assert_output --partial "mocked git output"
}
```

### Environment Variable Testing

Test scripts that rely on environment variables:

```bash
@test "script uses default config when ENV_VAR not set" {
    unset MY_CONFIG_VAR
    run ./script.sh
    assert_output --partial "Using default config"
}

@test "script uses custom config when ENV_VAR is set" {
    export MY_CONFIG_VAR="custom_value"
    run ./script.sh
    assert_output --partial "Using custom config: custom_value"
}
```

## Advanced Features

### Conditional Test Skipping

Skip tests based on conditions:

```bash
@test "test requiring docker" {
    if ! command -v docker >/dev/null; then
        skip "Docker not available"
    fi
    
    run docker --version
    assert_success
}
```

### Testing Piped Commands

Use `bats_pipe` for testing command pipelines:

```bash
@test "pipeline processing" {
    echo "input data" | bats_pipe run process_data | run format_output
    assert_success
    assert_output "formatted: input data"
}
```

### Background Process Testing

Test long-running processes:

```bash
@test "background service starts correctly" {
    run_in_background ./service.sh
    sleep 2
    
    run pgrep -f service.sh
    assert_success
    
    # Cleanup
    pkill -f service.sh
}
```

### Failure Hooks

Execute code when tests fail:

```bash
teardown() {
    if [ "$BATS_TEST_COMPLETED" != "1" ]; then
        echo "Test failed, collecting debug info..." >&3
        ps aux >&3
        df -h >&3
    fi
}
```

## Common Patterns and Examples

### Testing Error Conditions

```bash
@test "script fails gracefully with invalid input" {
    run ./script.sh --invalid-option
    assert_failure
    assert_output --partial "Error: Unknown option"
}
```

### Testing File Operations

```bash
@test "script creates output file" {
    run ./generate_report.sh
    assert_success
    [ -f "report.txt" ]
    
    run cat report.txt
    assert_output --partial "Report generated on"
}
```

### Testing Interactive Scripts

```bash
@test "interactive script with input" {
    run bash -c 'echo "yes" | ./interactive_script.sh'
    assert_success
    assert_output --partial "You selected: yes"
}
```

### Performance Testing

```bash
@test "script completes within reasonable time" {
    start_time=$(date +%s)
    run ./slow_script.sh
    end_time=$(date +%s)
    
    duration=$((end_time - start_time))
    [ "$duration" -lt 30 ]  # Should complete in under 30 seconds
}
```

## Debugging and Troubleshooting

### Common Issues

1. **Tests pass individually but fail when run together**
   - Check for shared state between tests
   - Ensure proper cleanup in teardown functions

2. **Tests fail in CI but pass locally**
   - Check for environment differences
   - Verify all dependencies are available

3. **Parallel execution issues**
   - Some tests may have hidden dependencies
   - Use `--no-parallelize-across-files` or `--no-parallelize-within-files`

### Debugging Techniques

```bash
# Print debug information (use file descriptor 3)
@test "debug example" {
    echo "Debug: Starting test" >&3
    run some_command
    echo "Debug: Command output: $output" >&3
    assert_success
}

# Use trace mode to see executed commands
bats -x test/example.bats
```

## Resources and References

- **Official Documentation**: [https://bats-core.readthedocs.io](https://bats-core.readthedocs.io)
- **GitHub Repository**: [https://github.com/bats-core/bats-core](https://github.com/bats-core/bats-core)
- **Community Chat**: [Gitter](https://gitter.im/bats-core/bats-core)
- **bats-assert Library**: [https://github.com/bats-core/bats-assert](https://github.com/bats-core/bats-assert)
- **bats-support Library**: [https://github.com/bats-core/bats-support](https://github.com/bats-core/bats-support)

## License

BATS is released under an MIT-style license with copyright held by the bats-core organization and Sam Stephenson.