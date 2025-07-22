# Unix/BSD Utilities Documentation for macOS

This document covers essential Unix command-line utilities as they exist on macOS, which uses BSD (Berkeley Software Distribution) implementations rather than GNU versions commonly found on Linux systems.

## Key Differences: BSD vs GNU

macOS ships with BSD-style command-line tools, which differ from GNU/Linux tools in several important ways:

- **Regular Expressions**: BSD tools use POSIX-compatible regex, while GNU tools often support Perl-compatible regex (PCRE)
- **Command Options**: Option flags and syntax can vary between implementations
- **Feature Sets**: GNU versions typically include more features and extended functionality
- **Escape Sequences**: BSD tools have limited support for escape sequences like `\n`, `\t`, etc.

### Installing GNU Alternatives

If you need GNU tool compatibility, install them via Homebrew:
```bash
brew install coreutils gnu-sed gnu-tar grep gawk findutils
```

Then add to your shell profile to use GNU tools by default:
```bash
if type brew &>/dev/null; then
  HOMEBREW_PREFIX=$(brew --prefix)
  for d in ${HOMEBREW_PREFIX}/opt/*/libexec/gnubin; do 
    export PATH=$d:$PATH
  done
fi
```

## Text Processing Commands

### grep - Search Text Patterns

**BSD grep** is POSIX-compliant and uses basic/extended regular expressions.

#### Syntax
```bash
grep [options] "pattern" [file...]
```

#### Key Options
- `-i` - Case insensitive search
- `-n` - Show line numbers
- `-v` - Invert match (show non-matching lines)
- `-w` - Match whole words only
- `-r` - Recursive search through directories
- `-l` - Show only filenames containing matches
- `-L` - Show only filenames NOT containing matches
- `-c` - Count matching lines
- `-A NUM` - Show NUM lines after each match
- `-B NUM` - Show NUM lines before each match
- `-C NUM` - Show NUM lines before and after each match
- `-E` - Use extended regular expressions (equivalent to `egrep`)
- `-F` - Treat patterns as fixed strings (equivalent to `fgrep`)
- `-q` - Quiet mode (exit status only)

#### Examples
```bash
# Basic search
grep "error" logfile.txt

# Case insensitive with line numbers
grep -in "warning" *.log

# Search recursively
grep -r "TODO" src/

# Show context around matches
grep -C 3 "exception" app.log

# Count occurrences
grep -c "success" results.txt

# Find files containing pattern
grep -l "config" *.conf

# Use extended regex
grep -E "[0-9]{3}-[0-9]{3}-[0-9]{4}" contacts.txt
```

#### BSD vs GNU Differences
- BSD grep uses `-E` for extended regex; GNU uses `-r` (though `-E` works in newer GNU)
- Lazy matching behaves differently between implementations
- BSD grep may handle Unicode differently than GNU grep

### sed - Stream Editor

**BSD sed** is a stream editor for filtering and transforming text.

#### Syntax
```bash
sed [options] 'command' [file...]
```

#### Key Options
- `-i [suffix]` - Edit files in-place (requires suffix on BSD, optional on GNU)
- `-e` - Add script command
- `-f` - Read script from file
- `-n` - Suppress automatic output
- `-E` - Use extended regular expressions

#### Common Commands
- `s/pattern/replacement/flags` - Substitute
- `d` - Delete lines
- `p` - Print lines
- `a\text` - Append text after line
- `i\text` - Insert text before line
- `c\text` - Change (replace) lines

#### Examples
```bash
# Basic substitution
sed 's/old/new/' file.txt

# Global substitution (all occurrences per line)
sed 's/old/new/g' file.txt

# In-place editing (BSD requires empty string for no backup)
sed -i '' 's/old/new/g' file.txt

# Delete lines containing pattern
sed '/pattern/d' file.txt

# Print only lines 5-10
sed -n '5,10p' file.txt

# Multiple commands
sed -e 's/foo/bar/g' -e 's/hello/hi/g' file.txt

# Use extended regex
sed -E 's/[0-9]+/NUMBER/g' file.txt
```

#### BSD vs GNU Differences
- **In-place editing**: BSD requires suffix argument: `sed -i '' ...` (no backup) or `sed -i '.bak' ...` (with backup)
- **Extended regex**: BSD uses `-E`, GNU uses `-r` (both support `-E` in newer versions)
- **Escape sequences**: BSD sed has limited support for `\n`, `\t`, etc. in replacement strings
- **Advanced features**: GNU sed supports more advanced features like address ranges and special escapes

