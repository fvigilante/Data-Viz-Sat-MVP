#!/bin/bash

# Test script for R Backend Process Management
# This script tests the startup, monitoring, and shutdown capabilities

set -e

# Configuration
TEST_PORT=8099
TEST_HOST="127.0.0.1"
TEST_LOG="test-process-management.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] TEST: $1"
    echo -e "${BLUE}$message${NC}"
    echo "$message" >> "$TEST_LOG"
}

error() {
    local message="[ERROR] $1"
    echo -e "${RED}$message${NC}" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] TEST: $message" >> "$TEST_LOG"
}

success() {
    local message="[SUCCESS] $1"
    echo -e "${GREEN}$message${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] TEST: $message" >> "$TEST_LOG"
}

warning() {
    local message="[WARNING] $1"
    echo -e "${YELLOW}$message${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] TEST: $message" >> "$TEST_LOG"
}

# Function to cleanup test environment
cleanup_test() {
    log "Cleaning up test environment..."
    
    # Stop any running test server
    if [ -f "r-server.pid" ]; then
        local pid=$(cat "r-server.pid")
        if kill -0 "$pid" 2>/dev/null; then
            log "Stopping test server (PID: $pid)..."
            kill -TERM "$pid" 2>/dev/null || true
            sleep 2
            kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true
        fi
        rm -f "r-server.pid" "r-server.pid.info"
    fi
    
    # Clean up test files
    rm -f "r-server.log" "server-shutdown.info" "server-metrics.log"
    
    log "Test cleanup completed"
}

# Function to test server startup
test_startup() {
    log "Testing server startup..."
    
    # Test basic startup
    if ./start-server.sh "$TEST_PORT" "$TEST_HOST" true; then
        success "Server startup test passed"
        
        # Wait a moment for server to fully initialize
        sleep 3
        
        # Test if server is responding
        if command -v curl &> /dev/null; then
            if curl -s --max-time 5 "http://$TEST_HOST:$TEST_PORT/health" > /dev/null 2>&1; then
                success "Server health check test passed"
            else
                error "Server health check test failed"
                return 1
            fi
        else
            warning "curl not available, skipping health check test"
        fi
        
        return 0
    else
        error "Server startup test failed"
        return 1
    fi
}

# Function to test server status
test_status() {
    log "Testing server status..."
    
    if ./server-status.sh "$TEST_PORT" "$TEST_HOST" > /dev/null 2>&1; then
        success "Server status test passed"
        return 0
    else
        error "Server status test failed"
        return 1
    fi
}

# Function to test process manager
test_process_manager() {
    log "Testing process manager..."
    
    # Test status command
    if ./process-manager.sh status > /dev/null 2>&1; then
        success "Process manager status test passed"
    else
        error "Process manager status test failed"
        return 1
    fi
    
    # Test logs command
    if ./process-manager.sh logs 5 > /dev/null 2>&1; then
        success "Process manager logs test passed"
    else
        error "Process manager logs test failed"
        return 1
    fi
    
    return 0
}

# Function to test graceful shutdown
test_shutdown() {
    log "Testing graceful shutdown..."
    
    if ./stop-server.sh; then
        success "Server shutdown test passed"
        
        # Check if shutdown info was created
        if [ -f "server-shutdown.info" ]; then
            success "Shutdown info file created successfully"
            log "Shutdown info contents:"
            cat "server-shutdown.info" >> "$TEST_LOG"
        else
            warning "Shutdown info file not created"
        fi
        
        return 0
    else
        error "Server shutdown test failed"
        return 1
    fi
}

# Function to test configuration
test_configuration() {
    log "Testing configuration management..."
    
    # Create test configuration
    cat > "server.conf" << EOF
# Test configuration
DEFAULT_PORT=$TEST_PORT
DEFAULT_HOST="$TEST_HOST"
STARTUP_TIMEOUT=30
R_LOG_LEVEL="DEBUG"
EOF
    
    success "Test configuration created"
    
    # Test configuration loading
    if ./process-manager.sh config > /dev/null 2>&1; then
        success "Configuration loading test passed"
        return 0
    else
        error "Configuration loading test failed"
        return 1
    fi
}

# Main test function
run_tests() {
    log "Starting R Backend Process Management Tests"
    log "=========================================="
    
    local tests_passed=0
    local tests_failed=0
    
    # Cleanup before starting
    cleanup_test
    
    # Test 1: Configuration
    log "Test 1: Configuration Management"
    if test_configuration; then
        tests_passed=$((tests_passed + 1))
    else
        tests_failed=$((tests_failed + 1))
    fi
    
    # Test 2: Startup
    log "Test 2: Server Startup"
    if test_startup; then
        tests_passed=$((tests_passed + 1))
    else
        tests_failed=$((tests_failed + 1))
        cleanup_test
        return 1
    fi
    
    # Test 3: Status
    log "Test 3: Server Status"
    if test_status; then
        tests_passed=$((tests_passed + 1))
    else
        tests_failed=$((tests_failed + 1))
    fi
    
    # Test 4: Process Manager
    log "Test 4: Process Manager"
    if test_process_manager; then
        tests_passed=$((tests_passed + 1))
    else
        tests_failed=$((tests_failed + 1))
    fi
    
    # Test 5: Shutdown
    log "Test 5: Graceful Shutdown"
    if test_shutdown; then
        tests_passed=$((tests_passed + 1))
    else
        tests_failed=$((tests_failed + 1))
    fi
    
    # Cleanup after tests
    cleanup_test
    
    # Summary
    log "Test Results Summary"
    log "==================="
    log "Tests passed: $tests_passed"
    log "Tests failed: $tests_failed"
    
    if [ $tests_failed -eq 0 ]; then
        success "All tests passed!"
        return 0
    else
        error "Some tests failed. Check $TEST_LOG for details."
        return 1
    fi
}

# Handle script arguments
case "${1:-}" in
    cleanup)
        cleanup_test
        ;;
    startup)
        test_startup
        ;;
    status)
        test_status
        ;;
    shutdown)
        test_shutdown
        ;;
    config)
        test_configuration
        ;;
    *)
        run_tests
        ;;
esac