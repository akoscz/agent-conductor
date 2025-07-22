# yq Documentation (v4.46.1)

## Overview

`yq` is a lightweight and portable command-line YAML, JSON, INI, XML, CSV, and properties processor written in Go. It uses jq-like syntax but works with YAML files as well as JSON, making it an essential tool for shell scripting and configuration file manipulation.

### Key Features
- Process YAML, JSON, INI, XML, CSV, TSV, and properties files
- jq-like syntax for familiar query patterns
- Multi-document YAML support
- In-place file editing capabilities
- Colorized output for better readability
- Comment and formatting preservation (when possible)
- Dependency-free binary distribution
- Cross-platform compatibility (Linux, macOS, Windows)

## Installation

### Direct Binary Download
```bash
# Latest version
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
chmod +x /usr/bin/yq
```

### Package Managers
```bash
# Homebrew (macOS/Linux)
brew install yq

# Snap
sudo snap install yq

# Go install
go install github.com/mikefarah/yq/v4@latest
```

### Docker
```bash
docker run --rm -i -v "${PWD}":/workdir mikefarah/yq:4.46.1
```

## Basic Command Syntax

### Core Usage Pattern
```bash
yq '[expression]' [file...]
```

### Key Command Line Options

| Option | Description |
|--------|-------------|
| `-i, --inplace` | Update file(s) in place |
| `-o, --output-format` | Output format (yaml, json, xml, csv, tsv, props) |
| `-p, --input-format` | Input format (yaml, json, xml, csv, tsv, props) |
| `-I, --indent` | Set output indent (default 2) |
| `-C, --colors` | Force colorized output |
| `-M, --no-colors` | Force monochrome output |
| `-n, --null-input` | Don't read input, create documents from scratch |
| `-r, --unwrapScalar` | Unwrap scalar values (remove quotes) |
| `-e, --exit-status` | Set exit status based on output |
| `-v, --verbose` | Verbose logging |

## YAML/JSON Processing Operations

### Reading Values

```bash
# Read simple value
yq '.database.host' config.yaml

# Read array element
yq '.servers[0].name' config.yaml

# Read nested value
yq '.app.database.credentials.username' config.yaml

# Read multiple values
yq '.database.host, .database.port' config.yaml
```

### Writing/Updating Values

```bash
# Update simple value
yq -i '.database.host = "localhost"' config.yaml

# Update array element
yq -i '.servers[0].name = "web-01"' config.yaml

# Add new key-value pair
yq -i '.database.timeout = 30' config.yaml

# Update multiple values
yq -i '.database.host = "localhost" | .database.port = 5432' config.yaml
```

### Array Operations

```bash
# Add element to array
yq -i '.servers += [{"name": "web-03", "ip": "192.168.1.3"}]' config.yaml

# Update array element by condition
yq -i '(.servers[] | select(.name == "web-01") | .ip) = "192.168.1.10"' config.yaml

# Remove array element
yq -i 'del(.servers[0])' config.yaml

# Sort array by field
yq -i '.servers |= sort_by(.name)' config.yaml
```

## Querying and Filtering Data

### Basic Querying

```bash
# Get all keys at root level
yq 'keys' config.yaml

# Get all values from array
yq '.servers[].name' config.yaml

# Get length of array
yq '.servers | length' config.yaml

# Check if key exists
yq 'has("database")' config.yaml
```

### Filtering with Select

```bash
# Filter array elements by condition
yq '.servers[] | select(.environment == "production")' config.yaml

# Filter by multiple conditions
yq '.servers[] | select(.environment == "production" and .status == "active")' config.yaml

# Filter using regular expressions
yq '.servers[] | select(.name | test("web-.*"))' config.yaml

# Filter by value existence
yq '.servers[] | select(has("backup_enabled"))' config.yaml
```

### Advanced Filtering