### awk - Pattern Scanning and Processing

**macOS comes with nawk** (new awk), which is a BSD implementation.

#### Syntax
```bash
awk 'pattern { action }' [file...]
```

#### Key Features
- Field variables: `$1`, `$2`, etc. (`$0` = entire line)
- Built-in variables: `NR` (line number), `NF` (number of fields), `FS` (field separator)
- Pattern matching with regular expressions
- Mathematical operations and string functions

#### Examples
```bash
# Print specific fields
awk '{print $1, $3}' file.txt

# Print lines longer than 80 characters
awk 'length($0) > 80' file.txt

# Sum values in column 2
awk '{sum += $2} END {print sum}' numbers.txt

# Use custom field separator
awk -F',' '{print $1}' data.csv

# Pattern matching
awk '/error/ {print $0}' logfile.txt

# Conditional processing
awk '$3 > 100 {print $1 " has value " $3}' data.txt

# Format output
awk '{printf "%-10s %s\n", $1, $2}' file.txt
```

#### BSD vs GNU Differences
- **GNU awk (gawk)** has many more built-in functions and features
- **BSD awk** is more limited but POSIX-compliant
- Install GNU awk via `brew install gawk` to use as `gawk`

### cut - Extract Columns

**cut** extracts specific columns or character positions from text.

#### Syntax
```bash
cut [options] [file...]
```

#### Key Options
- `-d DELIM` - Specify field delimiter
- `-f LIST` - Select fields by number
- `-c LIST` - Select characters by position
- `-b LIST` - Select bytes by position

#### Examples
```bash
# Extract first and third fields (tab-delimited)
cut -f1,3 file.txt

# Extract with custom delimiter
cut -d',' -f2,4 data.csv

# Extract character positions
cut -c1-10 file.txt

# Extract from position 5 to end
cut -c5- file.txt

# Use with other commands
ps aux | cut -d' ' -f1,11
```

### tr - Translate Characters

**tr** translates or deletes characters from input.

#### Syntax
```bash
tr [options] SET1 [SET2]
```

#### Key Options
- `-d` - Delete characters in SET1
- `-s` - Squeeze multiple consecutive characters into one
- `-c` - Complement SET1 (operate on characters NOT in set)

#### Examples
```bash
# Convert uppercase to lowercase
echo "HELLO" | tr '[:upper:]' '[:lower:]'

# Delete specific characters
echo "hello123world" | tr -d '[:digit:]'

# Replace spaces with newlines
echo "word1 word2 word3" | tr ' ' '\n'

# Squeeze multiple spaces into one
echo "hello    world" | tr -s ' '

# Delete all non-alphanumeric characters
echo "hello@#$world" | tr -cd '[:alnum:]'
```

### sort - Sort Lines

**sort** sorts lines of text files.

#### Syntax
```bash
sort [options] [file...]
```

#### Key Options
- `-n` - Numeric sort
- `-r` - Reverse order
- `-u` - Remove duplicates
- `-k FIELD` - Sort by specific field
- `-t DELIM` - Field separator
- `-f` - Case insensitive
- `-M` - Sort by month name
- `-h` - Human numeric sort (1K, 2M, etc.)

#### Examples
```bash
# Basic sort
sort file.txt

# Numeric sort
sort -n numbers.txt

# Reverse sort
sort -r file.txt

# Sort by second field
sort -k2 data.txt

# Sort CSV by third column
sort -t',' -k3 data.csv

# Sort and remove duplicates
sort -u file.txt

# Human readable size sort
du -h * | sort -h
```

### uniq - Remove Duplicate Lines

**uniq** removes consecutive duplicate lines.

#### Syntax
```bash
uniq [options] [file]
```

#### Key Options
- `-c` - Prefix lines with occurrence count
- `-d` - Show only duplicate lines
- `-u` - Show only unique lines
- `-i` - Case insensitive comparison
- `-f N` - Skip first N fields
- `-s N` - Skip first N characters

#### Examples
```bash
# Remove consecutive duplicates
sort file.txt | uniq

# Count occurrences
sort file.txt | uniq -c

# Show only duplicates
sort file.txt | uniq -d

# Show only unique lines
sort file.txt | uniq -u

# Case insensitive
sort file.txt | uniq -i
```

