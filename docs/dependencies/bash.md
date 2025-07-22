# Bash 3.2.57 Documentation

## Overview

Bash (Bourne-Again SHell) version 3.2.57 is a command language interpreter that provides powerful scripting capabilities. This version is commonly found on macOS systems and represents a stable, mature implementation of the Bash shell.

## 1. Bash Scripting Fundamentals

### Script Structure
```bash
#!/bin/bash
# Script description and purpose
# Author: Your Name
# Date: YYYY-MM-DD

# Your script commands here
echo "Hello, World!"
```

### Shebang Line
- `#!/bin/bash` - Use system Bash
- `#!/usr/bin/env bash` - Use Bash from PATH (more portable)

### Comments
```bash
# Single line comment
: '
Multi-line comment
Everything between the quotes is ignored
'
```

### Script Execution
```bash
# Make script executable
chmod +x script.sh

# Execute script
./script.sh
bash script.sh
```

### Exit Status
```bash
# Exit with status code
exit 0    # Success
exit 1    # General error
exit 2    # Misuse of shell builtins

# Check exit status of last command
echo $?
```

## 2. Variable Handling and Expansion

### Variable Declaration and Assignment
```bash
# Simple assignment (no spaces around =)
name="John Doe"
age=30
readonly PI=3.14159  # Read-only variable
```

### Variable Access
```bash
echo $name           # Basic access
echo "$name"         # Quoted (preferred)
echo "${name}"       # Braced (safe)
echo "${name}xyz"    # Concatenation
```

### Special Variables
```bash
$0    # Script name
$1    # First argument
$2    # Second argument, etc.
$#    # Number of arguments
$@    # All arguments (preserves spaces)
$*    # All arguments (single string)
$$    # Process ID
$?    # Exit status of last command
$!    # PID of last background job
```

### Environment Variables
```bash
export VAR="value"   # Make available to child processes
unset VAR           # Remove variable
env                 # Display all environment variables
```

### Parameter Expansion
```bash
# Default values
${var:-default}      # Use default if var is unset or empty
${var:=default}      # Assign default if var is unset or empty
${var:+alternate}    # Use alternate if var is set
${var:?error}        # Display error if var is unset or empty

# String manipulation
${#var}              # Length of string
${var:offset}        # Substring from offset
${var:offset:length} # Substring with length
${var#pattern}       # Remove shortest match from beginning
${var##pattern}      # Remove longest match from beginning
${var%pattern}       # Remove shortest match from end
${var%%pattern}      # Remove longest match from end

# Case modification (Bash 4.0+, limited in 3.2.57)
${var^}              # Uppercase first character (not in 3.2.57)
${var^^}             # Uppercase all (not in 3.2.57)
${var,}              # Lowercase first character (not in 3.2.57)
${var,,}             # Lowercase all (not in 3.2.57)

# Pattern replacement
${var/pattern/replacement}    # Replace first match
${var//pattern/replacement}   # Replace all matches
```

### Arrays (Bash 3.0+)
```bash
# Declaration
arr=("apple" "banana" "cherry")
declare -a arr

# Assignment
arr[0]="apple"
arr[1]="banana"

# Access
echo "${arr[0]}"     # First element
echo "${arr[@]}"     # All elements
echo "${#arr[@]}"    # Number of elements
echo "${!arr[@]}"    # All indices

# Iteration
for item in "${arr[@]}"; do
    echo "$item"
done
```

## 3. Control Structures

### Conditional Statements

#### if-then-else
```bash
if [ condition ]; then
    commands
elif [ another_condition ]; then
    other_commands
else
    default_commands
fi
```

#### Test Conditions
```bash
# String comparisons
[ "$str1" = "$str2" ]     # Equal
[ "$str1" != "$str2" ]    # Not equal
[ -z "$str" ]             # Empty string
[ -n "$str" ]             # Non-empty string

# Numeric comparisons
[ "$num1" -eq "$num2" ]   # Equal
[ "$num1" -ne "$num2" ]   # Not equal
[ "$num1" -lt "$num2" ]   # Less than
[ "$num1" -le "$num2" ]   # Less than or equal
[ "$num1" -gt "$num2" ]   # Greater than
[ "$num1" -ge "$num2" ]   # Greater than or equal

# File tests
[ -f "$file" ]            # Regular file exists
[ -d "$dir" ]             # Directory exists
[ -r "$file" ]            # File is readable
[ -w "$file" ]            # File is writable
[ -x "$file" ]            # File is executable
[ -s "$file" ]            # File exists and is not empty

# Logical operators
[ condition1 ] && [ condition2 ]  # AND
[ condition1 ] || [ condition2 ]  # OR
[ ! condition ]                   # NOT
```

#### [[ ]] (Extended Test)
```bash
# Pattern matching
[[ "$str" == pattern* ]]
[[ "$str" =~ regex ]]

# Better handling of empty variables
[[ -z $var ]]  # No need to quote
```

#### case Statement
```bash
case "$variable" in
    pattern1)
        commands
        ;;
    pattern2|pattern3)
        commands
        ;;
    *)
        default_commands
        ;;
esac
```

### Loops

#### for Loop
```bash
# Iterate over list
for item in apple banana cherry; do
    echo "$item"
done

# Iterate over files
for file in *.txt; do
    echo "Processing $file"
done

# C-style for loop (Bash 3.0+)
for ((i=0; i<10; i++)); do
    echo "$i"
done

# Range (Bash 3.0+)
for i in {1..10}; do
    echo "$i"
done
```

#### while Loop
```bash
while [ condition ]; do
    commands
done

# Reading file line by line
while IFS= read -r line; do
    echo "$line"
done < file.txt
```

#### until Loop
```bash
until [ condition ]; do
    commands
done
```

