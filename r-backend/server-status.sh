#!/bin/bash

# R Backend Server Status Script
# This script checks the status of the R Plumber API server

set -e

# Configuration
PID_FILE="r-server.pid"
LOG_FILE="r-server.log"
DEFAULT_PORT=8001
DEFAULT_HOST="127.0.0.1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

# Parse command line arguments
PORT=${1:-$DEFAULT_PORT}
HOST=${2:-$DEFAULT_HOST}

echo "R Volcano Plot API Server Status Check"
echo "======================================"

# Check if PID file exists
if [ ! -f "$PID_FILE" ]; then
    error "PID file not found - server appears to be stopped"
    exit 1
fi

# Read PID from file
PID=$(cat "$PID_FILE")
log "PID file found with process ID: $PID"

# Check if process is running
if ! kill -0 "$PID" 2>/dev/null; then
    error "Process with PID $PID is not running"
    warning "Stale PID file detected - server may have crashed"
    exit 1
fi

success "Server process is running (PID: $PID)"

# Get process information
if command -v ps &> /dev/null; then
    PROCESS_INFO=$(ps -p "$PID" -o pid,ppid,cmd,etime,pcpu,pmem --no-headers 2>/dev/null || echo "Process info unavailable")
    log "Process details: $PROCESS_INFO"
fi

# Check server health via HTTP
HEALTH_URL="http://$HOST:$PORT/health"
log "Checking server health at: $HEALTH_URL"

if command -v curl &> /dev/null; then
    HEALTH_RESPONSE=$(curl -s --max-time 5 "$HEALTH_URL" 2>/dev/null)
    HEALTH_STATUS=$?
elif command -v wget &> /dev/null; then
    HEALTH_RESPONSE=$(wget -q --timeout=5 -O - "$HEALTH_URL" 2>/dev/null)
    HEALTH_STATUS=$?
else
    warning "Neither curl nor wget available - cannot check HTTP health"
    HEALTH_STATUS=1
fi

if [ $HEALTH_STATUS -eq 0 ]; then
    success "Server is responding to health checks"
    if [ -n "$HEALTH_RESPONSE" ]; then
        log "Health response: $HEALTH_RESPONSE"
    fi
else
    error "Server is not responding to health checks"
    warning "Process is running but HTTP endpoint is not accessible"
fi

# Check log file
if [ -f "$LOG_FILE" ]; then
    LOG_SIZE=$(wc -c < "$LOG_FILE" 2>/dev/null || echo "0")
    LOG_LINES=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
    log "Log file: $LOG_FILE (${LOG_SIZE} bytes, ${LOG_LINES} lines)"
    
    # Show last few log entries
    if [ "$LOG_LINES" -gt 0 ]; then
        echo ""
        echo "Recent log entries:"
        echo "==================="
        tail -n 5 "$LOG_FILE" 2>/dev/null || echo "Could not read log file"
    fi
else
    warning "Log file not found: $LOG_FILE"
fi

# Show server endpoints
echo ""
echo "Server Endpoints:"
echo "================="
echo "Health Check:    http://$HOST:$PORT/health"
echo "Cache Status:    http://$HOST:$PORT/api/cache-status"
echo "Volcano Data:    http://$HOST:$PORT/api/volcano-data"
echo "Warm Cache:      http://$HOST:$PORT/api/warm-cache (POST)"
echo "Clear Cache:     http://$HOST:$PORT/api/clear-cache (POST)"

# Overall status
echo ""
if [ $HEALTH_STATUS -eq 0 ]; then
    success "Server is running and healthy"
    exit 0
else
    error "Server has issues - check logs for details"
    exit 1
fi