## File Operations

### cat - Display File Contents

**cat** concatenates and displays files.

#### Syntax
```bash
cat [options] [file...]
```

#### Key Options
- `-n` - Number all lines
- `-b` - Number non-blank lines
- `-s` - Squeeze multiple blank lines into one
- `-A` - Show all characters (including non-printing)
- `-E` - Show line endings with `$`
- `-T` - Show tabs as `^I`

#### Examples
```bash
# Display file
cat file.txt

# Concatenate files
cat file1.txt file2.txt > combined.txt

# Number lines
cat -n script.sh

# Show hidden characters
cat -A file.txt

# Create file (here document)
cat > newfile.txt << EOF
Line 1
Line 2
EOF
```

### head - Display First Lines

**head** displays the first lines of files.

#### Syntax
```bash
head [options] [file...]
```

#### Key Options
- `-n NUM` - Show first NUM lines (default: 10)
- `-c NUM` - Show first NUM characters
- `-q` - Suppress filename headers
- `-v` - Always show filename headers

#### Examples
```bash
# Show first 10 lines
head file.txt

# Show first 5 lines
head -n 5 file.txt

# Show first 100 characters
head -c 100 file.txt

# Multiple files
head -n 3 *.txt
```

### tail - Display Last Lines

**tail** displays the last lines of files.

#### Syntax
```bash
tail [options] [file...]
```

#### Key Options
- `-n NUM` - Show last NUM lines (default: 10)
- `-c NUM` - Show last NUM characters
- `-f` - Follow file changes (monitor)
- `-F` - Follow with retry (handle log rotation)
- `-q` - Suppress filename headers
- `-v` - Always show filename headers

#### Examples
```bash
# Show last 10 lines
tail file.txt

# Show last 20 lines
tail -n 20 file.txt

# Monitor log file
tail -f /var/log/system.log

# Follow multiple files
tail -f *.log

# Follow with retry
tail -F /var/log/app.log
```

### wc - Word Count

**wc** counts lines, words, and characters in files.

#### Syntax
```bash
wc [options] [file...]
```

#### Key Options
- `-l` - Count lines only
- `-w` - Count words only
- `-c` - Count characters (bytes)
- `-m` - Count characters (multibyte aware)

#### Examples
```bash
# Show lines, words, characters
wc file.txt

# Count lines only
wc -l file.txt

# Count words only
wc -w file.txt

# Multiple files
wc *.txt

# Use with pipes
ps aux | wc -l
```

### find - Search for Files

**find** searches for files and directories.

#### Syntax
```bash
find [path] [expression]
```

#### Key Options
- `-name pattern` - Find by name
- `-iname pattern` - Case insensitive name search
- `-type f|d|l` - Find files, directories, or links
- `-size [+-]N[cwbkMG]` - Find by size
- `-mtime [+-]N` - Find by modification time
- `-exec command {} \;` - Execute command on results
- `-print0` - Null-separated output

#### Examples
```bash
# Find files by name
find . -name "*.txt"

# Case insensitive search
find . -iname "*.LOG"

# Find directories only
find . -type d

# Find files larger than 100MB
find . -type f -size +100M

# Find files modified in last 24 hours
find . -type f -mtime -1

# Execute command on results
find . -name "*.tmp" -exec rm {} \;

# Find and delete empty directories
find . -type d -empty -delete
```

#### BSD vs GNU Differences
- **Regex handling**: BSD find requires `-E` flag for extended regex
- **Flag placement**: BSD find may require flags before path arguments
- **Feature sets**: GNU find has more predicates and options

### ls - List Directory Contents

**ls** lists files and directories.

#### Syntax
```bash
ls [options] [file...]
```

#### Key Options
- `-l` - Long format (detailed)
- `-a` - Show hidden files (starting with .)
- `-A` - Show hidden files except . and ..
- `-h` - Human readable sizes
- `-t` - Sort by modification time
- `-r` - Reverse order
- `-S` - Sort by size
- `-R` - Recursive listing
- `-G` - Colorize output (BSD)
- `--color` - Colorize output (GNU)

#### Examples
```bash
# Basic listing
ls

# Long format with hidden files
ls -la

# Human readable sizes
ls -lh

# Sort by time (newest first)
ls -lt

# Recursive listing
ls -R

# Sort by size
ls -lS

# Show only directories
ls -d */
```