```bash
# Find unique values
yq '[.servers[].environment] | unique' config.yaml

# Group by field
yq 'group_by(.environment)' config.yaml

# Get minimum/maximum values
yq '[.servers[].cpu_cores] | min' config.yaml
yq '[.servers[].cpu_cores] | max' config.yaml

# Filter and transform
yq '.servers[] | select(.cpu_cores > 4) | {name, cpu_cores}' config.yaml
```

## Modifying YAML Files

### In-Place Modifications

```bash
# Update configuration values
yq -i '.app.debug = true' config.yaml

# Set environment-specific values
yq -i '.database.host = env(DB_HOST)' config.yaml

# Update nested structures
yq -i '.app.features.authentication.enabled = true' config.yaml

# Conditional updates
yq -i '(.servers[] | select(.name == "web-01") | .maintenance_mode) = true' config.yaml
```

### Merging Files

```bash
# Merge two YAML files
yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' base.yaml override.yaml

# Merge with null input (create new file)
yq -n 'load("file1.yaml") * load("file2.yaml")' > merged.yaml

# Deep merge arrays
yq eval-all '. as $item ireduce ({}; . * $item)' file1.yaml file2.yaml
```

### Delete Operations

```bash
# Delete key
yq -i 'del(.database.password)' config.yaml

# Delete array element
yq -i 'del(.servers[1])' config.yaml

# Delete by condition
yq -i 'del(.servers[] | select(.status == "inactive"))' config.yaml

# Delete multiple keys
yq -i 'del(.database.password, .app.secret_key)' config.yaml
```

## Input/Output Formats

### Format Conversion

```bash
# YAML to JSON
yq -o json config.yaml

# JSON to YAML
yq -p json -o yaml data.json

# XML to YAML
yq -p xml -o yaml data.xml

# CSV to JSON
yq -p csv -o json data.csv
```

### Format-Specific Options

```bash
# Pretty print JSON
yq -o json -I 4 config.yaml

# Compact JSON
yq -o json -I 0 config.yaml

# XML with custom root
yq -o xml --xml-root-name "configuration" config.yaml

# CSV with custom delimiter
yq -p csv --csv-separator ";" data.csv
```

### Output Formatting

```bash
# Raw output (no quotes for strings)
yq -r '.database.host' config.yaml

# Null input for creating new documents
yq -n '{name: "test", version: "1.0"}' > new.yaml

# Multiple document output
yq -s '.environment' config.yaml  # Split by environment field
```

## Common Examples for Shell Scripting

### Configuration Management

```bash
#!/bin/bash

# Read configuration values
DB_HOST=$(yq '.database.host' config.yaml)
DB_PORT=$(yq '.database.port' config.yaml)
DB_NAME=$(yq '.database.name' config.yaml)

# Update configuration from environment variables
yq -i '.database.host = env(DB_HOST)' config.yaml
yq -i '.database.port = env(DB_PORT)' config.yaml

# Validate configuration
if yq -e '.database.host' config.yaml > /dev/null; then
    echo "Database host is configured"
else
    echo "Database host is missing"
    exit 1
fi
```

### Array Processing

```bash
#!/bin/bash

# Process all servers
yq '.servers[]' config.yaml | while IFS= read -r server; do
    name=$(echo "$server" | yq '.name')
    ip=$(echo "$server" | yq '.ip')
    echo "Processing server: $name ($ip)"
done

# Get server count by environment
for env in $(yq '.servers[].environment' config.yaml | sort | uniq); do
    count=$(yq ".servers[] | select(.environment == \"$env\") | length" config.yaml)
    echo "$env: $count servers"
done
```

### Conditional Operations

```bash
#!/bin/bash

# Update configuration based on conditions
if [[ "$ENVIRONMENT" == "production" ]]; then
    yq -i '.app.debug = false' config.yaml
    yq -i '.logging.level = "error"' config.yaml
else
    yq -i '.app.debug = true' config.yaml
    yq -i '.logging.level = "debug"' config.yaml
fi

# Enable features based on environment
if yq -e '.features.authentication' config.yaml > /dev/null; then
    yq -i '.features.authentication.enabled = true' config.yaml
fi
```

