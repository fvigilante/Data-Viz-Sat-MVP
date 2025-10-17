#!/bin/bash

# R Backend Server Stop Script
# This script gracefully stops the R Plumber API server

set -e

# Configuration
PID_FILE="r-server.pid"
LOG_FILE="r-server.log"
SHUTDOWN_TIMEOUT=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log "Stopping R Volcano Plot API Server..."

# Check if PID file exists
if [ ! -f "$PID_FILE" ]; then
    warning "PID file not found. Server may not be running."
    exit 0
fi

# Read PID from file
PID=$(cat "$PID_FILE")

# Check if process is actually running
if ! kill -0 "$PID" 2>/dev/null; then
    warning "Process with PID $PID is not running"
    rm -f "$PID_FILE"
    success "Cleaned up stale PID file"
    exit 0
fi

log "Found running server process (PID: $PID)"

# Send SIGTERM for graceful shutdown
log "Sending SIGTERM signal for graceful shutdown..."
kill -TERM "$PID"

# Wait for graceful shutdown
elapsed=0
while kill -0 "$PID" 2>/dev/null && [ $elapsed -lt $SHUTDOWN_TIMEOUT ]; do
    sleep 1
    elapsed=$((elapsed + 1))
    echo -n "."
done

echo ""

# Check if process terminated gracefully
if kill -0 "$PID" 2>/dev/null; then
    warning "Process did not terminate gracefully within ${SHUTDOWN_TIMEOUT} seconds"
    log "Sending SIGKILL signal to force termination..."
    kill -KILL "$PID"
    
    # Wait a bit more
    sleep 2
    
    if kill -0 "$PID" 2>/dev/null; then
        error "Failed to terminate process $PID"
        exit 1
    else
        warning "Process forcefully terminated"
    fi
else
    success "Server stopped gracefully"
fi

# Clean up PID file
rm -f "$PID_FILE"
success "PID file cleaned up"

# Show final status
log "Server shutdown complete"
if [ -f "$LOG_FILE" ]; then
    log "Log file preserved at: $LOG_FILE"
fi