## System Utilities

### date - Display/Set Date

**date** displays or sets the system date.

#### Syntax
```bash
date [options] [+format]
```

#### Key Options
- `-u` - Display UTC time
- `-r seconds` - Display date from Unix timestamp
- `+format` - Custom format output

#### Format Specifiers
- `%Y` - Four-digit year
- `%y` - Two-digit year
- `%m` - Month (01-12)
- `%d` - Day of month (01-31)
- `%H` - Hour (00-23)
- `%M` - Minute (00-59)
- `%S` - Second (00-59)
- `%a` - Abbreviated weekday
- `%A` - Full weekday name
- `%b` - Abbreviated month
- `%B` - Full month name

#### Examples
```bash
# Current date and time
date

# Custom format
date "+%Y-%m-%d %H:%M:%S"

# UTC time
date -u

# From Unix timestamp
date -r 1609459200

# ISO format
date "+%Y-%m-%dT%H:%M:%S"

# For filenames
date "+%Y%m%d_%H%M%S"
```

### basename - Extract Filename

**basename** extracts the filename from a path.

#### Syntax
```bash
basename path [suffix]
```

#### Examples
```bash
# Extract filename
basename /path/to/file.txt
# Output: file.txt

# Remove suffix
basename /path/to/file.txt .txt
# Output: file

# Multiple files (BSD extension)
basename -a /path/to/file1.txt /path/to/file2.txt
# Output: file1.txt
#         file2.txt

# Use in scripts
for file in *.txt; do
    echo "Processing $(basename "$file" .txt)"
done
```

### dirname - Extract Directory Path

**dirname** extracts the directory path from a file path.

#### Syntax
```bash
dirname path
```

#### Examples
```bash
# Extract directory
dirname /path/to/file.txt
# Output: /path/to

# Root directory
dirname /file.txt
# Output: /

# Current directory
dirname file.txt
# Output: .

# Use in scripts
script_dir=$(dirname "$0")
```

### pwd - Print Working Directory

**pwd** prints the current working directory.

#### Syntax
```bash
pwd [options]
```

#### Key Options
- `-L` - Logical path (follow symlinks) - default
- `-P` - Physical path (resolve symlinks)

#### Examples
```bash
# Current directory
pwd

# Physical path (resolve symlinks)
pwd -P

# Use in scripts
current_dir=$(pwd)
echo "Working in: $current_dir"
```

## Process Management

### ps - Process Status

**ps** displays information about running processes.

#### Syntax
```bash
ps [options]
```

#### Key Options
- `aux` - Show all processes with detailed info
- `-ef` - Alternative detailed format
- `-p PID` - Show specific process
- `-u USER` - Show processes for user
- `-o format` - Custom output format

#### Examples
```bash
# Show all processes
ps aux

# Show process tree
ps aux | grep -v grep | sort

# Find specific process
ps aux | grep firefox

# Show processes for user
ps -u username

# Custom format
ps -o pid,ppid,user,command

# Show CPU usage sorted
ps aux --sort=-%cpu | head -10
```

### pgrep - Find Process IDs

**pgrep** finds process IDs by name or pattern.

#### Syntax
```bash
pgrep [options] pattern
```

#### Key Options
- `-f` - Match against full command line
- `-i` - Case insensitive
- `-v` - Invert match
- `-x` - Exact match
- `-u USER` - Match user
- `-l` - List process names too

#### Examples
```bash
# Find by name
pgrep firefox

# Case insensitive
pgrep -i FIREFOX

# Exact match
pgrep -x "Google Chrome"

# Show names too
pgrep -l chrome

# By user
pgrep -u root
```

**Note**: pgrep is not installed by default on macOS but can be installed via Homebrew.

### kill - Terminate Processes

**kill** sends signals to processes.

#### Syntax
```bash
kill [signal] PID
```

#### Common Signals
- `TERM` (15) - Graceful termination (default)
- `KILL` (9) - Force kill (cannot be caught)
- `HUP` (1) - Hangup (reload config)
- `USR1` (10) - User-defined signal 1
- `USR2` (12) - User-defined signal 2

#### Examples
```bash
# Graceful termination
kill 1234

# Force kill
kill -9 1234
kill -KILL 1234

# Send HUP signal
kill -HUP 1234

# List available signals
kill -l

# Kill multiple processes
kill 1234 5678 9012
```