### Data Validation

```bash
#!/bin/bash

validate_config() {
    local config_file="$1"
    
    # Check required fields
    required_fields=("database.host" "database.port" "app.name")
    
    for field in "${required_fields[@]}"; do
        if ! yq -e ".$field" "$config_file" > /dev/null; then
            echo "Error: Required field '$field' is missing"
            return 1
        fi
    done
    
    # Validate data types
    if ! yq -e '.database.port | type == "number"' "$config_file" > /dev/null; then
        echo "Error: database.port must be a number"
        return 1
    fi
    
    echo "Configuration is valid"
    return 0
}
```

### Environment Variable Integration

```bash
#!/bin/bash

# Set values from environment variables
yq -i '.database.host = env(DATABASE_HOST)' config.yaml
yq -i '.database.port = (env(DATABASE_PORT) | tonumber)' config.yaml
yq -i '.app.debug = (env(DEBUG) == "true")' config.yaml

# Export configuration as environment variables
eval $(yq -r '
    to_entries |
    map(select(.value | type == "string")) |
    map("export " + .key + "=" + (.value | @sh)) |
    .[]
' simple_config.yaml)
```

### File Processing Patterns

```bash
#!/bin/bash

# Process multiple configuration files
find ./configs -name "*.yaml" | while read -r file; do
    echo "Processing $file"
    
    # Update common settings
    yq -i '.metadata.updated = now' "$file"
    yq -i '.metadata.version = "2.0"' "$file"
    
    # Validate after update
    if yq -e '.metadata.name' "$file" > /dev/null; then
        echo "✓ Updated $file successfully"
    else
        echo "✗ Failed to update $file"
    fi
done

# Merge multiple files into one
yq eval-all '. as $item ireduce ({}; . * $item)' configs/*.yaml > merged_config.yaml
```

### Advanced Text Processing

```bash
#!/bin/bash

# Extract and format data for reporting
yq '.servers[] | 
    select(.status == "active") |
    "\(.name),\(.ip),\(.environment),\(.cpu_cores)"
' config.yaml > server_report.csv

# Generate shell script from configuration
yq '.deployment.steps[] |
    "echo \"Executing: \(.description)\""
' deployment.yaml > deploy_script.sh

chmod +x deploy_script.sh
```

## Error Handling and Best Practices

### Error Handling in Scripts

```bash
#!/bin/bash

# Safe configuration reading with defaults
get_config_value() {
    local key="$1"
    local default="$2"
    local config_file="${3:-config.yaml}"
    
    if [[ -f "$config_file" ]]; then
        yq -e ".$key" "$config_file" 2>/dev/null || echo "$default"
    else
        echo "$default"
    fi
}

# Usage
DB_HOST=$(get_config_value "database.host" "localhost")
DB_PORT=$(get_config_value "database.port" "5432")
```

### Performance Tips

```bash
# Use specific paths instead of wildcards when possible
yq '.database.host' config.yaml    # Good
yq '.[] | select(.name == "database") | .host' config.yaml    # Less efficient

# Process multiple values in one command
yq '.database | {host, port, name}' config.yaml    # Better than multiple calls

# Use eval-all for multiple files
yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' file1.yaml file2.yaml
```

## Version 4.46.1 Features

### New in v4.46.1
- **INI Support**: Added support for INI file processing
- **Bug Fixes**: Fixed 'add' operator when piped with no data
- **Stability**: Fixed delete after slice problems
- **Dependencies**: Switched to YAML.org supported go-yaml
- **Build**: Fixed yq small build issues

### Compatibility Notes
- Maintains backward compatibility with v4.x syntax
- Enhanced error handling and reporting
- Improved performance for large files
- Better Unicode and special character support

---

*For the most up-to-date documentation and examples, visit the [official yq documentation](https://mikefarah.gitbook.io/yq/) and [GitHub repository](https://github.com/mikefarah/yq).*