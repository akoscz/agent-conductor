#\!/bin/bash
# Test the relationship between TMUX_CMD and tmux function

# Define TMUX_CMD as true
export TMUX_CMD="true"

# Define a tmux function
tmux() {
    echo "tmux function called with: $*"
    if [[ "$1" == "has-session" ]]; then
        return 0
    elif [[ "$1" == "display-message" ]]; then
        echo "/expected/path"
    fi
}
export -f tmux

# Test what gets called
echo "Testing TMUX_CMD=$TMUX_CMD"
echo "Direct call to \$TMUX_CMD has-session:"
$TMUX_CMD has-session
echo "Exit code: $?"

echo -e "\nDirect call to tmux function:"
tmux has-session
echo "Exit code: $?"

echo -e "\nWhat is TMUX_CMD actually running:"
which $TMUX_CMD