### pkill - Kill Processes by Name

**pkill** kills processes by name or pattern.

#### Syntax
```bash
pkill [options] pattern
```

#### Key Options
- `-f` - Match against full command line
- `-i` - Case insensitive
- `-x` - Exact match
- `-u USER` - Match user
- `-signal` - Send specific signal

#### Examples
```bash
# Kill by name
pkill firefox

# Case insensitive
pkill -i FIREFOX

# Exact match
pkill -x "Google Chrome"

# Force kill
pkill -9 chrome

# By user
pkill -u username
```

### test - File and String Tests

**test** evaluates conditional expressions.

#### Syntax
```bash
test expression
[ expression ]
[[ expression ]]  # Bash extension
```

#### File Tests
- `-e file` - File exists
- `-f file` - Regular file exists
- `-d file` - Directory exists
- `-r file` - File is readable
- `-w file` - File is writable
- `-x file` - File is executable
- `-s file` - File exists and is not empty
- `-L file` - File is a symbolic link

#### String Tests
- `-z string` - String is empty
- `-n string` - String is not empty
- `string1 = string2` - Strings are equal
- `string1 != string2` - Strings are not equal

#### Numeric Tests
- `n1 -eq n2` - Numbers are equal
- `n1 -ne n2` - Numbers are not equal
- `n1 -lt n2` - n1 less than n2
- `n1 -le n2` - n1 less than or equal to n2
- `n1 -gt n2` - n1 greater than n2
- `n1 -ge n2` - n1 greater than or equal to n2

#### Examples
```bash
# File tests
if [ -f "file.txt" ]; then
    echo "File exists"
fi

# Directory test
if [ -d "/path/to/dir" ]; then
    echo "Directory exists"
fi

# String tests
if [ -z "$var" ]; then
    echo "Variable is empty"
fi

# Numeric comparison
if [ "$count" -gt 10 ]; then
    echo "Count is greater than 10"
fi

# Complex conditions
if [ -f "config.txt" ] && [ -r "config.txt" ]; then
    echo "Config file exists and is readable"
fi

# Using [[ ]] (Bash)
if [[ -f "file.txt" && "$user" == "admin" ]]; then
    echo "File exists and user is admin"
fi
```

## Common Text Processing Pipelines

### Log Analysis
```bash
# Find most frequent IP addresses in access log
awk '{print $1}' access.log | sort | uniq -c | sort -nr | head -10

# Extract and count HTTP status codes
awk '{print $9}' access.log | sort | uniq -c | sort -nr

# Show errors from log with context
grep -B2 -A2 "ERROR" application.log
```

### Data Processing
```bash
# Process CSV: extract column, sort, count unique values
cut -d',' -f3 data.csv | sort | uniq -c | sort -nr

# Convert text to word frequency list
tr -c '[:alnum:]' '\n' < text.txt | tr '[:upper:]' '[:lower:]' | \
sed '/^$/d' | sort | uniq -c | sort -nr

# Extract email addresses from text
grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' file.txt
```

### System Monitoring
```bash
# Find processes using most CPU
ps aux --sort=-%cpu | head -10

# Monitor disk usage of directories
du -h * | sort -h

# Watch log file for specific patterns
tail -f /var/log/system.log | grep --line-buffered "ERROR"
```

## Best Practices

1. **Use quotes** around variables and patterns to handle spaces and special characters
2. **Test commands** on sample data before running on important files
3. **Use `--` separator** when filenames might start with dashes
4. **Combine commands** with pipes for powerful text processing
5. **Consider GNU alternatives** for advanced features or Linux compatibility
6. **Check exit codes** in scripts using `$?`
7. **Use `set -e`** in scripts to exit on first error
8. **Validate input** before processing in scripts

## Environment Variables

Several environment variables affect command behavior:

- `LC_CTYPE` - Character type for locale-sensitive operations
- `LC_COLLATE` - Sorting order for sort operations
- `LANG` - Default locale setting
- `GREP_OPTIONS` - Default options for grep (deprecated)
- `PAGER` - Program used to display long output (less, more)

## Exit Codes

Most commands follow standard Unix exit code conventions:
- `0` - Success
- `1` - General error or no matches found
- `2` - Misuse of command (invalid options)
- `>2` - Specific error conditions

Use `echo $?` immediately after a command to see its exit code.