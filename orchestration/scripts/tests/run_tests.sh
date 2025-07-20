#!/bin/bash

# Test runner for BATS tests

# Get the directory where this script is located
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use BATS installation - env var or fallback to project installation
if [ -n "$BATS_CMD" ]; then
    # Use environment variable if set
    if [ ! -x "$BATS_CMD" ]; then
        echo "❌ BATS command not found at: $BATS_CMD"
        exit 1
    fi
else
    # Fallback to project's BATS installation
    PROJECT_ROOT="$(cd "$TEST_DIR/../../../../.." && pwd)"
    BATS_CMD="$PROJECT_ROOT/bats/bin/bats"
    
    if [ ! -x "$BATS_CMD" ]; then
        # Final fallback to system bats
        if command -v bats &> /dev/null; then
            BATS_CMD="bats"
        else
            echo "❌ BATS not found. Options:"
            echo "  1. Set BATS_CMD environment variable to bats executable path"
            echo "  2. Install bats in project root: bats/bin/bats"
            echo "  3. Install system bats: brew install bats-core"
            exit 1
        fi
    fi
fi

echo "Using BATS: $BATS_CMD"

# Function to run tests with proper output
run_test_suite() {
    local test_path="$1"
    local suite_name="$2"
    
    echo "🧪 Running $suite_name tests..."
    echo "===========================================" 
    
    if "$BATS_CMD" "$test_path"; then
        echo "✅ $suite_name tests passed"
    else
        echo "❌ $suite_name tests failed"
        return 1
    fi
    echo ""
}

# Main test execution
main() {
    local test_type="${1:-all}"
    local failed=0
    
    echo "🚀 Starting BATS test suite for AI Agent Orchestrator"
    echo ""
    
    case "$test_type" in
        "unit")
            run_test_suite "$TEST_DIR/unit" "Unit" || failed=1
            ;;
        "integration")
            run_test_suite "$TEST_DIR/integration" "Integration" || failed=1
            ;;
        "verify")
            run_test_suite "$TEST_DIR/verify_bats.bats" "BATS Verification" || failed=1
            ;;
        "all")
            run_test_suite "$TEST_DIR/verify_bats.bats" "BATS Verification" || failed=1
            run_test_suite "$TEST_DIR/unit" "Unit" || failed=1
            run_test_suite "$TEST_DIR/integration" "Integration" || failed=1
            ;;
        *)
            echo "Usage: $0 [unit|integration|verify|all]"
            echo "  unit        - Run unit tests"
            echo "  integration - Run integration tests"
            echo "  verify      - Run BATS verification tests"
            echo "  all         - Run all tests (default)"
            exit 1
            ;;
    esac
    
    if [ $failed -eq 0 ]; then
        echo "🎉 All tests passed!"
        exit 0
    else
        echo "💥 Some tests failed!"
        exit 1
    fi
}

main "$@"