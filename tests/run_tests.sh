#!/bin/bash

# --- run_tests.sh ---
# Test runner script for abuse_scanner.sh
# Author: Test Suite
# Description: Helper script to run tests with proper setup and reporting

set -euo pipefail

# --- CONFIGURATION ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_FILE="$SCRIPT_DIR/test.bats"
SCANNER_SCRIPT="$PROJECT_ROOT/abuse_scanner.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- FUNCTIONS ---

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Hosting Abuse Scanner Tests${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_requirements() {
    print_info "Checking requirements..."
    
    local missing_requirements=()
    
    # Check if bats is installed
    if ! command -v bats &> /dev/null; then
        missing_requirements+=("bats-core")
    else
        print_success "bats-core is installed"
    fi
    
    # Check if scanner script exists
    if [ ! -f "$SCANNER_SCRIPT" ]; then
        print_error "Scanner script not found: $SCANNER_SCRIPT"
        return 1
    else
        print_success "Scanner script found"
    fi
    
    # Check if scanner script is executable
    if [ ! -x "$SCANNER_SCRIPT" ]; then
        print_warning "Scanner script is not executable, making it executable..."
        chmod +x "$SCANNER_SCRIPT"
        print_success "Scanner script is now executable"
    else
        print_success "Scanner script is executable"
    fi
    
    # Check if test file exists
    if [ ! -f "$TEST_FILE" ]; then
        print_error "Test file not found: $TEST_FILE"
        return 1
    else
        print_success "Test file found"
    fi
    
    # Check system tools
    local required_tools=("bash" "dd" "grep" "awk" "sort" "mktemp")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_requirements+=("$tool")
        else
            print_success "$tool is available"
        fi
    done
    
    if [ ${#missing_requirements[@]} -gt 0 ]; then
        print_error "Missing requirements: ${missing_requirements[*]}"
        echo
        print_info "Installation instructions:"
        echo "  Ubuntu/Debian: sudo apt-get install bats"
        echo "  macOS: brew install bats-core"
        echo "  Manual: https://github.com/bats-core/bats-core"
        return 1
    fi
    
    echo
    return 0
}

run_tests() {
    local test_args=("$TEST_FILE")
    
    # Add additional arguments if provided
    if [ $# -gt 0 ]; then
        test_args+=("$@")
    fi
    
    print_info "Running tests..."
    echo
    
    # Run bats with the test file
    if bats "${test_args[@]}"; then
        echo
        print_success "All tests passed!"
        return 0
    else
        echo
        print_error "Some tests failed!"
        return 1
    fi
}

run_specific_test() {
    local test_pattern="$1"
    print_info "Running tests matching: $test_pattern"
    echo
    
    if bats "$TEST_FILE" -f "$test_pattern"; then
        echo
        print_success "Selected tests passed!"
        return 0
    else
        echo
        print_error "Selected tests failed!"
        return 1
    fi
}

show_help() {
    cat << EOF
Usage: $0 [OPTIONS] [BATS_OPTIONS]

Options:
    -h, --help          Show this help message
    -c, --check         Check requirements only
    -t, --test PATTERN  Run specific test matching PATTERN
    -v, --verbose       Run with verbose output
    -f, --fail-fast     Stop on first failure

Examples:
    $0                  # Run all tests
    $0 --verbose        # Run all tests with verbose output
    $0 --test "Basic"   # Run tests matching "Basic"
    $0 --check          # Check requirements only
    $0 --fail-fast      # Stop on first failure

BATS Options:
    Any additional options are passed directly to bats.
    See 'bats --help' for more information.

EOF
}

# --- MAIN LOGIC ---

main() {
    local check_only=false
    local test_pattern=""
    local bats_args=()
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--check)
                check_only=true
                shift
                ;;
            -t|--test)
                test_pattern="$2"
                shift
                shift
                ;;
            -v|--verbose)
                bats_args+=("--verbose")
                shift
                ;;
            -f|--fail-fast)
                bats_args+=("--fail-fast")
                shift
                ;;
            *)
                # Pass unknown arguments to bats
                bats_args+=("$1")
                shift
                ;;
        esac
    done
    
    print_header
    
    # Check requirements
    if ! check_requirements; then
        exit 1
    fi
    
    if [ "$check_only" = true ]; then
        print_success "All requirements satisfied!"
        exit 0
    fi
    
    # Run tests
    if [ -n "$test_pattern" ]; then
        run_specific_test "$test_pattern"
    else
        run_tests "${bats_args[@]}"
    fi
}

# --- SCRIPT ENTRY POINT ---
main "$@"