#### Loop Control
```bash
break     # Exit loop
continue  # Skip to next iteration
```

## 4. Functions and Sourcing

### Function Definition
```bash
# Method 1
function_name() {
    commands
    return $?  # Optional return value (0-255)
}

# Method 2
function function_name {
    commands
}
```

### Function Parameters
```bash
my_function() {
    local param1="$1"
    local param2="$2"
    echo "First parameter: $param1"
    echo "Second parameter: $param2"
    echo "All parameters: $@"
    echo "Number of parameters: $#"
}

my_function "hello" "world"
```

### Local Variables
```bash
my_function() {
    local local_var="local value"
    global_var="global value"
}
```

### Function Return Values
```bash
get_user_input() {
    read -p "Enter your name: " name
    echo "$name"  # Return via stdout
}

result=$(get_user_input)
```

### Sourcing Scripts
```bash
# Source (include) another script
source script.sh
. script.sh      # Equivalent

# Check if file exists before sourcing
[ -f "config.sh" ] && source "config.sh"
```

## 5. Built-in Commands

### File Operations
```bash
cd directory        # Change directory
pwd                 # Print working directory
ls                  # List directory contents
mkdir directory     # Create directory
rmdir directory     # Remove empty directory
rm file             # Remove file
cp source dest      # Copy file
mv source dest      # Move/rename file
```

### Text Processing
```bash
echo "text"         # Print text
printf "format" args # Formatted output
cat file            # Display file contents
head -n 10 file     # First 10 lines
tail -n 10 file     # Last 10 lines
grep pattern file   # Search for pattern
sed 's/old/new/' file # Stream editor
awk '{print $1}' file # Text processing
```

### Variable Operations
```bash
export VAR=value    # Export variable
unset VAR           # Unset variable
readonly VAR=value  # Make variable read-only
declare -i VAR=5    # Declare integer variable
```

### Process Control
```bash
jobs                # List active jobs
bg %job             # Send job to background
fg %job             # Bring job to foreground
kill PID            # Terminate process
killall name        # Kill processes by name
```

### Input/Output
```bash
read var            # Read input into variable
read -p "Prompt: " var # Read with prompt
read -s var         # Silent read (for passwords)

# Here documents
cat << EOF
Multi-line text
goes here
EOF

# Here strings
grep "pattern" <<< "$string"
```

### Arithmetic
```bash
# Arithmetic expansion
result=$((5 + 3))
result=$((var1 * var2))

# let command
let "result = 5 + 3"
let "counter++"

# expr command (external)
result=$(expr 5 + 3)
```

### String Operations
```bash
# Length
length=${#string}

# Substring
substring=${string:2:5}

# Case conversion (limited in 3.2.57)
upper=$(echo "$string" | tr '[:lower:]' '[:upper:]')
lower=$(echo "$string" | tr '[:upper:]' '[:lower:]')
```

## 6. Compatibility Considerations for Bash 3.2.57

### Missing Features
Bash 3.2.57 lacks some features found in newer versions:

```bash
# NOT AVAILABLE in 3.2.57:
${var^}              # Case conversion operators
${var^^}
${var,}
${var,,}

mapfile              # Array assignment from command output
readarray

declare -A           # Associative arrays
declare -l           # Automatic case conversion
declare -u

&>>                  # Redirect both stdout and stderr
```

### Workarounds for Missing Features

#### Case Conversion
```bash
# Instead of ${var^}
first_upper() {
    echo "$1" | sed 's/./\U&/'
}

# Instead of ${var^^}
to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Instead of ${var,,}
to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}
```

#### Array from Command Output
```bash
# Instead of mapfile
IFS=$'\n' read -d '' -r -a lines < <(command)

# Or using while loop
while IFS= read -r line; do
    array+=("$line")
done < <(command)
```

#### Redirecting Both Streams
```bash
# Instead of &>>
command >> file 2>&1
```

### Version Detection
```bash
# Check Bash version
if [ "${BASH_VERSION%%.*}" -ge 4 ]; then
    # Use newer features
    echo "Modern Bash"
else
    # Use compatible alternatives
    echo "Older Bash"
fi
```

### Best Practices for 3.2.57 Compatibility

1. **Always quote variables**: `"$var"` instead of `$var`
2. **Use `[[ ]]` for tests** when available, fall back to `[ ]`
3. **Avoid bashisms** if portability to other shells is needed
4. **Test thoroughly** on the target version
5. **Use external tools** for features not available in 3.2.57

### Common Pitfalls

```bash
# Dangerous - word splitting
for file in $files; do  # WRONG

# Correct
for file in "$files"; do

# Better yet
while IFS= read -r file; do
    # process file
done <<< "$files"
```

### Shell Options
```bash
set -e              # Exit on error
set -u              # Exit on undefined variable
set -o pipefail     # Exit on pipe failure (Bash 3.0+)
set -x              # Debug mode

# Combined
set -euo pipefail
```

## Debugging and Best Practices

### Debugging Techniques
```bash
# Enable debug mode
bash -x script.sh

# Debug specific sections
set -x              # Turn on debugging
commands
set +x              # Turn off debugging

# Check syntax without execution
bash -n script.sh
```

### Error Handling
```bash
# Function to handle errors
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Usage
[ -f "$file" ] || error_exit "File not found: $file"

# Trap for cleanup
cleanup() {
    rm -f "$temp_file"
}
trap cleanup EXIT
```

### Performance Tips
- Use built-in commands instead of external programs when possible
- Quote variables to prevent word splitting
- Use `[[ ]]` instead of `[ ]` when available
- Avoid unnecessary subshells
- Use `printf` instead of `echo` for portable output

This documentation covers the essential features and considerations for Bash 3.2.57, providing a comprehensive reference for scripting in this environment.